-- =====================================================================
-- LPMS3 · StarRocks · LKP (FFR-708) multi-format: raw → stg → core (§13)
-- Ditulis oleh lkp-etl (ekstraksi) & plugin LPMS3 (koreksi, approval).
-- Tanpa transaksi multi-statement: status diturunkan dari log approval (append-only).
-- =====================================================================
SET CATALOG default_catalog;
USE lpms3;

CREATE TABLE IF NOT EXISTS lkp_format_profile (code VARCHAR(30) NOT NULL, version INT NOT NULL, config JSON, active BOOLEAN, created_by STRING, created_at DATETIME) PRIMARY KEY (code, version) DISTRIBUTED BY HASH(code);

CREATE TABLE IF NOT EXISTS lkp_raw_file (
  id BIGINT NOT NULL, project_id INT, period_month DATE, file_name STRING, mime STRING, sha256 VARCHAR(64), size_bytes BIGINT,
  storage_path STRING, pdf_creator STRING, pdf_producer STRING, page_count INT, sheet_names JSON, hidden_sheets JSON,
  detected_profile VARCHAR(30), uploaded_by INT, uploaded_at DATETIME
) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS lkp_raw_extract (file_id BIGINT NOT NULL, extracted_at DATETIME NOT NULL, profile_code VARCHAR(30), profile_version INT, payload JSON, warnings JSON)
PRIMARY KEY (file_id, extracted_at) DISTRIBUTED BY HASH(file_id);

CREATE TABLE IF NOT EXISTS lkp_submission (
  id BIGINT NOT NULL, project_id INT, kode_proyek STRING, period_month DATE, period_from DATE, period_to DATE,
  revision INT, is_current BOOLEAN, superseded_by BIGINT, no_laporan INT, bulan_ke INT, tanggal_pembuatan DATE,
  disiapkan_oleh STRING, jabatan STRING, source_profile VARCHAR(30), main_file_id BIGINT,
  status VARCHAR(20) COMMENT 'cache, sumber kebenaran = lkp_approval', published_level INT, is_historical BOOLEAN,
  structure_id INT, unit_id INT, created_by INT, created_at DATETIME, updated_at DATETIME
) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS lkp_header (
  submission_id BIGINT NOT NULL, nama_proyek STRING, nomor_kontrak STRING, nilai_proyek DECIMAL(20,2), mata_uang VARCHAR(5),
  tgl_mulai DATE, tgl_selesai DATE, termin_pembayaran JSON, institusi_pemberi_kerja STRING, unit_kerja_raw STRING, org_unit_id INT,
  pimpro_nama STRING, pimpro_telp STRING, akumulasi_progress DECIMAL(9,4), master_diff JSON
) PRIMARY KEY (submission_id) DISTRIBUTED BY HASH(submission_id);

CREATE TABLE IF NOT EXISTS lkp_signatory (submission_id BIGINT NOT NULL, seq INT NOT NULL, role VARCHAR(20), nama STRING, jabatan STRING, nomor_induk STRING, pihak VARCHAR(16))
PRIMARY KEY (submission_id, seq) DISTRIBUTED BY HASH(submission_id);

CREATE TABLE IF NOT EXISTS lkp_progress_line (
  id BIGINT NOT NULL, submission_id BIGINT, stage VARCHAR(5) COMMENT 'STG|CORE', line_no INT, wbs_code STRING, parent_wbs STRING, level INT,
  is_summary BOOLEAN, rincian_raw STRING, wbs_node_id BIGINT,
  bobot_a DECIMAL(9,4), rencana_kum_keg_b DECIMAL(9,4), rencana_kum_tot_c DECIMAL(9,4),
  prestasi_lalu_keg_d DECIMAL(9,4), prestasi_lalu_tot_e DECIMAL(9,4), prestasi_ini_keg_f DECIMAL(9,4), prestasi_ini_tot_g DECIMAL(9,4),
  prestasi_kum_keg_h DECIMAL(9,4), prestasi_kum_tot_i DECIMAL(9,4), deviasi_j DECIMAL(9,4),
  src_page INT, src_ref STRING, confidence DECIMAL(4,3), updated_at DATETIME
) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS lkp_total (
  submission_id BIGINT NOT NULL, rep_bobot DECIMAL(9,4), rep_rencana_kum DECIMAL(9,4), rep_prestasi_lalu DECIMAL(9,4), rep_prestasi_ini DECIMAL(9,4),
  rep_prestasi_kum DECIMAL(9,4), rep_deviasi DECIMAL(9,4), calc_bobot DECIMAL(9,4), calc_rencana_kum DECIMAL(9,4), calc_prestasi_kum DECIMAL(9,4), calc_deviasi DECIMAL(9,4)
) PRIMARY KEY (submission_id) DISTRIBUTED BY HASH(submission_id);

CREATE TABLE IF NOT EXISTS lkp_scurve_point (
  submission_id BIGINT NOT NULL, wbs_code VARCHAR(64) NOT NULL COMMENT '"*" = tingkat proyek', granularity VARCHAR(6) NOT NULL, period_start DATE NOT NULL,
  seq_label STRING, rencana DECIMAL(9,4), realisasi DECIMAL(9,4), rencana_kum DECIMAL(9,4), realisasi_kum DECIMAL(9,4), attachment_period DATE
) PRIMARY KEY (submission_id, wbs_code, granularity, period_start) DISTRIBUTED BY HASH(submission_id);

CREATE TABLE IF NOT EXISTS lkp_issue (
  submission_id BIGINT NOT NULL, no INT NOT NULL, source_form VARCHAR(10) COMMENT 'FFR-708 §5 Permasalahan | CFR-027/QFR-017',
  tanggal_laporan DATE, pelapor_unit STRING, pelapor_nama STRING, penerima_unit STRING, penerima_nama STRING, kategori STRING, detail STRING,
  analisa_penyebab STRING, kategori_5m1e JSON, tindakan_koreksi STRING, tindakan_korektif STRING, target_tgl DATE, penanggung_jawab STRING,
  status STRING, realisasi_tgl DATE, verifikasi STRING, work_package_id INT
) PRIMARY KEY (submission_id, no) DISTRIBUTED BY HASH(submission_id);

CREATE TABLE IF NOT EXISTS lkp_validation (
  id BIGINT NOT NULL, submission_id BIGINT, rule_code VARCHAR(5), severity VARCHAR(5), field STRING, expected STRING, actual STRING, message STRING,
  state VARCHAR(10), resolved_by INT, resolution_note STRING, resolved_at DATETIME
) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS lkp_correction (
  id BIGINT NOT NULL, submission_id BIGINT, table_name STRING, row_id BIGINT, field STRING, old_value STRING, new_value STRING, reason STRING,
  corrected_by INT, corrected_at DATETIME
) DUPLICATE KEY (id) DISTRIBUTED BY HASH(id);   -- append-only (jejak audit)

CREATE TABLE IF NOT EXISTS lkp_approval (
  id BIGINT NOT NULL, submission_id BIGINT, level_seq INT, level_code VARCHAR(5), actor_id INT, on_behalf_of INT,
  action VARCHAR(12) COMMENT 'SUBMIT|APPROVE|RETURN|REJECT|ACKNOWLEDGE', comment STRING, acted_at DATETIME,
  content_hash VARCHAR(64), structure_id INT, unit_id INT, fungsi_code VARCHAR(10), position_grade VARCHAR(20)
) DUPLICATE KEY (id) DISTRIBUTED BY HASH(id);   -- append-only

-- Status final per submission diturunkan dari log approval (sumber kebenaran)
CREATE VIEW IF NOT EXISTS v_lkp_status AS
SELECT s.id AS submission_id, s.project_id, s.period_month, s.revision, s.is_current,
       COALESCE(MAX(CASE WHEN a.action IN ('APPROVE','ACKNOWLEDGE') THEN a.level_seq END), 0) AS published_level,
       MAX(a.acted_at) AS last_action_at
FROM lkp_submission s LEFT JOIN lkp_approval a ON a.submission_id = s.id
GROUP BY s.id, s.project_id, s.period_month, s.revision, s.is_current;
