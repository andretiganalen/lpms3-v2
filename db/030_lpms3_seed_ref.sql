-- =====================================================================
-- LPMS3 · Data referensi yang diambil dari dokumen prosedur (idempoten)
-- Sumber: CLP-001 rev.01, FOP-700 rev.15, SOP-004 rev.15, SOP-009 rev.00,
--         BOG-003 rev.01, BFR-001 rev.00, ROP-911 rev.03, BOP-001 rev.01
-- =====================================================================

-- CLP-001 Nomenklatur Fungsi Generik ----------------------------------------
INSERT INTO lpms3.fungsi_generik (code, clp_no, name, category, involvement_mode, bop_alias) VALUES
 ('F-PMS',1,'Fungsi Pemasaran','KONTRIBUTOR','DIRECT','{}'),
 ('F-PBS',2,'Fungsi Pengembangan Bisnis','KONTRIBUTOR','PROXY','{}'),
 ('F-LTB',3,'Fungsi Litbang','KONTRIBUTOR','PROXY','{}'),
 ('F-RKS',4,'Fungsi Rekayasa Sistem','KONTRIBUTOR','DIRECT','{"Fungsi Rekayasa Solusi Teknis Proyek"}'),
 ('F-PRP',5,'Fungsi Perencanaan Proyek','CORE_MANAJEMEN_PROYEK','DIRECT','{}'),
 ('F-PPP',6,'Fungsi Pengawasan Pra Proyek','KONTRIBUTOR','DIRECT','{}'),
 ('F-MPR',7,'Fungsi Manajemen Proyek','CORE_PROYEK','DIRECT','{"Fungsi Pelaksanaan Proyek","Pimpro","Tim Proyek"}'),
 ('F-PWP',8,'Fungsi Pengawasan Proyek','CORE_MANAJEMEN_PROYEK','DIRECT','{"Fungsi Pengawasan Proyek","PMO"}'),
 ('F-PJL',9,'Fungsi Purna Jual','KONTRIBUTOR','DIRECT','{"Fungsi Purnajual"}'),
 ('F-PGD',10,'Fungsi Pengadaan','KONTRIBUTOR','DIRECT','{"Fungsi Perencanaan Pengadaan","Fungsi Operasional Pengadaan"}'),
 ('F-GDG',11,'Fungsi Pengelola Gudang','KONTRIBUTOR','DIRECT','{}'),
 ('F-TKL',12,'Fungsi Tata Kelola','KONTRIBUTOR','PROXY','{}'),
 ('F-MRS',13,'Fungsi Manajemen Risiko','KONTRIBUTOR','DIRECT','{}'),
 ('F-KEU',14,'Fungsi Keuangan','KONTRIBUTOR','DIRECT','{}'),
 ('F-AKT',15,'Fungsi Akuntansi','PIMPINAN_TEMBUSAN','DIRECT','{}'),
 ('F-ANG',16,'Fungsi Pengendali Anggaran','KONTRIBUTOR','DIRECT','{}'),
 ('F-SDM',17,'Fungsi SDM','KONTRIBUTOR','PROXY','{"Fungsi Rekrutmen","Fungsi Pembelajaran dan Pengembangan SDM"}'),
 ('F-UMM',18,'Fungsi Urusan Umum','LAINNYA','PROXY','{}'),
 ('F-PRT',19,'Fungsi Portofolio','PIMPINAN_TEMBUSAN','DIRECT','{}'),
 ('F-TI',20,'Fungsi Teknologi Informasi','LAINNYA','DIRECT','{}'),
 ('F-PPR',21,'Fungsi Perencanaan Perusahaan','PIMPINAN_TEMBUSAN','DIRECT','{"Unit Perencanaan & Evaluasi Korporasi"}'),
 ('F-SEK',22,'Fungsi Sekretaris Perusahaan','LAINNYA','PROXY','{}'),
 ('F-LGL',23,'Fungsi Legal','KONTRIBUTOR','PROXY','{}'),
 ('F-KOM',24,'Fungsi Komunikasi Korporasi','LAINNYA','PROXY','{}'),
 ('F-TJS',25,'Fungsi TJSL','LAINNYA','PROXY','{}'),
 ('F-AUD',26,'Fungsi Audit Internal','PIMPINAN_TEMBUSAN','DIRECT','{"SPI"}'),
 ('F-K3L',27,'Fungsi K3L','KONTRIBUTOR','DIRECT','{"Fungsi K3","Fungsi Pengelolaan Lingkungan Hidup"}'),
 ('F-PAM',28,'Fungsi Pengamanan','LAINNYA','PROXY','{}'),
 ('F-PMT',29,'Fungsi Penjaminan Mutu','KONTRIBUTOR','DIRECT','{"Fungsi Quality Control"}'),
 ('F-MPB',30,'Fungsi Manajemen Proses Bisnis','LAINNYA','PROXY','{}'),
 ('F-PSM',31,'Fungsi Pengelola Sistem Manajemen','LAINNYA','PROXY','{}'),
 ('F-PRD',32,'Fungsi Produksi','KONTRIBUTOR','PROXY','{}'),
 ('F-RPP',33,'Fungsi Rekayasa Pra Produksi','KONTRIBUTOR','PROXY','{}'),
 ('F-RDP',34,'Fungsi Rendal Produksi','KONTRIBUTOR','PROXY','{}'),
 ('F-OPP',35,'Fungsi Operasi Produksi','KONTRIBUTOR','PROXY','{}'),
 ('F-DIR',0,'Direksi / Project Sponsor','PIMPINAN_TEMBUSAN','DIRECT','{"Direksi","Project Sponsor"}')
ON CONFLICT (code) DO NOTHING;

-- FOP-700 Jenis Kode ---------------------------------------------------------
INSERT INTO lpms3.ref_jenis_kode (code, name, kelompok, pemilik_kode, template_code) VALUES
 ('PB','Proyek Bisnis','PROYEK','Fungsi Pelaksanaan (Manajemen) Proyek','LPMS3-Prediktif'),
 ('PL','Proyek Litbang','PROYEK','Fungsi Litbang / Fungsi Manajemen Proyek','LPMS3-Hibrid'),
 ('PI','Proyek Investasi','PROYEK','Fungsi yang ditugaskan','LPMS3-Prediktif'),
 ('PP','Prospek Proyek','PROYEK','Fungsi Pemasaran / Pengembangan Bisnis','LPMS3-Ringan'),
 ('PJ','Purnajual Proyek','PROYEK','Fungsi Purnajual','LPMS3-Purnajual'),
 ('GP','Program Persediaan Produk','PROGRAM','Fungsi Pemasaran','LPMS3-Program'),
 ('GR','Program Produksi','PROGRAM','Fungsi Rendal Produksi','LPMS3-Program'),
 ('GI','Program Internal Litbang','PROGRAM','Fungsi Litbang','LPMS3-Program'),
 ('GE','Program Eksternal Litbang','PROGRAM','Fungsi Litbang','LPMS3-Program'),
 ('GK','Program Rekayasa Produksi','PROGRAM','Fungsi Rekayasa Pra Produksi','LPMS3-Program'),
 ('GB','Program Kajian Bisnis','PROGRAM','Fungsi Pengembangan Bisnis','LPMS3-Program'),
 ('GV','Program Investasi','PROGRAM','Fungsi pengelola investasi','LPMS3-Program'),
 ('TP','Transfer Load Produksi dan Persediaan Produk','TRANSFER_LOAD','Fungsi Rendal Produksi','LPMS3-TransferLoad'),
 ('TL','Transfer Load Litbang dan POC','TRANSFER_LOAD','Fungsi Litbang','LPMS3-TransferLoad')
ON CONFLICT (code) DO NOTHING;

-- SOP-004 Kelas Kontrak ------------------------------------------------------
INSERT INTO lpms3.ref_kelas_kontrak VALUES
 ('Kecil', 0, 25000000000, 'Tidak dilakukan Tinjauan Kontrak Go (Persetujuan Kontrak Kecil SFR-024)'),
 ('Sedang', 25000000000, 100000000000, 'Tinjauan Kontrak Go kelas sedang (SFR-028)'),
 ('Besar', 100000000000, NULL, 'Tinjauan Kontrak Go kelas besar dipimpin Direktur Utama (SFR-028)')
ON CONFLICT (kelas) DO NOTHING;

-- BOG-003 & BFR-001 Matriks kewenangan ---------------------------------------
INSERT INTO lpms3.ref_matriks_kewenangan (objek, nilai_min, nilai_max, pengaju, penyetuju, sla_hari, dokumen, sumber_sop) VALUES
 ('PERGESERAN_ANGGARAN', 0, 200000000, 'Pemilik Anggaran', 'Pejabat Struktural ES II', 1, 'Form', 'BOG-003 §5.3'),
 ('PERGESERAN_ANGGARAN', 200000001, 500000001, 'Pemilik Anggaran', 'Pejabat Struktural ES I & ES II', 2, 'Nota', 'BOG-003 §5.3'),
 ('PERGESERAN_ANGGARAN', 500000001, NULL, 'Pemilik Anggaran dan Eselon I', 'Direksi terkait', 3, 'Nota', 'BOG-003 §5.3'),
 ('CHANGE_REQUEST', 0, 999999999.99, 'Pimpinan Proyek', 'Eselon II Fungsi Manajemen Proyek + Eselon II Fungsi Pengawasan Proyek', NULL, 'BFR-001', 'BFR-001 petunjuk 13 & 15'),
 ('CHANGE_REQUEST', 1000000000, NULL, 'Pimpinan Proyek', 'Eselon I Fungsi Manajemen Proyek + Eselon I Fungsi Pengawasan Proyek', NULL, 'BFR-001', 'BFR-001 petunjuk 13 & 15'),
 ('REVISI_ANGGARAN_ABT', 0, NULL, 'Fungsi Manajemen Proyek', 'Rapat Tinjauan ABT dipimpin Direktur bidang Keuangan & SDM', NULL, 'CFR-022', 'BOG-003 §5.4.1')
ON CONFLICT (objek, nilai_min) DO NOTHING;

-- ROP-911 Level Risiko ------------------------------------------------------
INSERT INTO lpms3.ref_level_risiko VALUES
 (1, 5, 'Rendah', 'green', 'Masuk Selera Risiko; diperhatikan dan dicatat ke database Risiko'),
 (6, 11, 'Rendah-Menengah', 'lime', 'Masuk Selera Risiko; dilakukan pemantauan'),
 (12, 15, 'Menengah', 'yellow', 'Masuk Selera Risiko; dilakukan pemantauan'),
 (16, 19, 'Menengah-Tinggi', 'orange', 'Diperlukan tindakan penanganan untuk menurunkan level risiko'),
 (20, 25, 'Tinggi', 'red', 'Diperlukan segera tindakan penanganan dengan koordinasi intensif semua level pengambil keputusan')
ON CONFLICT (level) DO NOTHING;

-- Peserta rapat (contoh inti; daftar lengkap dimuat dari docs/data-dictionary) --
INSERT INTO lpms3.ref_peserta_rapat (jenis_rapat, kelas, urutan, peran, peserta, fungsi_code, grade, sumber_sop) VALUES
 ('Kick-Off Meeting', NULL, 1, 'Pemimpin dan Penyelenggara Rapat', 'Eselon I/II Fungsi Pengawasan Proyek', 'F-PWP', 'ES1/ES2', 'BOP-001 Tabel 2'),
 ('Kick-Off Meeting', NULL, 2, 'Pemapar Rapat', 'Eselon I/II Fungsi Pelaksanaan Proyek / Pimpro', 'F-MPR', 'ES1/ES2', 'BOP-001 Tabel 2'),
 ('Rapat Tinjauan Proyek', NULL, 1, 'Pemimpin dan Penyelenggara Rapat', 'Eselon I/II Fungsi Pengawasan Proyek', 'F-PWP', 'ES1/ES2', 'BOP-001 Tabel 4'),
 ('Rapat Tinjauan Proyek', NULL, 2, 'Pemapar Tinjauan', 'Eselon I/II Fungsi Manajemen Proyek / Pimpro', 'F-MPR', 'ES1/ES2', 'BOP-001 Tabel 4'),
 ('Rapat Tinjauan Adendum', 'Biasa', 1, 'Pemimpin & Penyelenggara Rapat Tinjauan', 'Eselon I/II Fungsi Pengawasan Proyek', 'F-PWP', 'ES1/ES2', 'SOP-009'),
 ('Rapat Tinjauan Adendum', 'Biasa', 2, 'Pemapar Rapat Tinjauan', 'Eselon I/II Fungsi Manajemen Proyek', 'F-MPR', 'ES1/ES2', 'SOP-009'),
 ('Rapat Tinjauan ABT', NULL, 1, 'Pemimpin Rapat Tinjauan', 'Direktur yang membidangi Fungsi Keuangan dan SDM', 'F-DIR', 'DIREKSI', 'BOG-003 §5.4.1'),
 ('Rapat Tinjauan ABT', NULL, 2, 'Penyelenggara Rapat Tinjauan', 'Eselon I/II Fungsi Pengawasan Proyek', 'F-PWP', 'ES1/ES2', 'BOG-003 §5.4.1'),
 ('Rapat Tinjauan ABT', NULL, 3, 'Pemapar Rapat Tinjauan', 'Eselon I/II Fungsi Manajemen Proyek', 'F-MPR', 'ES1/ES2', 'BOG-003 §5.4.1')
ON CONFLICT DO NOTHING;

-- Katalog kapabilitas (§14.5) -----------------------------------------------
INSERT INTO lpms3.capability (code, name, module) VALUES
 ('PRJ_CREATE','Buat proyek / Add New dari LPMS 2','PROJECT'), ('PRJ_CODE','Kelola Kode Proyek (FFR-706/FLP-01)','INISIASI'),
 ('CHARTER_EDIT','Susun Project Charter (BOT-001)','INISIASI'), ('GATE_DECIDE','Putuskan gate fase','GOVERNANCE'),
 ('TEAM_ASSIGN','Penugasan Pimpro & tim','INISIASI'), ('PMP_EDIT','Susun/reviu 9 aspek PMP','PERENCANAAN'),
 ('PMP_APPROVE','Sahkan 9 aspek PMP','PERENCANAAN'), ('WBS_EDIT','Ubah WBS (Template LPMS)','PERENCANAAN'),
 ('WBS_PROGRESS','Update % Complete + bukti','EKSEKUSI'), ('BASELINE_SET','Tetapkan baseline/rebaseline','PERENCANAAN'),
 ('WO_ISSUE','Terbitkan Work Order','EKSEKUSI'), ('WO_EXECUTE','Kerjakan Work Order','EKSEKUSI'),
 ('CR_SUBMIT','Ajukan Change Request (BFR-001)','EKSEKUSI'), ('CR_REVIEW','Periksa CR (Fungsi Pengawasan)','MONITORING'),
 ('CR_APPROVE_ES2','Setujui CR < Rp1 M','MONITORING'), ('CR_APPROVE_ES1','Setujui CR ≥ Rp1 M','MONITORING'),
 ('BUDGET_SHIFT','Ajukan Top-Up/Pergeseran (BOG-003)','EKSEKUSI'), ('BUDGET_APPROVE','Setujui pergeseran sesuai matriks','MONITORING'),
 ('LKP_UPLOAD','Unggah & bersihkan LKP (L0)','MONITORING'), ('LKP_SUBMIT','Submit LKP (L1)','MONITORING'),
 ('LKP_VERIFY','Verifikasi LKP (L2)','MONITORING'), ('LKP_APPROVE_ES2','Periksa LKP (L3)','MONITORING'),
 ('LKP_APPROVE_ES1','Setujui LKP (L4)','MONITORING'), ('LKP_ACK_DIR','Tinjauan Direksi (L5)','MONITORING'),
 ('LKP_VIEW_CC','Lihat LKP sebagai tembusan','MONITORING'), ('VALIDATION_WAIVE','Waive aturan validasi','MONITORING'),
 ('PROC_EDIT','Kelola Procurement Pipeline','MONITORING'), ('PAYMENT_EDIT','Kelola termin & pembayaran','MONITORING'),
 ('PAYMENT_VIEW','Lihat Cross Payment','MONITORING'), ('RISK_EDIT','Kelola RFR-002/RFR-001','MONITORING'),
 ('K3LH_EDIT','Kelola VFR-015','MONITORING'), ('QA_EDIT','Kelola CFR-027 & inspeksi','MONITORING'),
 ('MEETING_RUN','Selenggarakan rapat & CFR-022','KOMUNIKASI'), ('CLOSE_PROJECT','Jalankan wizard Closing','CLOSING'),
 ('HEALTH_VIEW_PORTFOLIO','Lihat Project Health portofolio','OVERVIEW'), ('AUDIT_READ_RAW','Audit baca data mentah','AUDIT'),
 ('ORG_ADMIN','Settings › User & Access','SETTINGS'), ('APP_ADMIN','Settings › Application','SETTINGS')
ON CONFLICT (code) DO NOTHING;
