-- =====================================================================
-- LPMS3 · Skema formulir BOP-001 (DIBANGKITKAN dari docs/data-dictionary/spec_forms.py)
-- Jangan edit manual: ubah spec lalu jalankan tools/gen_data_dictionary.py
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS lpms3_form;

-- Definisi formulir (versi template) ----------------------------------
CREATE TABLE IF NOT EXISTS lpms3_form.form_definition (
  code text NOT NULL, rev text NOT NULL, title text NOT NULL, phase text, owner_function text,
  sop_refs text[], menu_path text, source_file text, active boolean DEFAULT true,
  PRIMARY KEY (code, rev));

-- Satu baris per dokumen yang diisi (instance formulir) --------------
CREATE TABLE IF NOT EXISTS lpms3_form.form_instance (
  id bigserial PRIMARY KEY, form_code text NOT NULL, form_rev text NOT NULL,
  project_id integer NOT NULL,            -- projects.id OpenProject
  wbs_node_id bigint,                     -- lpms3_wbs.wbs_node.id (folder bukti)
  doc_no text,                            -- penomoran otomatis per pola formulir
  period_month date,                      -- untuk formulir periodik (LKP, risk register)
  revision integer NOT NULL DEFAULT 1, is_current boolean NOT NULL DEFAULT true, superseded_by bigint,
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','SUBMITTED','IN_REVIEW','RETURNED','APPROVED','PUBLISHED','SUPERSEDED','CANCELLED')),
  published_level integer NOT NULL DEFAULT 0,
  structure_id integer, unit_id integer,   -- snapshot struktur organisasi saat dibuat (§14)
  source text NOT NULL DEFAULT 'LPMS3' CHECK (source IN ('LPMS3','IMPORT_LPMS2','ETL_UPLOAD','ERP')),
  pdf_render_file_id bigint,              -- PDF resmi yang dirender dari data
  created_by integer NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
  updated_by integer, updated_at timestamptz,
  FOREIGN KEY (form_code, form_rev) REFERENCES lpms3_form.form_definition(code, rev));
CREATE INDEX IF NOT EXISTS ix_form_instance_proj ON lpms3_form.form_instance(project_id, form_code, period_month);

-- Tanda tangan / pengesahan pada formulir (sesuai kolom pengesahan form) --
CREATE TABLE IF NOT EXISTS lpms3_form.form_signature (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  seq integer NOT NULL, role_label text NOT NULL,      -- 'Dibuat oleh', 'Diperiksa oleh', 'Disetujui oleh', ...
  function_code text, position_grade text,            -- mis. F-MPR / STRUKTURAL_ES2
  signer_user_id integer, signer_name text, signer_nik text, signer_jabatan text, external_party boolean DEFAULT false,
  on_behalf_of integer, method text CHECK (method IN ('SYSTEM','DIGITAL_CERT','WET_SCAN')),
  signed_at timestamptz, content_hash char(64));

-- Lampiran (bukti) – disimpan di attachments OpenProject + folder WBS ---
CREATE TABLE IF NOT EXISTS lpms3_form.form_attachment (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  field_name text, op_attachment_id bigint NOT NULL, wbs_node_id bigint, ffr710_item text, uploaded_by integer, uploaded_at timestamptz DEFAULT now());

INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('FFR-706','11','Pengajuan Kode Kegiatan','Inisiasi','Fungsi Manajemen Proyek (Eselon I pemilik kode)',ARRAY['FOP-700','BOP-001 §5.1.1']::text[],'PHASE › [Inisiasi] › ringkasan (Kode Proyek)','form/FFR-706 Formulir Pengajuan Kode Kegiatan rev.11.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('FLP-01','15','Checklist Persyaratan Dokumen Pengajuan Pembukaan Kode Proyek/Program/Transfer Load','Inisiasi','Fungsi Pengendali Anggaran (verifikasi) / Fungsi Manajemen Proyek (pengaju)',ARRAY['FOP-700']::text[],'PHASE › [Inisiasi] › ringkasan › Checklist FLP-01','form/FLP-01 Lampiran Persyaratan Dokumen ... rev.15.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('BOT-001','00','Template Project Charter','Inisiasi','Fungsi Manajemen Proyek (Pelaksanaan Proyek)',ARRAY['BOP-001 §5.1.3']::text[],'PHASE › [Inisiasi] › Project Charter (Gate G1)','form/BOT-001 Template Project Charter rev.00 (sign).pdf') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('SFR-028','00','Rapat Tinjauan Order/Kontrak – Go/No Go','Pra-proyek → Inisiasi','Fungsi Pemasaran (mengajukan) / Fungsi Pengawasan Pra Proyek (memeriksa)',ARRAY['SOP-001','SOP-004']::text[],'PROJECT › Add New (lampiran dari LPMS 2 / pra-proyek) & PHASE › [Inisiasi] ringkasan','form/SFR-028 Formulir Rapat Tinjauan Order_Kontrak Go atau No Go rev.00.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('RFR-004','02','Profil Proyek','Pra-proyek → Inisiasi','Fungsi Pemasaran / Fungsi Perencanaan Proyek; reviu Fungsi Manajemen Risiko',ARRAY['ROP-911','SOP-001']::text[],'PHASE › [Inisiasi] › Preliminary PM Aspect (Risiko) & Risk Status','form/RFR-004 Formulir Profil Proyek rev.02.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('RFR-005','00','Profil Risiko Program','Inisiasi (program)','Unit Pengusul Program',ARRAY['ROP-911','EOP-304']::text[],'PHASE › [Inisiasi] (jenis kode Program)','form/RFR-005 Profil Risiko Program rev.00.pdf') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('RFR-002','03','Project Risk Register','Inisiasi → Closing (update bulanan)','Fungsi Manajemen Proyek (Risk Owner); reviu Fungsi Manajemen Risiko',ARRAY['ROP-911','BOP-001 §5.2.1.7, §5.3.6, §5.4.9']::text[],'PHASE › [Monitoring] › Risk Status','form/RFR-002 Project Risk Register rev.03.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('RFR-001','05','Risk Register Unit Kerja (kertas kerja)','Eksekusi & Monitoring (risiko operasional)','Unit kerja pelaksana proyek',ARRAY['ROP-910']::text[],'PHASE › [Monitoring] › Risk Status (tab Risiko Operasional)','form/Kertas Kerja RFR-001 Formulir Risk Register Unit Kerja rev.05_20250210.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('VFR-015','05','Identifikasi dan Penilaian Bahaya-Risiko K3 dan Aspek-Dampak Lingkungan (HIRA)','Perencanaan → Eksekusi (review saat perubahan)','Fungsi K3L / P2K3 bersama Pimpro',ARRAY['VOP-505','VOP-513','BOP-001 §5.3.6']::text[],'PHASE › [Monitoring] › K3LH Status','form/VFR-015 ... rev.05_20191230.xlsx (+ contoh HIRA PMO & Marketing)') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('CFR-022','01','Risalah Rapat','Semua fase (Kick-Off, Rapat Tinjauan, Top-Up, Pergeseran, ABT, Adendum)','Penyelenggara rapat (umumnya Fungsi Pengawasan Proyek)',ARRAY['BOP-001 §5.2.2, §5.3.5, §5.4.8','BOG-003','SOP-004','SOP-009']::text[],'PHASE › [Perencanaan] Reviu PMP & Kick-Off / [Eksekusi] ringkasan Rapat','form/CFR-022 Formulir Risalah Rapat rev.01.docx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('BFR-001','00','Formulir Change Log / Change Request','Eksekusi & Monitoring (Integrated Change Control)','Pimpinan Proyek (pengaju)',ARRAY['BOP-001 §5.3.1, §5.4.2','BOG-003','SOP-009']::text[],'PHASE › [Eksekusi] › Change Request (BFR-001)','form/BFR-001 Formulir Change Log.pdf') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('FFR-708','09','Laporan Kemajuan Proyek/Program/Transfer Load (LKP)','Eksekusi & Monitoring (bulanan); Closing (LKP 100%)','Pimpinan Proyek (dibuat), Es.II Fungsi Manajemen Proyek (diperiksa), Es.I (disetujui bila 100%/akhir tahun)',ARRAY['BOP-001 §5.3.1, §5.4.1','FOP-705']::text[],'PHASE › [Monitoring] › Laporan Kemajuan (LKP / FFR-708)','form/FFR-708 Formulir Laporan Kemajuan Proyek(Program) rev.09.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('CFR-027','00','Ketidaksesuaian dan Tindakan Koreksi (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional)','Eksekusi & Monitoring','Unit pelapor; verifikasi Fungsi Penjaminan Mutu',ARRAY['QOG-001 §5.6.2–5.6.3','BOP-001 §5.3.4, §5.4.6']::text[],'PHASE › [Monitoring] › Quality Status / Issue Status','form/CFR-027 Form Ketidaksesuaian dan Tindakan Koreksi rev.00.xls (identik QFR-017 di LKP Sigma)') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('PFR-037','00','Pengajuan Proposal Pengadaan Barang/Jasa PMN','Perencanaan → Eksekusi (pengadaan PMN)','Project Manager (pengaju)',ARRAY['POP-109']::text[],'PHASE › [Monitoring] › Procurement Pipeline › Pra Procurement up to PR (jenis PMN)','procedure/PFR-037 Formulir Pengajuan Proposal Pengadaan PMN rev.00.xlsx') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('FFR-710','02','Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)','Seluruh fase; wajib lengkap saat Closing','Pimpro & Tim Proyek; Es.II/Es.I Fungsi Manajemen Proyek',ARRAY['BOP-001 §5.5.4','FOP-705','COP-002']::text[],'Dokumen proyek (folder WBS) & PHASE › [Closing] › Pendokumentasian Arsip','form/FFR-710 Formulir Laporan Dokumentasi Proyek rev.02.xlsx (rev.01 juga tersedia)') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('WFR-014','03','Berita Acara Serah Terima Pekerjaan / Pemeliharaan (BAST)','Eksekusi (serah terima deliverable) & Closing','Pimpinan Proyek',ARRAY['FOP-705','BOP-001 §5.3.1']::text[],'PHASE › [Eksekusi] ringkasan (Deliverable diterima) & [Closing]','form/WFR-014 ... rev.03_20031205.xls') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('WFR-010','03','Bukti Pengembalian Bahan Sisa Proyek/Sisa Produksi','Closing','Pimpro / Bag. Rekayasa / Bag. Produksi; Fungsi Akuntansi; Gudang',ARRAY['FOP-705','WOP-207']::text[],'PHASE › [Closing] langkah Arsip & Persediaan','form/WFR-010 ... rev.03_20031205.xls') ON CONFLICT DO NOTHING;
INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ('WFR-028','02','Berita Acara Pemeriksaan Fisik Persediaan (Stock Opname)','Eksekusi (bulanan) & Closing','Penanggungjawab Gudang & Pimpro',ARRAY['FOP-705','WOP-207']::text[],'PHASE › [Monitoring] (laporan persediaan bulanan) & [Closing]','form/WFR-028 ... rev02_20030605.docx') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS lpms3_form.ffr706_pengajuan_kode (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nama_kegiatan text,
  kode_unit_kerja integer,
  jenis_kegiatan text CHECK (jenis_kegiatan IN ('Proyek Bisnis', 'Proyek Litbang', 'Proyek Investasi', 'Prospek Proyek', 'Purnajual Proyek', 'Program Persediaan Produk', 'Program Produksi', 'Program Internal Litbang', 'Program Eksternal Litbang', 'Program Rekayasa Produksi', 'Program Kajian Bisnis', 'Program Investasi', 'Transfer Load Produksi dan Persediaan Produk', 'Transfer Load Litbang dan POC')),
  lini_bisnis text CHECK (lini_bisnis IN ('Defense (D)', 'Commercial (C)', 'Others (O)')),
  lini_bisnis_lainnya text,
  metode_revenue text CHECK (metode_revenue IN ('By Accrue', 'By Billing', 'Transfer Load')),
  kode_wbs_induk text,
  customer text,
  nilai_kontrak_netto numeric(20,2),
  sumber_dana text,
  nomor_kontrak text,
  tanggal_kontrak date,
  jadwal_awal date,
  jadwal_akhir date,
  account_manager integer,
  pimpinan_proyek integer,
  target_rkap text CHECK (target_rkap IN ('Ya', 'Tidak')),
  tempat_tanggal date,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.flp01_master_persyaratan (
  id serial PRIMARY KEY, form_rev text NOT NULL,
  no integer,
  dokumen_persyaratan text,
  kode_formulir text,
  berlaku_untuk jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.flp01_checklist (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  persyaratan_no integer NOT NULL,
  jenis_kode text NOT NULL CHECK (jenis_kode IN ('Proyek Bisnis', 'Proyek Litbang', 'Proyek Investasi', 'Prospek Proyek', 'Purnajual Proyek', 'Program Persediaan Produk', 'Program Produksi', 'Program Internal Litbang', 'Program Eksternal Litbang', 'Program Rekayasa Produksi', 'Program Kajian Bisnis', 'Program Investasi', 'Transfer Load Produksi dan Persediaan Produk', 'Transfer Load Litbang dan POC')),
  checklist boolean NOT NULL,
  dokumen_ref bigint,
  catatan_verifikator text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_flp01_checklist_inst ON lpms3_form.flp01_checklist(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_charter (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nama_proyek text,
  nomor_kode_proyek text,
  sponsor integer,
  project_manager integer,
  tanggal_penerbitan date,
  versi_dokumen text,
  purpose_justification text,
  high_level_requirements jsonb,
  in_scope jsonb,
  out_of_scope jsonb,
  total_estimasi_anggaran numeric(20,2),
  mata_uang text CHECK (mata_uang IN ('IDR', 'USD', 'EUR', 'Lainnya')),
  sumber_pendanaan text,
  approval_requirements text,
  pm_nik text,
  pm_otoritas_anggaran text,
  pm_otoritas_penugasan_sd text,
  pm_otoritas_keputusan_teknis text,
  authorization_text text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_success_criteria (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  aspek text NOT NULL CHECK (aspek IN ('Scope', 'Waktu (Schedule)', 'Biaya (Budget)', 'Kualitas')),
  target text NOT NULL,
  kriteria_sukses text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_bot001_success_criteria_inst ON lpms3_form.bot001_success_criteria(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_high_level_risks (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  deskripsi_risiko text NOT NULL,
  dampak text NOT NULL CHECK (dampak IN ('H', 'M', 'L')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_bot001_high_level_risks_inst ON lpms3_form.bot001_high_level_risks(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_timeline (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  milestone text NOT NULL,
  target_tanggal date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_bot001_timeline_inst ON lpms3_form.bot001_timeline(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_term_of_payment (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  urutan integer NOT NULL,
  persen_atau_nominal text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_bot001_term_of_payment_inst ON lpms3_form.bot001_term_of_payment(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bot001_key_stakeholders (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  nama_instansi text NOT NULL,
  peran text NOT NULL,
  kepentingan_pengaruh text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_bot001_key_stakeholders_inst ON lpms3_form.bot001_key_stakeholders(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.sfr028_go_nogo (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nomor text,
  jenis_tinjauan text CHECK (jenis_tinjauan IN ('Order', 'Kontrak')),
  nama_proyek text,
  nilai_proyek numeric(20,2),
  nama_pelanggan text,
  sumber_anggaran text,
  lini_bisnis text CHECK (lini_bisnis IN ('Pertahanan', 'Non-Pertahanan - Energi', 'Non-Pertahanan - Transportasi', 'Non-Pertahanan - ICT', 'Non-Pertahanan - Retail', 'Lainnya')),
  tanggal date,
  tempat text,
  pemimpin_tinjauan integer,
  kesimpulan_teknis text,
  kesimpulan_costing text,
  aspek_risiko text,
  paparan text,
  keputusan_forum text CHECK (keputusan_forum IN ('Menyetujui (Go)', 'Menolak (No Go)')),
  catatan text,
  kelas_tinjauan text CHECK (kelas_tinjauan IN ('Kecil', 'Sedang', 'Besar')),
  daftar_hadir bigint,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr004_profil_proyek (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nama_proyek text,
  customer text,
  lini_bisnis text CHECK (lini_bisnis IN ('Pertahanan', 'Non-Pertahanan - Energi', 'Non-Pertahanan - Transportasi', 'Non-Pertahanan - ICT', 'Non-Pertahanan - Retail', 'Lainnya')),
  risk_owner integer,
  project_manager integer,
  tanggal_update date,
  revisi integer,
  deskripsi_singkat text,
  lokasi_proyek text,
  kondisi_lokasi text CHECK (kondisi_lokasi IN ('Aman dan mudah akses', 'Sebagian lokasi sulit akses dan/atau tidak aman', 'Sulit akses dan/atau daerah rawan')),
  skema_perolehan text CHECK (skema_perolehan IN ('Tender', 'Penunjukan Langsung')),
  tgl_ttd_perjanjian date,
  status_ttd text CHECK (status_ttd IN ('target akan ditandatangan', 'sudah ditandatangan')),
  jenis_waktu text CHECK (jenis_waktu IN ('Single Year', 'Multi Year')),
  kecukupan_waktu text CHECK (kecukupan_waktu IN ('Cukup', 'Ketat', 'Tidak Cukup')),
  waktu_mulai date,
  waktu_selesai date,
  mata_uang text CHECK (mata_uang IN ('IDR', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'AUD', 'Lainnya')),
  nilai_proyek_netto numeric(20,2),
  bdp_pct numeric(9,4),
  hpp_pct numeric(9,4),
  lbdp numeric(20,2),
  laba_bruto numeric(20,2),
  ebitda_pct numeric(9,4),
  ebitda_nilai numeric(20,2),
  nama_customer text,
  jenis_customer text CHECK (jenis_customer IN ('Kementrian / Lembaga Pemerintah', 'BUMN / BUMD', 'Swasta', 'Asing')),
  status_customer text CHECK (status_customer IN ('New Customer', 'Existing Customer')),
  sumber_anggaran text CHECK (sumber_anggaran IN ('APBN', 'APBD', 'BUMN/ BUMD', 'Swasta', 'PDN', 'PLN', 'Lainnya')),
  nama_sumber_anggaran text,
  term_of_payment text CHECK (term_of_payment IN ('Pelunasan Di muka', 'Termin (Jelaskan di kolom keterangan)', 'Turnkey')),
  metode_pembayaran text CHECK (metode_pembayaran IN ('T/T', 'SKBDN', 'L/C', 'SCF', 'Giro mundur', 'Lainnya')),
  umur_piutang text CHECK (umur_piutang IN ('0 Hari Kalender / Segera', '15 Hari Kalender', '30 Hari Kalender', '45 Hari Kalender', '60 Hari Kalender', '120 Hari Kalender', '180 Hari Kalender', 'Lainnya')),
  jaminan_penawaran_pct numeric(9,4),
  jaminan_uang_muka_pct numeric(9,4),
  jaminan_pelaksanaan_pct numeric(9,4),
  jaminan_pembayaran_pct numeric(9,4),
  jaminan_pemeliharaan_pct numeric(9,4),
  jaminan_fungsional_pct numeric(9,4),
  jaminan_lainnya text,
  ppn text CHECK (ppn IN ('Ada', 'Tidak dipungut', 'Bebas PPN', 'Tidak ada')),
  pph_final text,
  bea_impor text,
  pajak_lainnya text,
  posisi_len text CHECK (posisi_len IN ('Kontraktor Utama', 'Sub-Kontraktor', 'Retail')),
  kebutuhan_partnership text CHECK (kebutuhan_partnership IN ('Tidak Perlu', 'Konsorsium/ KSO/ Joint Operation', 'Joint Venture', 'ToT Pemilik Teknologi', 'Lainnya')),
  kategori_proyek text CHECK (kategori_proyek IN ('Proyek EPC', 'Proyek MRO', 'Proyek Investasi', 'Proyek Penelitian dan Pengembangan', 'Retail')),
  jenis_order text CHECK (jenis_order IN ('Proyek Perdana', 'Sudah Ada Proyek Sejenis', 'Repeat Order')),
  regulasi_khusus text,
  lingkup_pekerjaan jsonb,
  ketergantungan_pihak_ketiga text CHECK (ketergantungan_pihak_ketiga IN ('Ada', 'Tidak Ada')),
  pct_material_impor numeric(9,4),
  barang_spesifik text CHECK (barang_spesifik IN ('Ada', 'Tidak Ada')),
  ketersediaan_personel text CHECK (ketersediaan_personel IN ('Cukup', 'Tidak Cukup')),
  kebutuhan_kompetensi text CHECK (kebutuhan_kompetensi IN ('Ya', 'Tidak')),
  skema_bisnis bigint,
  timeline_proyek bigint,
  keterangan_per_butir jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr005_profil_program (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nama_program text,
  unit_pengusul integer,
  jenis_program text,
  tanggal_update date,
  revisi integer,
  deskripsi_singkat text,
  sumber_usulan text,
  lini_bisnis text CHECK (lini_bisnis IN ('Pertahanan', 'Non-Pertahanan - Energi', 'Non-Pertahanan - Transportasi', 'Non-Pertahanan - ICT', 'Non-Pertahanan - Retail', 'Lainnya')),
  output_pengembangan text,
  pihak_eksternal text,
  haki text,
  sertifikasi_produk text,
  kajian_kelayakan text,
  mata_uang text CHECK (mata_uang IN ('IDR', 'USD', 'EUR', 'Lainnya')),
  biaya_pengembangan numeric(20,2),
  regulasi_khusus text,
  jenis_waktu text,
  ruang_lingkup jsonb,
  pct_material_impor numeric(9,4),
  barang_spesifik text CHECK (barang_spesifik IN ('Ada', 'Tidak Ada')),
  ketersediaan_personel text CHECK (ketersediaan_personel IN ('Cukup', 'Tidak Cukup')),
  personel_khusus text CHECK (personel_khusus IN ('Ya', 'Tidak')),
  sertifikasi_tkdn text CHECK (sertifikasi_tkdn IN ('Ya', 'Tidak')),
  struktur_organisasi bigint,
  skema_proses bigint,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr002_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nama_proyek text,
  customer text,
  lini_bisnis text CHECK (lini_bisnis IN ('Pertahanan', 'Non-Pertahanan - Energi', 'Non-Pertahanan - Transportasi', 'Non-Pertahanan - ICT', 'Non-Pertahanan - Retail', 'Lainnya')),
  risk_owner integer,
  project_manager integer,
  tanggal_update date,
  revisi integer,
  referensi jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr002_risiko (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  kategori_risiko text NOT NULL CHECK (kategori_risiko IN ('Kelangsungan bisnis jangka panjang (strategis)', 'Gagal tender', 'Keterlambatan pengadaan barang', 'Wanprestasi pekerjaan pihak ketiga', 'Keterlambatan penyelesaian pekerjaan', 'Kenaikan biaya proyek (harga, operasional, pemeliharaan)', 'Ketidakhandalan produk', 'Kerusakan produk', 'Progres pekerjaan tidak diakui customer', 'Keterlambatan pembayaran customer (piutang)', 'Pengurangan Scope of Work (SoW)', 'Penghentian pekerjaan', 'Overstock', 'Fluktuasi kurs', 'Perpajakan', 'Legal', 'Kehilangan SDM', 'Pelanggaran SMAP', '(Proyek Investasi) Target output tidak tercapai', 'Keamanan', 'Lainnya')),
  peristiwa_risiko text NOT NULL,
  kode_risiko text NOT NULL,
  peristiwa_lainnya text,
  penyebab_risiko jsonb,
  dampak_inheren_rp numeric(20,2) NOT NULL,
  dampak_inheren_kualitatif jsonb,
  inheren_skala_dampak text NOT NULL CHECK (inheren_skala_dampak IN ('1', '2', '3', '4', '5')),
  inheren_skala_kemungkinan text NOT NULL CHECK (inheren_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  inheren_level text NOT NULL CHECK (inheren_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  rencana_penanganan jsonb,
  pic integer NOT NULL,
  target_waktu_penanganan date NOT NULL,
  target_res_skala_dampak text NOT NULL CHECK (target_res_skala_dampak IN ('1', '2', '3', '4', '5')),
  target_res_skala_kemungkinan text NOT NULL CHECK (target_res_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  target_res_level text NOT NULL CHECK (target_res_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  realisasi_penanganan text,
  realisasi_waktu_penanganan date,
  res_skala_dampak text CHECK (res_skala_dampak IN ('1', '2', '3', '4', '5')),
  res_skala_kemungkinan text CHECK (res_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  res_level text CHECK (res_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  dampak_residual_rp numeric(20,2),
  dampak_residual_kualitatif jsonb,
  kejadian_risiko text CHECK (kejadian_risiko IN ('Terjadi', 'Tidak Terjadi')),
  catatan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_rfr002_risiko_inst ON lpms3_form.rfr002_risiko(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr001_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  jenis_unit text CHECK (jenis_unit IN ('DIVISI', 'BAGIAN')),
  unit_kerja integer,
  tahun integer,
  revisi_ke integer,
  periode text CHECK (periode IN ('Awal Tahun', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember')),
  tanggal_update date,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.rfr001_risiko (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  sasaran text NOT NULL,
  peristiwa_risiko text NOT NULL,
  taksonomi_risiko text NOT NULL,
  penyebab_risiko text NOT NULL,
  uraian_dampak text NOT NULL,
  nilai_dampak_rp numeric(20,2) NOT NULL,
  kontrol_existing text NOT NULL,
  kecukupan text NOT NULL CHECK (kecukupan IN ('Cukup', 'Tidak Cukup')),
  efektivitas text NOT NULL CHECK (efektivitas IN ('Efektif', 'Efektif Sebagian', 'Tidak Efektif')),
  inheren_skala_dampak text NOT NULL CHECK (inheren_skala_dampak IN ('1', '2', '3', '4', '5')),
  inheren_skala_kemungkinan text NOT NULL CHECK (inheren_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  inheren_level text NOT NULL CHECK (inheren_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  program_kerja text NOT NULL,
  unit_terkait text,
  anggaran_program_rp numeric(20,2),
  target_res_skala_dampak text NOT NULL CHECK (target_res_skala_dampak IN ('1', '2', '3', '4', '5')),
  target_res_skala_kemungkinan text NOT NULL CHECK (target_res_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  target_res_level text NOT NULL CHECK (target_res_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  risiko_positif text,
  jadwal_jan_des jsonb,
  deskripsi_realisasi text,
  pct_realisasi numeric(9,4),
  realisasi_biaya_rp numeric(20,2),
  real_res_skala_dampak text CHECK (real_res_skala_dampak IN ('1', '2', '3', '4', '5')),
  real_res_skala_kemungkinan text CHECK (real_res_skala_kemungkinan IN ('1', '2', '3', '4', '5')),
  real_res_level text CHECK (real_res_level IN ('Rendah (1-5)', 'Rendah-Menengah (6-11)', 'Menengah (12-15)', 'Menengah-Tinggi (16-19)', 'Tinggi (20-25)')),
  status_terjadi text CHECK (status_terjadi IN ('Terjadi', 'Tidak Terjadi')),
  catatan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_rfr001_risiko_inst ON lpms3_form.rfr001_risiko(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.vfr015_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  divisi_bagian_unit integer,
  no_review integer,
  tanggal date,
  lingkup text CHECK (lingkup IN ('Proyek', 'Korporasi', 'Subcon')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.vfr015_aspek_bahaya (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  aktivitas text NOT NULL,
  rutin text NOT NULL CHECK (rutin IN ('R', 'NR')),
  no_aspek_bahaya text NOT NULL,
  aspek_bahaya text NOT NULL,
  dampak_risiko text NOT NULL,
  kondisi_operasional text NOT NULL CHECK (kondisi_operasional IN ('N', 'Ab', 'E')),
  jenis_dampak text NOT NULL CHECK (jenis_dampak IN ('+', '-')),
  pengendalian_ada text NOT NULL CHECK (pengendalian_ada IN ('Administrasi', 'APD', 'Eliminasi', 'Pengelolaan limbah', 'Pengolahan limbah', 'Recycle', 'Reduce', 'Rekayasa Teknik', 'Reuse', 'Substitusi')),
  pengendalian_uraian text,
  keparahan text NOT NULL CHECK (keparahan IN ('1', '2', '3', '4')),
  kemungkinan text NOT NULL CHECK (kemungkinan IN ('1', '2', '3', '4')),
  total integer NOT NULL,
  level_risiko text NOT NULL,
  aspek_signifikan text NOT NULL CHECK (aspek_signifikan IN ('Yes', 'No')),
  legal text,
  risiko text,
  peluang text,
  eval_legal text CHECK (eval_legal IN ('0', '1', '3', '5')),
  eval_teknologi text CHECK (eval_teknologi IN ('1', '3', '5')),
  eval_finansial text CHECK (eval_finansial IN ('1', '3', '5')),
  eval_operasional text CHECK (eval_operasional IN ('1', '3', '5')),
  eval_pihak_berkepentingan text CHECK (eval_pihak_berkepentingan IN ('1', '3', '5')),
  eval_total integer,
  pertimbangan_otp text,
  action_plan text,
  no_action_plan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_vfr015_aspek_bahaya_inst ON lpms3_form.vfr015_aspek_bahaya(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.cfr022_risalah (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nomor text,
  jenis_rapat text CHECK (jenis_rapat IN ('Kick-Off Meeting', 'Rapat Tinjauan Proyek', 'Rapat Tinjauan Top-Up', 'Rapat Tinjauan Pergeseran Anggaran', 'Rapat Tinjauan ABT', 'Rapat Tinjauan Adendum', 'Rapat CCM', 'Lainnya')),
  judul_rapat text,
  tanggal date,
  waktu_mulai text,
  waktu_selesai text,
  tempat text,
  pimpinan_rapat integer,
  notulis integer,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.cfr022_agenda (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  agenda_bahasan text NOT NULL,
  resume_bahasan text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_cfr022_agenda_inst ON lpms3_form.cfr022_agenda(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.cfr022_tindak_lanjut (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  isu text NOT NULL,
  tindak_lanjut text NOT NULL,
  deadline date NOT NULL,
  pic integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_cfr022_tindak_lanjut_inst ON lpms3_form.cfr022_tindak_lanjut(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.cfr022_peserta (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  nama integer NOT NULL,
  fungsi_jabatan text NOT NULL,
  peran_rapat text NOT NULL CHECK (peran_rapat IN ('Pemimpin', 'Penyelenggara', 'Pemapar', 'Pendukung Pemapar', 'Peninjau Aspek', 'Narasumber', 'Peserta', 'Delegasi')),
  hadir boolean NOT NULL,
  delegasi_dari integer,
  persetujuan boolean,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_cfr022_peserta_inst ON lpms3_form.cfr022_peserta(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.bfr001_change_request (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  unit_kerja integer,
  nama_proyek text,
  kode_proyek text,
  progres_lkp_pct numeric(9,4),
  change_request_no text,
  kategori_perubahan jsonb,
  latar_belakang text,
  anggaran_jenis text CHECK (anggaran_jenis IN ('Pergeseran Anggaran (WBS Eksisting)', 'Pergeseran Anggaran (WBS Baru)')),
  anggaran_nilai_kebutuhan numeric(20,2),
  anggaran_dari_wbs bigint,
  anggaran_ke_wbs bigint,
  scope_jenis text CHECK (scope_jenis IN ('Perubahan Scope Pekerjaan', 'Penambahan Scope Pekerjaan', 'Pengurangan Scope pekerjaan')),
  jadwal_selesai_kontrak_awal date,
  jadwal_selesai_addendum date,
  kurva_s_awal bigint,
  kurva_s_perubahan bigint,
  catatan_pengawasan jsonb,
  catatan_eselon_pengawasan jsonb,
  ambang_persetujuan text CHECK (ambang_persetujuan IN ('< Rp1 Miliar → Eselon II', '≥ Rp1 Miliar → Eselon I')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr708_cover (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  jenis_laporan text CHECK (jenis_laporan IN ('Proyek', 'Program', 'Transfer Load')),
  nama_proyek text,
  kode_proyek text,
  nomor_kontrak text,
  nilai_proyek numeric(20,2),
  tanggal_mulai date,
  tanggal_selesai date,
  termin_pembayaran jsonb,
  institusi_pemberi_kerja text,
  pimpro_nama integer,
  pimpro_telepon text,
  unit_kerja integer,
  nama_dokumen text,
  periode_dari date,
  periode_sampai date,
  akumulasi_progress_pct numeric(9,4),
  disiapkan_nama integer,
  disiapkan_jabatan text,
  tanggal_pembuatan date,
  pemberi_kerja_nama text,
  pemberi_kerja_nik_nrp text,
  pemberi_kerja_jabatan text,
  tembusan jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr708_rekap (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  no_laporan integer NOT NULL,
  bulan date NOT NULL,
  bulan_ke integer NOT NULL,
  no text NOT NULL,
  wbs_node bigint NOT NULL,
  bobot_a numeric(9,4) NOT NULL,
  rencana_kum_keg_b numeric(9,4) NOT NULL,
  rencana_kum_tot_c numeric(9,4) NOT NULL,
  prestasi_lalu_keg_d numeric(9,4) NOT NULL,
  prestasi_lalu_tot_e numeric(9,4) NOT NULL,
  prestasi_ini_keg_f numeric(9,4) NOT NULL,
  prestasi_ini_tot_g numeric(9,4) NOT NULL,
  prestasi_kum_keg_h numeric(9,4) NOT NULL,
  prestasi_kum_tot_i numeric(9,4) NOT NULL,
  deviasi_j numeric(9,4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr708_rekap_inst ON lpms3_form.ffr708_rekap(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr708_kurva_s (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  wbs_node bigint NOT NULL,
  bobot numeric(9,4) NOT NULL,
  tahun integer NOT NULL,
  bulan_ke integer NOT NULL,
  rencana_pct numeric(9,4) NOT NULL,
  realisasi_pct numeric(9,4),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr708_kurva_s_inst ON lpms3_form.ffr708_kurva_s(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr708_permasalahan (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  rincian_permasalahan text NOT NULL,
  rencana text NOT NULL,
  realisasi text,
  analisa_penyebab jsonb,
  tindakan_koreksi_pencegahan jsonb,
  pic integer NOT NULL,
  due_date date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr708_permasalahan_inst ON lpms3_form.ffr708_permasalahan(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr708_pembukuan (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  dibukukan_oleh integer NOT NULL,
  kode_perkiraan text NOT NULL,
  debet numeric(20,2) NOT NULL,
  kredit numeric(20,2) NOT NULL,
  catatan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr708_pembukuan_inst ON lpms3_form.ffr708_pembukuan(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.cfr027_ketidaksesuaian (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  jenis text NOT NULL CHECK (jenis IN ('Keluhan Pelanggan', 'Ketidaksesuaian SKU', 'Operasional')),
  tanggal_laporan date NOT NULL,
  pelapor_tipe text NOT NULL CHECK (pelapor_tipe IN ('Unit kerja', 'Pelanggan')),
  pelapor_unit text NOT NULL,
  pelapor_nama text NOT NULL,
  penerima_unit integer NOT NULL,
  penerima_nama integer NOT NULL,
  kategori text NOT NULL CHECK (kategori IN ('Permasalahan operasional/proyek', 'Ketidaksesuaian pencapaian SKU', 'Keluhan Pelanggan', 'Keluhan pihak eksternal')),
  detail text NOT NULL,
  analisa_penyebab text NOT NULL,
  tindakan_koreksi text NOT NULL,
  tindakan_korektif text NOT NULL,
  target_tanggal date NOT NULL,
  penanggung_jawab integer NOT NULL,
  status text NOT NULL CHECK (status IN ('OK', 'On Progress', 'Not OK')),
  realisasi_tanggal date,
  verifikasi text CHECK (verifikasi IN ('Belum Efektif', 'Sudah Efektif')),
  tanggal_verifikasi date,
  verifikator integer,
  keterangan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_cfr027_ketidaksesuaian_inst ON lpms3_form.cfr027_ketidaksesuaian(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.pfr037_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nomor text,
  tempat_tanggal date,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.pfr037_item (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  alokasi_mata_anggaran text NOT NULL,
  deskripsi text NOT NULL,
  jumlah numeric(20,4) NOT NULL,
  satuan text NOT NULL,
  rencana_kebutuhan numeric(20,2) NOT NULL,
  keterangan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_pfr037_item_inst ON lpms3_form.pfr037_item(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  unit_bisnis integer,
  account_manager integer,
  nama_proyek text,
  pimpinan_proyek integer,
  kode_sap text,
  nilai_kontrak_netto numeric(20,2),
  jadwal text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_daftar_isi (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  bagian text CHECK (bagian IN ('A. Pemasaran Proyek', 'B. Perencanaan & Pelaksanaan Proyek (Teknis)', 'C. Pelaksanaan Proyek (Pengadaan)', 'D. Pelaksanaan Proyek (Keuangan)', 'E. Penutupan Proyek')),
  no text,
  uraian text,
  ada_tanggal date,
  tidak_ada boolean,
  pj_nama integer,
  pj_bagian integer,
  keterangan text,
  dokumen bigint,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_c1_pengadaan (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  tanggal date NOT NULL,
  no_dpbj text NOT NULL,
  nilai_dpbj numeric(20,2) NOT NULL,
  no_spph text,
  no_po text,
  nilai_po numeric(20,2),
  supplier text,
  barang_tiba text CHECK (barang_tiba IN ('Merah', 'Hijau', 'Kuning')),
  status_kedatangan text CHECK (status_kedatangan IN ('Belum', 'Parsial Bertahap', 'Parsial Termin 1', 'Parsial Termin 2', 'Parsial Termin 3', 'Parsial Termin 4', 'Parsial Termin 5', 'Lengkap, Tepat Waktu', 'Lengkap, Terlambat', 'Wanprestasi', 'Batal')),
  no_bapbj text,
  kelengkapan_bast_subkon text CHECK (kelengkapan_bast_subkon IN ('Ada', 'Tidak')),
  keterangan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_c1_pengadaan_inst ON lpms3_form.ffr710_c1_pengadaan(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_c2_persediaan (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  kode_barang text NOT NULL,
  nama_barang text NOT NULL,
  lokasi_barang text NOT NULL,
  satuan text NOT NULL,
  pj_gudang integer NOT NULL,
  tanggal date NOT NULL,
  no_po text,
  nilai_po numeric(20,2),
  qty_po numeric(20,4),
  qty_bapb numeric(20,4),
  tanggal_bast date,
  no_bast text,
  nilai_bast numeric(20,2),
  qty_bast numeric(20,4),
  sisa numeric(20,4),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_c2_persediaan_inst ON lpms3_form.ffr710_c2_persediaan(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_d1_anggaran (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  periode_ke integer NOT NULL,
  jenis_anggaran text NOT NULL,
  nilai_anggaran numeric(20,2) NOT NULL,
  nilai_penyerapan numeric(20,2) NOT NULL,
  pct_penyerapan numeric(9,4) NOT NULL,
  pct_progres_lkp numeric(9,4) NOT NULL,
  pct_progres_kurva_s numeric(9,4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_d1_anggaran_inst ON lpms3_form.ffr710_d1_anggaran(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_d2_d4_d7_beban (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  jenis_tabel text NOT NULL CHECK (jenis_tabel IN ('D2 Beban SPD', 'D3 UM Swakelola', 'D4 Beban Lain-lain', 'D7a Beban Pemasaran')),
  tanggal date NOT NULL,
  no_bukti text NOT NULL,
  uraian text NOT NULL,
  saldo numeric(20,2) NOT NULL,
  nama text NOT NULL,
  jenis_kegiatan_marketing text,
  status text NOT NULL CHECK (status IN ('Lumpsum', 'Sudah Ptjwb', 'Belum Ptjwb')),
  ptjwb_saldo_kurang numeric(20,2),
  ptjwb_saldo_lebih numeric(20,2),
  keterangan text CHECK (keterangan IN ('Belum Diterima', 'Saldo lebih sudah dikembalikan', 'Saldo lebih belum dikembalikan', 'Saldo kurang sudah dibayar', 'Saldo kurang belum dibayar')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_d2_d4_d7_beban_inst ON lpms3_form.ffr710_d2_d4_d7_beban(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_d5a_pendapatan (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  tanggal date NOT NULL,
  termin text NOT NULL,
  progres_lkp_pct numeric(9,4) NOT NULL,
  progres_lkp_nilai numeric(20,2) NOT NULL,
  invoice_pct numeric(9,4),
  invoice_nilai numeric(20,2),
  nilai_penerimaan numeric(20,2),
  tagihan_bruto numeric(20,2),
  piutang_usaha numeric(20,2),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_d5a_pendapatan_inst ON lpms3_form.ffr710_d5a_pendapatan(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.ffr710_d5c_penjualan_retail (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  tanggal date NOT NULL,
  no_po text NOT NULL,
  no_transfer_load text,
  no_ppbj text,
  uraian text NOT NULL,
  nilai numeric(20,2) NOT NULL,
  customer text NOT NULL,
  no_bpbj text,
  status_penerimaan_barang text NOT NULL CHECK (status_penerimaan_barang IN ('Belum Dikirim', 'Sudah Diterima', 'Batal')),
  status_pembayaran text NOT NULL CHECK (status_pembayaran IN ('Belum Dibayar', 'Sudah Dibayar', 'Batal')),
  keterangan text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_ffr710_d5c_penjualan_retail_inst ON lpms3_form.ffr710_d5c_penjualan_retail(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.wfr014_bast (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  jenis text CHECK (jenis IN ('Pekerjaan', 'Pemeliharaan')),
  nama_proyek text,
  lokasi text,
  no_kontrak text,
  nilai_kontrak numeric(20,2),
  jadwal_pelaksanaan text,
  tanggal_bast date,
  tempat text,
  pihak1_nama text,
  pihak1_jabatan text,
  pihak1_instansi text,
  pihak2_nama text,
  pihak2_jabatan text,
  pihak2_instansi text,
  bobot_pct numeric(9,4),
  nilai_rp numeric(20,2),
  wbs_deliverable jsonb,
  distribusi jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.wfr010_header (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  nomor text,
  nama_proyek text,
  kode_proyek text,
  no_penerimaan_gudang text,
  tanggal date,
  total_rp numeric(20,2),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

CREATE TABLE IF NOT EXISTS lpms3_form.wfr010_item (
  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),
  line_no integer NOT NULL,
  kode_barang text NOT NULL,
  nama_barang text NOT NULL,
  satuan text NOT NULL,
  jumlah numeric(20,4) NOT NULL,
  harga_satuan numeric(20,2),
  jumlah_harga numeric(20,2),
  kode_rek text,
  debet numeric(20,2),
  kredit numeric(20,2),
  kondisi_baik numeric(20,4),
  kondisi_reject numeric(20,4),
  masih_diperlukan boolean,
  tidak_diperlukan boolean,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_wfr010_item_inst ON lpms3_form.wfr010_item(form_instance_id, line_no);

CREATE TABLE IF NOT EXISTS lpms3_form.wfr028_stock_opname (
  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),
  tanggal_pemeriksaan date,
  metode text CHECK (metode IN ('Perhitungan keseluruhan', 'Sampling')),
  metode_uraian text,
  lokasi_jenis text CHECK (lokasi_jenis IN ('Gudang Len', 'Gudang Proyek/Program')),
  lokasi_uraian text,
  gudang_kode text,
  gudang_nama text,
  gudang_jadwal text,
  cakupan jsonb,
  hasil_pemeriksaan text,
  lampiran_laporan bigint,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz
);

