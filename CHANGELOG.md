# CHANGELOG
## 17.9.7-lpms3.1.43 — pengadaan tertaut WBS, master rekanan, pohon Member garis komando (24 Nov 2026)
- **Item Pengadaan ↔ aktivitas WBS** (`lpms3.pengadaan_wbs`, `Lpms3::PengadaanWbs`): ditautkan dari halaman Pengadaan; tahap memberi usulan % Complete (PO/Kontrak 25, Pengiriman 50, GR/SES 75, Selesai 100; aktivitas = tahap terendah item tertautnya). Usulan diterapkan otomatis saat status item berubah bila bukti sudah ada di WP aktivitas (tidak pernah menurunkan, tidak menyentuh aktivitas beku). Chip "Pengadaan n item · usulan x %" di editor WBS.
- **Master rekanan** (`/lpms3/rekanan`, menu global; `Lpms3::Rekanan`): PFR-001 dikelola Fungsi Pengadaan/admin; **daftar hitam PFR-030** oleh Pejabat Eselon 1/2 atau admin — gerbang menolak rekanan daftar hitam mulai PO/Kontrak; **evaluasi penyedia PFR-019** (skor mutu/waktu/harga/K3L 1–5) mulai GR/SES oleh Pengadaan/Pimpro/Penjaminan Mutu. Temuan baru: rekanan daftar hitam, belum terdaftar, evaluasi belum, belum tertaut WBS.
- **Kartu Member Beranda = pohon garis komando** (menggantikan bagan 1.42, format `docs/template-bop001/tampilan-widget-project-member.md`): Pejabat Direktur Operasional → Admin → Pejabat Eselon 1 setiap Fungsi (semua bermuara ke Direktur Operasional) → Admin/Spesialis/Staff Eselon 1 → Pejabat Eselon 2 (bisa lebih dari satu) → Admin/Spesialis (Pimpro, Project Analis)/Staff Eselon 2; kursi pejabat kosong tetap tampil; cabang dapat dibuka/ditutup. Nama fungsi mendahulukan Fungsi Generik siklus proyek.
- **Tim default**: bila bagian Pimpro punya lebih dari satu Pejabat Eselon 2, yang sudah menjadi member dipakai sebagai atasan (pemetaan per proyek dihormati).
- Migrasi `20261125000004` (`rekanan`, `rekanan_evaluasi`, `pengadaan_wbs`).
- Smoke `lpms3/smoke/pengadaan_wbs.rb` 21/21; regresi pengadaan lama 33/33 (temuan 1.43 diabaikan di sana), kontrak 30/30, wbs_baseline 33/33, wbs_editor 34/34, tim proyek 22/22, pemicu 33/33, menu 27/27.

## 17.9.7-lpms3.1.42 — monitoring Kontrak awal, struktur BOP-001 di semua proyek, tim Fungsi Pengawasan (24 Nov 2026)
- **Kontrak** (`/projects/:id/lpms3/kontrak`, menu Inisiasi → Ringkasan Fase → Kontrak; `Lpms3::Kontrak`): ringkasan (nomor, pemberi kerja, nilai awal → efektif, kelas SOP-004 dari `ref_kelas_kontrak`, masa kontrak, sisa hari, progres WBS vs waktu, Go/No-Go SFR-028/SFR-024), **jaminan** (Uang Muka/Pelaksanaan/Pemeliharaan/…; masa berlaku, dikembalikan/dicairkan), **termin pembayaran** (persen nilai; syarat uang muka, progres ≥ x %, aktivitas WBS selesai, G3 Serah terima, manual; Rencana → Ditagih → Dibayar oleh Keuangan/Pimpro), **adendum SFR-025** (draft oleh pencatat, disahkan Pejabat Eselon 2/1 yang bukan pencatat; atribut proyek Nilai/Tanggal Selesai/Nomor Adendum diperbarui, nilai & tanggal awal tetap terekam).
- **Temuan & peringatan**: data kontrak belum lengkap, Go/No-Go belum, kontrak lewat/≤ 60 hari, progres tertinggal > 10 pp, WBS melewati kontrak, jaminan kedaluwarsa/≤ 30 hari, Jaminan Pelaksanaan belum ada, Σ termin ≠ 100 %, termin layak tagih / terlambat / ditagih > 30 hari belum dibayar, adendum menunggu pengesahan, kelas berubah karena adendum (SOP-009). Masuk Tugas & Notifikasi + Tasklist header sesuai peran (Pimpro, Keuangan, Pejabat Eselon 2/1).
- **Monitoring Kontrak** lintas proyek (`/lpms3/kontrak`, menu global) dan **kartu Portofolio**: nilai efektif & kelas, termin terbayar, jaminan aktif/bermasalah, adendum, chip temuan.
- **Struktur BOP-001 di semua proyek** (seed `85_struktur_proyek.rb`, idempoten): proyek aktif tanpa struktur mendapat modul/tipe template, 37 langkah, 4 gerbang, 9 aspek PMP berstatus awal, WBS Level 0, catatan kontrak, dan tim default. Ruang informasi tanpa Work packages dilewati.
- **Tim default + Fungsi Pengawasan Proyek** (`Lpms3::TimProyek`): Pejabat Eselon 1 F-PWP (Approver CCM), Admin Pejabat Eselon 1 F-PWP dan Pejabat Eselon 2 unit primer F-PWP (Fungsi Pengawasan Proyek) otomatis menjadi member setiap proyek; `Hierarki.unit_primer_of_fungsi`.
- **Beranda (semua workspace): kartu Member = bagan garis komando** (`Lpms3::Widgets::MemberHierarki`, `Lpms3::MemberHierarki`; menggantikan `Grids::Widgets::Members` lewat `Grids::WidgetGridComponent#build_widget`): satu kotak Direksi di puncak, **semua Divisi Eselon 1 dari semua direktorat sejajar dalam satu baris**, lalu Bagian Eselon 2/Eselon 3 sampai Pimpro. Setiap kotak menampilkan tingkat, unit, Fungsi (pemetaan Nota 021), serta orang (Kepala/Admin/Staf, peran proyek, grup Fungsi); Pimpro disorot. Cabang dapat dibuka/ditutup (`<details>`), tombol Buka/Tutup semua; member tanpa jabatan aktif di daftar terpisah.
- Migrasi `20261125000003` (`lpms3.kontrak`, `kontrak_jaminan`, `kontrak_termin`, `kontrak_adendum`). Catatan: timestamp migrasi tidak boleh > 1 hari di masa depan (Rails menolak saat boot).
- Smoke `lpms3/smoke/kontrak.rb` 30/30; regresi wbs_baseline 33/33, wbs_editor 34/34, tim proyek 22/22 (jumlah tim default dihitung dari jabatan), pemicu 33/33, menu 27/27.

## 17.9.7-lpms3.1.41 — baseline WBS otomatis via CR, sidebar Langkah BOP-001 (24 Nov 2026)
Tahap ketiga `docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md` §6.
- **Baseline otomatis** (`Lpms3::WbsBaseline`, panel "Baseline" di WBS & Bobot): perubahan atribut rencana (struktur/nomor, Tasks, Weight, Date Plan, harga) memperbarui satu versi **DRAFT**; progres (% Complete, tanggal aktual) tidak. Sebelum ada baseline aktif, draft = **Baseline 0 (Kick-Off)** dan ditetapkan Pimpro/Project Analis (semua aktivitas bertanggal, Σ bobot 100 %); Tanggal Kick-Off (Baseline 0) terisi.
- Sesudahnya, draft versi berikutnya otomatis membawa work package **Change Request "BFR-001 Baseline n"** (status Draft, assignee Pimpro, ringkasan perubahan di deskripsi). CR **Disetujui** → draft ACTIVE dan yang lama SUPERSEDED; **Ditolak** → REJECTED, lalu "Kembalikan ke baseline aktif" memulihkan rencana (baris baru tanpa progres dihapus, baris terhapus dibuat lagi). Bila WBS kembali sama dengan baseline aktif, draft dan CR Draft dibuang. Selama CR sudah diajukan, perubahan rencana ditahan.
- **Pekerjaan selesai dibekukan**: aktivitas 100 % direkam di `lpms3.wbs_done_snapshot`; Tasks, tanggal, % Complete, dan bobotnya tidak dapat diubah, dan baseline berikutnya memakai nilai rekam. Kurva normal saat menambah saudara mempertahankan bobot aktivitas beku.
- **Kurva-S**: aktivasi baseline mengisi `lpms3.scurve_plan` (bulanan, linear).
- **Ringkasan ikut berubah**: Portfolio (Rencana % dari baseline aktif, Aktual % = % Progress Level 0, Kenaikan dari riwayat WP × weight, chip baseline/draft), kartu "WBS & Baseline" di Ikhtisar fase Perencanaan/Eksekusi/Pengawasan, Tugas & Notifikasi + Tasklist header ("Draft Baseline WBS — ajukan CR" untuk Pimpro). Gantt/Kalender tetap mengikuti WP aktivitas.
- **Sidebar fase**: dua submenu dropdown — **Ringkasan Fase** (Ringkasan, Gerbang, Aspek, Register, WBS & Bobot, Pengadaan) dan **Langkah BOP-001** (klik membuka daftar langkah project berurutan predecessor → successor, ✓ selesai / ● berikutnya / ○ belum; tanpa relasi agar jadwal tidak digeser).
- **Perbaikan**: WP aktivitas WBS kini `ignore_non_working_days` — sebelumnya tanggal akhir pekan digeser OpenProject sehingga setiap edit WBS menulis ulang WP dan mengirim notifikasi berulang ke PIC (hingga ~100 per aktivitas).
- **Workflow register** (seed `00_data`/`50_workflows`): fungsi pemilik register mendapat transisi penuh — Risiko/Isu (Fungsi Manajemen Risiko), Bahaya K3L (Fungsi K3 & LH), Inspeksi Mutu/NCR (Fungsi Penjaminan Mutu), Item Pengadaan, Stakeholder, Action Item/Lesson Learned (fungsi kontributor).
- Migrasi `20261125000001`/`…02`: status baseline + indeks unik draft/aktif per proyek, struktur `baseline_item`, `wbs_done_snapshot`.
- Smoke `lpms3/smoke/wbs_baseline.rb` 33/33; regresi wbs_editor 34/34, tim proyek 22/22, registrasi pemicu 33/33, bahasa & menu 27/27.

## 17.9.7-lpms3.1.40 — editor WBS bobot cascading (23 Nov 2026)
Tahap kedua `docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md` (baseline otomatis + snapshot Done + sinkron ringkasan di 1.41).
- **Menu fase Perencanaan → WBS & Bobot** (`/projects/:id/lpms3/wbs`, `Lpms3::WbsController`, `Lpms3::Wbs`): tabel kolom WBS Template LPMS (WBS, Level, Tasks, Notes, PIC & Resource, Date Plan/Actual Start/Finish, Weigh Factor, Weight, % Complete, % Progress, Priority, Evidence Files). Sel disimpan langsung (Enter/keluar sel; Esc membatalkan); server mengembalikan tabel yang dihitung ulang. Tambah sub-tugas / tugas setelahnya, naik/turun, hapus. Edit: Pimpro, Project Analis, Project admin, admin; lainnya baca-saja.
- **Bobot cascading**: Weight = Weight induk × Weigh Factor; Level 0 = 100 %. Weigh Factor awal sub-tugas mengikuti **kurva normal** (mis. 5 anak = 9,24/24,14/33,24/24,14/9,24 %) dan diatur ulang saat anak ditambah/dihapus. "Bobot anak" mengubah semua saudara sekaligus; simpan ditolak bila jumlahnya ≠ 100 %. Nomor WBS, level, tanggal induk (min/maks anak), % Progress (Σ weight × % Complete), dan folder bukti dihitung server.
- **% Complete** hanya 0/25/50/75/100 dan hanya di aktivitas; di atas 0 wajib ada bukti (lampiran di work package). Actual Start/Finish terisi otomatis. Aktivitas berprogres tidak dapat dipecah atau dihapus.
- **PIC**: wajib anggota proyek, atau **Fungsi induk (unit Eselon 1)**. Kepala/Admin unit Eselon 1 itu mendapat tugas "Penugasan PIC WBS" (Tugas & Notifikasi + Tasklist header) dan menugaskan anggota timnya (pemegang jabatan unit itu dan unit di bawahnya); orang itu otomatis menjadi member Tim Proyek.
- **Gantt & Kalender**: setiap baris (kecuali Level 0) tertaut ke work package Task (subjek "kode tugas", induk WP mengikuti WBS, tanggal rencana, assignee = PIC, % Complete). Diubah sebagai Sistem dengan catatan journal "Editor WBS LPMS3 oleh …".
- Seed `80_tim_proyek.rb`: peran kerja LPMS3 yang melihat WP diberi izin `work_package_assigned` (sebelumnya tidak ada peran LPMS3 yang bisa menjadi assignee). Migrasi `20261124000001`: kolom PIC di `lpms3.wbs_node`, cek level `Level 0–7 (Activity)`.
- Smoke `lpms3/smoke/wbs_editor.rb` 34/34; regresi tim proyek 22/22, registrasi pemicu 33/33.

## 17.9.7-lpms3.1.39 — jabatan pengguna dan member proyek berjenjang dari Direksi (23 Nov 2026)
Tahap pertama `docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md` (editor WBS bobot cascading 1.40, baseline otomatis 1.41 menyusul).
- **Administrasi → Jabatan Pengguna** (`/admin/lpms3/jabatan`, admin saja): Kepala, Admin, dan Staf setiap Direktorat/Divisi/Bagian struktur aktif (`lpms3.position`, `lpms3.user_position`). Penugasan DEFINITIF/PLT/PLH/DELEGASI bermasa berlaku; Kepala definitif baru mengakhiri yang lama; "Akhiri" mengisi tanggal akhir (riwayat tidak dihapus). **Impor CSV** `email,kode_unit,jabatan,jenis,mulai,sampai` (maks. 512 KB; baris bermasalah dilewati dan dilaporkan).
- **Tim default setiap proyek** (`Lpms3::TimProyek`, resolver `Lpms3::Hierarki`): Direktur Operasi (peran Direksi) + Admin Direksi, Pejabat Eselon 1 Fungsi Pelaksanaan Proyek (F-MPR → Divisi Project Deployment Center) + Admin Pejabat Eselon 1.
- **Pimpro ditetapkan → Pejabat Eselon 2 atasannya otomatis member** (Kepala unit ES2 tempat Pimpro berjabatan; Plt/Plh dihitung). Dipicu peran Pimpro (MemberRole), atribut proyek Pimpro (CustomValue), dan pembuatan proyek dari pemicu LenO. Hanya menambah, tidak pernah menghapus; jejak di `lpms3_auto_members`. Galat di callback dicatat, tidak menggagalkan aksi pengguna. Tombol "Terapkan" untuk satu/semua proyek aktif beserta peringatan jabatan yang belum diisi.
- Peran proyek baru "Admin Direksi" dan "Admin Pejabat Eselon 1" (izin Tim Proyek; tidak memutus persetujuan). Seed `80_tim_proyek.rb` membuat peran + 193 posisi unit. Migrasi `20261123000003`.
- Smoke `lpms3/smoke/tim_proyek.rb` 22/22 (transaksi di-rollback); regresi registrasi pemicu 33/33.
- **Belum berlaku penuh sampai jabatan diisi**: `user_position` masih kosong di :5100.

## 17.9.7-lpms3.1.38 — tampilan LenO: header Reminder/Tasklist/Notifikasi, profil, sidebar (23 Nov 2026)
Mengikuti template `docs/image/template-uix-leno/` (10 tangkapan layar LenO).
- **Header**: bilah merah bergradasi, blok logo putih selebar sidebar, ikon putih. Tiga panel tarik-turun dengan badge jumlah: **Reminder** (pengingat work package buatan pengguna + WP miliknya jatuh tempo ≤3 hari/terlambat), **Tasklist** (Tugas & Notifikasi LPMS3: persetujuan, Kick-Off, masukan, tembusan, pemicu LenO; "Lihat dalam grid"), **Notifikasi** (notifikasi in-app OpenProject belum dibaca; "Tandai sudah dibaca", "Lihat semua"; lonceng bawaan disembunyikan). Data dirender saat halaman dimuat dan disegarkan tiap 60 dtk / saat panel dibuka (`GET /lpms3/header/ringkasan`, `POST /lpms3/header/notifikasi/baca`; login wajib; hanya data milik pengguna). Esc menutup panel.
- **Profil**: nama tebal + jabatan kecil (grup Fungsi pengguna, lalu peran global) di kiri avatar.
- **Sidebar** putih selebar penuh, teks 12px, item aktif merah muda + teks merah + penanda kanan merah, submenu berbulatan. Halaman global LPMS3 (Tugas, Pemicu, Mata uang, Portofolio, Panduan, Pengadaan lintas project) memakai layout `global` sehingga sidebar selalu tampil.
- **Halaman**: latar abu muda, kartu putih bersudut 4px, judul halaman 22px tipis, tombol aksi merah. Komponen untuk halaman berikutnya: `.lpms3-searchbar`, `.lpms3-fchips`/`.lpms3-fchip`, `.lpms3-seg`, `.lpms3-panel` (header merah), `.lpms3-tag`.
- Modul `OpenProject::Lpms3::HeaderSummary`, `Lpms3::HeaderController`; token warna `--leno-*` di `uix.css`. Regresi: smoke pemicu 22/22, registrasi 33/33.

## 17.9.7-lpms3.1.37 — registrasi dan persetujuan proyek dari pemicu LenO (23 Nov 2026)
Tahap ketiga `docs/plan/RANCANGAN-PEMICU-LENO.md` (1.36, pembaca LPMS-2, menunggu akses DB). Keputusan: template dipilih Admin.
- **Peran global baru** (seed `80_pemicu_roles.rb`): "Admin Fungsi Pelaksanaan Proyek" (`lpms3_register_project_trigger`) dan "Pejabat Eselon 1 Fungsi Pelaksanaan Proyek" (`lpms3_approve_project_trigger`). Wewenang dibaca dari keanggotaan peran global (langsung atau lewat grup); **admin OpenProject tidak otomatis berwenang**.
- **Halaman pemicu** `/lpms3/pemicu/:id`: Admin memilih template (Prediktif/Hibrid/Purnajual), nama proyek, Kode Proyek LPMS3 (format atribut Kode Proyek, unik terhadap proyek dan pemicu lain), Pimpro, VP Fungsi Pelaksanaan Proyek. Pejabat Eselon 1 menyetujui atau mengembalikan (catatan wajib); **pengusul tidak dapat memutus usulannya sendiri** walau memegang dua peran. Admin dapat membatalkan pemicu (alasan wajib). Semua langkah masuk riwayat append-only.
- **Proyek dibuat di job** `Lpms3::BuatProyekDariPemicuJob` (±7 dtk): salin template (anggota, WP, wiki), Pimpro dan VP menjadi anggota (peran Pimpro / Fungsi Pelaksanaan Proyek (Struktural)), semua atribut proyek diaktifkan, diisi Kode Proyek, LPMS-2 Proyek ID (atribut baru), Pimpro, Fungsi Pelaksanaan Proyek, Pendekatan Delivery. Idempoten (tidak pernah ganda); gagal = dibatalkan seluruhnya, galat tercatat, Admin dapat "Coba buat proyek lagi". Kick-Off **tidak** dibuat di sini (tetap setelah Dokumen Inisiasi disetujui Final).
- **Tugas & Notifikasi**: bagian "Proyek baru dari LenO" (dari, kapan, harus apa) dan jumlahnya ikut di badge. Administrasi → Pemicu LenO menautkan ke halaman pemicu.
- Migrasi `20261123000002`. Smoke `lpms3/smoke/pemicu_registrasi.rb` (33 skenario, dalam transaksi yang di-rollback).

## 17.9.7-lpms3.1.35 — penerima pemicu proyek dari LenO (23 Nov 2026)
Tahap pertama `docs/plan/RANCANGAN-PEMICU-LENO.md`: menerima dan mencatat; pembaca LPMS-2 (1.36) dan registrasi/persetujuan (1.37) menyusul.
- **API** `POST /lpms3/api/pemicu-proyek` dan `GET /lpms3/api/pemicu-proyek/:kode_proyek` (`Lpms3::PemicuLenoController`, `ActionController::API`: tanpa sesi/login/CSRF). Kunci bersama di header `X-Lpms3-Key`, dibandingkan constant-time dengan `LPMS3_LENO_KEYS` (min. 32 karakter, boleh dua nilai untuk rotasi; kosong = 401). Batas 60/menit per alamat (429), body maks. 16 KB (413), validasi isian (400), `lpms2_proyek_id` berbeda (409). Log hanya metadata, tanpa kunci.
- **Idempoten**: satu baris per kode proyek (`lpms3_project_triggers`, unik; kode dinormalkan huruf besar); `id_kiriman` sama tidak dihitung ulang; kiriman bersamaan tetap satu baris; klaim pembaca yang macet > 10 menit dilepas oleh kiriman ulang.
- **Riwayat append-only** `lpms3_project_trigger_events` (tidak bisa diubah/dihapus). Migrasi `20261123000001`.
- **Administrasi → Pemicu LenO** (`/admin/lpms3/pemicu-leno`, admin saja): ringkasan per status, saring status, riwayat per pemicu, peringatan bila kunci belum diatur.
- Env baru `LPMS3_LENO_KEYS` (compose web/worker/cron/seeder, `.env.example`). Smoke `lpms3/smoke/pemicu_leno.sh` (22 skenario, data uji dihapus).
- Keputusan 23 Nov 2026: Kick-Off tetap dibuat setelah Dokumen Inisiasi disetujui Final; pemicu LenO tidak membuat Kick-Off.

## 17.9.7-lpms3.1.34 — status keputusan hanya lewat rantai persetujuan (23 Nov 2026)
Menutup temuan audit P0 #2 (status keputusan bisa dicapai langsung dari form OpenProject).
- **Workflow tipe keputusan disinkron penuh** (`DECISION_FLOWS` di `seed/00_data.rb`, dipakai `50_workflows.rb`): untuk Dokumen Rencana, Top Up Anggaran, dan Deliverable hanya transisi di daftar itu yang boleh ada; sisanya dihapus. Dokumen Rencana: form hanya New/Revisi → Draft, dan Pimpro dapat menandai Diganti; Reviu, Revisi, Disahkan hanya lewat `Lpms3::ApprovalTask` (42 transisi lama dihapus). Seed idempoten.
- **Aspek PMP**: "Ajukan" membuat tugas di rantai persetujuan (`ApprovalTask.ajukan!`), bukan mengubah status langsung. "Minta revisi" hanya untuk yang berwenang memutus tugas yang sedang menunggu (`actions_for` → `revisi`), sehingga tugas tidak tertinggal "menunggu" setelah dokumen dikembalikan.

## 17.9.7-lpms3.1.33 — satu pintu login IDS, rilis 1.31–1.33 masuk git (dicatat 23 Nov 2026)
Rilis 1.31–1.33 sudah terpasang di `:5100` sejak 16–17 Nov 2026 (image dibangun dari *working tree*). Entri ini mencatatnya ke git agar rilis yang berjalan bisa dibangun ulang (temuan audit P0 #3).
- **Satu pintu login IDS (20 Nov 2026):** akun lokal tertanam dan `/ids/local` dihapus dari `Lpms3.IdsLogin`; proxy mengalihkan `/ids/local` ke `/ids/login`. Tidak ada pilihan Pengguna/Admin. Admin dan peran ditentukan di aplikasi, tidak dari klaim IDS (`AdminRoles`/`AdminEmails` dibuang). Akun yang dikunci di LPMS3 tetap ditolak. `back_url` OpenProject dibawa lewat login (hanya jalur lokal, cegah open redirect). Halaman galat UIx dengan "Coba lagi"/"Keluar".
- **9 Aspek PMP** di halaman fase (`aspects.rb`, `Lpms3::AspectsController`): tabel isian, bilah "Ajukan Semua Aspek", masukan pembaca per baris, unduh PDF.
- **Persetujuan berjenjang** (`Lpms3::ApprovalTask`, menu "Tugas & Notifikasi" `/lpms3/tugas`): Staff → Pimpro → Eselon 2 → Eselon 1, bypass Eselon 2, tembusan Direksi, masukan (`Lpms3::Feedback`) tercatat di aktivitas WP. Migrasi `20261117000001..03`.
- **Kick-Off** (`Lpms3::Kickoff`, migrasi `20261117000004`).
- **LenO Mobile** (`/lpms3/m`): laporan harian, progres, kendala, persetujuan/tolak, notifikasi, review WO; PDF laporan harian. Migrasi `20261116000001`.
- **Pengadaan** (`/projects/:id/lpms3/pengadaan`), **Portofolio**, **Galeri**, **PDF** (Prawn, gaya UIx).
- **MOD-08** logo/favicon Len 2023 (`deploy/brand`), **MOD-09** hapus Edisi Enterprise dan Link Eksternal.
- Seed: `80_persetujuan_roles.rb`, `proyek_referensi_len.rb`, `leno_mobile_demo.rb`, `wiki_fungsi_generik.rb`. Smoke: `alur_persetujuan.rb`, `procurement.rb`, `procurement_flow.rb`.
- Tidak di-commit (di `.gitignore`): seed akun uji dengan password bersama (`akun_uji*.rb`, `tambah_akun_fungsi.rb`) dan `ops/_accts.txt`.
- Audit 20 Nov 2026 disimpan lokal (tidak di-commit karena repo publik).

## 17.9.7-lpms3.1.30 — menu Mata uang & kurs (konversi dan budget korporasi)
- **Menu baru** "Mata uang & kurs" (`/lpms3/mata-uang`, sidebar global dan Administrasi): konverter untuk semua pengguna login; kurs terhadap mata uang dasar **IDR**; daftar mata uang (IDR dasar, USD, EUR, SGD, JPY aktif; CNY, AUD, GBP nonaktif; dapat ditambah/diubah/dinonaktifkan).
- **Hak akses**: izin global baru `manage_currency_rates`; seed `lpms3/seed/90_currency.rb` membuat **peran global "Keuangan"**. Admin dan akun Keuangan dapat mengubah mata uang dan kurs; pengguna lain hanya melihat dan mengonversi (403 bila mengubah). Sumber eksternal hanya dapat diatur admin.
- **Kurs append-only**: setiap perubahan = baris riwayat baru (siapa, kapan, sumber, catatan); tidak dapat diubah atau dihapus. Kurs berlaku sejak tanggal efektif; pada tanggal sama yang terakhir diisi menang. Konversi lewat mata uang dasar dengan BigDecimal; pasangan tanpa kurs menghasilkan "belum ada kurs", bukan angka palsu.
- **Sumber kurs yang direkomendasikan**: ECB via Frankfurter (`api.frankfurter.dev`), **nonaktif secara bawaan** (tidak ada panggilan eksternal sampai admin mengaktifkan; host tetap, bukan input pengguna). Tombol "Ambil kurs sekarang" dan opsional otomatis hari kerja 09.10 (`Lpms3::FxFetchJob`).
- **Budget**: mata uang budget OpenProject diselaraskan ke mata uang dasar (`Rp`, format awalan, tombol "Pakai Rp sebagai mata uang budget"); tabel budget project yang boleh dilihat pengguna dikonversi ke mata uang dan tanggal pilihan.
- Tabel `lpms3_currencies` dan `lpms3_exchange_rates` (migrasi plugin). Nama mata uang adalah isian pengguna (tidak diterjemahkan saat ganti bahasa). Uji: `lpms3/smoke/currency.rb` (`run_currency.sh`, 37 PASS, masuk `ops/verify.sh`).

## 17.9.7-lpms3.1.28 — menu fase induk-anak tersorot, panduan untuk tamu
- Menu project per fase: **Ringkasan / Gerbang / Langkah / Register** kini rute sendiri (`/projects/:id/lpms3/fase/:fase/:bagian`); anak aktif tersorot dan **induk fasenya terbuka dan ikut tersorot** (latar abu, bobot 500, ikon merah, penanda 3px; garis hierarki di sisi anak). Halaman fase menampilkan kartu sesuai bagian (Ringkasan = semua). Bagian tak dikenal 404. Sidebar yang tidak dimuat ulang (Turbo) ikut menyinkronkan induk-anak.
- `/lpms3/panduan` dapat dibuka tanpa login (seperti halaman statis sebelumnya).
- Uji: `lpms3/smoke/lang_switch.rb` menambah pemeriksaan menu induk-anak, 404 bagian, panduan tamu.

## 17.9.7-lpms3.1.26 — bahasa menyeluruh, panduan mengikuti bahasa, UIx total (font, bentuk, notifikasi, loader)
- **Terjemahan Indonesia**: 3.705 kunci tambahan (Angular `js.*` dan Rails: label model/atribut, pengaturan project, tipe, jurnal, ekspor, dll.) di `config/lpms3_id_overrides.yml` (total 3.918). Kunci fitur yang dimatikan (Jira, storage, Enterprise, SCIM) sengaja tidak diterjemahkan.
- **Panduan internal** kini halaman aplikasi `/lpms3/panduan` yang mengikuti bahasa akun (ID/EN); `/panduan-internal` dialihkan ke sana, tombol bantuan "?" menunjuk ke sana. Folder statis `deploy/panduan` dihapus.
- **Isian pengguna tidak diterjemahkan**: nama project, subjek/deskripsi paket-penugasan, komentar tetap persis. Diuji oleh `lpms3/smoke/lang_switch.rb` (`run_lang.sh`, masuk `ops/verify.sh`).
- **UIx total** (`uix.css`): variabel Primer/OpenProject dipetakan ke token UIx (ukuran font 12/13/16/18/20, bobot 400/500/600, radius 6/8/12, tinggi kontrol 30/34/38, bayangan xs/md/lg/xl, warna semantik, tombol, kolom isian, dropdown, modal). Notifikasi (toast, flash, banner, galat formulir) putih dengan penanda status 3px dan ikon berwarna status. **Loader** bawaan OpenProject (dua kotak hijau berputar, loading.gif) diganti cincin UIx dengan busur merah dan titik berdenyut; menghormati `prefers-reduced-motion`.
- Rujukan: `ops/monitor.sh` dan `ops/verify.sh` memeriksa `/lpms3/panduan`.
- **Homework tetap**: SMTP ditunda (notifikasi internal saja).

## 17.9.7-lpms3.1.25 — menu per fase BOP-001 dan sidebar yang tidak dimuat ulang
- **Menu project dikelompokkan per 5 fase BOP-001** (Inisiasi, Perencanaan, Eksekusi, Pengawasan & Kendali, Penutupan) sebagai container di bawah Ikhtisar, masing-masing berisi Ringkasan fase, Gerbang, Langkah, Register. Dibangun di plugin (`OpenProject::Lpms3::Phases`, `Lpms3::PhasesController`, rute `/projects/:id/lpms3/fase/:fase`).
- **Halaman fase** (UIx): stepper 5 fase dengan progres selesai/total, gerbang G1–G4 (G3 menutup Eksekusi dan Pengawasan), tabel langkah `[T1-..]`..`[T6-..]`, register per tipe dengan tautan ke tabel paket-penugasan, tombol "Buka di tabel paket-penugasan". Akses: harus punya izin lihat paket-penugasan; non-anggota 404.
- **Sidebar tidak dimuat ulang** saat berpindah halaman (Turbo Drive): `#main-menu` ditandai `data-turbo-permanent` selama konteks sama; item terpilih disinkronkan; konteks berbeda (pindah project/Administrasi) memakai sidebar baru. Diverifikasi di Chrome: penanda dokumen tetap, elemen sidebar sama, menu bawah bertahan.
- Baru: `lpms3/smoke/fase_walkthrough.rb` + `run_fase.sh` (alur 5 fase pada proyek uji: langkah, dokumen, gerbang, progres, arsip; 30 PASS, 0 FAIL, 1 N/A) dan masuk `ops/verify.sh`.

## 17.9.7-lpms3.1.22 — UIx menyeluruh, Tampilan (logo/ikon/warna), pemilih bahasa, Pengaturan di sidebar
- Administrasi → **Tampilan** (in-house, `/admin/lpms3/branding`): ganti logo, ikon/thumbnail (favicon + apple-touch), 4 warna; validasi isi berkas (PNG/JPEG/WEBP/ICO/SVG tanpa skrip, maks. 300 KB), warna `#RRGGBB`, reset. Tidak memakai CustomStyle/EnterpriseToken.
- **Pemilih bahasa ID/EN** di kanan atas header (`/lpms3/language`, hanya bahasa aktif, alihan aman), dan **Pengaturan** di kiri bawah sidebar.
- UIx: bayangan `xs`/`md` disamakan dengan `leno.css` (:8585); gaya halaman LPMS3 (kartu, judul 16/600, tombol 34px/radius 8, input warna); panduan memakai token. 213 teks Indonesia (override sesudah kamus inti), audit bahasa 238 → 46 kunci.
- Perbaikan: `*` sisa markdown di deskripsi katalog fitur; lokasi menu katalog diterjemahkan.
- Baru: `ops/uix_lint.sh` (8 pemeriksaan, masuk `ops/verify.sh`), `docs/UIX-COMPLIANCE.md`.

## 17.9.7-lpms3.1.18 — ikon berlian Enterprise disembunyikan
- `uix.css`: menyembunyikan `svg.octicon-op-enterprise-addons`, `svg.upsell-colored`, `svg[op-enterprise-addons-icon]` (Angular), `.icon-enterprise`, `.icon-enterprise-addons`. Diperiksa di 9 halaman server-side: semua ikon berlian (78 + 71 elemen) tercakup selector. Label menu fitur Enterprise tidak diubah.

## 17.9.7-lpms3.1.17 — audit kepatuhan BOP-001 dan penutupan risiko
- `OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGOUT` dikembalikan ke `true`; `OPENPROJECT_SHOW__PRODUCT__VERSION=false` (menghilangkan tautan versi/commit ke github.com).
- Plugin: `pagination_guard.rb` — halaman di luar rentang (mis. `/projects?page=99`) kini dialihkan ke halaman 1, bukan HTTP 500 bawaan OpenProject.
- Baru: `ops/monitor.sh` (dipasang di cron tiap 5 menit), `ops/audit_bop001.sh` (48 PASS / 9 GAP / 1 FAIL), `docs/COMPLIANCE-BOP001.md` (dasbor, janji J1–J7, telusur §15, matriks UAT U01–U31, registri bukti, kesenjangan). Checklist D12, DEPLOY_SOP, dan plan diperbarui.
- Temuan keamanan: `.env` di root repo berisi kredensial root StarRocks dalam teks biasa (izin 664 → 600); rotasi password diperlukan.
- Ditunda atas keputusan pemilik: SMTP (homework).

## 17.9.7-lpms3.1.16 — audit lintas modul MOD-00..08
- Perbaikan: Caddy memblokir jalur trial yang salah (`/admin/enterprise/save_trial_key`); yang benar `/admin/enterprise_tokens/{save,delete}_trial_key`.
- Perbaikan: `/panduan-internal` (tombol bantuan) 404 → halaman statis `deploy/panduan/index.html` (placeholder) lewat Caddy + mount di `docker-compose.stock.yml`.
- Pesan log guard IDS diperjelas (login lewat IdsLogin bridge).
- Baru: `ops/verify.sh` + `ops/audit_mod08.rb` (36 pemeriksaan); `DEPLOY_SOP.md` ditulis ulang; plan `openproject_custom_plan.md` disinkronkan (Bagian 0A status & risiko, Bagian 4, MOD-03, MOD-08).
- Temuan terbuka: SMTP (812 job gagal ECONNREFUSED localhost:25, sudah ada sebelum MOD-01), keputusan `DROP_OLD_SESSIONS_ON_LOGOUT`, merge ke `main`, `/admin/roles?page=N` di luar rentang → 500 (bawaan OpenProject).

## 17.9.7-lpms3.1.15 — MOD-08 (audit) + perbaikan 1.14/1.15
- **Perbaikan bug 1.8–1.13:** ikon menu "Modul Fitur Internal" `settings` tidak valid → seluruh halaman Administration HTTP 500. Diganti `gear` (1.14). Ditemukan oleh audit MOD-08.
- 1.15: teks sambutan Homescreen (tautan pemasaran vendor) diganti teks internal; tautan `<noscript>` ke enable-javascript.com dihapus (`patch_mod07.rb`).
- Laporan: `docs/plan/AUDIT_VERIFICATION_REPORT.md` (34/35 lulus; sisa: tautan versi GitHub di halaman Info).

## 17.9.7-lpms3.1.13 — MOD-07
- Seed `80_settings.rb`: `organization_name` = "PT Len Industri (Persero)" (nama organisasi ini asumsi; ubah di seed bila keliru), `emails_footer` id/en tanpa tautan. `app_title` sudah "LPMS3".
- `deploy/patch_mod07.rb` (build): default bawaan `app_title`/`organization_name` diganti, dan `text_powered_by` (en, id) menjadi teks netral tanpa `%{link}`. Override via plugin tidak berlaku (locale inti menang), jadi dipatch langsung.
- Temuan: layout email OpenProject 17.9.7 tidak memuat tautan vendor; `text_powered_by` tidak dipakai kode aplikasi. Email uji berisi hanya tautan ke host internal.

## 17.9.7-lpms3.1.11 — MOD-06
- Gravatar: sebelumnya AKTIF (`enable_gravatars=true`); kini `engine.rb` default `false` dan `AvatarManager.gravatar_enabled?` selalu `false`. Avatar lokal tetap aktif.
- CSP dibersihkan: tanpa `*.chargebee.com`, `js.chargebee.com`, `start.openproject.com`, `releases.openproject.com` (object-src kini `'none'`), dan video onboarding. Sekaligus memperbaiki entri rusak `://` di `default-src`/`form-action`/`media-src` yang muncul sejak MOD-05.
- Patch lewat `deploy/patch_mod06.rb` saat build (abort bila pola source berubah); `.dockerignore` mengizinkan file itu.

## 17.9.7-lpms3.1.10 — MOD-05 (lanjutan)
- Banner promosi Enterprise (Angular `<op-enterprise-banner>` dan komponen Rails `.op-enterprise-banner-container`) disembunyikan lewat `uix.css` plugin. Template Angular tidak diedit karena source `frontend/` tidak ada di image (hanya bundle terkompilasi); mengunduhnya dari repo vendor ditolak pemilik.

## 17.9.7-lpms3.1.9 — MOD-04
- Plugin `config/initializers/homescreen_hardening.rb`: blok Homescreen `community`, `upsell`, `new_features` dibuang dari daftar (sisa: welcome, favorite_projects, meetings, my_account, news, administration).
- `deploy/Dockerfile`: `SecurityBadgeHelper#display_security_badge_graphic?` dipatch menjadi `false` (menutup juga halaman Administration → Information); build gagal bila patch tidak terpasang.
- Berbeda dari plan: komponen tidak punya `render?` dan blok sudah difilter lewat `if` di `config/initializers/homescreen.rb`, jadi file komponen tidak diedit.

## 17.9.7-lpms3.1.8 — MOD-03 (in-house)
- `InhouseFeatureCatalog`: 35 fitur (30 utama + 5 kompatibilitas) lengkap dengan lokasi menu, deskripsi, tujuan, output; dibangkitkan dari Bagian 3 plan. Tujuan/output klaster F ditulis tim LPMS3 (plan hanya memberi deskripsi).
- Halaman Administration → Modul Fitur Internal (`/admin/lpms3/internal_features`, admin saja), controller `Lpms3::Admin::InternalFeaturesSettingsController`, menu di plugin, terjemahan en/id. Saklar hanya bisa dinyalakan untuk fitur berstatus implemented (saat ini 0); sisanya "Belum tersedia".
- Tidak mengubah `EnterpriseToken`. Langkah 8 plan (hapus tampilan fitur Enterprise terkunci) belum dikerjakan.

## 17.9.7-lpms3.1.7 — MOD-02 (revisi in-house)
- Plugin: `OpenProject::Lpms3::Features` (katalog 35 kunci, klaster A-F, `IMPLEMENTED` awalnya kosong) dan setting `internal_enabled_features` (default `[]`, tabel `settings`).
- `EnterpriseToken` tidak diubah; gerbang lisensi OpenProject tetap tertutup (diverifikasi: `allows_to?(:board_view)` tetap `false` sebelum/sesudah).
- Plan MOD-02/MOD-03 direvisi: fitur dikembangkan sendiri di plugin, menu tetap sebagai kerangka. Penghapusan tampilan fitur Enterprise terkunci dijadwalkan di MOD-03 langkah 8 (belum dikerjakan).

## 17.9.7-lpms3.1.6 — MOD-01
- Env isolasi di `deploy/docker-compose.stock.yml` (web/worker/cron/seeder): security badge off, community links off, help link `/panduan-internal`, login wajib, drop sesi lama saat login on / saat logout off, CSP img-src `'self' data: blob:` (ditulis sebagai array YAML; format string di plan ditolak parser), email delivery `smtp`, self-registration 0.
- Tidak dipasang (setting tidak ada di 17.9.7): `ONBOARDING_VIDEO_URL`, `OMNIAUTH_ALLOW_SINGLE_SIGN_ON`.
- Plugin: `config/initializers/inhouse_ids_sso_guard.rb` — hanya memeriksa kelengkapan config IDS & mencatat log; tidak menyentuh lisensi/token.
- Perlu tindak lanjut: host SMTP internal belum ada (D12), halaman `/panduan-internal` belum ada (404).

## 17.9.7-lpms3.1.5 — MOD-05
- `static_links.yml` di image: tautan openproject.org/.com, docs S3, chargebee, youtube, github opf → `/` (patch `sed` di `deploy/Dockerfile`, build gagal bila masih ada sisa).
- Caddy `:5100` menutup `/admin/enterprise_trial*` dan `save/delete_trial_key` (404). Rute Rails tidak dihapus karena `enterprise_tokens_controller` dan komponen trial memakai path helper-nya (akan 500).
- Token Enterprise dibiarkan kosong. Langkah 3 plan (template banner Angular) tidak dikerjakan: image hanya berisi bundle terkompilasi, source `frontend/` tidak ada.

## 2026-11-15 — Rilis 17.9.7-lpms3.1.4 (pilihan radio Pengguna/Admin, pembersihan data pra-go-live)
- IdsLogin: landing memakai radio button "Pengguna" / "Admin" + satu tombol "Masuk dengan IDS" (menggantikan dua tombol).
- Data: dihapus proyek `demo-project`, `your-scrum-project`, `demo-nvg-monocular-100` dan user `pimpro.demo` (backup `data/backup/20261115-0814`); akun `admin` bawaan dikunci; template `lpms3-tpl-*` dibuat non-publik.
- Smoke: PASS=22 FAIL=0 N/A=5.

## 2026-11-15 — Rilis 17.9.7-lpms3.1.3 (halaman IdsLogin bergaya UIx, tabel, pengaturan)
- IdsLogin: landing, "Akses ditolak", dan "Berhasil masuk" memakai token dan font Poppins dari `uix.css` (tema terang), teks tombol dirapikan. Versi rilis (`Lpms3__Release`) menjadi pemecah cache URL aset; titik diganti `-` karena segmen `:digest` di route Rails tidak menerima titik (sebelumnya 404).
- `uix.css`: ukuran isi 13px (`--body-font-size`, `--main-menu-font-size`); kepala tabel 12px/600, warna sekunder, tanpa huruf kapital semua.
- Seed `80_settings.rb` (idempoten): nama aplikasi "LPMS3", bahasa default Indonesia, pilihan bahasa id/en; akun manusia berbahasa "en" dipindah ke "id" (1 akun).
- Verifikasi: smoke PASS=22 FAIL=0 N/A=5; landing 200 dan aset CSS/font 200.
- Image: `lpms3/openproject:17.9.7-lpms3.1.3` (`f6cff65ec9ad`), `lpms3-idslogin:17.9.7-lpms3.1.3`; data sama dengan 1.0.

## 2026-11-14 — Rilis 17.9.7-lpms3.1.2 (tema UIx benar-benar berlaku)
- Verifikasi browser (Chrome headless, 1440×900): berkas plugin di image identik dengan repo dan `uix.css` tersaji byte demi byte sama, tetapi dua pemetaan dari commit awal (`70eb3c5`) **tidak berlaku** di OP 17:
  - Font: Poppins terunduh tetapi `body` tetap font sistem, karena OP/Primer memasang font lewat `--body-font-family`/`--fontStack-sansSerif`. Kedua variabel kini diarahkan ke `--uix-font`.
  - Menu sidebar terpilih memakai `--control-transparent-bgColor-selected` (Primer), bukan `--main-menu-bg-selected-background`. Dipetakan ke `--uix-surface-muted`, dibatasi pada `.main-menu`.
- Hasil: Proyek, Ringkasan, Paket-Penugasan, dan My page memakai font "UIx Poppins", primer `#ae2524`, menu terpilih `#f3f4f6`. Health check penuh 6/6 PASSED.
- Image: `lpms3/openproject:17.9.7-lpms3.1.2` (`0a2bc899c97d`); idslogin dan data sama dengan 1.1.

## 2026-11-14 — Rilis 17.9.7-lpms3.1.1 (login wajib IDS)
- Semua pintu login, registrasi, aktivasi, dan reset password bawaan OpenProject di `:5100` dialihkan ke IDS (`deploy/Caddyfile.landing`); `/logout` → `/ids/logout`.
- IdsLogin: `/ids/logout` menghapus cookie `_open_project_session` sebelum keluar dari IDS, supaya logout tidak otomatis masuk lagi.
- Image: `lpms3-idslogin:17.9.7-lpms3.1.1` (`042d373b9ea6`); image lain sama dengan 1.0 (tag 1.1 menunjuk image ID yang sama). Tag `17.9.7-lpms3.1.0` tetap menunjuk image teruji lama (`11f8fe7eb8dc`).
- Verifikasi: 9 path login bawaan + POST `/login` → 302 `/ids/login`; `/ids/login` → IDS authorize; bridge login internal 302 dan sesi membuka `/projects` lewat `:5100` (200); health check penuh 6/6 PASSED.

## 2026-11-14 — Rilis 17.9.7-lpms3.1.0 (pin image, D12 butir 5)
- Image dipin ke versi yang diuji (isi image tidak berubah; rebuild menghasilkan image ID sama):
  - `lpms3/openproject:17.9.7-lpms3.1.0` (`7d413dcaf6b9`), base `openproject/openproject:17-slim@sha256:4e978557b400…` (OP 17.9.7)
  - `lpms3-idslogin:17.9.7-lpms3.1.0` (`11f8fe7eb8dc`), `lpms3/data:17.9.7-lpms3.1.0` (`0c1f1219a89e`)
  - `postgres:17.11@sha256:ff87138949ad…`, `memcached:1.6.45@sha256:a395a1bcf5e0…`, `openproject/hocuspocus:17.9.7`
  - `openproject/proxy` dibangun lokal dari `upstream/proxy` (`cca8d78b5734`).
- `OP_TAG` dikoreksi 17.9.6 → 17.9.7 (versi yang benar-benar berjalan). `ops/build_image.sh` kini membaca `LPMS3_IMAGE_TAG` dari `deploy/.env`.
- Verifikasi pascadeploy: health check penuh PASSED, data identik, outbox 0, smoke PASS=22 FAIL=0 N/A=5, alur bridge IDS→OpenProject→/projects OK.

## 2026-11-09 — Master Plan v2.0
- Master plan BOP-001 Inisiasi→Closing, WBS Template LPMS, UX, kamus data 18 formulir (43 tabel, 509 kolom), tabel SOP.
- Database utama StarRocks default_catalog.lpms3 (192.168.125.29:9030); PostgreSQL tetap untuk runtime OpenProject.
- DDL PostgreSQL (diuji PG16) & StarRocks; skrip deploy/ops.
- Buku Teknis v1.3 (deploy, sidebar, LKP ETL & approval, fungsi & kapabilitas).
