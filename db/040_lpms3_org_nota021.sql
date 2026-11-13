-- Struktur organisasi & pemetaan Fungsi Generik -> Unit Aktual.
-- Sumber: Nota 021/N/UQ/VIII/2026 (24 Agustus 2026) "Pembaruan Pemetaan Fungsi Generik Terhadap Unit Aktual",
--         dasar struktur: Keputusan Direktur Utama No. 001/SKEP.HC/DU/I/2026 (8 Januari 2026).
-- Idempoten: aman dijalankan berulang. Dibangkitkan dari PDF Nota; ubah lewat Settings > Organisasi, bukan dengan menyunting berkas ini.
--
-- Asumsi jenjang (SKEP belum ada di repo): Direktorat = DIREKSI, Divisi = ES1, Bagian = ES2 (sesuai contoh kapabilitas Spesifikasi 14.5/14.9).
-- Bila SKEP menunjukkan lain, ubah kolom grade di lpms3.org_unit.

ALTER TABLE lpms3.fungsi_generik ADD COLUMN IF NOT EXISTS induk_id integer REFERENCES lpms3.fungsi_generik(id);
ALTER TABLE lpms3.fungsi_generik ADD COLUMN IF NOT EXISTS sumber_dok text;
ALTER TABLE lpms3.fungsi_unit_map ADD COLUMN IF NOT EXISTS fungsi_lama_id integer REFERENCES lpms3.fungsi_generik(id);
ALTER TABLE lpms3.fungsi_unit_map ADD COLUMN IF NOT EXISTS lingkup text;
ALTER TABLE lpms3.fungsi_unit_map ADD COLUMN IF NOT EXISTS catatan text;
COMMENT ON COLUMN lpms3.fungsi_generik.induk_id IS 'Fungsi generik lama (CLP-001) yang menjadi induk fungsi baru menurut Nota 021';
COMMENT ON COLUMN lpms3.fungsi_unit_map.fungsi_lama_id IS 'Fungsi generik lama pada baris Nota 021 yang sama (NULL bila ditulis "-")';

INSERT INTO lpms3.org_structure (code, name, effective_from, status) VALUES
 ('SKEP-001-2026','Struktur Organisasi PT Len Industri (Persero) - Kepdir No. 001/SKEP.HC/DU/I/2026','2026-01-08','ACTIVE')
ON CONFLICT (code) DO NOTHING;

-- Unit: DIREKSI
INSERT INTO lpms3.org_unit (structure_id, parent_id, code, name, grade, aliases)
SELECT s.id, p.id, v.code, v.name, v.grade, v.aliases::text[]
FROM (VALUES
 ('DIR-1',NULL,'Direktorat Utama','DIREKSI','{}'),
 ('DIR-2',NULL,'Direktorat Bisnis & Kerjasama','DIREKSI','{}'),
 ('DIR-3',NULL,'Direktorat Operasi','DIREKSI','{}'),
 ('DIR-4',NULL,'Direktorat Teknologi & Manajemen Risiko','DIREKSI','{}'),
 ('DIR-5',NULL,'Direktorat Keuangan, Manajemen Portofolio Dan SDM','DIREKSI','{}')
) AS v(code, parent_code, name, grade, aliases)
JOIN lpms3.org_structure s ON s.code = 'SKEP-001-2026'
LEFT JOIN lpms3.org_unit p ON p.structure_id = s.id AND p.code = v.parent_code
ON CONFLICT (structure_id, code) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, aliases = EXCLUDED.aliases;

-- Unit: ES1
INSERT INTO lpms3.org_unit (structure_id, parent_id, code, name, grade, aliases)
SELECT s.id, p.id, v.code, v.name, v.grade, v.aliases::text[]
FROM (VALUES
 ('DIR-1.1','DIR-1','Divisi Corporate Strategic Planning','ES1','{}'),
 ('DIR-1.2','DIR-1','Divisi Corporate Secretary','ES1','{}'),
 ('DIR-1.3','DIR-1','Divisi Internal Audit','ES1','{}'),
 ('DIR-1.4','DIR-1','Divisi Legal','ES1','{}'),
 ('DIR-2.1','DIR-2','Divisi Marketing & Sales Center','ES1','{}'),
 ('DIR-2.2','DIR-2','Divisi Business Development & Global Partnership','ES1','{}'),
 ('DIR-3.1','DIR-3','Divisi Project Deployment Center','ES1','{}'),
 ('DIR-3.2','DIR-3','Divisi Project Management Office','ES1','{}'),
 ('DIR-3.3','DIR-3','Divisi Engineering','ES1','{}'),
 ('DIR-3.4','DIR-3','Divisi Supply Chain Management','ES1','{}'),
 ('DIR-4.1','DIR-4','Divisi Innovation Center','ES1','{}'),
 ('DIR-4.2','DIR-4','Divisi Information System','ES1','{}'),
 ('DIR-4.3','DIR-4','Divisi Governance, Risk Management & Compliance','ES1','{}'),
 ('DIR-4.4','DIR-4','Divisi QHSE & Process Excellence','ES1','{}'),
 ('DIR-5.1','DIR-5','Divisi Finance','ES1','{}'),
 ('DIR-5.2','DIR-5','Divisi Accounting','ES1','{}'),
 ('DIR-5.3','DIR-5','Divisi Human Capital & General Affairs','ES1','{}'),
 ('DIR-5.4','DIR-5','Divisi Portfolio Management','ES1','{}')
) AS v(code, parent_code, name, grade, aliases)
JOIN lpms3.org_structure s ON s.code = 'SKEP-001-2026'
LEFT JOIN lpms3.org_unit p ON p.structure_id = s.id AND p.code = v.parent_code
ON CONFLICT (structure_id, code) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, aliases = EXCLUDED.aliases;

-- Unit: ES2
INSERT INTO lpms3.org_unit (structure_id, parent_id, code, name, grade, aliases)
SELECT s.id, p.id, v.code, v.name, v.grade, v.aliases::text[]
FROM (VALUES
 ('DIR-1.1.1','DIR-1.1','Bagian Corporate Planning & Performance Management','ES2','{"Corporate Planning & Performance Management"}'),
 ('DIR-1.1.2','DIR-1.1','Bagian Corporate Program & Strategy Management','ES2','{"Corporate Program & Strategy Management"}'),
 ('DIR-1.2.1','DIR-1.2','Bagian Institutional Relation & Corporate Communication','ES2','{"Institutional Relation & Corporate Communication"}'),
 ('DIR-1.2.2','DIR-1.2','Bagian Corporate Social Responsibility','ES2','{"Corporate Social Responsibility"}'),
 ('DIR-1.2.3','DIR-1.2','Bagian Corporate Security','ES2','{"Corporate Security"}'),
 ('DIR-1.3.1','DIR-1.3','Bagian General Audit','ES2','{"General Audit"}'),
 ('DIR-1.3.2','DIR-1.3','Bagian Specific Audit & Audit Quality','ES2','{"Specific Audit & Audit Quality"}'),
 ('DIR-1.4.1','DIR-1.4','Bagian Corporate Legal','ES2','{"Corporate Legal"}'),
 ('DIR-1.4.2','DIR-1.4','Bagian Litigation & Dispute Resolution','ES2','{"Litigation & Dispute Resolution","Bagian Ligitation & Dispute Resolution","Ligitation & Dispute Resolution"}'),
 ('DIR-2.1.1','DIR-2.1','Bagian Marketing & Sales - Army','ES2','{"Marketing & Sales - Army"}'),
 ('DIR-2.1.2','DIR-2.1','Bagian Marketing & Sales – Navy','ES2','{"Marketing & Sales – Navy"}'),
 ('DIR-2.1.3','DIR-2.1','Bagian Marketing & Sales – Air Force','ES2','{"Marketing & Sales – Air Force"}'),
 ('DIR-2.1.4','DIR-2.1','Bagian Project & Supply Planning','ES2','{"Project & Supply Planning"}'),
 ('DIR-2.2.1','DIR-2.2','Bagian Business Development','ES2','{"Business Development"}'),
 ('DIR-2.2.2','DIR-2.2','Bagian Strategic Partnership','ES2','{"Strategic Partnership"}'),
 ('DIR-3.1.1','DIR-3.1','Bagian Project Operation 1, 2 dan 3','ES2','{"Project Operation 1, 2 dan 3"}'),
 ('DIR-3.2.1','DIR-3.2','Bagian Operation Monitoring & Evaluation','ES2','{"Operation Monitoring & Evaluation"}'),
 ('DIR-3.2.2','DIR-3.2','Bagian Bid & Resource Management','ES2','{"Bid & Resource Management"}'),
 ('DIR-3.3.1','DIR-3.3','Bagian Engineering 1','ES2','{"Engineering 1"}'),
 ('DIR-3.3.2','DIR-3.3','Bagian Engineering 2','ES2','{"Engineering 2"}'),
 ('DIR-3.4.1','DIR-3.4','Bagian Procurement Policy','ES2','{"Procurement Policy"}'),
 ('DIR-3.4.2','DIR-3.4','Bagian Procurement Operation','ES2','{"Procurement Operation"}'),
 ('DIR-4.1.1','DIR-4.1','Bagian Innovation Ecosystem','ES2','{"Innovation Ecosystem"}'),
 ('DIR-4.1.2','DIR-4.1','Bagian Technology Innovation','ES2','{"Technology Innovation"}'),
 ('DIR-4.2.1','DIR-4.2','Bagian IT Governance & Data Management','ES2','{"IT Governance & Data Management"}'),
 ('DIR-4.2.2','DIR-4.2','Bagian IT Operation and Cyber Security','ES2','{"IT Operation and Cyber Security"}'),
 ('DIR-4.2.3','DIR-4.2','Bagian IT Development','ES2','{"IT Development"}'),
 ('DIR-4.3.1','DIR-4.3','Bagian Risk Management','ES2','{"Risk Management"}'),
 ('DIR-4.3.2','DIR-4.3','Bagian Corporate Governance & Compliance','ES2','{"Corporate Governance & Compliance"}'),
 ('DIR-4.4.1','DIR-4.4','Bagian Business Process Management','ES2','{"Business Process Management"}'),
 ('DIR-4.4.2','DIR-4.4','Bagian Quality Assurance','ES2','{"Quality Assurance"}'),
 ('DIR-4.4.3','DIR-4.4','Bagian Health Safety & Environment','ES2','{"Health Safety & Environment"}'),
 ('DIR-5.1.1','DIR-5.1','Bagian Corporate Finance','ES2','{"Corporate Finance"}'),
 ('DIR-5.1.2','DIR-5.1','Bagian Treasury','ES2','{"Treasury"}'),
 ('DIR-5.2.1','DIR-5.2','Bagian Accounting & Reporting','ES2','{"Accounting & Reporting"}'),
 ('DIR-5.2.2','DIR-5.2','Bagian Budgeting, PMN, & Cost Control','ES2','{"Budgeting, PMN, & Cost Control"}'),
 ('DIR-5.2.3','DIR-5.2','Bagian Tax Management','ES2','{"Tax Management"}'),
 ('DIR-5.3.1','DIR-5.3','Bagian Human Capital Policy & Strategy','ES2','{"Human Capital Policy & Strategy"}'),
 ('DIR-5.3.2','DIR-5.3','Bagian Human Capital Performance & Talent Management','ES2','{"Human Capital Performance & Talent Management"}'),
 ('DIR-5.3.3','DIR-5.3','Bagian Human Capital Services','ES2','{"Human Capital Services"}'),
 ('DIR-5.3.4','DIR-5.3','Bagian General Affairs','ES2','{"General Affairs"}'),
 ('DIR-5.4.1','DIR-5.4','Bagian Portfolio Optimization','ES2','{"Portfolio Optimization"}'),
 ('DIR-5.4.2','DIR-5.4','Bagian Subsidiaries Alignment & Support','ES2','{"Subsidiaries Alignment & Support","Bagian Subsidiairies Alignment & Support","Subsidiairies Alignment & Support"}')
) AS v(code, parent_code, name, grade, aliases)
JOIN lpms3.org_structure s ON s.code = 'SKEP-001-2026'
LEFT JOIN lpms3.org_unit p ON p.structure_id = s.id AND p.code = v.parent_code
ON CONFLICT (structure_id, code) DO UPDATE SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, aliases = EXCLUDED.aliases;

-- Fungsi generik baru (Nota 021) yang belum ada di CLP-001
INSERT INTO lpms3.fungsi_generik (code, name, definition, category, involvement_mode, induk_id, sumber_dok)
SELECT v.code, v.name, v.definition, v.category, v.mode, i.id, 'Nota 021/N/UQ/VIII/2026'
FROM (VALUES
 ('FB-01','Fungsi Kinerja Perusahaan','Melakukan pengawasan, evaluasi, dan pengendalian kinerja Perusahaan guna memastikan pencapaian target, efektivitas implementasi strategi, dan peningkatan kinerja Perusahaan.','PIMPINAN_TEMBUSAN','DIRECT','F-PPR'),
 ('FB-02','Fungsi Tanggung Jawab Sosial & Lingkungan','Melakukan pelaksanaan, monitoring, evaluasi, regulasi, dan administrasi kegiatan Tanggung Jawab Sosial dan Lingkungan (TJSL) guna meningkatkan citra positif Perusahaan serta memastikan pelaksanaan program TJSL berjalan efektif, terarah, dan sesuai ketentuan Perusahaan.','LAINNYA','PROXY','F-TJS'),
 ('FB-03','Fungsi Asurans','Melakukan kegiatan audit internal secara periodik dan audit khusus secara independen dan objektif guna mendukung fungsi pengawasan internal, memberikan assurance dan consulting, serta memastikan pelaksanaan kegiatan Perusahaan berjalan sesuai kaidah, perencanaan, peraturan, dan ketentuan yang berlaku.','PIMPINAN_TEMBUSAN','DIRECT','F-AUD'),
 ('FB-04','Fungsi Advisori','Melakukan monitoring tindak lanjut hasil audit secara periodik dalam rangka pengawasan internal untuk memberikan assurance dan consulting yang independen dan objektif guna meningkatkan efektivitas pengendalian internal, manajemen risiko, tata kelola Perusahaan, serta mendukung optimalisasi operasional Perusahaan.','PIMPINAN_TEMBUSAN','DIRECT','F-AUD'),
 ('FB-05','Fungsi Penjaminan & Peningkatan Mutu Audit','Melakukan penyusunan pedoman strategis peningkatan infrastruktur dan standarisasi Internal Audit serta pelaksanaan aktivitas audit internal lainnya guna meningkatkan kualitas audit dan kapabilitas personil Internal Audit.','PIMPINAN_TEMBUSAN','DIRECT','F-AUD'),
 ('FB-06','Fungsi Kontrak Bisnis','Melaksanakan peninjauan, evaluasi, pengendalian, negosiasi, dan finalisasi dokumen hukum serta kontrak yang berkaitan dengan kegiatan dan/atau hubungan bisnis Perusahaan dengan mitra kerja, memberikan opini legal atas isu hukum yang timbul dalam kegiatan bisnis Perusahaan, serta melakukan pendampingan negosiasi kontrak guna memastikan kepatuhan terhadap ketentuan hukum dan perlindungan kepentingan Perusahaan.','KONTRIBUTOR','PROXY','F-LGL'),
 ('FB-07','Fungsi Legal Korporasi','Melaksanakan pengelolaan aspek legal korporasi guna memastikan seluruh operasional, kebijakan, dan keputusan strategis Perusahaan berjalan sesuai dengan peraturan perundang-undangan, prinsip kepatuhan, dan tata kelola perusahaan yang baik, termasuk pengelolaan aspek hukum terkait perubahan struktur perusahaan, merger, akuisisi, restrukturisasi, perubahan Anggaran Dasar, perizinan, dan perbuatan hukum Perusahaan sesuai ketentuan yang berlaku.','KONTRIBUTOR','PROXY','F-LGL'),
 ('FB-08','Fungsi Perijinan','Melakukan pengelolaan perijinan dan perbuatan hukum Perusahaan guna mendukung kelancaran operasional Perusahaan serta memastikan pemenuhan ketentuan dan regulasi yang berlaku.','KONTRIBUTOR','PROXY','F-LGL'),
 ('FB-09','Fungsi Penanganan Litigasi dan Sengketa Hukum','Melakukan pengelolaan advokasi serta penyelesaian permasalahan dan sengketa hukum Perusahaan secara litigasi maupun non-litigasi, termasuk pemberian rekomendasi strategis atas risiko dan dampak hukum guna mendukung kegiatan bisnis dan operasional Perusahaan secara efektif dan sesuai ketentuan yang berlaku.','KONTRIBUTOR','PROXY','F-LGL'),
 ('FB-10','Fungsi Perencanaan PMN','Memimpin dan mengoordinasikan penyusunan business plan dan perencanaan pengembangan fasilitas radar, termasuk penyusunan prioritas kerja, rencana aksi, serta perumusan arah, sasaran, dan strategi pengembangan.','LAINNYA','PROXY',NULL),
 ('FB-11','Fungsi Kemitraan Strategis','Melakukan pengelolaan, perumusan, dan pengembangan kemitraan strategis Perusahaan guna memperkuat posisi kompetitif, meningkatkan leverage teknologi dan pasar, serta mendorong pertumbuhan bisnis Perusahaan secara berkesinambungan.','KONTRIBUTOR','PROXY','F-PBS'),
 ('FB-12','Program Director','Mengelola perencanaan, koordinasi, pelaksanaan, pengendalian, monitoring, dan evaluasi program strategis Perusahaan guna memastikan pencapaian target program sesuai ruang lingkup, jadwal, anggaran, mutu, serta kebijakan Perusahaan.','LAINNYA','PROXY',NULL),
 ('FB-13','Fungsi Pelaksanaan PMN','Melakukan pengelolaan dan pengendalian pelaksanaan proyek PMN sesuai perencanaan, kontrak, dan ketentuan yang berlaku guna mendukung pencapaian target proyek, peningkatan value, dan profitabilitas Perusahaan.','LAINNYA','PROXY',NULL),
 ('FB-14','Fungsi Rekayasa Solusi Teknis Proyek','Memberikan dukungan teknis dan engineering mulai dari tahap pengembangan bisnis, pemasaran, hingga penjualan, mendesain solusi kesisteman serta mendukung implementasi teknis proyek.','KONTRIBUTOR','DIRECT','F-RKS'),
 ('FB-15','Fungsi Rekayasa Sistem/Produk','Memberikan dukungan teknis dan engineering mulai dari tahap pengembangan bisnis, pemasaran, hingga penjualan yang terkait dengan produk hasil pengembangan yang akan digelar di proyek.','KONTRIBUTOR','DIRECT','F-RKS'),
 ('FB-16','Fungsi Perencanaan Pengadaan','Melakukan perencanaan terhadap pengadaan barang/jasa serta kepatuhan terhadap peraturan yang berlaku baik internal maupun eksternal. Melaksanakan perencanaan pengadaan barang/jasa dengan memperhatikan kepatuhan terhadap peraturan perundang-undangan, kebijakan Perusahaan, serta ketentuan internal yang berlaku.','KONTRIBUTOR','DIRECT','F-PGD'),
 ('FB-17','Fungsi Operasional Pengadaan','Melakukan seluruh kegiatan operasional dalam proses pengadaan barang/jasa.','KONTRIBUTOR','DIRECT','F-PGD'),
 ('FB-18','Fungsi Kemitraan Inovasi','Melakukan pembangunan dan pengelolaan ekosistem inovasi teknologi melalui kolaborasi guna mendukung pengembangan bisnis dan peningkatan daya saing Perusahaan.','KONTRIBUTOR','PROXY','F-PBS'),
 ('FB-19','Fungsi Kekayaan Intelektual','Melakukan pengelolaan perlindungan hasil inovasi guna mendukung pemanfaatan teknologi dan peningkatan nilai produk Perusahaan.','KONTRIBUTOR','PROXY','F-PBS'),
 ('FB-20','Fungsi Pengelolaan Data','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap pengelolaan dan pemanfaatan data Perusahaan (baik data terstruktur maupun tidak terstruktur) sebagai pendukung pengembangan dan pemanfaatan sistem informasi guna meningkatkan value Perusahaan dan efektivitas operasional perusahaan.','LAINNYA','DIRECT','F-TI'),
 ('FB-21','Fungsi Pengelolaan Sistem Manajemen Keamanan Informasi','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap penerapan Sistem Manajemen Keamanan Informasi (SMKI) sesuai ISO 27001 guna memastikan pengelolaan keamanan informasi berjalan sesuai kaidah, peraturan, dan ketentuan yang berlaku di Perusahaan.','LAINNYA','PROXY','F-PSM'),
 ('FB-22','Fungsi ICoFR','Melakukan pelaksanaan Internal Control over Financial Reporting (ICoFR) guna memastikan penerapan manajemen risiko atas pengendalian pelaporan keuangan Perusahaan berjalan secara terpadu untuk mendukung pencapaian target bisnis Perusahaan','KONTRIBUTOR','DIRECT','F-MRS'),
 ('FB-23','Fungsi Tata Kelola Perusahaan','Melakukan perumusan dan pelaksanaan tata kelola Perusahaan sesuai kaidah Good Corporate Governance (GCG) serta pengembangan kerangka kerja Environmental, Social, and Governance (ESG) guna menjaga profesionalisme dan akuntabilitas operasional Perusahaan.','KONTRIBUTOR','PROXY','F-TKL'),
 ('FB-24','Fungsi Kepatuhan','Melakukan pengelolaan dan pengawasan kepatuhan Perusahaan terhadap peraturan pemerintah dan ketentuan yang berlaku guna mendukung penerapan manajemen kepatuhan Perusahaan secara efektif.','KONTRIBUTOR','PROXY','F-TKL'),
 ('FB-25','Fungsi Integrasi Sistem Manajemen','Melakukan penyusunan panduan, pengawasan, dan evaluasi implementasi sistem manajemen guna mendukung integrasi dan efektivitas penerapan sistem manajemen Perusahaan.','LAINNYA','PROXY','F-PSM'),
 ('FB-26','Fungsi Quality Control','Melakukan pengendalian dan pemeriksaan kualitas barang dan jasa Perusahaan guna memastikan kesesuaian terhadap standar dan ketentuan mutu yang berlaku.','KONTRIBUTOR','DIRECT','F-PMT'),
 ('FB-27','Fungsi Kalibrasi','Melakukan pengelolaan dan pelaksanaan kegiatan kalibrasi peralatan guna memastikan keakuratan hasil pengukuran dan mendukung kualitas proses operasional Perusahaan.','KONTRIBUTOR','DIRECT','F-PMT'),
 ('FB-28','Fungsi Keselamatan dan Kesehatan Kerja (K3)','Menyelenggarakan perencanaan, koordinasi, implementasi, pemantauan, dan evaluasi program Keselamatan dan Kesehatan Kerja sesuai prinsip SMK3 dan ISO 45001, guna memastikan seluruh aktivitas kerja di lingkungan Perusahaan berjalan aman, sehat, terkendali, serta memenuhi ketentuan peraturan perundang-undangan/persyaratan lainnya dan standar internal yang berlaku.','KONTRIBUTOR','DIRECT','F-K3L'),
 ('FB-29','Fungsi Pengelolaan Lingkungan Hidup','Menyelenggarakan perencanaan, koordinasi, implementasi, pemantauan, dan evaluasi program pengelolaan lingkungan hidup sesuai prinsip ISO 14001, guna memastikan aspek dan dampak lingkungan dari kegiatan Perusahaan dikelola secara terkendali, memenuhi ketentuan peraturan perundang- undangan/persyaratan lainnya yang dibutuhkan dan mendukung peningkatan kinerja lingkungan secara berkelanjutan.','KONTRIBUTOR','DIRECT','F-K3L'),
 ('FB-30','Fungsi Pendanaan','Melakukan pengelolaan kegiatan pendanaan, pengadaan asuransi aset tetap dan peninjauan prospek bisnis Perusahaan guna mendukung keberlangsungan bisnis dan mitigasi risiko Perusahaan.','KONTRIBUTOR','DIRECT','F-KEU'),
 ('FB-31','Fungsi Pengawasan PMN','Mengawasi, memonitor, dan mengevaluasi pengelolaan dana Penyertaan Modal Negara (PMN) guna memastikan pemanfaatan dana berjalan efektif, tepat sasaran, sesuai ketentuan, serta mendukung akuntabilitas, transparansi, dan pencapaian target strategis Perusahaan.','KONTRIBUTOR','DIRECT','F-ANG'),
 ('FB-32','Fungsi Pajak','Melakukan pengelolaan kegiatan perpajakan Perusahaan meliputi standarisasi pembebanan transaksi perpajakan, pelaksanaan dan pengendalian perpajakan, pemeriksaan dan pencatatan transaksi pajak, penyusunan daftar pembayaran pajak, administrasi pembayaran pajak, serta pemberian rekomendasi aspek perpajakan pada prospek bisnis Perusahaan.','KONTRIBUTOR','DIRECT','F-KEU'),
 ('FB-33','Fungsi Pengembangan Organisasi','Melakukan penyusunan kerangka kerja, kajian dan pengembangan organisasi meliputi perancangan struktur organisasi, penyusunan tupoksi, uraian dan spesifikasi jabatan, serta evaluasi efektivitas organisasi dan evaluasi jabatan guna mendukung pengelolaan organisasi yang efektif dan selaras dengan kebutuhan Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-34','Fungsi Penyusunan Kebijakan SDM','Melakukan penyusunan, pengembangan, pengoordinasian, dan evaluasi terhadap kerangka kerja, kebijakan, pedoman, serta ketentuan pengelolaan SDM dan hubungan industrial guna mendukung pengelolaan sumber daya manusia yang efektif dan selaras dengan kebutuhan Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-35','Fungsi Perencanaan dan Strategi SDM','Melakukan penyusunan strategi, kebijakan, dan pedoman pengelolaan SDM serta evaluasi implementasi pengelolaan SDM guna mendukung pengelolaan sumber daya manusia yang efektif dan selaras dengan kebutuhan Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-36','Fungsi Manajemen Talenta','Melaksanaan penyusunan dan pengelolaan kegiatan program manajemen talenta dalam rangka melakukan pemenuhan talenta terbaik Perusahaan meliputi penjaringan, asesmen, promosi, perencanaan suksesi.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-37','Fungsi Pembelajaran dan Pengembangan SDM','Melakukan penyusunan dan pengelolaan program pengembangan kompetensi karyawan meliputi training need analysis, pelaksanaan pelatihan dan pengembangan, sertifikasi keahlian.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-38','Fungsi Digital Learning','Melaksanaan pengelolaan kegiatan knowledge management dan learning management system di Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-39','Fungsi Manajemen Kinerja SDM','Melakukan pengelolaan, monitoring, dan evaluasi penilaian kinerja karyawan guna mendukung peningkatan kinerja dan pencapaian target Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-40','Fungsi Manajemen Budaya','Melakukan pengelolaan perencanaan, pelaksanaan, monitoring, dan evaluasi implementasi nilai dan budaya Perusahaan, employee engagement, serta kegiatan komunitas karyawan guna mendukung peningkatan keterlibatan dan budaya kerja Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-41','Fungsi Rekrutmen','Melakukan pengelolaan perencanaan, pelaksanaan, dan evaluasi rekrutmen serta perencanaan kebutuhan SDM guna mendukung pemenuhan sumber daya manusia sesuai kebutuhan Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-42','Fungsi Hubungan Industrial','Melakukan pengelolaan kepatuhan ketenagakerjaan, PKB, hubungan dan koordinasi dengan serikat pekerja, serta penanganan kasus, keluhan, dan perselisihan karyawan guna mendukung hubungan industrial yang kondusif dan sesuai ketentuan yang berlaku.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-43','Fungsi Penggajian & Fasilitas Karyawan','Melakukan pengelolaan perencanaan, perhitungan, dan pembayaran kompensasi dan benefit serta koordinasi dan pengurusan dengan pihak ketiga terkait manfaat karyawan guna mendukung pengelolaan kesejahteraan karyawan sesuai ketentuan yang berlaku.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-44','Fungsi Administrasi Kepegawaian','Melakukan pengelolaan database dan administrasi personalia meliputi pengangkatan, penugasan, penjatuhan sanksi, mutasi, pemutusan hubungan kerja, serta pelaksanaan offboarding karyawan guna mendukung tertib administrasi SDM Perusahaan.','KONTRIBUTOR','PROXY','F-SDM'),
 ('FB-45','Fungsi Area, Bangunan, & Pemeliharaan Listrik','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap area kerja, bangunan, utilitas, instalasi listrik, serta kegiatan building & services yang meliputi pengelolaan kantor dan gedung, kerumahtanggaan, dan kebersihan dalam lingkup Perusahaan, serta berkoordinasi dengan unit kerja terkait dalam pelaksanaan kajian investasi fasilitas umum Perusahaan guna mendukung kelancaran operasional perusahaan.','LAINNYA','PROXY','F-UMM'),
 ('FB-46','Fungsi Manajemen Aset','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap administrasi, inventarisasi, pemeliharaan, pengendalian, optimalisasi aset produktif maupun non produktif Perusahaan, fasilitas arsip, pengelolaan SAP terkait aset, serta kegiatan sewa menyewa aset tetap sesuai ketentuan yang berlaku guna mendukung efektivitas operasional perusahaan.','LAINNYA','PROXY','F-UMM'),
 ('FB-47','Fungsi Layanan Admin Kantor','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap layanan administrasi perkantoran, pengelolaan dokumen, kebutuhan perlengkapan kerja, fasilitas operasional kantor, serta standarisasi pengelolaan manajemen general services termasuk ketentuan, kebijakan, form, dan template guna mendukung kelancaran operasional perusahaan secara efektif dan tertib administrasi.','LAINNYA','PROXY','F-UMM'),
 ('FB-48','Fungsi Kendaraan Operasional & Rumah Tangga','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap kendaraan operasional, layanan kerumahtanggaan, kebersihan, keamanan, serta fasilitas penunjang lingkungan kerja, termasuk perencanaan penyedia jasa vendor kebersihan, kendaraan, dan catering, penyusunan dokumen teknis pengadaan, pengawasan dan evaluasi vendor, serta pemeliharaan kendaraan operasional kantor guna mendukung kenyamanan dan kelancaran operasional perusahaan.','LAINNYA','PROXY','F-UMM'),
 ('FB-49','Fungsi Optimisasi Aset','Melakukan pengelolaan optimisasi aset Perusahaan meliputi strategi optimasi aset, kajian utilisasi dan pendayagunaan aset, evaluasi mitra strategis, serta pengelolaan data aset.','PIMPINAN_TEMBUSAN','DIRECT','F-PRT'),
 ('FB-50','Fungsi Pengelolaan Portofolio Anak Perusahaan','Melakukan pengelolaan portofolio anak Perusahaan meliputi aksi korporasi, investasi dan divestasi bisnis, analisa dan evaluasi pertumbuhan bisnis, pengelolaan portofolio anak Perusahaan, pendampingan aksi korporasi, pembentukan entitas, serta pengelolaan shared services.','PIMPINAN_TEMBUSAN','DIRECT','F-PRT')
) AS v(code, name, definition, category, mode, induk_code)
LEFT JOIN lpms3.fungsi_generik i ON i.code = v.induk_code
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, definition = EXCLUDED.definition, induk_id = EXCLUDED.induk_id;

-- Fungsi produksi yang ditetapkan lewat Keputusan Direksi No. 058/SKEP.HC/DU/VI/2026 (tidak ada di SO, tidak dipetakan ke unit)
UPDATE lpms3.fungsi_generik SET sumber_dok = 'Nota 021/N/UQ/VIII/2026; Kepdir 058/SKEP.HC/DU/VI/2026', definition = COALESCE(definition,
 'Mengelola rekayasa produksi dan menyusun dokumen persiapan produk yang meliputi Bill of Material (BoM) produksi, struktur produk produksi, flowchart/routing proses produksi, bill of tools/equipment, waktu baku proses produksi, layout proses produksi, dan instruksi kerja pembuatan produk.') WHERE code = 'F-RPP';
UPDATE lpms3.fungsi_generik SET sumber_dok = 'Nota 021/N/UQ/VIII/2026; Kepdir 058/SKEP.HC/DU/VI/2026', definition = COALESCE(definition,
 'Mengelola pelaksanaan kegiatan produksi sesuai dengan perencanaan produksi, mengelola pemeliharaan fasilitas produksi dan memastikan kesiapan fasilitas produksi untuk kegiatan produksi.') WHERE code = 'F-OPP';
UPDATE lpms3.fungsi_generik SET sumber_dok = 'Nota 021/N/UQ/VIII/2026; Kepdir 058/SKEP.HC/DU/VI/2026' WHERE code = 'F-RDP';

-- Pemetaan Fungsi Generik (baru) -> Unit Aktual
INSERT INTO lpms3.fungsi_unit_map (structure_id, fungsi_id, unit_id, is_primary, basis_doc, effective_from, fungsi_lama_id, lingkup, catatan)
SELECT s.id, f.id, u.id, true, 'Nota 021/N/UQ/VIII/2026', DATE '2026-08-24', l.id, v.lingkup, v.catatan
FROM (VALUES
 ('DIR-1.1.1','F-PPR','F-PPR','Melakukan perumusan strategi dan arah pengembangan Perusahaan, termasuk rencana strategis penguatan neraca, modal kerja, dan kemampuan berinvestasi melalui pengelolaan PMN dan sumber pendanaan lainnya, penyusunan dan koordinasi masterplan, RJPP, dan RKAP, serta pengawasan, evaluasi, dan pengendalian kinerja Perusahaan untuk memastikan pencapaian target dan keselarasan implementasi strategi dengan kebijakan Perusahaan.',NULL),
 ('DIR-1.1.1','FB-01','F-PPR','Melakukan pengawasan, evaluasi, dan pengendalian kinerja Perusahaan guna memastikan pencapaian target, efektivitas implementasi strategi, dan peningkatan kinerja Perusahaan.',NULL),
 ('DIR-1.1.2','F-PPR','F-PPR','Memimpin dan mengoordinasikan penyusunan strategi pencapaian kinerja Perusahaan, penyusunan program strategis dalam rencana jangka pendek dan rencana jangka panjang, serta pelaksanaan pemantauan dan evaluasi terhadap progres inisiatif strategis dan program strategis Perusahaan guna memastikan efektivitas pelaksanaan program, pengendalian gap pencapaian kinerja, dan tercapainya target kinerja Perusahaan.',NULL),
 ('DIR-1.2','F-SEK','F-SEK','Memimpin koordinasi kegiatan Direksi Len dan pengelolaan hubungan dengan stakeholder internal maupun eksternal; Memimpin penyelenggaraan RUPS, Rapat Teknis Laporan Tahunan, serta pengelolaan dokumen Organ Perusahaan; dan memimpin penatausahaan serta penyimpanan dokumen/informasi /data korporasi termasuk hasil kegiatan dan risalah rapat Direksi, Dewan Komisaris, dan RUPS.',NULL),
 ('DIR-1.2.1','F-KOM','F-KOM','Melakukan pengelolaan kegiatan hubungan kelembagaan dan komunikasi korporasi kepada seluruh stakeholder dan masyarakat dan Len Industri Company guna menjaga dan meningkatkan citra positif Perusahaan.',NULL),
 ('DIR-1.2.2','FB-02','F-TJS','Melakukan pelaksanaan, monitoring, evaluasi, regulasi, dan administrasi kegiatan Tanggung Jawab Sosial dan Lingkungan (TJSL) guna meningkatkan citra positif Perusahaan serta memastikan pelaksanaan program TJSL berjalan efektif, terarah, dan sesuai ketentuan Perusahaan.',NULL),
 ('DIR-1.2.3','F-PAM','F-PAM','Melakukan pengamanan kegiatan Perusahaan serta perlindungan terhadap karyawan, aset, dan inventaris Perusahaan dengan mengedepankan tindakan preventif guna memastikan keamanan dan kelancaran operasional Perusahaan.',NULL),
 ('DIR-1.3.1','FB-03','F-AUD','Melakukan kegiatan audit internal secara periodik dan audit khusus secara independen dan objektif guna mendukung fungsi pengawasan internal, memberikan assurance dan consulting, serta memastikan pelaksanaan kegiatan Perusahaan berjalan sesuai kaidah, perencanaan, peraturan, dan ketentuan yang berlaku.',NULL),
 ('DIR-1.3.2','FB-04','F-AUD','Melakukan monitoring tindak lanjut hasil audit secara periodik dalam rangka pengawasan internal untuk memberikan assurance dan consulting yang independen dan objektif guna meningkatkan efektivitas pengendalian internal, manajemen risiko, tata kelola Perusahaan, serta mendukung optimalisasi operasional Perusahaan.',NULL),
 ('DIR-1.3.2','FB-05','F-AUD','Melakukan penyusunan pedoman strategis peningkatan infrastruktur dan standarisasi Internal Audit serta pelaksanaan aktivitas audit internal lainnya guna meningkatkan kualitas audit dan kapabilitas personil Internal Audit.',NULL),
 ('DIR-1.4.1','FB-06','F-LGL','Melaksanakan peninjauan, evaluasi, pengendalian, negosiasi, dan finalisasi dokumen hukum serta kontrak yang berkaitan dengan kegiatan dan/atau hubungan bisnis Perusahaan dengan mitra kerja, memberikan opini legal atas isu hukum yang timbul dalam kegiatan bisnis Perusahaan, serta melakukan pendampingan negosiasi kontrak guna memastikan kepatuhan terhadap ketentuan hukum dan perlindungan kepentingan Perusahaan.',NULL),
 ('DIR-1.4.1','FB-07','F-LGL','Melaksanakan pengelolaan aspek legal korporasi guna memastikan seluruh operasional, kebijakan, dan keputusan strategis Perusahaan berjalan sesuai dengan peraturan perundang-undangan, prinsip kepatuhan, dan tata kelola perusahaan yang baik, termasuk pengelolaan aspek hukum terkait perubahan struktur perusahaan, merger, akuisisi, restrukturisasi, perubahan Anggaran Dasar, perizinan, dan perbuatan hukum Perusahaan sesuai ketentuan yang berlaku.',NULL),
 ('DIR-1.4.1','FB-08','F-LGL','Melakukan pengelolaan perijinan dan perbuatan hukum Perusahaan guna mendukung kelancaran operasional Perusahaan serta memastikan pemenuhan ketentuan dan regulasi yang berlaku.',NULL),
 ('DIR-1.4.2','FB-09','F-LGL','Melakukan pengelolaan advokasi serta penyelesaian permasalahan dan sengketa hukum Perusahaan secara litigasi maupun non-litigasi, termasuk pemberian rekomendasi strategis atas risiko dan dampak hukum guna mendukung kegiatan bisnis dan operasional Perusahaan secara efektif dan sesuai ketentuan yang berlaku.',NULL),
 ('DIR-2.1.1','F-PMS','F-PMS','Melakukan koordinasi kegiatan pemasaran, penjualan, pencapaian pendapatan, pengembangan peluang MRO/After Sales, serta pengelolaan hubungan pelanggan pada segmen Pertahanan Matra Darat guna mendukung pencapaian sasaran dan target pendapatan Perusahaan.',NULL),
 ('DIR-2.1.2','F-PMS','F-PMS','Melakukan koordinasi kegiatan pemasaran, penjualan, pencapaian pendapatan, pengembangan dan pemanfaatan peluang MRO/After Sales, serta pengelolaan hubungan pelanggan pada segmen Pertahanan Matra Laut guna mendukung pencapaian sasaran dan target pendapatan Perusahaan.',NULL),
 ('DIR-2.1.3','F-PMS','F-PMS','Melakukan koordinasi kegiatan pemasaran, penjualan, pencapaian pendapatan, pengembangan dan pemanfaatan peluang MRO/After Sales, serta pengelolaan hubungan pelanggan pada segmen Pertahanan Matra Udara guna mendukung pencapaian sasaran dan target pendapatan Perusahaan.',NULL),
 ('DIR-2.1.4','F-PRP','F-PRP','Melakukan pengelolaan dan penyusunan perencanaan proyek guna mendukung keberhasilan kegiatan bisnis Perusahaan agar berjalan sesuai sasaran, strategi, dan kebijakan Perusahaan.',NULL),
 ('DIR-2.2','FB-10',NULL,'Memimpin dan mengoordinasikan penyusunan business plan dan perencanaan pengembangan fasilitas radar, termasuk penyusunan prioritas kerja, rencana aksi, serta perumusan arah, sasaran, dan strategi pengembangan.','** Tidak tercantum langsung dalam Struktur Organisasi; ditetapkan berdasarkan Surat Tugas Direktur Utama No. 028/STU/DU/I/2026 tentang Tim Perencanaan dan Pelaksanaan PMN Tahun 2026.'),
 ('DIR-2.2.1','F-PBS','F-PBS','Melakukan analisis dan penyusunan strategi pemasaran guna memastikan Perusahaan memiliki pipeline potensi bisnis jangka panjang, meningkatkan value Perusahaan, serta mendukung kegiatan operasional Perusahaan secara optimal.',NULL),
 ('DIR-2.2.2','FB-11','F-PBS','Melakukan pengelolaan, perumusan, dan pengembangan kemitraan strategis Perusahaan guna memperkuat posisi kompetitif, meningkatkan leverage teknologi dan pasar, serta mendorong pertumbuhan bisnis Perusahaan secara berkesinambungan.',NULL),
 ('DIR-3.1','FB-12',NULL,'Mengelola perencanaan, koordinasi, pelaksanaan, pengendalian, monitoring, dan evaluasi program strategis Perusahaan guna memastikan pencapaian target program sesuai ruang lingkup, jadwal, anggaran, mutu, serta kebijakan Perusahaan.','** Tidak tercantum langsung dalam Struktur Organisasi; ditetapkan berdasarkan Surat Tugas Direktur Utama No. 028/STU/DU/I/2026 tentang Tim Perencanaan dan Pelaksanaan PMN Tahun 2026.'),
 ('DIR-3.1','FB-13',NULL,'Melakukan pengelolaan dan pengendalian pelaksanaan proyek PMN sesuai perencanaan, kontrak, dan ketentuan yang berlaku guna mendukung pencapaian target proyek, peningkatan value, dan profitabilitas Perusahaan.','** Tidak tercantum langsung dalam Struktur Organisasi; ditetapkan berdasarkan Surat Tugas Direktur Utama No. 028/STU/DU/I/2026 tentang Tim Perencanaan dan Pelaksanaan PMN Tahun 2026.'),
 ('DIR-3.1.1','F-PJL','F-PJL','Melakukan pengelolaan kegiatan after sales, maintenance, repair, and overhaul (MRO), serta masa garansi proyek guna mendukung keberlanjutan layanan dan kepuasan pelanggan.',NULL),
 ('DIR-3.1.1','F-MPR','F-MPR','Melakukan perencanaan, koordinasi, monitoring, dan evaluasi pelaksanaan proyek mulai dari pembangunan hingga penyelesaian proyek guna memastikan pencapaian target, kesesuaian kontrak, dan milestone pembayaran.',NULL),
 ('DIR-3.2.1','F-PWP','F-PWP','Mengelola, mengoordinasikan, dan melaksanakan kegiatan pengawasan, evaluasi, serta pengendalian pelaksanaan proyek dalam lingkup Len Industri Company guna memastikan progres, biaya, waktu, dan profitabilitas proyek berjalan sesuai target, ketentuan, dan standar Perusahaan.',NULL),
 ('DIR-3.2.2','F-PPP','F-PPP','Melakukan pengelolaan order pipeline management serta pre contract phase pada order dengan kriteria tertentu melalui analisis dan perencanaan secara terperinci guna meningkatkan profitabilitas order, memperbaiki cashflow order, dan menurunkan risiko Perusahaan secara optimal.',NULL),
 ('DIR-3.3','F-RDP',NULL,'Mengelola perencanaan dan pengendalian kegiatan produksi yang meliputi pengelolaan permintaan produksi, penyusunan rencana anggaran produksi, penyusunan Material Requirement Plan (MRP), penyusunan jadwal produksi, perencanaan kebutuhan manpower kegiatan produksi, monitoring dan evaluasi serta pelaporan pelaksanaan kegiatan produksi, pengelolaan serah terima produk hasil produksi kepada pengguna.','* Tidak tercantum langsung dalam Struktur Organisasi; ditetapkan berdasarkan Keputusan Direksi No. 058/SKEP.HC/DU/VI/2026 tentang Tim Produksi.'),
 ('DIR-3.3.1','FB-14','F-RKS','Memberikan dukungan teknis dan engineering mulai dari tahap pengembangan bisnis, pemasaran, hingga penjualan, mendesain solusi kesisteman serta mendukung implementasi teknis proyek.',NULL),
 ('DIR-3.3.2','F-LTB','F-RKS','Melakukan inovasi dan pengembangan teknologi/produk, pengujian konsep teknologi dan solusi baru berdasarkan kebutuhan bisnis, serta memastikan kelayakan teknis usulan inovasi guna mendukung pengembangan teknologi dan peningkatan daya saing Perusahaan.',NULL),
 ('DIR-3.3.2','FB-15','F-RKS','Memberikan dukungan teknis dan engineering mulai dari tahap pengembangan bisnis, pemasaran, hingga penjualan yang terkait dengan produk hasil pengembangan yang akan digelar di proyek.',NULL),
 ('DIR-3.4.1','FB-16','F-PGD','Melakukan perencanaan terhadap pengadaan barang/jasa serta kepatuhan terhadap peraturan yang berlaku baik internal maupun eksternal. Melaksanakan perencanaan pengadaan barang/jasa dengan memperhatikan kepatuhan terhadap peraturan perundang-undangan, kebijakan Perusahaan, serta ketentuan internal yang berlaku.',NULL),
 ('DIR-3.4.2','FB-17','F-PGD','Melakukan seluruh kegiatan operasional dalam proses pengadaan barang/jasa.',NULL),
 ('DIR-3.4.2','F-GDG','F-GDG','Melakukan kegiatan pengelolaan gudang yang mencakup penerimaan, penyimpanan, pengendalian, dan distribusi barang di lingkungan Perusahaan.',NULL),
 ('DIR-4.1.1','FB-18','F-PBS','Melakukan pembangunan dan pengelolaan ekosistem inovasi teknologi melalui kolaborasi guna mendukung pengembangan bisnis dan peningkatan daya saing Perusahaan.',NULL),
 ('DIR-4.1.1','FB-19','F-PBS','Melakukan pengelolaan perlindungan hasil inovasi guna mendukung pemanfaatan teknologi dan peningkatan nilai produk Perusahaan.',NULL),
 ('DIR-4.1.2','F-LTB','F-LTB','Melakukan inovasi dan pengembangan teknologi/produk, pengujian konsep teknologi dan solusi baru berdasarkan kebutuhan bisnis, serta memastikan kelayakan teknis usulan inovasi beserta monitoring progressnya guna mendukung pengembangan teknologi dan peningkatan daya saing Perusahaan.',NULL),
 ('DIR-4.2.1','F-TI','F-TI','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, evaluasi, serta pengawasan terhadap pelaksanaan fungsi teknologi informasi Melakukan koordinasi, representasi, dan pengelolaan Fungsi Teknologi Informasi secara umum dan menyeluruh yang mencakup, namun tidak terbatas pada, tata kelola TI, operasional dan layanan TI, operasional keamanan siber, infrastruktur TI, serta pengembangan TI, atau memimpin pelaksanaan penerapan dan pengawasan Fungsi Teknologi Informasi di Perusahaan.',NULL),
 ('DIR-4.2.2','F-TI','F-TI','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, evaluasi, serta pengawasan terhadap pelaksanaan fungsi teknologi informasi Melakukan koordinasi, representasi, dan pengelolaan Fungsi Teknologi Informasi secara umum dan menyeluruh yang mencakup, namun tidak terbatas pada, tata kelola TI, operasional dan layanan TI, operasional keamanan siber, infrastruktur TI, serta pengembangan TI, atau memimpin pelaksanaan penerapan dan pengawasan Fungsi Teknologi Informasi di Perusahaan.',NULL),
 ('DIR-4.2.3','F-TI','F-TI','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, evaluasi, serta pengawasan terhadap pelaksanaan fungsi teknologi informasi Melakukan koordinasi, representasi, dan pengelolaan Fungsi Teknologi Informasi secara umum dan menyeluruh yang mencakup, namun tidak terbatas pada, tata kelola TI, operasional dan layanan TI, operasional keamanan siber, infrastruktur TI, serta pengembangan TI, atau memimpin pelaksanaan penerapan dan pengawasan Fungsi Teknologi Informasi di Perusahaan.',NULL),
 ('DIR-4.2.1','FB-20','F-TI','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap pengelolaan dan pemanfaatan data Perusahaan (baik data terstruktur maupun tidak terstruktur) sebagai pendukung pengembangan dan pemanfaatan sistem informasi guna meningkatkan value Perusahaan dan efektivitas operasional perusahaan.',NULL),
 ('DIR-4.2.1','FB-21','F-PSM','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap penerapan Sistem Manajemen Keamanan Informasi (SMKI) sesuai ISO 27001 guna memastikan pengelolaan keamanan informasi berjalan sesuai kaidah, peraturan, dan ketentuan yang berlaku di Perusahaan.',NULL),
 ('DIR-4.3.1','F-MRS','F-MRS','Melakukan pengelolaan dan koordinasi perumusan program serta kerangka kerja manajemen risiko guna memastikan penerapan manajemen risiko Perusahaan berjalan secara terpadu untuk mendukung pencapaian target bisnis Perusahaan',NULL),
 ('DIR-4.3.1','FB-22','F-MRS','Melakukan pelaksanaan Internal Control over Financial Reporting (ICoFR) guna memastikan penerapan manajemen risiko atas pengendalian pelaporan keuangan Perusahaan berjalan secara terpadu untuk mendukung pencapaian target bisnis Perusahaan',NULL),
 ('DIR-4.3.2','FB-23','F-TKL','Melakukan perumusan dan pelaksanaan tata kelola Perusahaan sesuai kaidah Good Corporate Governance (GCG) serta pengembangan kerangka kerja Environmental, Social, and Governance (ESG) guna menjaga profesionalisme dan akuntabilitas operasional Perusahaan.',NULL),
 ('DIR-4.3.2','FB-24','F-TKL','Melakukan pengelolaan dan pengawasan kepatuhan Perusahaan terhadap peraturan pemerintah dan ketentuan yang berlaku guna mendukung penerapan manajemen kepatuhan Perusahaan secara efektif.',NULL),
 ('DIR-4.3.2','F-PSM','F-PSM','Melakukan penerapan dan pengelolaan Sistem Manajemen Anti Penyuapan (SMAP) sesuai ISO 37001 guna memastikan sistem manajemen Perusahaan berjalan sesuai standar dan ketentuan yang berlaku.',NULL),
 ('DIR-4.4.1','F-MPB','F-MPB','Melakukan perumusan, koordinasi, dan pengelolaan proses bisnis Perusahaan secara end-to-end yang efektif, efisien, dan adaptif dengan mengintegrasikan prinsip internal control berbasis COSO guna mendukung transformasi Perusahaan.',NULL),
 ('DIR-4.4.1','FB-25','F-PSM','Melakukan penyusunan panduan, pengawasan, dan evaluasi implementasi sistem manajemen guna mendukung integrasi dan efektivitas penerapan sistem manajemen Perusahaan.',NULL),
 ('DIR-4.4.2','F-PMT','F-PMT','Melakukan perumusan, pengelolaan, dan koordinasi kebijakan quality assurance dalam lingkup guna mendukung peningkatan kualitas barang dan jasa Perusahaan.',NULL),
 ('DIR-4.4.2','FB-26','F-PMT','Melakukan pengendalian dan pemeriksaan kualitas barang dan jasa Perusahaan guna memastikan kesesuaian terhadap standar dan ketentuan mutu yang berlaku.',NULL),
 ('DIR-4.4.2','FB-27','F-PMT','Melakukan pengelolaan dan pelaksanaan kegiatan kalibrasi peralatan guna memastikan keakuratan hasil pengukuran dan mendukung kualitas proses operasional Perusahaan.',NULL),
 ('DIR-4.4.2','F-PSM','F-PSM','Melakukan implementasi dan pengelolaan sistem manajemen mutu guna memastikan penerapan quality assurance berjalan efektif sesuai kebijakan dan standar yang berlaku.',NULL),
 ('DIR-4.4.3','FB-28','F-K3L','Menyelenggarakan perencanaan, koordinasi, implementasi, pemantauan, dan evaluasi program Keselamatan dan Kesehatan Kerja sesuai prinsip SMK3 dan ISO 45001, guna memastikan seluruh aktivitas kerja di lingkungan Perusahaan berjalan aman, sehat, terkendali, serta memenuhi ketentuan peraturan perundang-undangan/persyaratan lainnya dan standar internal yang berlaku.',NULL),
 ('DIR-4.4.3','FB-29','F-K3L','Menyelenggarakan perencanaan, koordinasi, implementasi, pemantauan, dan evaluasi program pengelolaan lingkungan hidup sesuai prinsip ISO 14001, guna memastikan aspek dan dampak lingkungan dari kegiatan Perusahaan dikelola secara terkendali, memenuhi ketentuan peraturan perundang- undangan/persyaratan lainnya yang dibutuhkan dan mendukung peningkatan kinerja lingkungan secara berkelanjutan.',NULL),
 ('DIR-4.4.3','F-PSM','F-PSM','Melaksanakan identifikasi, pemantauan, dan evaluasi kesesuaian kegiatan operasional terhadap prosedur K3L yang berlaku, termasuk identifikasi ketidaksesuaian, evaluasi efektivitas prosedur berdasarkan kondisi aktual operasional, serta pemberian rekomendasi perbaikan guna mendukung efektivitas penerapan SMK3, ISO 45001, dan ISO 14001 di lingkungan Perusahaan.',NULL),
 ('DIR-5.1.1','FB-30','F-KEU','Melakukan pengelolaan kegiatan pendanaan, pengadaan asuransi aset tetap dan peninjauan prospek bisnis Perusahaan guna mendukung keberlangsungan bisnis dan mitigasi risiko Perusahaan.',NULL),
 ('DIR-5.1.2','F-KEU','F-KEU','Melakukan analisis dan peninjauan prospek bisnis Perusahaan pada aspek keuangan guna mendukung pengambilan keputusan dan pengelolaan keuangan Perusahaan secara efektif.',NULL),
 ('DIR-5.2.1','F-AKT','F-AKT','Melakukan pengelolaan kegiatan akuntansi dan pelaporan Perusahaan meliputi perencanaan dan pengelolaan akuntansi, penyusunan laporan proyeksi keuangan, pengelolaan transaksi dan database akuntansi, pengembangan sistem akuntansi, pengelolaan data biaya dan pendapatan, analisa varian biaya proyek, penerbitan nomor aset tetap, serta pemberian rekomendasi aspek accounting & reporting Perusahaan.',NULL),
 ('DIR-5.2.2','F-ANG','F-ANG','Mengelola, mengendalikan, memonitor, dan mengevaluasi anggaran Perusahaan yang mencakup program, proyek, beban usaha, dan investasi secara terintegrasi guna memastikan efektivitas penggunaan anggaran, optimalisasi profitabilitas, akuntabilitas keuangan, serta pengendalian risiko sesuai target dan kebijakan Perusahaan.',NULL),
 ('DIR-5.2.2','FB-31','F-ANG','Mengawasi, memonitor, dan mengevaluasi pengelolaan dana Penyertaan Modal Negara (PMN) guna memastikan pemanfaatan dana berjalan efektif, tepat sasaran, sesuai ketentuan, serta mendukung akuntabilitas, transparansi, dan pencapaian target strategis Perusahaan.',NULL),
 ('DIR-5.2.3','FB-32','F-KEU','Melakukan pengelolaan kegiatan perpajakan Perusahaan meliputi standarisasi pembebanan transaksi perpajakan, pelaksanaan dan pengendalian perpajakan, pemeriksaan dan pencatatan transaksi pajak, penyusunan daftar pembayaran pajak, administrasi pembayaran pajak, serta pemberian rekomendasi aspek perpajakan pada prospek bisnis Perusahaan.',NULL),
 ('DIR-5.3.1','FB-33','F-SDM','Melakukan penyusunan kerangka kerja, kajian dan pengembangan organisasi meliputi perancangan struktur organisasi, penyusunan tupoksi, uraian dan spesifikasi jabatan, serta evaluasi efektivitas organisasi dan evaluasi jabatan guna mendukung pengelolaan organisasi yang efektif dan selaras dengan kebutuhan Perusahaan.',NULL),
 ('DIR-5.3.1','FB-34','F-SDM','Melakukan penyusunan, pengembangan, pengoordinasian, dan evaluasi terhadap kerangka kerja, kebijakan, pedoman, serta ketentuan pengelolaan SDM dan hubungan industrial guna mendukung pengelolaan sumber daya manusia yang efektif dan selaras dengan kebutuhan Perusahaan.',NULL),
 ('DIR-5.3.1','FB-35','F-SDM','Melakukan penyusunan strategi, kebijakan, dan pedoman pengelolaan SDM serta evaluasi implementasi pengelolaan SDM guna mendukung pengelolaan sumber daya manusia yang efektif dan selaras dengan kebutuhan Perusahaan.',NULL),
 ('DIR-5.3.2','FB-36','F-SDM','Melaksanaan penyusunan dan pengelolaan kegiatan program manajemen talenta dalam rangka melakukan pemenuhan talenta terbaik Perusahaan meliputi penjaringan, asesmen, promosi, perencanaan suksesi.',NULL),
 ('DIR-5.3.2','FB-37','F-SDM','Melakukan penyusunan dan pengelolaan program pengembangan kompetensi karyawan meliputi training need analysis, pelaksanaan pelatihan dan pengembangan, sertifikasi keahlian.',NULL),
 ('DIR-5.3.2','FB-38','F-SDM','Melaksanaan pengelolaan kegiatan knowledge management dan learning management system di Perusahaan.',NULL),
 ('DIR-5.3.2','FB-39','F-SDM','Melakukan pengelolaan, monitoring, dan evaluasi penilaian kinerja karyawan guna mendukung peningkatan kinerja dan pencapaian target Perusahaan.',NULL),
 ('DIR-5.3.2','FB-40','F-SDM','Melakukan pengelolaan perencanaan, pelaksanaan, monitoring, dan evaluasi implementasi nilai dan budaya Perusahaan, employee engagement, serta kegiatan komunitas karyawan guna mendukung peningkatan keterlibatan dan budaya kerja Perusahaan.',NULL),
 ('DIR-5.3.3','FB-41','F-SDM','Melakukan pengelolaan perencanaan, pelaksanaan, dan evaluasi rekrutmen serta perencanaan kebutuhan SDM guna mendukung pemenuhan sumber daya manusia sesuai kebutuhan Perusahaan.',NULL),
 ('DIR-5.3.3','FB-42','F-SDM','Melakukan pengelolaan kepatuhan ketenagakerjaan, PKB, hubungan dan koordinasi dengan serikat pekerja, serta penanganan kasus, keluhan, dan perselisihan karyawan guna mendukung hubungan industrial yang kondusif dan sesuai ketentuan yang berlaku.',NULL),
 ('DIR-5.3.3','FB-43','F-SDM','Melakukan pengelolaan perencanaan, perhitungan, dan pembayaran kompensasi dan benefit serta koordinasi dan pengurusan dengan pihak ketiga terkait manfaat karyawan guna mendukung pengelolaan kesejahteraan karyawan sesuai ketentuan yang berlaku.',NULL),
 ('DIR-5.3.3','FB-44','F-SDM','Melakukan pengelolaan database dan administrasi personalia meliputi pengangkatan, penugasan, penjatuhan sanksi, mutasi, pemutusan hubungan kerja, serta pelaksanaan offboarding karyawan guna mendukung tertib administrasi SDM Perusahaan.',NULL),
 ('DIR-5.3.4','FB-45','F-UMM','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap area kerja, bangunan, utilitas, instalasi listrik, serta kegiatan building & services yang meliputi pengelolaan kantor dan gedung, kerumahtanggaan, dan kebersihan dalam lingkup Perusahaan, serta berkoordinasi dengan unit kerja terkait dalam pelaksanaan kajian investasi fasilitas umum Perusahaan guna mendukung kelancaran operasional perusahaan.',NULL),
 ('DIR-5.3.4','FB-46','F-UMM','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap administrasi, inventarisasi, pemeliharaan, pengendalian, optimalisasi aset produktif maupun non produktif Perusahaan, fasilitas arsip, pengelolaan SAP terkait aset, serta kegiatan sewa menyewa aset tetap sesuai ketentuan yang berlaku guna mendukung efektivitas operasional perusahaan.',NULL),
 ('DIR-5.3.4','FB-47','F-UMM','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap layanan administrasi perkantoran, pengelolaan dokumen, kebutuhan perlengkapan kerja, fasilitas operasional kantor, serta standarisasi pengelolaan manajemen general services termasuk ketentuan, kebijakan, form, dan template guna mendukung kelancaran operasional perusahaan secara efektif dan tertib administrasi.',NULL),
 ('DIR-5.3.4','FB-48','F-UMM','Melakukan pengelolaan, perencanaan, pengoordinasian, monitoring, dan evaluasi terhadap kendaraan operasional, layanan kerumahtanggaan, kebersihan, keamanan, serta fasilitas penunjang lingkungan kerja, termasuk perencanaan penyedia jasa vendor kebersihan, kendaraan, dan catering, penyusunan dokumen teknis pengadaan, pengawasan dan evaluasi vendor, serta pemeliharaan kendaraan operasional kantor guna mendukung kenyamanan dan kelancaran operasional perusahaan.',NULL),
 ('DIR-5.4.1','F-PRT','F-PRT','Melakukan pengelolaan dukungan aksi korporasi dan shared services antar entitas meliputi koordinasi, monitoring, evaluasi, dan pelaporan pelaksanaan layanan.',NULL),
 ('DIR-5.4.1','FB-49','F-PRT','Melakukan pengelolaan optimisasi aset Perusahaan meliputi strategi optimasi aset, kajian utilisasi dan pendayagunaan aset, evaluasi mitra strategis, serta pengelolaan data aset.',NULL),
 ('DIR-5.4.2','FB-50','F-PRT','Melakukan pengelolaan portofolio anak Perusahaan meliputi aksi korporasi, investasi dan divestasi bisnis, analisa dan evaluasi pertumbuhan bisnis, pengelolaan portofolio anak Perusahaan, pendampingan aksi korporasi, pembentukan entitas, serta pengelolaan shared services.',NULL)
) AS v(unit_code, fungsi_code, lama_code, lingkup, catatan)
JOIN lpms3.org_structure s ON s.code = 'SKEP-001-2026'
JOIN lpms3.org_unit u ON u.structure_id = s.id AND u.code = v.unit_code
JOIN lpms3.fungsi_generik f ON f.code = v.fungsi_code
LEFT JOIN lpms3.fungsi_generik l ON l.code = v.lama_code
ON CONFLICT (structure_id, fungsi_id, unit_id) DO UPDATE SET fungsi_lama_id = EXCLUDED.fungsi_lama_id, lingkup = EXCLUDED.lingkup, catatan = EXCLUDED.catatan, basis_doc = EXCLUDED.basis_doc;

-- Samakan nama dengan penulisan Nota 021 (nama lama CLP-001 dipertahankan sebagai alias)
UPDATE lpms3.fungsi_generik SET name = 'Fungsi Pelaksanaan Proyek',
  bop_alias = ARRAY(SELECT DISTINCT unnest(bop_alias || ARRAY['Fungsi Manajemen Proyek']) EXCEPT SELECT 'Fungsi Pelaksanaan Proyek')
 WHERE code = 'F-MPR' AND name <> 'Fungsi Pelaksanaan Proyek';
UPDATE lpms3.fungsi_generik SET name = 'Fungsi Pengawasan Pra-Proyek' WHERE code = 'F-PPP';
UPDATE lpms3.fungsi_generik SET name = 'Fungsi Teknologi Informasi/TI' WHERE code = 'F-TI';
