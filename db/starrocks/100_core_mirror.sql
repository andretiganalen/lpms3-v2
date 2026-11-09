-- =====================================================================
-- LPMS3 · StarRocks default_catalog.lpms3 · mirror schema PostgreSQL lpms3
-- (organisasi, fungsi, kapabilitas, referensi SOP, WBS, baseline, Kurva-S)
-- Diisi oleh layanan lpms3-data (outbox lpms3.sync_outbox, upsert per PK).
-- =====================================================================
SET CATALOG default_catalog;
USE lpms3;

CREATE TABLE IF NOT EXISTS org_structure (id INT NOT NULL, code STRING, name STRING, effective_from DATE, effective_to DATE, status VARCHAR(10), synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS org_unit (id INT NOT NULL, structure_id INT, parent_id INT, code STRING, name STRING, grade VARCHAR(10), aliases JSON, hr_code STRING, sap_code STRING, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS fungsi_generik (id INT NOT NULL, code VARCHAR(10), clp_no INT, name STRING, category VARCHAR(30), involvement_mode VARCHAR(10), bop_alias JSON, active BOOLEAN, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS fungsi_unit_map (id INT NOT NULL, structure_id INT, fungsi_id INT, unit_id INT, is_primary BOOLEAN, basis_doc STRING, effective_from DATE, effective_to DATE, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS position (id INT NOT NULL, unit_id INT, title STRING, grade VARCHAR(20), is_head BOOLEAN, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS user_position (id INT NOT NULL, user_id INT, position_id INT, assignment_type VARCHAR(10), valid_from DATE, valid_to DATE, delegate_of INT, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS project_unit (project_id INT NOT NULL, unit_id INT NOT NULL, role VARCHAR(12) NOT NULL, synced_at DATETIME) PRIMARY KEY (project_id, unit_id, role) DISTRIBUTED BY HASH(project_id);
CREATE TABLE IF NOT EXISTS app_user (id INT NOT NULL, login STRING, firstname STRING, lastname STRING, mail STRING, nik STRING, status INT, sr_login STRING COMMENT 'akun StarRocks bila user memakai BI langsung', synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS project (id INT NOT NULL, identifier STRING, name STRING, kode_proyek STRING, jenis_kode VARCHAR(4), nomor_kontrak STRING, nilai_kontrak DECIMAL(20,2), kelas_kontrak VARCHAR(10), pelanggan STRING, lini_bisnis STRING, tgl_mulai DATE, tgl_selesai DATE, pimpro_user_id INT, sponsor_user_id INT, current_phase VARCHAR(20), active BOOLEAN, archived BOOLEAN, lpms2_project_id STRING, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS project_gate (project_id INT NOT NULL, gate VARCHAR(4) NOT NULL, status VARCHAR(12), decided_by INT, decided_at DATETIME, evidence JSON, synced_at DATETIME) PRIMARY KEY (project_id, gate) DISTRIBUTED BY HASH(project_id);

CREATE TABLE IF NOT EXISTS ref_jenis_kode (code VARCHAR(4) NOT NULL, name STRING, kelompok VARCHAR(16), pemilik_kode STRING, template_code STRING) PRIMARY KEY (code) DISTRIBUTED BY HASH(code);
CREATE TABLE IF NOT EXISTS ref_kelas_kontrak (kelas VARCHAR(10) NOT NULL, nilai_min DECIMAL(20,2), nilai_max DECIMAL(20,2), tinjauan_go STRING) PRIMARY KEY (kelas) DISTRIBUTED BY HASH(kelas);
CREATE TABLE IF NOT EXISTS ref_matriks_kewenangan (id INT NOT NULL, objek VARCHAR(30), nilai_min DECIMAL(20,2), nilai_max DECIMAL(20,2), pengaju STRING, penyetuju STRING, sla_hari INT, dokumen STRING, sumber_sop STRING) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS ref_level_risiko (level VARCHAR(20) NOT NULL, skor_min INT, skor_max INT, warna STRING, tindakan STRING) PRIMARY KEY (level) DISTRIBUTED BY HASH(level);

CREATE TABLE IF NOT EXISTS wbs_node (
  id BIGINT NOT NULL, project_id INT, work_package_id INT, parent_id BIGINT, wbs_code STRING, level VARCHAR(20), is_activity BOOLEAN,
  tasks STRING, notes STRING, resource STRING, priority VARCHAR(10),
  date_plan_start DATE, date_plan_finish DATE, date_actual_start DATE, date_actual_finish DATE,
  weigh_factor DECIMAL(9,6), weight DECIMAL(12,9), pct_complete DECIMAL(5,4), pct_progress DECIMAL(12,9),
  harga_pekerjaan DECIMAL(20,2), evidence_folder STRING, sort_order INT, updated_at DATETIME, synced_at DATETIME
) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS wbs_progress (id BIGINT NOT NULL, wbs_node_id BIGINT, period_month DATE, pct_complete DECIMAL(5,4), evidence_count INT, note STRING, updated_by INT, updated_at DATETIME, verified_by INT, verified_at DATETIME, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS baseline (id BIGINT NOT NULL, project_id INT, version INT, label STRING, change_request_form_id BIGINT, meeting_form_id BIGINT, approved_by INT, approved_at DATETIME, is_active BOOLEAN, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS baseline_item (baseline_id BIGINT NOT NULL, wbs_node_id BIGINT NOT NULL, wbs_code STRING, tasks STRING, level VARCHAR(20), weight DECIMAL(12,9), date_plan_start DATE, date_plan_finish DATE, harga_pekerjaan DECIMAL(20,2), synced_at DATETIME) PRIMARY KEY (baseline_id, wbs_node_id) DISTRIBUTED BY HASH(baseline_id);
CREATE TABLE IF NOT EXISTS scurve_plan (baseline_id BIGINT NOT NULL, wbs_node_id BIGINT NOT NULL, period_start DATE NOT NULL, granularity VARCHAR(6) NOT NULL, planned_weight DECIMAL(12,9), method VARCHAR(8), synced_at DATETIME) PRIMARY KEY (baseline_id, wbs_node_id, period_start, granularity) DISTRIBUTED BY HASH(baseline_id);
