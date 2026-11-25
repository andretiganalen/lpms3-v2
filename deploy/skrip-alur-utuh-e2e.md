# Skrip uji E2E Playwright: satu proyek dari pembukaan sampai penutupan (E2E-00)

> **Untuk siapa:** penulis spesifikasi Playwright dan siapa pun yang menjalankan alur ini langkah demi langkah di peramban.
> **Isi:** satu alur utuh pada **satu** proyek, dari pemicu LenO sampai proyek Ditutup dan kode purnajualnya diputus,
> dibagi menjadi **sembilan bagian yang kurang lebih sama besar** (11–14 langkah per bagian, 110 langkah seluruhnya).
> **Sumber:** [`../uat-desember-2026.md`](../uat-desember-2026.md) § 7.1 (E2E-00, tujuh sesi) beserta skenario yang dirujuknya,
> dan [`../playbook-e2e.md`](../playbook-e2e.md) Fase B, C, D, dan F. Label tombol, judul baris Daftar Kerja, dan kalimat
> yang dicetak miring diambil dari kedua dokumen itu, lalu dicocokkan dengan kode (halaman `.razor`, service, dan fixture
> `e2e/`) pada `main` @ `e30ec5bd` (23 November 2026). Bila dokumen dan kode berbeda, skrip ini mengikuti kode (Lampiran C).
> **Keadaan:** skrip ini disusun dari dokumen dan halaman aplikasi; ia belum pernah dijalankan sebagai satu alur otomatis.
> Empat belas spesifikasi di [`e2e/specs/`](../../e2e/specs/) menguji tiap modul di proyek contoh yang berbeda-beda;
> alur utuh pada satu proyek belum ada spesifikasinya (Lampiran A dan B).

## 1. Cara memakai skrip ini dengan Playwright

- **Satu kelompok serial.** Kesembilan bagian dijalankan berurutan pada proyek yang sama, dalam satu `test.describe`
  ber-`mode: 'serial'`. Setiap baris tabel langkah menjadi satu `test(...)`; nomornya (`B1-01` … `B9-12`) dipakai sebagai
  awalan judul. Satu langkah gagal berarti sisanya dilewati.
- **Satu pelaku per langkah.** Kolom *Pelaku* menyebut akun yang masuk. Di tumpukan uji (`docs/e2e/README.md`) masuknya
  lewat `/e2e/masuk`, tombol `Masuk sebagai <email>` (fixture `masuk(persona, tujuan)`); di staging atau UAT lewat IdS.
- **Langkah di luar peramban** bertanda *API*: pemicu LenO dikirim ke API dengan kunci pemicu (fixture `pemicu()`), dan
  pemeriksaan rute langsung memakai klien API beridentitas persona (fixture `api(persona)`).
- **Menunggu.** Halamannya Blazor Server: tunggu keadaan yang diharapkan dengan asersi yang menunggu (`toBeVisible`,
  `toHaveText`, `expect(...).toPass()`), bukan jeda tetap. Jeda tetap hanya sebelum memastikan sesuatu **tidak** ada.
- **Pemilih.** Pakai peran dan nama yang terlihat pengguna (`getByRole('button', { name: … })`, judul kartu, judul baris
  Daftar Kerja). Pola yang sudah teruji untuk tiap modul ada di fixture yang disebut Lampiran A.
- **Data.** Kelompok ini menulis banyak data: awali dan akhiri dengan pemulihan basis data (`basisDataSegar()`), dan
  jalankan dengan satu pekerja. Berkas unggahan dibangkitkan di memori (`e2e/fixtures/berkas.ts`).
- **Tanda yang dipakai di tabel.** *Miring* = kalimat atau judul yang tampil di layar. **Tebal** = tombol, tab, atau kartu.
  `{KODE}` = kode proyek uji; `{ID}` = `requestId` jawaban pemicu; `{NO}` = Nomor Work Order (angka; di pemilih cocokkan
  dengan `\d+`); `H` = hari uji menurut WIB.

## 2. Persiapan (sesi S0)

### 2.1 Pemeran

Akun menurut matriks kursi [`../uat-desember-2026.md`](../uat-desember-2026.md) § 2; di tumpukan uji emailnya
`<id-huruf-kecil>@e2e.lpms.test`.

| Persona | Kursi | Dipakai di bagian |
|---|---|---|
| `FP-ADM1` | Admin Bagian Pelaksanaan Proyek (Eselon 1, Admin) | 1 |
| `FP-E1` | Pejabat Eselon 1 Fungsi Pelaksanaan Proyek | 1, 7, 8 |
| `FP-E2` | Pejabat Eselon 2 Fungsi Pelaksanaan Proyek (VP FP) | 1, 3, 7, 8, 9 |
| `FP-PIMPRO` | Spesialis Eselon 2 FP, kursi Pimpro | 1, 2, 3, 4, 6, 7, 8, 9 |
| `FP-PIC1`, `FP-PIC2` | Staf FP, Tim Proyek dan PIC aktivitas | 2, 4, 5, 6, 7, 8, 9 |
| `FPP-ADM1` | Admin Bagian Pengawasan Proyek | 1 |
| `FPP-PA` | Spesialis Eselon 2 FPP, kursi Project Analyst | 2, 3, 7 |
| `FPP-STAF` | Staf FPP, anggota proyek | 2, 5, 7, 9 |
| `FPP-E2` | Pejabat Eselon 2 FPP (VP FPP) | 1, 5, 7, 9 |
| `FPP-E1` | Pejabat Eselon 1 FPP | 3, 9 |
| `LUAR` | Staf Fungsi lain, bukan anggota proyek | 2, 3 |
| `SYSADMIN` | Developer, administrasi aplikasi | 1, 6 |

Syaratnya: semua akun berbeda orang, dan `FPP-E2` serta `FPP-E1` pemegang tunggal kursinya (keduanya dijadikan anggota
proyek secara otomatis di bagian 1 dan 3).

### 2.2 Data uji

| Data | Isi |
|---|---|
| `{KODE}` | Satu kode proyek LPMS-1/2 sungguhan yang belum pernah dipicu di lingkungan itu: baris aktif `lpms_proyek`, 1–20 karakter dari `A-Z 0-9 . _ -`. Kode karangan dijawab 404. |
| WBS | Berkas `.xlsx` dalam template LPMS (tombol **Download Template** di halaman impor): dua kelompok dan empat baris terkecil, bobot total 100. Semua baris bertanggal mulai `H−7` dan selesai `H+30`, supaya hari uji selalu di dalam rentangnya. |
| Baris WBS | `1` AU Persiapan dan rekayasa: `1.1` AU Survei lokasi (bobot 30), `1.2` AU Desain rinci (20). `2` AU Pengadaan dan instalasi: `2.1` AU Pengadaan material (30), `2.2` AU Instalasi dan uji (20). |
| Aktivitas hasil breakdown | Satu aktivitas per baris terkecil, bobotnya sama dengan bobot baris itu: *AU 1.1 Survei dan laporan lokasi* (PIC `FP-PIC1`), *AU 1.2 Gambar desain rinci* (`FP-PIC2`), *AU 2.1 Pengadaan material utama* (`FP-PIC1`), *AU 2.2 Instalasi dan uji fungsi* (`FP-PIC2`). Mulai `H−7`, Due Date `H`. |
| Berkas | Sebelas PDF dokumen PMP; satu JPG dokumentasi kegiatan reviu; foto Kick-Off (JPG) dan risalah CFR-022 (PDF); satu JPG bukti kendala; satu PDF deliverable per aktivitas (ditambah satu revisi); risalah, dokumentasi, dan bukti tindak lanjut Rapat Tinjauan; BAST 100%, Laporan Akhir Proyek, RFR-002 Akhir, sepuluh berkas ceklis Tabel 31, dokumentasi Event Review, dan FFR-713. |

### 2.3 Lingkungan

| Hal | Nilai yang diandaikan skrip |
|---|---|
| Sumber LPMS-1/2 | Terbaca (`LpmsPlanning:Provider` = `DirectSql`); tanpa itu pemicu dijawab 503 dan seluruh alur dilewati. |
| Kunci pemicu | Terpasang di API (`ExternalTriggerApiKey`); nilainya tidak ditulis di skrip maupun laporan. |
| LenO | `Leno__Mode=Fake`: kiriman dicatat, tidak dikirim. Langkah B6-10 hanya berlaku pada mode `Fake` atau `Live`. |
| Tanda tangan LKP | `LkpSigning:Enabled` mati (bawaan, juga di tumpukan uji): LKP langsung **Final** sesudah persetujuan terakhir. Bila menyala dengan LenSign tiruan, B7-08 menunggu *Menunggu tanda tangan elektronik …* berubah menjadi Final. |
| Penyerahan LKP | `LkpHandover__Mode=Manual` dengan SAP simulasi: tombolnya **Tandai sudah diserahkan**, bukan **Post LKP**. |
| Job latar | Berjalan menurut jam dinding. Bila hari uji tanggal 1 (UTC), LKP periode bulan lalu bisa sudah terbit; B7-01 membuat LKP periode **bulan berjalan**. |

## 3. Ringkasan sembilan bagian

| Bagian | Sesi UAT | Isi | Langkah | Keadaan akhir |
|---|---|---|---|---|
| 1 | S1 | Pembukaan proyek: pemicu, registrasi, persetujuan, Project Analyst | 13 | Proyek terbuka; Pimpro, VP FP, Project Analyst, dan VP FPP menjadi anggota |
| 2 | S2 | Tim Proyek dan Reviu Dokumen PMP | 11 | Tim Proyek berlaku; Review & Replanning revisi 1 disetujui Pimpro |
| 3 | S3 | WBS, Kick-Off, dan Baseline 0 | 13 | Baseline 0 ditetapkan; Kick-Off *Completed*; jadwal dan dokumen PMP terkunci |
| 4 | S4, paruh pertama | Breakdown, laporan progres, dan Work Order WBS 1.1 dan 1.2; Lapor Kendala | 14 | Aktivitas 1.1 dan 1.2 Selesai; realisasi 50%; satu Issue Log terbuka |
| 5 | S5 | Pantauan Proyek dan Rapat Tinjauan | 12 | Rapat Tinjauan disetujui; hasilnya tersimpan; tindak lanjutnya selesai |
| 6 | S4, paruh kedua | Breakdown, laporan progres, dan Work Order WBS 2.1 dan 2.2; kiriman LenO | 11 | Semua aktivitas 100%; semua Work Order Selesai |
| 7 | S6 | LKP 100% sampai diserahkan | 11 | LKP periode berjalan Final dan ditandai diserahkan |
| 8 | S7, langkah 1–3 | Penutupan Proyek dua tahap | 13 | Dokumen penutupan Final; `FP-E1` anggota proyek |
| 9 | S7, langkah 4–7 | Event Review, FFR-713, proyek Ditutup, hanya-baca, kode purnajual | 12 | Proyek Ditutup; permintaan kode purnajual disetujui |

Urutan yang tidak boleh ditukar:
- WBS diimpor sebelum Baseline 0 ditetapkan (bagian 3). Sesudahnya impor terkunci.
- Bagian 5 dijalankan selagi masih ada aktivitas yang belum selesai, yaitu di antara bagian 4 dan 6.
- Bagian 7 baru dimulai sesudah semua aktivitas 100%. Satu periode hanya punya satu LKP.
- `FP-E1` menyetujui LKP 100% (B7-07) sebelum dimasukkan ke Tim Proyek (B8-07): sesudah menjadi anggota, persetujuan tanpa
  keanggotaan tidak teruji lagi.
- Sesudah bagian 9 proyek hanya-baca. Mengulang alur memakai kode proyek lain, atau basis data yang dipulihkan.

## 4. Bagian 1 — Pembukaan proyek

Rujukan: UAT S1; playbook B1–B5; FP-E1-03. Prasyarat: persiapan § 2. Proyek `{KODE}` belum ada di LPMS-3.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B1-01 | *API*, kunci pemicu | `POST api/project-trigger` dengan badan `{"kodeProyek":"{KODE}"}` dan header `X-Lpms-External-Key`. Simpan `requestId` sebagai `{ID}`. | Jawaban `201`, `status` = `created`, `projectCode` = `{KODE}`. `GET api/project-trigger/{KODE}` dengan kunci yang sama memuat `"status":"Imported"`. |
| B1-02 | *API*, kunci pemicu | Kirim pemicu yang sama sekali lagi. Lalu kirim tanpa header kunci. | Kiriman ulang: `200`, `status` = `existing`, tidak ada baris Daftar Kerja baru. Tanpa kunci: `401` *X-Lpms-External-Key header required.* |
| B1-03 | `FP-ADM1` | **Daftar Kerja** (`/tasklist`), tab **Kerjakan** → baris *Registrasi proyek {KODE}: tetapkan VP Fungsi Pelaksanaan Proyek dan Pimpro* → **Buka**. | Halaman **Registrasi Proyek** (`/project-trigger/{ID}`) terbuka dan memuat kartu *Proyek {KODE}* dengan profil dari LPMS-1/2. |
| B1-04 | `FP-ADM1` | **Pimpro proyek ini**: pilih `FP-PIMPRO` (bila tampil, pilih juga **Capability yang dijalankan Pimpro di proyek ini**). **VP Fungsi Pelaksanaan Proyek penanggung jawab**: pilih `FP-E2`. Isi *Catatan untuk Pimpro (opsional)* → **Ajukan ke Eselon 1 Fungsi Pelaksanaan Proyek** → **Ya, ajukan**. | Halaman berubah menjadi *Menunggu persetujuan Eselon 1 Fungsi Pelaksanaan Proyek*; usulannya baca-saja. |
| B1-05 | `FP-PIMPRO` | Buka **Beranda** dan **Daftar Kerja**. | Proyek belum dibuka: `{KODE}` tidak ada di *Proyek Anda*, dan tidak ada baris Daftar Kerja untuk `{KODE}`. |
| B1-06 | `FP-E1` | **Daftar Kerja**, tab **Kerjakan** → *Setujui registrasi proyek {KODE}* → **Buka** → halaman **Persetujuan Registrasi Proyek** (`/project-trigger/{ID}/approval`) → isi *Alasan pengembalian (wajib)* → **Kembalikan dengan alasan**. | Tombol kembalikan mati selama alasan kosong. Sesudahnya baris itu tertutup, dan `FP-ADM1` menerima baris berawalan *Perbaiki registrasi proyek {KODE}*. |
| B1-07 | `FP-ADM1` | Buka baris *Perbaiki registrasi proyek {KODE} …* → periksa formulir → **Ajukan ulang** → **Ya, ajukan ulang**. | Formulir terisi usulan terakhir, dan alasan pengembalian tampil di atasnya. Halaman kembali *Menunggu persetujuan …*. |
| B1-08 | `FP-E1` | *Setujui registrasi proyek {KODE}* → centang *Saya telah membaca, dan yakin untuk meneruskan proses ke tahap berikutnya* → **Setujui registrasi** → **Ya, setujui**. | Registrasi disetujui dan proyek langsung dibuka. |
| B1-09 | `FP-PIMPRO` | Buka **Beranda**, **Daftar Kerja**, lalu **Review & Replanning** proyek (`/projects/{KODE}/review-replanning`). | `{KODE}` tampil di *Proyek Anda*. Daftar Kerja memuat *Inisiasi Tim Proyek {KODE}*, bukan *Susun Review & Replanning*. Review & Replanning revisi 1 terbuka berisi sebelas dokumen PMP. |
| B1-10 | `FP-E2` | Buka **Beranda** dan **Notifikasi** (`/notifications`). | `{KODE}` tampil di *Proyek Anda*; ada kabar *Anda ditetapkan sebagai VP Fungsi Pelaksanaan Proyek proyek {KODE}*. |
| B1-11 | `FPP-ADM1` | **Daftar Kerja** → *Registrasi Project Analyst proyek {KODE}* → **Buka** → halaman **Penugasan Project Analyst** (`/project-trigger/{ID}/project-analyst`) → *Project Analyst proyek ini*: pilih `FPP-PA` beserta capability-nya → **Tetapkan Project Analyst** → **Ya, tetapkan**. | Project Analyst tercatat; baris Daftar Kerja itu tertutup. |
| B1-12 | `FPP-E2`, lalu `FPP-PA` | Masing-masing membuka `/projects/{KODE}`. | Keduanya anggota: halaman proyek terbuka. `FPP-E2` menjadi anggota secara otomatis saat Project Analyst ditetapkan dan menerima kabarnya. |
| B1-13 | `SYSADMIN`, lalu `FP-ADM1` | `SYSADMIN` membuka `/project-trigger/{ID}/project-analyst`. `FP-ADM1` membuka `/project-trigger/{ID}/approval`. Pembanding: `FP-ADM1` membuka `/project-trigger/{ID}`. | `SYSADMIN`: *Pemicu proyek ini tidak ditemukan, atau Anda tidak berwenang melihatnya.* `FP-ADM1` di halaman persetujuan: *Akses Ditolak*, hanya Pejabat Eselon 1 Fungsi Pelaksanaan Proyek. Halaman registrasinya sendiri menyatakan *Proyek {KODE} sudah diregistrasi*. |

Keadaan akhir: proyek `{KODE}` terbuka dengan anggota `FP-PIMPRO` (kursi Pimpro), `FP-E2`, `FPP-PA` (kursi Project
Analyst), dan `FPP-E2`. Belum ada Tim Proyek yang disimpan.

## 5. Bagian 2 — Tim Proyek dan Reviu Dokumen PMP

Rujukan: UAT S2; playbook B6–B8; FP-PIM-01, FP-PIM-02, FP-TIM-13. Prasyarat: bagian 1.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B2-01 | `FP-PIMPRO` | **Daftar Kerja** → *Inisiasi Tim Proyek {KODE}* → halaman **Tim Proyek** (`/projects/{KODE}/resource`) → **Tambah Anggota**: *Pengguna* `FP-PIC1`, *Capability di proyek ini* → **Tambahkan**. Ulangi untuk `FP-PIC2` dan `FPP-STAF`. | Setiap penambahan: *Anggota ditambahkan ke Resource proyek.* Ketiganya tampil aktif di tabel *Tim proyek*. |
| B2-02 | `FP-PIMPRO` | Kartu *Inisiasi Tim Proyek — putaran 1* → **Simpan Tim Proyek** → setujui konfirmasi *Simpan daftar Tim Proyek ini? Tim Proyek langsung berlaku tanpa persetujuan.* | Kartu menjadi *Berlaku* beserta daftarnya. Daftar Kerja memuat *Susun Review & Replanning {KODE} (revisi 1)*. |
| B2-03 | `FP-E2`, lalu `FP-E1` | Masing-masing membuka **Daftar Kerja**, tab **Kerjakan** dan **Setujui**. | Tidak ada baris *Review Tim Proyek* maupun *Setujui Tim Proyek*: Tim Proyek berlaku tanpa persetujuan siapa pun. |
| B2-04 | `FP-PIMPRO` | *Susun Review & Replanning {KODE} (revisi 1)* → **Buka** → **Perbaiki Isi PMP** → halaman **Pemutakhiran PMP** (`/projects/{KODE}/review-replanning/draft`) → kartu **Penugasan Dokumen PMP**: enam dokumen kepada `FP-PIC1`, lima kepada `FP-PIC2` → **Simpan**. Pimpro tidak mengisi satu dokumen pun. | Penugasan tersimpan. `FP-PIC1` dan `FP-PIC2` menerima kabar *Anda ditugaskan mengisi dokumen PMP …*. |
| B2-05 | `FP-PIC1` | Buka halaman Draft dari kabar itu (atau Detail → **Isi Dokumen yang Ditugaskan**). Untuk setiap dokumen miliknya: isi teks, pilih berkas PDF → **Unggah Berkas**. Lalu **Simpan Draft**. | Hanya dokumen yang ditugaskan kepadanya yang bisa diisi; yang lain abu-abu dengan *Ditugaskan kepada: …*. Enam dokumennya berteks dan berberkas. |
| B2-06 | `FP-PIC2` | Sama untuk kelima dokumennya → **Simpan Draft**. | Kartu berjudul *Dokumen PMP — 11 dari 11 terisi*. |
| B2-07 | `FP-PIC1` | Kartu **Kegiatan Reviu Dokumen PMP**: Tanggal Kegiatan `H`; Peserta Lintas Fungsi `LUAR` dan satu anggota; Nomor Daftar Hadir Len Meet; Catatan Kegiatan → **Simpan Kegiatan** → unggah satu JPG sebagai Dokumentasi. | Atribut tersimpan dan berkasnya bisa diunduh. Nomor Daftar Hadir lebih dari 100 karakter ditolak dengan kalimat. |
| B2-08 | `FP-PIC1` | **Ajukan Pemutakhiran PMP** → **Ajukan**. | Putaran terkunci. Halaman Detail menyebut pemutusnya Pimpro, dan `FP-PIMPRO` melihat butirnya di tab **Setujui**. |
| B2-09 | `FP-PIMPRO` | **Daftar Kerja**, tab **Setujui** → kartu Review & Replanning `{KODE}` → **Approve** → centang konfirmasi baca → **Setuju**. | Revisi 1 berstatus *Disetujui*. Atribut kegiatan reviu terbaca di halaman Detail. |
| B2-10 | `FPP-PA` | Buka **Daftar Kerja**, tab **Kerjakan**. | Ada baris *Buat Kick Off Meeting {KODE}*. |
| B2-11 | `LUAR`; pembanding `FPP-STAF` | `LUAR` membuka `/projects/{KODE}`. `FPP-STAF` membuka halaman Detail Review & Replanning. | `LUAR` ditolak: peserta lintas fungsi tidak menjadi anggota. `FPP-STAF` membaca halamannya tanpa kontrol isian. |

Keadaan akhir: Tim Proyek berlaku (`FP-PIC1`, `FP-PIC2`, `FPP-STAF` ditambah empat anggota bagian 1); Review &
Replanning revisi 1 disetujui Pimpro; gerbang Kick-Off terbuka.

## 6. Bagian 3 — WBS, Kick-Off, dan Baseline 0

Rujukan: UAT S3; playbook C1, B9, C3; FPP-PA-01, FPP-E1-01, FPP-PA-02; NEG-04, NEG-15. Prasyarat: bagian 2.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B3-01 | `FP-PIMPRO` | Halaman impor (`/schedule/import/{KODE}`) → pilih berkas WBS § 2.2 → **Upload & Preview** → mode **Replace All** → tombol impor di bawah pratinjau → **Ya, Import**. | Kartu *3. Preview & Validasi*: Total Baris 6, Error 0. Sesudah impor, **Activity Breakdown** (`/projects/{KODE}/schedule`) memuat enam baris dengan bobot baris terkecil 30, 20, 30, 20. |
| B3-02 | `FPP-PA` | **Daftar Kerja** → *Buat Kick Off Meeting {KODE}* → **Buka** → **+ Buat Event Baru** → isi *Tanggal Kegiatan* `H` dan *Lokasi* → **Buat Event**. | Halaman **Detail Kick Off Meeting Event** terbuka, berstatus Draft. |
| B3-03 | `FPP-PA` | Tab **Peserta**: tambah `FP-PIMPRO` (*Pengguna LPMS-3*), `LUAR` (*Pengguna LPMS-3*, bukan anggota proyek), dan satu *Peserta luar* (nama dan instansi) → **Tambah** setiap kali. | Ketiga peserta tampil di tabel. |
| B3-04 | `FPP-PA` | Tab **Informasi** → **Ajukan ke Pejabat Eselon 1 Fungsi Pengawasan Proyek (FPP)** → **Ajukan**. | Status menunggu persetujuan. `FPP-E1` dijadikan anggota proyek secara otomatis dan melihat butirnya di tab **Setujui**. |
| B3-05 | `FP-PIMPRO`, lalu `FP-E2` | Masing-masing membuka halaman Kick-Off (`/projects/{KODE}/kickoff`). | Halaman terbaca tanpa tombol penyelenggara maupun tombol keputusan. |
| B3-06 | `FPP-E1` | **Daftar Kerja**, tab **Setujui** → kartu Kick-Off → **Tolak** → isi *Alasan penolakan (wajib)* → **Kirim Penolakan**. | Tombol kirim mati selama alasan kosong. Kick-Off kembali Draft, dan `FPP-PA` menerima *Perbaiki Kick Off Meeting {KODE}*. |
| B3-07 | `FPP-PA` | Buka baris perbaikan → ubah *Lokasi* → simpan → **Ajukan ke Pejabat Eselon 1 Fungsi Pengawasan Proyek (FPP)** → **Ajukan**. | Menunggu persetujuan lagi; alasan penolakan tercatat di riwayatnya. |
| B3-08 | `FPP-E1` | Tab **Setujui** → **Approve** → centang konfirmasi baca → **Setuju**. | Kick-Off disetujui. `FPP-PA` menerima *Kirim undangan & unggah MoM Kick Off Meeting {KODE}*. |
| B3-09 | `FPP-PA` | Tab **Undangan** → **Generate Undangan PDF** → **Kirim Notifikasi Undangan**. | PDF undangan terbentuk. `FP-PIMPRO` dan `LUAR` menerima kabar undangan. |
| B3-10 | `FPP-PA` | Tab **Dokumentasi**: pilih foto, *Jenis berkas* **Dokumentasi Kegiatan** → **Unggah & Simpan**. | Berkas tampil di tabel dengan jenisnya. Kotak *Penetapan Control Baseline / Baseline 0* masih mati, dengan kalimat yang menyebut risalah CFR-022. |
| B3-11 | `FPP-PA` | Pilih risalah PDF, *Jenis berkas* **Formulir Risalah Rapat (CFR-022)**, isi *Nomor Daftar Hadir Len Meet* dan *Catatan* → **Unggah & Simpan**. | Tabel menampilkan Jenis, Nomor Daftar Hadir, dan waktu unggah; **Baca** dan **Unduh** membuka berkasnya. |
| B3-12 | `FPP-PA` | Panel *Penetapan Control Baseline / Baseline 0*: periksa ringkasan jadwal (6 aktivitas, total bobot 100), berkas risalah, dan penerima salinan → centang → **Confirm** → **Tetapkan Baseline 0**. | Baseline 0 ditetapkan dan Kick-Off berstatus *Completed*. Kalimat hasil menyebut satu peserta luar. `FP-PIMPRO` menerima *Baseline 0 proyek {KODE} ditetapkan*. |
| B3-13 | `FP-PIMPRO`, lalu `LUAR` | `FP-PIMPRO`: buka `/schedule/import/{KODE}`, **Review & Replanning**, lalu **Kurva S & LKP** (`/projects/{KODE}/kurva-s`) → **Generate Kurva S**. `LUAR`: buka kabar *Baseline 0 proyek {KODE} ditetapkan*, lalu coba halaman Kick-Off. | Impor: **Upload & Preview** mati dengan kalimat Baseline 0; rute impor langsung 409. Review & Replanning: spanduk *Dokumen PMP terkunci …*, tanpa tombol **Mulai Review & Replanning**. Kurva S: bilah *Garis rencana: Baseline 0*. `LUAR`: salinan risalah terbuka, halaman Kick-Off tetap ditolak. |

Keadaan akhir: Baseline 0 berisi enam baris; jadwal WBS dan dokumen PMP hasil reviu terkunci; `FPP-E1` anggota proyek.

## 7. Bagian 4 — Eksekusi paruh pertama: WBS 1.1 dan 1.2, Lapor Kendala

Rujukan: UAT S4; playbook D1 dan D5; FP-TIM-01..05, FP-PIM-03, FP-PIM-04. Prasyarat: bagian 3.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B4-01 | `FP-PIC1` | **Activity Breakdown** → baris WBS 1.1 → **Breakdown** → **+ Tambah Aktifitas**: Judul *AU 1.1 Survei dan laporan lokasi*, Bobot 30, Deliverable, PIC `FP-PIC1`, Mulai `H−7`, Due Date `H` → **Simpan** → **Ajukan ke …** → konfirmasi. | Kalimat *Isi tabel ini rancangan …* tampil sebelum diajukan. Tombol ajukan menyebut Pimpro sebagai pemutus. Sesudahnya rancangan terkunci dan `FP-PIMPRO` menerima *Putuskan breakdown aktivitas WBS 1.1 proyek {KODE}*. |
| B4-02 | `FP-PIMPRO` | **Daftar Kerja**, tab **Kerjakan** → baris itu → **Buka** → isi catatan → **Decline**. | Tombol mati sampai catatan diisi. Jadwal tidak berubah, tidak ada Work Order lahir, dan `FP-PIC1` menerima *Perbaiki breakdown aktivitas WBS 1.1 …*. |
| B4-03 | `FP-PIC1` | Buka baris perbaikan → ubah Deliverable → **Simpan** → **Ajukan ke …** → konfirmasi. | Baris perbaikannya tertutup; `FP-PIMPRO` ditagih lagi. |
| B4-04 | `FP-PIMPRO` | Buka baris keputusan → catatan → **Accept**. | Aktivitas turunan `1.1.1` masuk Activity Breakdown. `FP-PIC1` menerima *Kerjakan Work Order {NO} aktivitas AU 1.1 Survei dan laporan lokasi (WBS 1.1.1) proyek {KODE}*. Daftar **Work Orders** proyek memuat satu Work Order **Draft** bernomor. |
| B4-05 | `FP-PIC2` | Breakdown WBS 1.2: satu aktivitas *AU 1.2 Gambar desain rinci*, Bobot 20, PIC `FP-PIC2`, tanggal yang sama → **Simpan** → **Ajukan ke …**. | `FP-PIMPRO` menerima *Putuskan breakdown aktivitas WBS 1.2 proyek {KODE}*. |
| B4-06 | `FP-PIMPRO` | Buka baris itu → catatan → **Accept**. | Aktivitas `1.2.1` masuk jadwal; `FP-PIC2` ditagih; Work Order Draft kedua bernomor berikutnya. |
| B4-07 | `FP-PIC1` | **Daftar Kerja** → **Aktivitas Saya** (`/aktivitas-saya`) → aktivitas 1.1.1 → **Laporan Aktivitas** → kartu **Tambah progres**: 50%, keterangan, satu foto → **Simpan Progres**. | Tersimpan tanpa menunggu persetujuan dan tampil di riwayat beserta lampirannya. Kartu **Work Order** berstatus **Draft** dengan Nomor Work Order. Kurva S: Actual 15%. |
| B4-08 | `FP-PIC1` | **Lapor Kendala** → isi Judul, Uraian kendala, Kategori, Aspek, Prioritas, dan satu foto JPG → **Kirim Laporan Kendala** → **Buka Issue Log**. | Proyek, kode WBS `1.1.1`, dan nama aktivitas terisi oleh server. Issue Log lahir, dan **Buka bukti** membuka fotonya. `FP-PIMPRO` menerima kabar, bukan baris Daftar Kerja. |
| B4-09 | `FP-PIC1` | Laporan Aktivitas 1.1.1: kartu **Tanggal aktual** → mulai dan selesai aktual `H` → **Simpan Tanggal**. Coba **Submit Workorder** sekarang. Lalu **Tambah progres** 100% dengan satu PDF di kolom deliverable → **Simpan Progres**. | Submit sebelum 100% ditolak dengan kalimat syaratnya. Laporan 100% tersimpan. |
| B4-10 | `FP-PIC1` | Kartu **Submit Workorder**: isi catatan → **Submit Workorder** → **Ajukan**. | Laporan terkunci; baris *Kerjakan Work Order {NO} aktivitas …* tertutup. `FP-PIMPRO` menerima *Putuskan Work Order {NO} aktivitas AU 1.1 Survei dan laporan lokasi (WBS 1.1.1) proyek {KODE}* di tab **Kerjakan**. |
| B4-11 | `FP-PIMPRO` | Buka baris itu → kartu **Keputusan Work Order** → komentar → **Perbaiki**. | Tombol mati sampai komentar diisi. Work Order kembali ke PIC; `FP-PIC1` menerima *Perbaiki Work Order {NO} aktivitas …* beserta komentarnya. |
| B4-12 | `FP-PIC1` | Buka baris perbaikan → **Tambah progres** 100% dengan deliverable revisi → **Submit Workorder** → **Ajukan**. | Pengajuan ulang memakai Work Order yang sama: Nomor Work Order tetap. `FP-PIMPRO` ditagih lagi. |
| B4-13 | `FP-PIMPRO` | Kartu **Keputusan Work Order** → komentar → **Selesai**. | Work Order **Selesai**; aktivitas 1.1.1 Closed 100%; laporannya terkunci. |
| B4-14 | `FP-PIC2`, lalu `FP-PIMPRO` | `FP-PIC2`: Laporan Aktivitas 1.2.1 → tanggal aktual → progres 100% dengan deliverable → **Submit Workorder**. `FP-PIMPRO`: komentar → **Selesai**. | Work Order kedua Selesai. Kurva S: Actual 50%. |

Keadaan akhir: aktivitas 1.1.1 dan 1.2.1 Closed 100% dengan Work Order Selesai; WBS 2.1 dan 2.2 belum di-breakdown;
satu Issue Log dari Lapor Kendala terbuka.

## 8. Bagian 5 — Pantauan Proyek dan Rapat Tinjauan

Rujukan: UAT S5; FPP-STF-02, FPP-STF-03, FPP-E2-02, FPP-STF-04, FP-TIM-12. Prasyarat: bagian 4, dan WBS 2.x masih berjalan.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B5-01 | `FPP-STAF` | Sidebar **Portofolio → Pantauan Proyek** (`/pantauan-proyek`). Coba saringan *Hanya yang perlu perhatian*. | Baris `{KODE}` tampil: rencana dan realisasi dari Baseline 0 (realisasi 50%), deviasi, SPI, aktivitas lewat tenggat, issue terbuka 1, dan posisi LKP. Jumlah issue tertaut ke daftar issue proyek itu. |
| B5-02 | `FPP-STAF` | Sidebar proyek **Monitoring → Rapat Tinjauan Proyek** (`/projects/{KODE}/rapat-tinjauan`) → **+ Create Event** → **Tanggal dan Jam Rapat** `H`; **Aspek Tinjauan**: *Aspek kemajuan Proyek* dan *Aspek risiko & peluang*; **Tempat / Tautan Rapat (opsional)** → **Simpan Draft**. | Halaman detail event terbuka, berstatus Draft. |
| B5-03 | `FPP-STAF` | Di detail: tambah peserta per peran langsung di tabel (`FP-PIMPRO`, `FP-PIC1`, dan satu lagi dari usulan peserta) → simpan. Buka PDF undangan. | Peserta tersimpan. PDF undangan bertanda **DRAF**. |
| B5-04 | `FPP-STAF` | **Submit Event**. | Submit ditahan selama ada baris peserta yang belum disimpan. Sesudahnya isi terkunci, dan `FPP-E2` serta `FPP-E1` menerima *Setujui Rapat Tinjauan Proyek {KODE}*. |
| B5-05 | `FPP-E2` | **Daftar Kerja** → baris itu → **Decline** dengan catatan. | Event kembali Draft; `FPP-STAF` menerima *Perbaiki Rapat Tinjauan Proyek {KODE}*. |
| B5-06 | `FPP-STAF` | Buka baris perbaikan → ubah tempat → simpan → **Submit Event**. | Pengajuan kedua tercatat; kedua Pejabat FPP ditagih lagi. |
| B5-07 | `FPP-E2` | Buka baris keputusan → catatan, centang konfirmasi baca → **Accept**. | Event disetujui dan isinya terkunci. Baris `FPP-E1` ikut tertutup. |
| B5-08 | `FP-PIC1` | Buka **Notifikasi**. | Undangan Rapat Tinjauan diterima sesudah Accept, tidak sebelumnya. |
| B5-09 | `FPP-STAF` | Kartu **Hasil Rapat Tinjauan Proyek**: unggah risalah CFR-022, lalu dokumentasi. | **Save** mati sampai risalah CFR-022 diunggah. |
| B5-10 | `FPP-STAF` | Catat satu rekomendasi dengan PIC `FP-PIC1` dan target `H+3`; isi Nomor Daftar Hadir Len Meet → **Save**. | Hasil tersimpan. `FP-PIC1` menerima baris berawalan *Tindak lanjut Rapat Tinjauan Proyek {KODE}:* bertenggat target; peserta lain menerima salinan risalah. |
| B5-11 | `FP-PIC1` | Buka baris itu → pada baris rekomendasinya **Tandai Selesai** tanpa berkas; lalu dengan berkas bukti dan catatan. | Tanpa berkas bukti ditolak. Dengan berkas: tindak lanjut selesai dan baris Daftar Kerja tertutup. |
| B5-12 | `FPP-STAF` | Buka **Notifikasi**, lalu halaman event. | Ada kabar tindak lanjut selesai; rekomendasinya berstatus selesai dengan buktinya. |

Keadaan akhir: satu Rapat Tinjauan disetujui dengan hasil tersimpan; tidak ada tindak lanjut terbuka.

## 9. Bagian 6 — Eksekusi paruh kedua: WBS 2.1 dan 2.2, kiriman LenO

Rujukan: UAT S4; playbook D1, D2, D4; FP-TIM-01..03, FP-PIM-03, FP-PIM-04. Prasyarat: bagian 5.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B6-01 | `FP-PIC1` | Breakdown WBS 2.1: satu aktivitas *AU 2.1 Pengadaan material utama*, Bobot 30, PIC `FP-PIC1`, Mulai `H−7`, Due Date `H` → **Simpan** → **Ajukan ke …**. | Mengajukan dengan Bobot 25 ditolak: jumlahnya harus sama dengan bobot WBS 2.1 di Baseline 0 (30). Dengan 30 diterima. |
| B6-02 | `FP-PIC2` | Breakdown WBS 2.2: satu aktivitas *AU 2.2 Instalasi dan uji fungsi*, Bobot 20, PIC `FP-PIC2` → **Simpan** → **Ajukan ke …**. | `FP-PIMPRO` memegang dua baris *Putuskan breakdown aktivitas WBS 2.1 …* dan *… WBS 2.2 …*. |
| B6-03 | `FP-PIMPRO` | Putuskan keduanya: catatan → **Accept**. | Aktivitas `2.1.1` dan `2.2.1` masuk jadwal. Dua Work Order Draft lahir dengan nomor baru, melanjutkan nomor bagian 4. |
| B6-04 | `FP-PIC1` | Laporan Aktivitas 2.1.1: **Tambah progres** 40% → **Simpan Progres**. Lalu coba 30%. Lalu coba memilih enam berkas sekaligus. | 40% tersimpan. 30% ditolak: *tidak boleh lebih rendah dari laporan sebelumnya (40%)*. Enam berkas ditolak: *Paling banyak 5 berkas per laporan …*. |
| B6-05 | `FP-PIC1` | Tanggal aktual → **Simpan Tanggal**; **Tambah progres** 100% dengan deliverable → **Simpan Progres**; catatan → **Submit Workorder** → **Ajukan**. | `FP-PIMPRO` menerima *Putuskan Work Order {NO} aktivitas AU 2.1 Pengadaan material utama (WBS 2.1.1) proyek {KODE}*. |
| B6-06 | `FP-PIC2` | Laporan Aktivitas 2.2.1: tanggal aktual, progres 100% dengan deliverable, **Submit Workorder** → **Ajukan**. | `FP-PIMPRO` menerima baris keputusan untuk WBS 2.2.1. |
| B6-07 | `FP-PIC2`; pembanding `FP-PIC1` | `FP-PIC2` membuka Laporan Aktivitas 2.1.1 milik `FP-PIC1`. | Halaman terbaca, tetapi kartu **Tambah progres** tidak tersedia bagi yang bukan PIC aktivitas itu. |
| B6-08 | `FP-PIMPRO` | Putuskan kedua Work Order: komentar → **Selesai**. | Kedua Work Order Selesai; aktivitas 2.1.1 dan 2.2.1 Closed 100%. |
| B6-09 | `FP-PIC1` | Daftar **Work Orders** proyek (`/projects/{KODE}/work-orders`); buka satu detailnya. | Empat Work Order Selesai, masing-masing bernomor dan nomornya tidak berubah sejak Draft. Detailnya hanya membaca dan menautkan ke Laporan Aktivitas. |
| B6-10 | `SYSADMIN` | `/admin/leno-sync-failures`, penyaring **Semua**. | Kiriman Tasklist tercatat: *Update* ke PIC saat breakdown disetujui dan sesudah Perbaiki (B4-11); *Approval* beserta notifikasi ke pemutus saat Submit Workorder. Tidak ada kiriman untuk Selesai. |
| B6-11 | `FP-PIMPRO` | **Activity Breakdown**, lalu **Kurva S & LKP** → **Generate Kurva S**. | Semua aktivitas turunan 100%. Kartu ringkasan: Actual 100%. |

Keadaan akhir: empat aktivitas Closed 100%, empat Work Order Selesai, realisasi Kurva S 100%.

## 10. Bagian 7 — LKP 100% sampai diserahkan

Rujukan: UAT S6; playbook D3; FP-TIM-06, FP-PIM-05, FPP-PA-03, FPP-E2-01, FP-TIM-07, FP-E2-03, FP-E1-01, FPP-STF-05.
Prasyarat: bagian 6. `FP-E1` belum anggota proyek.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B7-01 | `FP-PIC1` | Sidebar **Monitoring → LKP Reports** (`/projects/{KODE}/lkp`) → **+ Generate LKP** → ganti periode (bawaannya bulan lalu) menjadi bulan berjalan → buat. Bila LKP periode itu sudah ada, buka yang ada. | LKP periode berjalan terbuka, berstatus Draft, dengan kartu **Alur Persetujuan LKP**. |
| B7-02 | `FP-PIC1` | **Hitung Ulang** → periksa angka → **Ajukan Review**. | Realisasi 100%. `FP-PIMPRO` menerima *Review LKP {KODE} periode … (kursi Pimpro)* dan `FPP-PA` menerima *Review LKP … (Project Analyst)*, bertenggat tanggal 5 bulan berikutnya. `FP-PIC1` tidak punya tombol keputusan pada LKP ini. |
| B7-03 | `FP-PIMPRO` | **Daftar Kerja**, tab **Kerjakan** → baris itu → **Konfirm (Pimpro)** dengan catatan dan konfirmasi baca. | Catatan wajib. LKP masih menunggu Project Analyst. |
| B7-04 | `FPP-PA` | Baris *Review LKP … (Project Analyst)* → **Konfirm (Project Analyst)** dengan catatan. | Kedua review selesai; `FPP-E2` menerima *Setujui LKP … (Eselon 2 FPP)*. |
| B7-05 | `FPP-E2` | Baris itu → **Accept** dengan catatan. | Tim Proyek menerima *Tetapkan versi final LKP …*. |
| B7-06 | `FP-PIC1` | Baris itu → centang **Set Final Periode LKP** → **Ajukan Persetujuan & Tanda Tangan**. | Tombol mati sampai kotak dicentang. `FP-E2` menerima *Setujui LKP final … (Eselon 2 FP)*. |
| B7-07 | `FP-E2`, lalu `FP-E1` | `FP-E2`: **Accept** dengan catatan dan konfirmasi baca. `FP-E1`: baris *Setujui LKP 100% {KODE} periode …* → **Accept** dengan catatan. | Sesudah `FP-E2`, LKP menunggu *Pejabat Eselon 1 Fungsi Pelaksanaan Proyek* karena realisasinya 100%. `FP-E1` memutusnya walau bukan anggota proyek. |
| B7-08 | `FP-PIMPRO` | Halaman LKP → kartu FFR-708 → **Lihat FFR-708 (PDF)** dan **Unduh FFR-708**. | LKP berstatus **Final**. FFR-708 memuat identitas proyek, progres terhadap Baseline 0, rincian WBS, dan kotak tanda tangan termasuk Eselon 1. |
| B7-09 | `FPP-STAF` | **Daftar Kerja** → *Serahkan LKP {KODE} periode … ke Fungsi Akuntansi* → kartu **Penyerahan ke Fungsi Akuntansi** → **Tandai sudah diserahkan** (catatan opsional) → **Tandai Diserahkan**. | Status *Diserahkan ke Akuntansi (ditandai manual)* beserta waktunya. Tombol **Post LKP** tidak tampil. |
| B7-10 | `FPP-PA`, lalu `FP-PIMPRO` | `FPP-PA` membuka **Daftar Kerja**. `FP-PIMPRO` membuka **Notifikasi** dan halaman LKP. | Baris penyerahan `FPP-PA` ikut tertutup. `FP-PIMPRO` dikabari, dan tidak mendapat tombol penyerahan. |
| B7-11 | `FPP-STAF` | **Pantauan Proyek**. | Baris `{KODE}`: realisasi 100%, dan posisi LKP periode berjalan menyebut sudah final dan diserahkan. |

Keadaan akhir: LKP 100% periode berjalan Final, disetujui `FP-E1`, dan ditandai diserahkan.

## 11. Bagian 8 — Penutupan Proyek dua tahap

Rujukan: UAT S7 langkah 1–3; FP-TIM-09, NEG-08, FP-PIM-10, FP-E2-04, FP-E1-04. Prasyarat: bagian 7.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B8-01 | `FP-PIMPRO` | Sidebar **Penutupan → Dokumen Penutupan** (`/projects/{KODE}/closing-documents`) → **Buat Penutupan Proyek**. | Halaman penutupan terbuka, berstatus Draft, dengan ceklis sepuluh dokumen dalam urutan Tabel 31. |
| B8-02 | `FP-PIMPRO` | **Konfirmasi LKP 100%** (LKP bagian 7); unggah BAST 100% bertanda tangan; unggah RFR-002 Akhir (atau isi tautan risk register terakhir); unggah Laporan Akhir Proyek. | Keempat syarat tercatat terpenuhi. |
| B8-03 | `FP-PIMPRO` | Isi ceklis sepuluh dokumen langsung di tabel: status, tanggal target, PIC, dan unggahan. Biarkan satu baris *Done* tanpa berkas → **Simpan**; lalu lengkapi dan **Simpan** lagi. | Baris *Done* yang belum lengkap dilewati dan dilaporkan nomor barisnya; sisanya tersimpan. Isian yang belum disimpan bertahan saat berkas diunggah. |
| B8-04 | `FP-PIC1` | Buka halaman penutupan Draft itu. | Hanya membaca: kontrol isian tidak tampil, dan halaman menyebut *Hanya Pimpro proyek ini — … — yang membuat, mengisi, dan mengajukan Penutupan Proyek …*. |
| B8-05 | `FP-PIMPRO` | Kartu **Ajukan Penutupan** → **Submit** → **Ajukan**. | Ditolak: *Tidak ada Pejabat Eselon 1 Fungsi Pelaksanaan Proyek (FP) anggota proyek ini yang tidak ikut menyusun penutupan ini, jadi persetujuan tahap 2 dari 2 tidak bisa diputus. …* Penutupan tetap Draft, tanpa baris Daftar Kerja keputusan. |
| B8-06 | `FP-E1`, bukan anggota | Buka halaman penutupan. *API*: `POST api/project-closing-documents/closures/{id}/decision`. | Halaman terbaca tanpa tombol keputusan. Rute langsung 403 berkalimat *Penutupan Proyek diputus berurutan oleh Pejabat Eselon 2 …, lalu Pejabat Eselon 1 …, masing-masing anggota proyek ini dengan jabatan itu.* |
| B8-07 | `FP-PIMPRO` | **Tim Proyek** → **Tambah Anggota**: `FP-E1` dengan capability Pejabat Eselon 1 FP → **Tambahkan**. Lalu kartu **Inisiasi Tim Proyek — putaran 2** → **Simpan Tim Proyek** → konfirmasi. | *Anggota ditambahkan ke Resource proyek.* Baris *Simpan perubahan Tim Proyek {KODE} (putaran 2)* terbit lalu tertutup sesudah disimpan. |
| B8-08 | `FP-PIMPRO` | Halaman penutupan → **Submit** → **Ajukan**. | Diterima: *Penutupan Proyek diajukan. Persetujuannya berurutan: Pejabat Eselon 2 Fungsi Pelaksanaan Proyek (FP), lalu Pejabat Eselon 1 Fungsi Pelaksanaan Proyek (FP).* `FP-E2` menerima *Putuskan Penutupan Proyek {KODE} (tahap 1 dari 2)*. |
| B8-09 | `FP-E1` | Buka **Daftar Kerja**, lalu halaman penutupan. | Belum ditagih. Kartu **Keputusan — tahap 1 dari 2** tanpa tombol, dengan kalimat *… sedang menunggu persetujuan tahap 1 dari 2 … Kursi Anda kursi tahap lain, …*. |
| B8-10 | `FP-E2` | Baris tahap 1 → kartu **Keputusan — tahap 1 dari 2** → catatan → **Perbaiki**. | Penutupan kembali Draft; `FP-PIMPRO` menerima *Perbaiki Penutupan Proyek {KODE}*. |
| B8-11 | `FP-PIMPRO` | Buka baris perbaikan → ubah satu catatan ceklis → **Simpan** → **Submit** → **Ajukan**. | Pengajuan mulai lagi dari tahap 1; judul baris keputusannya memuat *pengajuan 2*. |
| B8-12 | `FP-E2` | Kartu **Keputusan — tahap 1 dari 2** → catatan, centang konfirmasi baca → **Confirm**. | *Penutupan Proyek disetujui pada tahap 1 dari 2; kini menunggu persetujuan Pejabat Eselon 1 Fungsi Pelaksanaan Proyek (FP).* Status tetap *Menunggu persetujuan*. `FP-E1` menerima *Putuskan Penutupan Proyek {KODE} (tahap 2 dari 2)*. |
| B8-13 | `FP-E1` | Baris tahap 2 → kartu **Keputusan — tahap 2 dari 2** → catatan, centang konfirmasi baca → **Confirm**. | Kartu menyebut *Ini tahap terakhir: Confirm menetapkan dokumen penutupan Final.* Sesudahnya: *Penutupan Proyek disetujui — status dokumen penutupannya Final.* Status **Final**; isinya terkunci. |

Keadaan akhir: dokumen penutupan Final; `FP-E1` anggota proyek.

## 12. Bagian 9 — Event Review, FFR-713, proyek Ditutup, kode purnajual

Rujukan: UAT S7 langkah 4–7; FP-TIM-10, FP-E2-05, FP-TIM-11, FP-E2-06, NEG-09, FP-E2-07, FPP-E2-04, FPP-E1-03.
Prasyarat: bagian 8.

| Langkah | Pelaku | Aksi | Periksa |
|---|---|---|---|
| B9-01 | `FP-PIC1` | Sidebar **Penutupan → Event Review Closing** (`/projects/{KODE}/closing-review`) → **Buat Event Review** → isi resume Lesson Learned, Free Stock (centang dan catatan sisa material), dan peserta per baris dari anggota aktif → **Simpan Isi Event**. | Event tersimpan, berstatus Draft. |
| B9-02 | `FP-PIC1` | **Request Review**. | Diterima karena dokumen penutupan sudah Final. Peserta menerima kabar berlampiran dokumen penutupan; `FP-E2` melihat butirnya di tab **Setujui**. |
| B9-03 | `FP-E2` | **Daftar Kerja**, tab **Setujui** → kartu Event Review → centang konfirmasi baca → **Confirm**. | Event disetujui; undangan terkirim ke setiap peserta. |
| B9-04 | `FP-PIMPRO` | Halaman penutupan → kartu **Persetujuan Penutupan Proyek (FFR-713)** → unggah dokumentasi Event Review Penutupan dan FFR-713 → **Submit FFR-713**. | `FP-E2` menerima *Putuskan Persetujuan Penutupan Proyek {KODE}*. Berkas yang sudah diajukan tidak bisa dihapus. |
| B9-05 | `FP-E2` | Baris itu → catatan, centang konfirmasi baca → **Accept — Tutup Proyek**. | Status proyek **Ditutup**. Setiap anggota menerima *Proyek {KODE} Ditutup*. |
| B9-06 | `FP-PIC1` | Buka Overview, Activity Breakdown, Laporan Aktivitas 1.1.1, LKP Reports, dan Issue Log proyek. | Semua terbaca, masing-masing dengan spanduk *Proyek ini sudah Ditutup — hanya-baca*. |
| B9-07 | `FP-PIC1`, lalu `FPP-STAF` | `FP-PIC1`: coba **Lapor Kendala** dan **+ Generate LKP**. `FPP-STAF`: coba **+ Create Event** Rapat Tinjauan. *API*: kirim satu laporan progres. | Setiap tulisan ditolak berkalimat *… sudah Ditutup, jadi datanya hanya bisa dibaca …*; rute langsung 409. |
| B9-08 | `FP-PIMPRO` | **Tim Proyek** → **Tambah Anggota** satu akun, lalu keluarkan lagi. | Keduanya tetap bisa: administrasi akses tidak ikut terkunci. |
| B9-09 | `FP-E2` | Halaman penutupan → kartu **Pembukaan Kode Purnajual Proyek** → **Request Pembukaan Kode Purnajual Proyek** → isi **Catatan / justifikasi** → **Submit**. | Permintaan langsung menunggu keputusan. `FPP-E2` dan `FPP-E1` menerima baris keputusan. `FP-PIMPRO` dan `FP-PIC1` melihat kartunya tanpa tombol. |
| B9-10 | `FPP-E2` | **Daftar Kerja** → halaman penutupan → kartu itu → **Decline** dengan catatan. | Catatan wajib. `FP-E2` menerima baris perbaikan beserta kabarnya; `FP-PIMPRO` dikabari. |
| B9-11 | `FP-E2` | Buka baris perbaikan → ajukan ulang dengan justifikasi baru. | Permintaan menunggu keputusan lagi; pilihan **Tutup tanpa Purnajual** juga ditawarkan dan tidak dipilih. |
| B9-12 | `FPP-E1` | **Daftar Kerja** → baris keputusan → catatan, centang konfirmasi baca → **Accept**. | Permintaan disetujui. Baris `FPP-E2` tertutup; `FP-E2` dan `FP-PIMPRO` dikabari. Kartu mencatat lanjut ke Request Project Code (LPMS-2), tanpa kiriman ke LPMS-2. |

Keadaan akhir: proyek `{KODE}` Ditutup dan hanya-baca; permintaan kode purnajual disetujui. Alur selesai.

## Lampiran A — Peta bagian ke use case dan ke spesifikasi yang sudah ada

Kolom terakhir menunjuk berkas di `e2e/` yang sudah berjalan hijau di runner dan memuat pemilih untuk modul itu. Semuanya
menguji proyek contoh (`UAT-2026-001` … `-005`), bukan proyek `{KODE}`.

| Bagian | Use case SRS | Pemilih yang bisa dipinjam |
|---|---|---|
| 1 | UC-PMS3-127 (registrasi), pembukaan proyek | `fixtures/uji.ts` (`pemicu`), `fixtures/daftar-kerja.ts`. Halaman registrasi, persetujuan, dan Project Analyst belum punya spesifikasi. |
| 2 | UC-PMS3-127, UC-PMS3-01, UC-PMS3-02 | `specs/reviu-pmp.spec.ts`, `fixtures/reviu-pmp.ts`. Halaman Tim Proyek belum punya spesifikasi. |
| 3 | UC-PMS3-03, UC-PMS3-04, UC-PMS3-110 | `specs/kickoff-baseline0.spec.ts`, `fixtures/kickoff.ts`. Impor WBS dengan berkas sungguhan belum ada. |
| 4 dan 6 | UC-PMS3-69, UC-PMS3-128, UC-PMS3-70, UC-PMS3-71, UC-PMS3-66 | `specs/breakdown.spec.ts`, `specs/work-order.spec.ts`, `specs/issue-log-keputusan.spec.ts`, `fixtures/eksekusi.ts`, `fixtures/issue-log.ts`. |
| 5 | UC-PMS3-56, UC-PMS3-57, UC-PMS3-111, UC-PMS3-112, UC-PMS3-113 | Belum ada: Pantauan Proyek dan Rapat Tinjauan. |
| 7 | UC-PMS3-10, UC-PMS3-11, UC-PMS3-129, UC-PMS3-101, UC-PMS3-12, UC-PMS3-102 | Belum ada: LKP. |
| 8 | UC-PMS3-79, UC-PMS3-84, UC-PMS3-85 | `specs/penutupan-proyek.spec.ts`, `fixtures/penutupan.ts` (rutenya terikat `UAT-2026-005`). |
| 9 | UC-PMS3-86, UC-PMS3-87, UC-PMS3-104, UC-PMS3-105, UC-PMS3-106, UC-PMS3-107 | `specs/penutupan-ffr713.spec.ts`. |

## Lampiran B — Yang belum tersedia di kerangka `e2e/` untuk mengotomasi alur ini

1. **Kode proyek `{KODE}`.** Tumpukan uji menyalin tabel `lpms_*` dev LPMS-II, tetapi tidak meneruskan satu kode pun ke
   Playwright, dan API tidak punya rute yang mendaftar kode LPMS-II. Perlu satu langkah di `e2e/scripts/tumpukan.sh`
   (subperintah `lpms2`) yang memilih baris aktif pertama `lpms_proyek` berkode sah dan meneruskannya sebagai variabel
   lingkungan, ditambah barisnya di layanan `playwright` pada `e2e/docker-compose.yml`.
2. **Berkas WBS.** `e2e/fixtures/berkas.ts` membangkitkan PDF, JPG, PNG, dan teks, belum `.xlsx`. Pilihannya: pembangkit
   `.xlsx` di memori yang bentuknya diterima pengurai template LPMS, atau mengganti B3-01 dengan isian manual di
   **Activity Breakdown** (playbook C2: tambah aktivitas satu per satu, total bobot 100).
3. **Halaman tanpa spesifikasi.** Registrasi dan persetujuan pemicu, penetapan Project Analyst, Tim Proyek, Pantauan
   Proyek, Rapat Tinjauan, dan LKP belum punya pemilih yang teruji; langkahnya di sini disusun dari playbook dan dokumen UAT.
4. **Tanggal.** Proyek contoh bertanggal tetap, sedangkan alur ini memakai tanggal relatif terhadap hari uji. LKP dibuat
   untuk periode bulan berjalan, jadi hasilnya tidak bergantung pada job tanggal 1.
5. **Lama jalan.** Seratus sepuluh langkah dengan satu pekerja diperkirakan menambah beberapa menit pada putaran malam;
   batas putarannya 90 menit, dan putaran penuh hari ini 12–14 menit.

## Lampiran C — Perbedaan dokumen sumber dengan kode

Ditemukan saat kutipan skrip ini dicocokkan dengan kode pada `main` @ `e30ec5bd`. Skrip ini mengikuti kode; kedua dokumen
sumbernya belum dibetulkan.

| Di dokumen | Di kode | Langkah |
|---|---|---|
| Playbook B1–B3: *… tetapkan VP Fungsi Proyek dan Pimpro*, **VP Fungsi Proyek penanggung jawab**, **Ajukan ke Eselon 1 Fungsi Proyek**, *Menunggu persetujuan Eselon 1 Fungsi Proyek* | Keempatnya memakai nama tampilan BOP-001, *Fungsi Pelaksanaan Proyek* (`ProjectTriggerService.cs`, `ProjectTriggerRegistrationPage.razor`) | B1-03, B1-04 |
| Playbook B9: **Ajukan ke Pejabat Eselon 1 Fungsi Pengawas Proyek** | **Ajukan ke Pejabat Eselon 1 Fungsi Pengawasan Proyek (FPP)** (`KickoffEventService.ApproverLabel`; `e2e/fixtures/kickoff.ts`) | B3-04, B3-07 |
| UAT dan playbook: *Kerjakan aktivitas …*, *Putuskan Work Order aktivitas …*, *Perbaiki Work Order aktivitas …* | Judulnya memuat Nomor Work Order: *Kerjakan Work Order {NO} aktivitas …*, *Putuskan Work Order {NO} aktivitas …*, *Perbaiki Work Order {NO} aktivitas …* (`WorkOrderWorklistText`). Bentuk tanpa nomor hanya untuk Work Order yang belum bernomor. | B4-04, B4-10, B4-11, B6-05 |
| UAT FPP-STF-03: aspek *Risiko & Peluang* | Kotak centang **Aspek Tinjauan** berlabel *Aspek kemajuan Proyek*, *Aspek risiko & peluang*, dan seterusnya (`RapatTinjauanCatalog.AspectLabel`) | B5-02 |

Yang tidak dicocokkan dengan kode: perilaku yang hanya terlihat saat aplikasi berjalan (tombol mati, siapa menerima kabar,
urutan baris Daftar Kerja). Bagian itu mengikuti hasil yang diharapkan di dokumen UAT.
