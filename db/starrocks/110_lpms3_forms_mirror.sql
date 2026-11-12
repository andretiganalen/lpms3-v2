-- =====================================================================
-- LPMS3 · StarRocks default_catalog.lpms3 · mirror tabel formulir (DIBANGKITKAN)
-- Sumber tulis: PostgreSQL schema lpms3_form (aplikasi). Disinkron oleh db/starrocks/900_sync_tasks.sql
-- =====================================================================
SET CATALOG default_catalog;
USE ${STARROCKS_DATABASE};

CREATE TABLE IF NOT EXISTS form_definition (code VARCHAR(20) NOT NULL, rev VARCHAR(10) NOT NULL, title STRING, phase STRING, owner_function STRING, sop_refs JSON, menu_path STRING, source_file STRING, active BOOLEAN) PRIMARY KEY (code, rev) DISTRIBUTED BY HASH(code);
CREATE TABLE IF NOT EXISTS form_instance (id BIGINT NOT NULL, form_code VARCHAR(20), form_rev VARCHAR(10), project_id INT, wbs_node_id BIGINT, doc_no STRING, period_month DATE, revision INT, is_current BOOLEAN, superseded_by BIGINT, status VARCHAR(20), published_level INT, structure_id INT, unit_id INT, source VARCHAR(20), pdf_render_file_id BIGINT, created_by INT, created_at DATETIME, updated_by INT, updated_at DATETIME, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS form_signature (id BIGINT NOT NULL, form_instance_id BIGINT, seq INT, role_label STRING, function_code VARCHAR(20), position_grade VARCHAR(30), signer_user_id INT, signer_name STRING, signer_nik VARCHAR(30), signer_jabatan STRING, external_party BOOLEAN, on_behalf_of INT, method VARCHAR(20), signed_at DATETIME, content_hash VARCHAR(64), synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);
CREATE TABLE IF NOT EXISTS form_attachment (id BIGINT NOT NULL, form_instance_id BIGINT, field_name STRING, op_attachment_id BIGINT, wbs_node_id BIGINT, ffr710_item STRING, uploaded_by INT, uploaded_at DATETIME, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr706_pengajuan_kode (
  form_instance_id BIGINT NOT NULL,
  nama_kegiatan STRING COMMENT 'Nama Proyek / Program / Transfer Load',
  kode_unit_kerja INT COMMENT 'Kode Unit Kerja | Bagian',
  jenis_kegiatan STRING COMMENT 'Kegiatan (Proyek/Program/Transfer Load)',
  lini_bisnis STRING COMMENT 'Lini Bisnis',
  lini_bisnis_lainnya STRING COMMENT 'Lini Bisnis – Others (uraian)',
  metode_revenue STRING COMMENT 'Metode Revenue',
  kode_wbs_induk STRING COMMENT 'Kode WBS Induk (petunjuk no.6)',
  customer STRING COMMENT 'Customer**',
  nilai_kontrak_netto DECIMAL(20,2) COMMENT 'Nilai Kontrak/Anggaran (netto)',
  sumber_dana STRING COMMENT 'Sumber Dana',
  nomor_kontrak STRING COMMENT 'Nomor Kontrak**',
  tanggal_kontrak DATE COMMENT 'Tanggal Kontrak**',
  jadwal_awal DATE COMMENT 'Jadwal Kontrak/Program – Awal',
  jadwal_akhir DATE COMMENT 'Jadwal Kontrak/Program – Akhir',
  account_manager INT COMMENT 'Account Manager | NIK',
  pimpinan_proyek INT COMMENT 'Pimpinan Proyek/Program/Transfer Load | NIK',
  target_rkap STRING COMMENT 'Ditargetkan dalam RKAP',
  tempat_tanggal DATE COMMENT 'Bandung, (tanggal)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'FFR-706 Pengajuan Kode Kegiatan'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_flp01_master_persyaratan (
  id INT NOT NULL,
  form_rev VARCHAR(10),
  no INT COMMENT 'No',
  dokumen_persyaratan STRING COMMENT 'Dokumen Persyaratan',
  kode_formulir STRING COMMENT 'Kode formulir terkait',
  berlaku_untuk JSON COMMENT 'Kolom checklist per jenis kode (14 kolom)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FLP-01 Checklist Persyaratan Dokumen Pengajuan Pembukaan Kode Proyek/Program/Transfer Load'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_flp01_checklist (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  persyaratan_no INT COMMENT 'No dokumen persyaratan',
  jenis_kode STRING COMMENT 'Jenis kode yang diajukan',
  checklist BOOLEAN COMMENT 'Checklist (ü)',
  dokumen_ref BIGINT COMMENT 'Dokumen/berkas bukti',
  catatan_verifikator STRING COMMENT 'Catatan verifikasi Fungsi Pengendali Anggaran',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FLP-01 Checklist Persyaratan Dokumen Pengajuan Pembukaan Kode Proyek/Program/Transfer Load'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bot001_charter (
  form_instance_id BIGINT NOT NULL,
  nama_proyek STRING COMMENT 'Nama Proyek',
  nomor_kode_proyek STRING COMMENT 'Nomor / Kode Proyek',
  sponsor INT COMMENT 'Sponsor / Pemberi Otorisasi (Nama & Jabatan)',
  project_manager INT COMMENT 'Project Manager Ditugaskan',
  tanggal_penerbitan DATE COMMENT 'Tanggal Penerbitan',
  versi_dokumen STRING COMMENT 'Versi Dokumen',
  purpose_justification STRING COMMENT '1. Purpose / Justification',
  high_level_requirements JSON COMMENT '3. High-Level Requirements',
  in_scope JSON COMMENT '4. Scope Boundaries – In-Scope',
  out_of_scope JSON COMMENT '4. Scope Boundaries – Out-of-Scope',
  total_estimasi_anggaran DECIMAL(20,2) COMMENT '7. Summary Budget – Total Estimasi Anggaran',
  mata_uang STRING COMMENT 'Mata uang (Rp/USD ...)',
  sumber_pendanaan STRING COMMENT '7. Sumber Pendanaan',
  approval_requirements STRING COMMENT '9. Approval Requirements',
  pm_nik STRING COMMENT '10. Nomor Induk Karyawan PM',
  pm_otoritas_anggaran STRING COMMENT '10. Tingkat Otoritas Anggaran',
  pm_otoritas_penugasan_sd STRING COMMENT '10. Otoritas Penugasan Sumber Daya',
  pm_otoritas_keputusan_teknis STRING COMMENT '10. Otoritas Pengambilan Keputusan Teknis',
  authorization_text STRING COMMENT '11. Authorization (pernyataan otorisasi)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_bot001_success_criteria (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  aspek STRING COMMENT 'Aspek',
  target STRING COMMENT 'Target',
  kriteria_sukses STRING COMMENT 'Kriteria Sukses',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bot001_high_level_risks (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  deskripsi_risiko STRING COMMENT 'Deskripsi Risiko',
  dampak STRING COMMENT 'Dampak (H/M/L)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bot001_timeline (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  milestone STRING COMMENT 'Milestone',
  target_tanggal DATE COMMENT 'Target Tanggal',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bot001_term_of_payment (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  urutan INT COMMENT 'Term of Payment ke-',
  persen_atau_nominal STRING COMMENT '% atau nominal',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bot001_key_stakeholders (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  nama_instansi STRING COMMENT 'Nama / Instansi',
  peran STRING COMMENT 'Peran',
  kepentingan_pengaruh STRING COMMENT 'Kepentingan / Pengaruh',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'BOT-001 Template Project Charter'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_sfr028_go_nogo (
  form_instance_id BIGINT NOT NULL,
  nomor STRING COMMENT 'No.: NN/SFR-028/XXX/MMM/YYYY',
  jenis_tinjauan STRING COMMENT 'Tinjauan Order / Kontrak',
  nama_proyek STRING COMMENT 'Nama Proyek',
  nilai_proyek DECIMAL(20,2) COMMENT 'Nilai Proyek',
  nama_pelanggan STRING COMMENT 'Nama Pelanggan',
  sumber_anggaran STRING COMMENT 'Sumber Anggaran',
  lini_bisnis STRING COMMENT 'Lini Bisnis',
  tanggal DATE COMMENT 'Tanggal',
  tempat STRING COMMENT 'Tempat',
  pemimpin_tinjauan INT COMMENT 'Pemimpin Tinjauan',
  kesimpulan_teknis STRING COMMENT '1. Kesimpulan Hasil Tinjauan Order/Kontrak – Teknis',
  kesimpulan_costing STRING COMMENT '2. Kesimpulan Hasil Tinjauan Order/Kontrak – Costing',
  aspek_risiko STRING COMMENT '3. Aspek Risiko Tinjauan Order/Kontrak',
  paparan STRING COMMENT '4. Paparan Tinjauan – Teknis, Costing, Go/No Go',
  keputusan_forum STRING COMMENT 'Keputusan Forum',
  catatan STRING COMMENT 'catatan',
  kelas_tinjauan STRING COMMENT 'Kelas tinjauan (penentu penanda tangan)',
  daftar_hadir BIGINT COMMENT 'Daftar hadir terlampir',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'SFR-028 Rapat Tinjauan Order/Kontrak – Go/No Go'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_rfr004_profil_proyek (
  form_instance_id BIGINT NOT NULL,
  nama_proyek STRING COMMENT 'Nama Proyek',
  customer STRING COMMENT 'Customer',
  lini_bisnis STRING COMMENT 'Lini Bisnis',
  risk_owner INT COMMENT 'Risk Owner',
  project_manager INT COMMENT 'Project Manager',
  tanggal_update DATE COMMENT 'Tanggal Update',
  revisi INT COMMENT 'Revisi',
  deskripsi_singkat STRING COMMENT '1 Deskripsi Singkat Proyek',
  lokasi_proyek STRING COMMENT '2 Lokasi Proyek',
  kondisi_lokasi STRING COMMENT '2 Lokasi – kondisi',
  skema_perolehan STRING COMMENT '4 Skema Perolehan Proyek',
  tgl_ttd_perjanjian DATE COMMENT '5 Tanggal Penandatanganan Perjanjian',
  status_ttd STRING COMMENT '5 Status validasi',
  jenis_waktu STRING COMMENT '6 Waktu Pelaksanaan – Jenis',
  kecukupan_waktu STRING COMMENT '6 Kecukupan Jangka Waktu',
  waktu_mulai DATE COMMENT '6 waktu pelaksanaan (… s/d …) mulai',
  waktu_selesai DATE COMMENT '6 waktu pelaksanaan (… s/d …) selesai',
  mata_uang STRING COMMENT '7 Nilai Proyek (Netto) – Mata Uang',
  nilai_proyek_netto DECIMAL(20,2) COMMENT '7 Nilai Proyek (Netto)',
  bdp_pct DECIMAL(9,4) COMMENT '8 BDP | HPP (%) – BDP',
  hpp_pct DECIMAL(9,4) COMMENT '8 BDP | HPP (%) – HPP',
  lbdp DECIMAL(20,2) COMMENT '9 LBDP | Laba Bruto – LBDP',
  laba_bruto DECIMAL(20,2) COMMENT '9 LBDP | Laba Bruto – Laba Bruto',
  ebitda_pct DECIMAL(9,4) COMMENT '10 EBITDA (%)',
  ebitda_nilai DECIMAL(20,2) COMMENT '10 EBITDA (nilai)',
  nama_customer STRING COMMENT '11 Nama Customer',
  jenis_customer STRING COMMENT '11 Jenis Customer',
  status_customer STRING COMMENT '12 Status Customer',
  sumber_anggaran STRING COMMENT '13 Sumber Anggaran',
  nama_sumber_anggaran STRING COMMENT '13 Nama Sumber Anggaran',
  term_of_payment STRING COMMENT '14 Term of Payment',
  metode_pembayaran STRING COMMENT '15 Metode Pembayaran',
  umur_piutang STRING COMMENT '16 Jatuh Tempo Pembayaran Setelah Tagihan',
  jaminan_penawaran_pct DECIMAL(9,4) COMMENT '17 Jaminan Penawaran (%)',
  jaminan_uang_muka_pct DECIMAL(9,4) COMMENT '17 Jaminan Uang Muka (%)',
  jaminan_pelaksanaan_pct DECIMAL(9,4) COMMENT '17 Jaminan Pelaksanaan (%)',
  jaminan_pembayaran_pct DECIMAL(9,4) COMMENT '17 Jaminan Pembayaran (%)',
  jaminan_pemeliharaan_pct DECIMAL(9,4) COMMENT '17 Jaminan Pemeliharaan (%)',
  jaminan_fungsional_pct DECIMAL(9,4) COMMENT '17 Jaminan Fungsional (%)',
  jaminan_lainnya STRING COMMENT '17 Jaminan Lainnya (% & uraian)',
  ppn STRING COMMENT '18 PPN',
  pph_final STRING COMMENT '18 PPh Final (Ada/Tidak Ada, %)',
  bea_impor STRING COMMENT '18 Bea Impor (Ada/Tidak Ada, %)',
  pajak_lainnya STRING COMMENT '18 Pajak/Bea Lainnya',
  posisi_len STRING COMMENT '19 Posisi Len dalam Proyek',
  kebutuhan_partnership STRING COMMENT '20 Kebutuhan Partnership',
  kategori_proyek STRING COMMENT '21 Kategori Proyek',
  jenis_order STRING COMMENT '22 Jenis Order/ Proyek',
  regulasi_khusus STRING COMMENT '23 Dipengaruhi Regulasi/ Peraturan Khusus (+penjelasan)',
  lingkup_pekerjaan JSON COMMENT '24 Ruang Lingkup: Survey, Perizinan, Desain, Pengadaan, Software, Konstruksi/infrastruktur, Instalasi, Integrasi Sistem, Pemeliharaan, Pelatihan, Produksi (Transfer Load), Operator, Lainnya',
  ketergantungan_pihak_ketiga STRING COMMENT '25 Ketergantungan Penyelesaian atas Pekerjaan Pihak Ketiga',
  pct_material_impor DECIMAL(9,4) COMMENT '26 Persentase Pengadaan Material Impor terhadap HPP',
  barang_spesifik STRING COMMENT '27 Pengadaan Barang Spesifik/ Khusus/ Customize',
  ketersediaan_personel STRING COMMENT '28 Ketersediaan Jumlah Personel',
  kebutuhan_kompetensi STRING COMMENT '29 Kebutuhan Kompetensi Personel Proyek',
  skema_bisnis BIGINT COMMENT '30 Skema Bisnis (gambar)',
  timeline_proyek BIGINT COMMENT '31 Timeline Proyek (gambar)',
  keterangan_per_butir JSON COMMENT 'Kolom KETERANGAN per butir',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'RFR-004 Profil Proyek'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_rfr005_profil_program (
  form_instance_id BIGINT NOT NULL,
  nama_program STRING COMMENT 'Nama Program Pengembangan',
  unit_pengusul INT COMMENT 'Unit Pengusul',
  jenis_program STRING COMMENT 'Jenis Program Pengembangan',
  tanggal_update DATE COMMENT 'Tanggal Update',
  revisi INT COMMENT 'Revisi ke',
  deskripsi_singkat STRING COMMENT '1 Deskripsi Singkat Program Pengembangan',
  sumber_usulan STRING COMMENT '3 Sumber Usulan Pengembangan',
  lini_bisnis STRING COMMENT '4 Lini Bisnis Terkait Produk',
  output_pengembangan STRING COMMENT '5 Output Pengembangan',
  pihak_eksternal STRING COMMENT '6 Keterlibatan pihak eksternal (+posisi)',
  haki STRING COMMENT '7 Potensi Kepemilikan HAKI',
  sertifikasi_produk STRING COMMENT '8 Potensi Kebutuhan Sertifikasi Produk',
  kajian_kelayakan STRING COMMENT '10 Kajian Kelayakan',
  mata_uang STRING COMMENT '11 Biaya Pengembangan – Mata Uang',
  biaya_pengembangan DECIMAL(20,2) COMMENT '11 Biaya Pengembangan (Netto)',
  regulasi_khusus STRING COMMENT '13 Dipengaruhi Regulasi / Aturan Khusus',
  jenis_waktu STRING COMMENT '14 Waktu Pelaksanaan Program (jenis, tgl s/d tgl)',
  ruang_lingkup JSON COMMENT '15 Ruang Lingkup Pekerjaan (Inovasi Produk, dst.)',
  pct_material_impor DECIMAL(9,4) COMMENT '16 Persentase Pengadaan Material Impor',
  barang_spesifik STRING COMMENT '17 Pengadaan Barang Spesifik/Khusus',
  ketersediaan_personel STRING COMMENT '18 Ketersediaan Jumlah Personel',
  personel_khusus STRING COMMENT '19 Kebutuhan personel berkualifikasi khusus',
  sertifikasi_tkdn STRING COMMENT '20 Sertifikasi TKDN',
  struktur_organisasi BIGINT COMMENT '21 Struktur Organisasi & Kebutuhan Kompetensi',
  skema_proses BIGINT COMMENT '22 Skema Proses Pengembangan Ide Produk',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'RFR-005 Profil Risiko Program'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_rfr002_header (
  form_instance_id BIGINT NOT NULL,
  nama_proyek STRING COMMENT 'Nama Proyek',
  customer STRING COMMENT 'Customer',
  lini_bisnis STRING COMMENT 'Lini Bisnis',
  risk_owner INT COMMENT 'Risk Owner',
  project_manager INT COMMENT 'Project Manager',
  tanggal_update DATE COMMENT 'Tanggal Update',
  revisi INT COMMENT 'Revisi',
  referensi JSON COMMENT 'Referensi (Ref) 1..3',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'RFR-002 Project Risk Register'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_rfr002_risiko (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  kategori_risiko STRING COMMENT '(2) Kategori Risiko *merujuk Standar Risiko',
  peristiwa_risiko STRING COMMENT '(3) Peristiwa Risiko *merujuk Standar Risiko',
  kode_risiko STRING COMMENT '(4) Kode Risiko (Risk Id)',
  peristiwa_lainnya STRING COMMENT '(5) Peristiwa Risiko Lainnya',
  penyebab_risiko JSON COMMENT '(6) Penyebab Risiko (bisa >1)',
  dampak_inheren_rp DECIMAL(20,2) COMMENT '(7) Dampak Risiko Inheren – Kuantitatif (Rp)',
  dampak_inheren_kualitatif JSON COMMENT '(8) Dampak Risiko Inheren – Kualitatif (bisa >1)',
  inheren_skala_dampak STRING COMMENT '(9) Risiko Inheren – Skala Dampak',
  inheren_skala_kemungkinan STRING COMMENT '(10) Risiko Inheren – Skala Kemungkinan',
  inheren_level STRING COMMENT '(11) Risiko Inheren – Level Risiko',
  rencana_penanganan JSON COMMENT '(12) Rencana Penanganan Risiko (bisa >1)',
  pic INT COMMENT '(13) PIC',
  target_waktu_penanganan DATE COMMENT '(14) Target Waktu Penanganan Risiko',
  target_res_skala_dampak STRING COMMENT '(15) Target Risiko Residual – Skala Dampak',
  target_res_skala_kemungkinan STRING COMMENT '(16) Target Risiko Residual – Skala Kemungkinan',
  target_res_level STRING COMMENT '(17) Target Risiko Residual – Level Risiko',
  realisasi_penanganan STRING COMMENT '(18) Deskripsi Realisasi Penanganan Risiko',
  realisasi_waktu_penanganan DATE COMMENT '(19) Realisasi Waktu Penanganan Risiko',
  res_skala_dampak STRING COMMENT '(20) Risiko Residual – Skala Dampak',
  res_skala_kemungkinan STRING COMMENT '(21) Risiko Residual – Skala Kemungkinan',
  res_level STRING COMMENT '(22) Risiko Residual – Level Risiko',
  dampak_residual_rp DECIMAL(20,2) COMMENT '(23) Dampak Risiko Residual – Kuantitatif (Rp)',
  dampak_residual_kualitatif JSON COMMENT '(24) Dampak Risiko Residual – Kualitatif',
  kejadian_risiko STRING COMMENT '(25) Kejadian Risiko',
  catatan STRING COMMENT '(26) Catatan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'RFR-002 Project Risk Register'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_rfr001_header (
  form_instance_id BIGINT NOT NULL,
  jenis_unit STRING COMMENT 'Divisi/Bagian',
  unit_kerja INT COMMENT 'Unit kerja',
  tahun INT COMMENT 'Tahun',
  revisi_ke INT COMMENT 'Revisi ke',
  periode STRING COMMENT 'Periode',
  tanggal_update DATE COMMENT 'Tanggal update',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'RFR-001 Risk Register Unit Kerja (kertas kerja)'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_rfr001_risiko (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  sasaran STRING COMMENT '2 Sasaran',
  peristiwa_risiko STRING COMMENT '3 Peristiwa Risiko',
  taksonomi_risiko STRING COMMENT '4 Kategori / Taksonomi Risiko',
  penyebab_risiko STRING COMMENT '5 Penyebab Risiko',
  uraian_dampak STRING COMMENT '6 Uraian Dampak',
  nilai_dampak_rp DECIMAL(20,2) COMMENT '7 Nilai Dampak (Rp)',
  kontrol_existing STRING COMMENT '8 Kontrol Yang Ada (Existing Control)',
  kecukupan STRING COMMENT '9 Kecukupan',
  efektivitas STRING COMMENT '10 Efektivitas',
  inheren_skala_dampak STRING COMMENT '11 Risiko Inheren – Skala Dampak',
  inheren_skala_kemungkinan STRING COMMENT '12 Risiko Inheren – Skala Kemungkinan',
  inheren_level STRING COMMENT '13 Risiko Inheren – Level Risiko',
  program_kerja STRING COMMENT '14 Program Kerja / Rencana Perlakuan Risiko',
  unit_terkait STRING COMMENT '15 Unit Kerja Terkait',
  anggaran_program_rp DECIMAL(20,2) COMMENT '16 Anggaran Biaya Program Kerja (Rp)',
  target_res_skala_dampak STRING COMMENT '17 Target Risiko Residual – Skala Dampak',
  target_res_skala_kemungkinan STRING COMMENT '18 Target Risiko Residual – Skala Kemungkinan',
  target_res_level STRING COMMENT '19 Target Risiko Residual – Level Risiko',
  risiko_positif STRING COMMENT '20 Risiko Positif',
  jadwal_jan_des JSON COMMENT '21–32 Target & Realisasi Waktu Pelaksanaan Program Kerja (JAN … DES)',
  deskripsi_realisasi STRING COMMENT '33 Deskripsi Realisasi Program Kerja',
  pct_realisasi DECIMAL(9,4) COMMENT '34 % Realisasi Program Kerja',
  realisasi_biaya_rp DECIMAL(20,2) COMMENT '35 Realisasi Biaya Program Kerja (Rp)',
  real_res_skala_dampak STRING COMMENT '36 Realisasi Risiko Residual – Skala Dampak',
  real_res_skala_kemungkinan STRING COMMENT '37 Realisasi Risiko Residual – Skala Kemungkinan',
  real_res_level STRING COMMENT '38 Realisasi Risiko Residual – Level Risiko',
  status_terjadi STRING COMMENT '39 Status Terjadinya Risiko',
  catatan STRING COMMENT '40 Catatan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'RFR-001 Risk Register Unit Kerja (kertas kerja)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_vfr015_header (
  form_instance_id BIGINT NOT NULL,
  divisi_bagian_unit INT COMMENT 'Divisi/Bag/Unit',
  no_review INT COMMENT 'No. Review',
  tanggal DATE COMMENT 'Tgl',
  lingkup STRING COMMENT 'Proyek / Korporasi / Subcon',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'VFR-015 Identifikasi dan Penilaian Bahaya-Risiko K3 dan Aspek-Dampak Lingkungan (HIRA)'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_vfr015_aspek_bahaya (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  aktivitas STRING COMMENT '2 Aktifitas / Obyek / Produk',
  rutin STRING COMMENT '3 Aktifitas Rutin (R) / Non Rutin (NR)',
  no_aspek_bahaya STRING COMMENT '4 No. Aspek / Bahaya',
  aspek_bahaya STRING COMMENT '5 Aspek / Bahaya',
  dampak_risiko STRING COMMENT '6 Dampak / Resiko',
  kondisi_operasional STRING COMMENT '7 Kondisi Operasional (N, Ab, E)',
  jenis_dampak STRING COMMENT '8 Jenis Dampak (+/-)',
  pengendalian_ada STRING COMMENT '9 Pengendalian Yang Ada (hierarki)',
  pengendalian_uraian STRING COMMENT '9 Pengendalian Yang Ada – uraian',
  keparahan STRING COMMENT '10 Nilai Dampak/Resiko – Keparahan',
  kemungkinan STRING COMMENT '11 Nilai Dampak/Resiko – Kemungkinan',
  total INT COMMENT '12 Total (Keparahan × Kemungkinan)',
  level_risiko STRING COMMENT '13 Level Risiko',
  aspek_signifikan STRING COMMENT '14 Aspek significant (Yes/No)',
  legal STRING COMMENT '15 Legal (peraturan terkait)',
  risiko STRING COMMENT '16 Risiko',
  peluang STRING COMMENT '17 Peluang',
  eval_legal STRING COMMENT '18 Evaluasi – Legal and Other Requirement',
  eval_teknologi STRING COMMENT '19 Evaluasi – Technological Option',
  eval_finansial STRING COMMENT '20 Evaluasi – Financial',
  eval_operasional STRING COMMENT '21 Evaluasi – Operational and Business Requirement',
  eval_pihak_berkepentingan STRING COMMENT '22 Evaluasi – View of Interested parties',
  eval_total INT COMMENT '23 Evaluasi – Total',
  pertimbangan_otp STRING COMMENT '24 Pertimbangan OTP?',
  action_plan STRING COMMENT '25 Action Plan (hierarki pengendalian)',
  no_action_plan STRING COMMENT '26 No Action Plan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'VFR-015 Identifikasi dan Penilaian Bahaya-Risiko K3 dan Aspek-Dampak Lingkungan (HIRA)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_cfr022_risalah (
  form_instance_id BIGINT NOT NULL,
  nomor STRING COMMENT 'No. 00/CFR-022/XXXX/MM/YYYY',
  jenis_rapat STRING COMMENT 'Jenis rapat (LPMS3)',
  judul_rapat STRING COMMENT 'Judul / perihal rapat',
  tanggal DATE COMMENT 'Tanggal',
  waktu_mulai STRING COMMENT 'Waktu mulai',
  waktu_selesai STRING COMMENT 'Waktu selesai',
  tempat STRING COMMENT 'Tempat / media',
  pimpinan_rapat INT COMMENT 'Pimpinan rapat',
  notulis INT COMMENT 'Notulis',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'CFR-022 Risalah Rapat'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_cfr022_agenda (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  agenda_bahasan STRING COMMENT 'I. Agenda Bahasan',
  resume_bahasan STRING COMMENT 'I. Resume Bahasan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'CFR-022 Risalah Rapat'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_cfr022_tindak_lanjut (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  isu STRING COMMENT 'II. Isu',
  tindak_lanjut STRING COMMENT 'II. Tindak-Lanjut',
  deadline DATE COMMENT 'II. Deadline',
  pic INT COMMENT 'II. PIC',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'CFR-022 Risalah Rapat'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_cfr022_peserta (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  nama INT COMMENT 'Peserta – Nama',
  fungsi_jabatan STRING COMMENT 'Peserta – Fungsi/Jabatan',
  peran_rapat STRING COMMENT 'Peran (Pemimpin, Penyelenggara, Pemapar, Peninjau aspek, Narasumber, Peserta)',
  hadir BOOLEAN COMMENT 'Kehadiran',
  delegasi_dari INT COMMENT 'Mewakili (delegasi struktural)',
  persetujuan BOOLEAN COMMENT 'Persetujuan hasil rapat (tanda tangan)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'CFR-022 Risalah Rapat'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_bfr001_change_request (
  form_instance_id BIGINT NOT NULL,
  unit_kerja INT COMMENT 'Unit Kerja',
  nama_proyek STRING COMMENT 'Nama Proyek',
  kode_proyek STRING COMMENT 'Kode Proyek',
  progres_lkp_pct DECIMAL(9,4) COMMENT 'Progres proyek (% LKP)',
  change_request_no STRING COMMENT 'Change Request No. NN/BFR-001/XXXX/MM/YYYY',
  kategori_perubahan JSON COMMENT 'Kategori Perubahan',
  latar_belakang STRING COMMENT 'Latar belakang perubahan',
  anggaran_jenis STRING COMMENT 'Perubahan Anggaran – jenis',
  anggaran_nilai_kebutuhan DECIMAL(20,2) COMMENT 'Nilai Kebutuhan Anggaran',
  anggaran_dari_wbs BIGINT COMMENT 'pergeseran dari WBS (Kode & Nama)',
  anggaran_ke_wbs BIGINT COMMENT 'ke WBS / WBS Baru (Kode & Nama)',
  scope_jenis STRING COMMENT 'Perubahan Scope Pekerjaan',
  jadwal_selesai_kontrak_awal DATE COMMENT 'Tanggal penyelesaian – kontrak awal',
  jadwal_selesai_addendum DATE COMMENT 'Tanggal penyelesaian – addendum',
  kurva_s_awal BIGINT COMMENT 'Kurva S awal (terlampir)',
  kurva_s_perubahan BIGINT COMMENT 'Kurva S perubahan (terlampir)',
  catatan_pengawasan JSON COMMENT 'Catatan Fungsi Pengawasan Proyek (checklist 18 butir)',
  catatan_eselon_pengawasan JSON COMMENT 'Catatan Eselon I/II Fungsi Pengawasan Proyek (rekomendasi 9 butir)',
  ambang_persetujuan STRING COMMENT 'Ambang persetujuan (dihitung)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'BFR-001 Formulir Change Log / Change Request'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_ffr708_cover (
  form_instance_id BIGINT NOT NULL,
  jenis_laporan STRING COMMENT 'Laporan Kemajuan Proyek/Program/Transfer Load *)',
  nama_proyek STRING COMMENT 'Nama Proyek/Program',
  kode_proyek STRING COMMENT 'Kode Proyek/Program',
  nomor_kontrak STRING COMMENT 'Nomor Kontrak',
  nilai_proyek DECIMAL(20,2) COMMENT 'Nilai Proyek/Program (Nilai tanpa PPn)',
  tanggal_mulai DATE COMMENT 'Tanggal Mulai',
  tanggal_selesai DATE COMMENT 'Tanggal Selesai',
  termin_pembayaran JSON COMMENT 'Termin Pembayaran',
  institusi_pemberi_kerja STRING COMMENT 'Institusi Pemberi Kerja',
  pimpro_nama INT COMMENT 'Nama Lengkap Pimpinan Proyek',
  pimpro_telepon STRING COMMENT 'No. Telepon',
  unit_kerja INT COMMENT 'Unit Kerja',
  nama_dokumen STRING COMMENT 'Nama Dokumen',
  periode_dari DATE COMMENT 'Periode Pelaporan – Dari',
  periode_sampai DATE COMMENT 'Periode Pelaporan – Sampai',
  akumulasi_progress_pct DECIMAL(9,4) COMMENT 'Akumulasi Progress (%)',
  disiapkan_nama INT COMMENT 'Disiapkan Oleh – Nama',
  disiapkan_jabatan STRING COMMENT 'Disiapkan Oleh – Jabatan',
  tanggal_pembuatan DATE COMMENT 'Tanggal Pembuatan',
  pemberi_kerja_nama STRING COMMENT 'Disetujui oleh Pemberi Kerja – Nama',
  pemberi_kerja_nik_nrp STRING COMMENT 'Pemberi Kerja – NIK/NRP',
  pemberi_kerja_jabatan STRING COMMENT 'Pemberi Kerja – Jabatan',
  tembusan JSON COMMENT 'Tembusan (Perencanaan Perusahaan, Keuangan, Akuntansi, Audit Internal, Es.1 Fungsi Manajemen Proyek, Arsip)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'FFR-708 Laporan Kemajuan Proyek/Program/Transfer Load (LKP)'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_ffr708_rekap (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  no_laporan INT COMMENT 'No. Laporan',
  bulan DATE COMMENT 'Bulan',
  bulan_ke INT COMMENT 'Bulan Ke',
  no STRING COMMENT 'No. (I, II, …)',
  wbs_node BIGINT COMMENT 'Rincian Kegiatan (mengikuti SoW & BoQ kontrak) → node WBS',
  bobot_a DECIMAL(9,4) COMMENT 'Bobot Kegiatan (%) a',
  rencana_kum_keg_b DECIMAL(9,4) COMMENT 'Akumulasi Rencana s/d Bulan ini – Kegiatan (%) b',
  rencana_kum_tot_c DECIMAL(9,4) COMMENT 'Akumulasi Rencana – Total (%) c = a × b',
  prestasi_lalu_keg_d DECIMAL(9,4) COMMENT 'Prestasi s/d Bulan Lalu – Kegiatan (%) d',
  prestasi_lalu_tot_e DECIMAL(9,4) COMMENT 'Prestasi s/d Bulan Lalu – Total (%) e = a × d',
  prestasi_ini_keg_f DECIMAL(9,4) COMMENT 'Prestasi Bulan Ini – Kegiatan (%) f',
  prestasi_ini_tot_g DECIMAL(9,4) COMMENT 'Prestasi Bulan Ini – Total (%) g = a × f',
  prestasi_kum_keg_h DECIMAL(9,4) COMMENT 'Akumulasi Prestasi – Kegiatan (%) h = d + f',
  prestasi_kum_tot_i DECIMAL(9,4) COMMENT 'Akumulasi Prestasi – Total (%) i = e + g',
  deviasi_j DECIMAL(9,4) COMMENT 'Deviasi (%) j = i − c',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-708 Laporan Kemajuan Proyek/Program/Transfer Load (LKP)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr708_kurva_s (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  wbs_node BIGINT COMMENT 'Rincian Kegiatan',
  bobot DECIMAL(9,4) COMMENT 'Bobot (%)',
  tahun INT COMMENT '(Tahun)',
  bulan_ke INT COMMENT 'Bulan 1 … Bulan 12',
  rencana_pct DECIMAL(9,4) COMMENT 'Rencana (P)',
  realisasi_pct DECIMAL(9,4) COMMENT 'Realisasi (A)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-708 Laporan Kemajuan Proyek/Program/Transfer Load (LKP)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr708_permasalahan (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  rincian_permasalahan STRING COMMENT 'Rincian Permasalahan',
  rencana STRING COMMENT 'Rencana',
  realisasi STRING COMMENT 'Realisasi',
  analisa_penyebab JSON COMMENT 'Analisa Penyebab (Man, Method, Material, Machine, Money, Environment)',
  tindakan_koreksi_pencegahan JSON COMMENT 'Tindakan Koreksi & Pencegahan (5M 1E)',
  pic INT COMMENT 'PIC',
  due_date DATE COMMENT 'Due Date',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-708 Laporan Kemajuan Proyek/Program/Transfer Load (LKP)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr708_pembukuan (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  dibukukan_oleh INT COMMENT 'Dibukukan Oleh',
  kode_perkiraan STRING COMMENT 'Kode Perkiraan',
  debet DECIMAL(20,2) COMMENT 'Debet',
  kredit DECIMAL(20,2) COMMENT 'Kredit',
  catatan STRING COMMENT 'Catatan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-708 Laporan Kemajuan Proyek/Program/Transfer Load (LKP)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_cfr027_ketidaksesuaian (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  jenis STRING COMMENT 'Jenis (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional)',
  tanggal_laporan DATE COMMENT 'Tanggal Laporan',
  pelapor_tipe STRING COMMENT 'Dilaporkan oleh – Unit Kerja/Pelanggan',
  pelapor_unit STRING COMMENT 'Dilaporkan oleh – Unit Kerja/Pelanggan (nama)',
  pelapor_nama STRING COMMENT 'Dilaporkan oleh – Nama Personil',
  penerima_unit INT COMMENT 'Kepada/Diterima oleh – Unit Kerja',
  penerima_nama INT COMMENT 'Kepada/Diterima oleh – Nama Personil',
  kategori STRING COMMENT 'Kategori Permasalahan',
  detail STRING COMMENT 'Detail Permasalahan',
  analisa_penyebab STRING COMMENT 'Analisa Penyebab Masalah [Man/Material/Machine/Method/Environment]',
  tindakan_koreksi STRING COMMENT 'Tindak Lanjut – Tindakan Koreksi',
  tindakan_korektif STRING COMMENT 'Tindak Lanjut – Tindakan Korektif',
  target_tanggal DATE COMMENT 'Target Tanggal Penyelesaian / Batas Waktu',
  penanggung_jawab INT COMMENT 'Penanggung Jawab',
  status STRING COMMENT 'Status (OK / On Progress / Not OK)',
  realisasi_tanggal DATE COMMENT 'Realisasi Tanggal Penyelesaian',
  verifikasi STRING COMMENT 'Verifikasi Tindak Lanjut (Belum Efektif / Sudah Efektif)',
  tanggal_verifikasi DATE COMMENT 'Tanggal Verifikasi',
  verifikator INT COMMENT 'Verifikator (nama & ttd)',
  keterangan STRING COMMENT 'Keterangan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'CFR-027 Ketidaksesuaian dan Tindakan Koreksi (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_pfr037_header (
  form_instance_id BIGINT NOT NULL,
  nomor STRING COMMENT 'Nomor',
  tempat_tanggal DATE COMMENT 'Bandung, DD-MM-YYYY',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'PFR-037 Pengajuan Proposal Pengadaan Barang/Jasa PMN'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_pfr037_item (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  alokasi_mata_anggaran STRING COMMENT 'Alokasi Mata Anggaran',
  deskripsi STRING COMMENT 'Deskripsi Barang/Jasa',
  jumlah DECIMAL(20,4) COMMENT 'Jumlah',
  satuan STRING COMMENT 'Satuan',
  rencana_kebutuhan DECIMAL(20,2) COMMENT 'Rencana Kebutuhan PMN',
  keterangan STRING COMMENT 'Keterangan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'PFR-037 Pengajuan Proposal Pengadaan Barang/Jasa PMN'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_header (
  form_instance_id BIGINT NOT NULL,
  unit_bisnis INT COMMENT 'Unit Bisnis',
  account_manager INT COMMENT 'Account Manager',
  nama_proyek STRING COMMENT 'Nama Proyek/Program',
  pimpinan_proyek INT COMMENT 'Pimpinan Proyek/Program',
  kode_sap STRING COMMENT 'Kode Proyek/Program (Kode SAP)',
  nilai_kontrak_netto DECIMAL(20,2) COMMENT 'Nilai Kontrak (Netto)',
  jadwal STRING COMMENT 'Jadwal Proyek/Program',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_ffr710_daftar_isi (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  bagian STRING COMMENT 'Bagian',
  no STRING COMMENT 'No.',
  uraian STRING COMMENT 'Uraian',
  ada_tanggal DATE COMMENT 'Checklist Kelengkapan – Ada (Tanggal)',
  tidak_ada BOOLEAN COMMENT 'Checklist – Tidak Ada',
  pj_nama INT COMMENT 'Penanggungjawab – Nama',
  pj_bagian INT COMMENT 'Penanggungjawab – Bagian',
  keterangan STRING COMMENT 'Keterangan (Dokumen Pembukaan / Penutupan Kode Proyek / Jika ada)',
  dokumen BIGINT COMMENT 'Berkas (tautan ke repositori dokumen)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_c1_pengadaan (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  tanggal DATE COMMENT 'Tanggal',
  no_dpbj STRING COMMENT 'No DPB/J',
  nilai_dpbj DECIMAL(20,2) COMMENT 'Nilai DPB/J (Rp)',
  no_spph STRING COMMENT 'No SPPH',
  no_po STRING COMMENT 'No PO',
  nilai_po DECIMAL(20,2) COMMENT 'Nilai PO (Rp)',
  supplier STRING COMMENT 'Supplier',
  barang_tiba STRING COMMENT 'Barang Tiba/ Progres Pekerjaan',
  status_kedatangan STRING COMMENT 'Status Kedatangan Barang/ Progres Pekerjaan',
  no_bapbj STRING COMMENT 'No BAPB/J (Internal)',
  kelengkapan_bast_subkon STRING COMMENT 'Kelengkapan BAST Subkontrak (Eksternal)',
  keterangan STRING COMMENT 'Keterangan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_c2_persediaan (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  kode_barang STRING COMMENT 'Kode Barang (header)',
  nama_barang STRING COMMENT 'Nama Barang (header)',
  lokasi_barang STRING COMMENT 'Lokasi Barang (header)',
  satuan STRING COMMENT 'Satuan (header)',
  pj_gudang INT COMMENT 'Penanggung Jawab Gudang (header)',
  tanggal DATE COMMENT 'Tanggal',
  no_po STRING COMMENT 'PO Pembelian (Subkontrak) – No PO',
  nilai_po DECIMAL(20,2) COMMENT 'PO – Nilai (Rp)',
  qty_po DECIMAL(20,4) COMMENT 'PO – Kuantitas',
  qty_bapb DECIMAL(20,4) COMMENT 'BAPB – Kuantitas',
  tanggal_bast DATE COMMENT 'Tanggal (BAST)',
  no_bast STRING COMMENT 'BAST Pemberi Kerja – No BAST',
  nilai_bast DECIMAL(20,2) COMMENT 'BAST – Nilai (Rp)',
  qty_bast DECIMAL(20,4) COMMENT 'BAST – Kuantitas',
  sisa DECIMAL(20,4) COMMENT 'Sisa persediaan (kolom lanjutan)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_d1_anggaran (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  periode_ke INT COMMENT 'Periode ke-n (Bulan ke-n)',
  jenis_anggaran STRING COMMENT 'Total Anggaran – Jenis Anggaran (Beban Rutin, Beban Perjalanan Dinas, …)',
  nilai_anggaran DECIMAL(20,2) COMMENT 'Total Anggaran – Nilai (Rp)',
  nilai_penyerapan DECIMAL(20,2) COMMENT 'Total Penyerapan – Nilai (Rp)',
  pct_penyerapan DECIMAL(9,4) COMMENT 'Total Penyerapan – %',
  pct_progres_lkp DECIMAL(9,4) COMMENT '% Progres – LKP',
  pct_progres_kurva_s DECIMAL(9,4) COMMENT '% Progres – Kurva-S',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_d2_d4_d7_beban (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  jenis_tabel STRING COMMENT 'Jenis tabel',
  tanggal DATE COMMENT 'Tanggal',
  no_bukti STRING COMMENT 'No Bukti',
  uraian STRING COMMENT 'Uraian',
  saldo DECIMAL(20,2) COMMENT 'Saldo',
  nama STRING COMMENT 'Nama',
  jenis_kegiatan_marketing STRING COMMENT 'Jenis Kegiatan Marketing (D7a)',
  status STRING COMMENT 'Status (pilih)',
  ptjwb_saldo_kurang DECIMAL(20,2) COMMENT 'Pertanggungjawaban (Rp) – Saldo Kurang',
  ptjwb_saldo_lebih DECIMAL(20,2) COMMENT 'Pertanggungjawaban (Rp) – Saldo Lebih',
  keterangan STRING COMMENT 'Keterangan (pilih)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_d5a_pendapatan (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  tanggal DATE COMMENT 'Tanggal',
  termin STRING COMMENT 'Termin',
  progres_lkp_pct DECIMAL(9,4) COMMENT 'Progres LKP Approval – %',
  progres_lkp_nilai DECIMAL(20,2) COMMENT 'Progres LKP Approval – Nilai (Rp)',
  invoice_pct DECIMAL(9,4) COMMENT 'Invoice – %',
  invoice_nilai DECIMAL(20,2) COMMENT 'Invoice – Nilai (Rp)',
  nilai_penerimaan DECIMAL(20,2) COMMENT 'Nilai Penerimaan Pendapatan (Rp)',
  tagihan_bruto DECIMAL(20,2) COMMENT 'Tagihan Bruto (Rp)',
  piutang_usaha DECIMAL(20,2) COMMENT 'Piutang Usaha (Rp)',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_ffr710_d5c_penjualan_retail (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  tanggal DATE COMMENT 'Tanggal',
  no_po STRING COMMENT 'No PO',
  no_transfer_load STRING COMMENT 'No Transfer Load',
  no_ppbj STRING COMMENT 'No PPBJ',
  uraian STRING COMMENT 'Uraian',
  nilai DECIMAL(20,2) COMMENT 'Nilai (Rp)',
  customer STRING COMMENT 'Customer',
  no_bpbj STRING COMMENT 'No BPBJ',
  status_penerimaan_barang STRING COMMENT 'Status Penerimaan Barang',
  status_pembayaran STRING COMMENT 'Status Pembayaran',
  keterangan STRING COMMENT 'Keterangan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'FFR-710 Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_wfr014_bast (
  form_instance_id BIGINT NOT NULL,
  jenis STRING COMMENT 'Serah Terima Pekerjaan / Pemeliharaan',
  nama_proyek STRING COMMENT 'Nama Proyek / Program',
  lokasi STRING COMMENT 'Lokasi',
  no_kontrak STRING COMMENT 'No. Kontrak',
  nilai_kontrak DECIMAL(20,2) COMMENT 'Nilai Kontrak',
  jadwal_pelaksanaan STRING COMMENT 'Jadwal Pelaksanaan',
  tanggal_bast DATE COMMENT 'Pada hari ini … tanggal … bulan … tahun',
  tempat STRING COMMENT 'Tempat',
  pihak1_nama STRING COMMENT 'PIHAK PERTAMA – Nama',
  pihak1_jabatan STRING COMMENT 'PIHAK PERTAMA – Jabatan',
  pihak1_instansi STRING COMMENT 'PIHAK PERTAMA – Instansi',
  pihak2_nama STRING COMMENT 'PIHAK KEDUA – Nama',
  pihak2_jabatan STRING COMMENT 'PIHAK KEDUA – Jabatan',
  pihak2_instansi STRING COMMENT 'PIHAK KEDUA – Instansi',
  bobot_pct DECIMAL(9,4) COMMENT 'bobot pekerjaan/pemeliharaan sebesar …%',
  nilai_rp DECIMAL(20,2) COMMENT 'dengan nilai Rp …',
  wbs_deliverable JSON COMMENT 'Deliverable/WBS yang diserahterimakan',
  distribusi JSON COMMENT 'Lembar ke: Pimpro (asli), Bag. Keuangan, Bag. …',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'WFR-014 Berita Acara Serah Terima Pekerjaan / Pemeliharaan (BAST)'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_wfr010_header (
  form_instance_id BIGINT NOT NULL,
  nomor STRING COMMENT 'No.',
  nama_proyek STRING COMMENT 'Nama Proyek/Program',
  kode_proyek STRING COMMENT 'Kode Proyek/Program',
  no_penerimaan_gudang STRING COMMENT 'No. Penerimaan Gudang',
  tanggal DATE COMMENT 'Bandung, …',
  total_rp DECIMAL(20,2) COMMENT 'Jumlah Rp.',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'WFR-010 Bukti Pengembalian Bahan Sisa Proyek/Sisa Produksi'
DISTRIBUTED BY HASH(form_instance_id);

CREATE TABLE IF NOT EXISTS form_wfr010_item (
  id BIGINT NOT NULL,
  form_instance_id BIGINT,
  line_no INT,
  kode_barang STRING COMMENT 'Kode Barang',
  nama_barang STRING COMMENT 'Nama Barang',
  satuan STRING COMMENT 'Satuan',
  jumlah DECIMAL(20,4) COMMENT 'Jumlah',
  harga_satuan DECIMAL(20,2) COMMENT 'Harga Satuan (Fungsi Akuntansi)',
  jumlah_harga DECIMAL(20,2) COMMENT 'Jumlah Harga',
  kode_rek STRING COMMENT 'Kode Rek.',
  debet DECIMAL(20,2) COMMENT 'Debet',
  kredit DECIMAL(20,2) COMMENT 'Kredit',
  kondisi_baik DECIMAL(20,4) COMMENT 'Bahan – Baik',
  kondisi_reject DECIMAL(20,4) COMMENT 'Bahan – Reject',
  masih_diperlukan BOOLEAN COMMENT 'Keterangan – Masih diperlukan',
  tidak_diperlukan BOOLEAN COMMENT 'Keterangan – Tidak diperlukan',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (id)
COMMENT 'WFR-010 Bukti Pengembalian Bahan Sisa Proyek/Sisa Produksi'
DISTRIBUTED BY HASH(id);

CREATE TABLE IF NOT EXISTS form_wfr028_stock_opname (
  form_instance_id BIGINT NOT NULL,
  tanggal_pemeriksaan DATE COMMENT 'Pada hari ini … tanggal … bulan … tahun',
  metode STRING COMMENT 'Metode pemeriksaan',
  metode_uraian STRING COMMENT 'Uraian metode (dasar sampling)',
  lokasi_jenis STRING COMMENT 'Pemeriksaan berdasarkan',
  lokasi_uraian STRING COMMENT 'Gudang Len – uraian',
  gudang_kode STRING COMMENT 'Gudang Proyek – Kode',
  gudang_nama STRING COMMENT 'Gudang Proyek – Nama',
  gudang_jadwal STRING COMMENT 'Gudang Proyek – Jadwal',
  cakupan JSON COMMENT 'Meliputi material on stock (milik Len) & on site (milik bowheer)',
  hasil_pemeriksaan STRING COMMENT 'Hasil Pemeriksaan Persediaan',
  lampiran_laporan BIGINT COMMENT 'Laporan terlampir',
  created_at DATETIME,
  updated_at DATETIME,
  synced_at DATETIME
) PRIMARY KEY (form_instance_id)
COMMENT 'WFR-028 Berita Acara Pemeriksaan Fisik Persediaan (Stock Opname)'
DISTRIBUTED BY HASH(form_instance_id);

