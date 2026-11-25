Saya sedang meninjau playbook E2E dan dokumen UAT di repo untuk menyesuaikan urutan sesi. #879 dan #880 sudah di-merge dan dideploy ke staging, jadi pengingat SLA Cashflow Baseline sudah aktif di sana.

Saya sedang menyusun alur dari buka sampai Kick-Off; berikutnya saya cek rantai LKP 100% dan penutupan, termasuk apakah LKP bulan berjalan boleh dibuat manual, karena itu menentukan apakah satu proyek bisa ditutup tanpa menunggu pergantian bulan.

Hampir selesai. Saya baca bagian FPP (Kick-Off, Baseline 0, Rapat Tinjauan, penyerahan LKP), lalu saya tulis rencana sesinya.

## Uji end-to-end satu proyek, dari pembukaan sampai penutupan, dalam tujuh sesi

Satu proyek sungguhan dari LPMS-1/2 diikuti dari pemicu LenO sampai Ditutup dan kode purnajual. Langkah klik rincinya sudah ada di [docs/playbook-e2e.md](docs/playbook-e2e.md) (Fase A–D) dan [docs/uat-desember-2026.md](docs/uat-desember-2026.md) (skenario per kursi, termasuk penutupan). Di bawah ini urutan sesinya, siapa yang harus hadir, dan apa yang diperiksa. Nama kursi mengikuti matriks akun UAT § 2.

| Sesi | Isi | Kursi yang hadir | Perkiraan |
|---|---|---|---|
| 0 | Persiapan akun dan lingkungan | SysAdmin, pengelola lingkungan | sebelum hari pertama |
| 1 | Pembukaan proyek | ops, `FP-ADM1`, `FP-E1`, `FPP-ADM1` | 1 jam |
| 2 | Tim Proyek dan Reviu Dokumen PMP | `FP-PIMPRO`, `FP-PIC1`, `FP-PIC2` | 2 jam |
| 3 | WBS, Kick-Off, Baseline 0 | `FP-PIMPRO`, `FPP-PA`, `FPP-E1` | 2 jam |
| 4 | Breakdown, progres, Work Order, LenO | `FP-PIC1`, `FP-PIC2`, `FP-PIMPRO` | 3 jam, bisa 2 hari |
| 5 | Pengawasan FPP dan Rapat Tinjauan | `FPP-STAF`, `FPP-E2`, PIC | 1,5 jam |
| 6 | LKP 100% sampai diserahkan | PIC, `FP-PIMPRO`, `FPP-PA`, `FPP-E2`, `FP-E2`, `FP-E1`, `FPP-STAF` | 2 jam |
| 7 | Penutupan, proyek Ditutup, kode purnajual | `FP-PIC1`, `FP-E2`, `FPP-E2`, `FPP-E1` | 2–3 jam |

Urutan yang tidak boleh dilanggar:
- WBS harus diimpor sebelum Baseline 0 ditetapkan. Sesudah Baseline 0 impor terkunci.
- Sesi 5 harus selesai sebelum Sesi 7. Paling wajar dijalankan di tengah Sesi 4, selagi aktivitas masih berjalan.
- Sesi 6 baru bisa dimulai setelah **semua** aktivitas 100%. Status "LKP 100%" dibaca dari angka realisasi yang dibekukan di LKP itu.
- Setelah Sesi 7 proyek hanya-baca. Untuk mengulang uji, pakai kode LPMS-1/2 yang baru.

### Sesi 0: Persiapan
1. **Akun:** 12 kursi dari matriks UAT: `SYSADMIN`, `FP-ADM1`, `FP-E1`, `FP-E2`, `FP-PIMPRO`, `FP-PIC1`, `FP-PIC2`, `FPP-ADM1`, `FPP-PA`, `FPP-STAF`, `FPP-E2`, `FPP-E1`. Tambahkan `LUAR` untuk peserta lintas fungsi.
   - Semua akun harus berbeda.
   - `FPP-E1` dan `FPP-E2` masing-masing harus satu-satunya pemegang kursinya, supaya otomatis masuk tim.
   - Email penanda tangan LenSign harus terisi.
2. **Kode proyek:** satu kode LPMS-1/2 yang belum pernah dipicu dan belum punya Pimpro. Kunci pemicu harus terpasang dan API bisa dijangkau (playbook A4).
3. **Berkas uji:**
   - WBS kecil dalam template LPMS, misalnya 2 kelompok dan 4 baris terkecil dengan bobot total 100, bertanggal dari hari uji sampai akhir Desember. Buat kecil karena setiap baris terkecil harus di-breakdown dan mencapai 100% sebelum penutupan.
   - 11 PDF dokumen PMP.
   - Foto Kick-Off dan risalah CFR-022.
   - Berkas deliverable.
   - BAST 100%, Laporan Akhir, FFR-713, dan dokumentasi Event Review.
4. **LenSign tiruan** dinyalakan untuk tanda tangan LKP final (runbook UAT).
5. **LenO** pakai mode `Fake`, supaya kiriman Work Order bisa diperiksa tanpa benar-benar terkirim (sesuai panduan Work Order–LenO sebelumnya).

### Sesi 1: Pembukaan proyek (playbook B1–B5)
1. ops mengirim pemicu `POST api/project-trigger` dengan kode tadi. Jawabannya `201 created`; simpan `requestId`.
2. `FP-ADM1` membuka Daftar Kerja ? Registrasi proyek, mengusulkan `FP-PIMPRO` sebagai Pimpro dan `FP-E2` sebagai VP FP, lalu Ajukan.
3. `FP-E1` membuka tab Kerjakan dan memilih **Kembalikan** sekali dengan alasan. `FP-ADM1` mengajukan ulang, lalu `FP-E1` memilih **Setujui**.
4. `FPP-ADM1` membuka Penugasan Project Analyst dan memilih `FPP-PA`.

Periksa: proyek muncul di dashboard `FP-PIMPRO` dan `FP-E2`, dan `FPP-E2` otomatis menjadi anggota.

### Sesi 2: Tim Proyek dan Reviu Dokumen PMP (B6–B8; FP-PIM-01/02, FP-TIM-13)
1. `FP-PIMPRO` menambahkan `FP-PIC1`, `FP-PIC2`, dan `FPP-STAF` ke Tim Proyek, lalu **Simpan**. Tim langsung berlaku tanpa persetujuan.
2. `FP-PIMPRO` membuka Review & Replanning revisi 1 dan menugaskan kesebelas dokumen PMP ke `FP-PIC1` dan `FP-PIC2`.
3. `FP-PIC1` dan `FP-PIC2` mengisi teks dan berkas tiap dokumen, lalu kartu Kegiatan Reviu (peserta lintas fungsi diisi `LUAR`), lalu **Ajukan Pemutakhiran PMP**.
4. `FP-PIMPRO` menyetujui di tab Setujui.

Periksa: yang memutus Pimpro, karena ia tidak menulis isi. `LUAR` tidak mendapat akses ke proyek. Variannya: kalau Pimpro ikut mengisi satu dokumen saja, keputusan pindah ke `FP-E2`.

### Sesi 3: WBS, Kick-Off, dan Baseline 0 (C1, B9, C3; FPP-PA-01/02, FPP-E1-01)
1. `FP-PIMPRO` mengimpor WBS di `/schedule/import/{kode}`: Preview & Validasi, lalu Confirm.
2. `FPP-PA` membuat Kick-Off dari Daftar Kerja, menambahkan peserta (`FP-PIMPRO`, `LUAR`, satu peserta luar), lalu Ajukan.
3. `FPP-E1` menolak sekali. `FPP-PA` memperbaiki dan mengajukan ulang, lalu `FPP-E1` menyetujui.
4. `FPP-PA` membuat undangan PDF dan mengirim notifikasinya. Lalu mengunggah foto, kemudian risalah CFR-022 beserta Nomor Daftar Hadir, dan menekan **Tetapkan Baseline 0**.

Periksa:
- Kick-Off berstatus Completed.
- Impor WBS terkunci (NEG-04).
- Review & Replanning terkunci (NEG-15).
- Kurva S menampilkan garis rencana.

### Sesi 4: Breakdown, progres, dan Work Order (D1, D4, D5; FP-TIM-01..05, FP-PIM-03/04)
Ulangi untuk setiap baris WBS terkecil:
1. PIC membuka Activity Breakdown dan menekan **Breakdown**. Isi aktivitasnya: bobot totalnya sama dengan bobot baris itu, tanggal di dalam rentang baris itu, dan PIC terisi. Lalu Ajukan.
2. `FP-PIMPRO` memilih **Decline** sekali. PIC mengajukan ulang, lalu `FP-PIMPRO` memilih **Accept**. Work Order Draft lahir dengan nomornya.
3. PIC melapor progres bertahap sampai 100%, mengisi tanggal aktual, mengunggah deliverable, lalu **Submit Workorder**.
4. `FP-PIMPRO` memilih **Perbaiki** sekali. PIC mengirim ulang, lalu `FP-PIMPRO` memilih **Selesai**.

Cukup sekali saja: Lapor Kendala dari satu aktivitas, lalu periksa kiriman LenO di `/admin/leno-sync-failures` dengan penyaring Semua.

Sesi selesai kalau semua aktivitas 100%, semua Work Order Selesai, dan realisasi Kurva S 100%.

### Sesi 5: Pengawasan FPP (E2E-05)
1. `FPP-STAF` membuka Pantauan Proyek. Proyek ini harus tampil.
2. `FPP-STAF` membuat Rapat Tinjauan bertanggal hari uji, menambahkan peserta, lalu **Submit Event**.
3. `FPP-E2` memilih **Decline** sekali. `FPP-STAF` mengajukan ulang, lalu `FPP-E2` memilih **Accept**.
4. `FPP-STAF` mengunggah risalah dan dokumentasi, mencatat rekomendasi dengan PIC `FP-PIC1`, lalu **Save**.
5. `FP-PIC1` menandai tindak lanjutnya selesai dengan berkas bukti.

### Sesi 6: LKP 100% sampai diserahkan (E2E-03 dan FP-E1-01)
1. `FP-PIC1` membuka LKP Reports, menekan **Generate LKP** untuk periode bulan berjalan, lalu **Hitung Ulang** sampai realisasinya 100%, lalu **Ajukan Review**.
   - Kalau LKP periode itu sudah ada (misalnya dibuat job tanggal 1), buka yang ada lalu tekan Hitung Ulang.
   - Jangan memfinalkan LKP periode ini sebelum semua aktivitas 100%, karena satu periode hanya punya satu LKP.
2. `FP-PIMPRO` dan `FPP-PA` masing-masing memilih **Konfirm**.
3. `FPP-E2` memilih **Accept**.
4. `FP-PIC1` mencentang **Set Final Periode LKP**, lalu mengajukan persetujuan dan tanda tangan.
5. `FP-E2` memilih **Accept**. LKP lalu menunggu Pejabat Eselon 1 FP, karena progresnya 100%.
6. `FP-E1` memilih **Accept**, walaupun ia bukan anggota proyek.
7. `FPP-STAF` menekan **Tandai sudah diserahkan**.

Periksa: FFR-708 memuat kotak tanda tangan Eselon 1, dan tanda tangan LenSign tiruan selesai.

### Sesi 7: Penutupan (E2E-04)
1. `FP-PIC1` membuat **Penutupan Proyek**: konfirmasi LKP 100%, unggah BAST 100%, risk register atau RFR-002 Akhir, dan Laporan Akhir, isi ceklis Tabel 31, lalu Ajukan.
2. `FP-E2` memilih **Perbaiki** sekali. PIC mengajukan ulang, lalu `FP-E2` memilih **Confirm**. Penutupan menjadi Final.
3. `FP-PIC1` membuat Event Review Closing (Lesson Learned dan Free Stock), lalu **Request Review**. `FP-E2` memilih **Confirm**.
4. `FP-PIC1` mengunggah dokumentasi Event Review dan FFR-713, lalu **Submit FFR-713**. `FP-E2` memilih **Accept — Tutup Proyek**.
5. Periksa bahwa proyek hanya-baca (NEG-09):
   - progres, Lapor Kendala, Rapat Tinjauan, dan Generate LKP ditolak dengan kalimat penjelasan;
   - menambah dan mengeluarkan anggota tetap bisa.
6. `FP-E2` mengajukan pembukaan kode purnajual. `FPP-E2` memilih **Decline** dengan catatan. `FP-E2` mengajukan ulang, lalu `FPP-E1` memilih **Accept**.

**Catatan saat menjalankan:**
- Pengingat dan job berjalan per jam, jadi notifikasi bisa terlambat sampai satu jam.
- Satu orang satu kursi. Banyak gerbang menolak orang yang sama di dua peran.
- Catat hasil tiap langkah sebagai Lulus, Gagal, atau Terhambat, seperti UAT § 4.

Kalau berguna, saya masukkan rencana ini ke `docs/uat-desember-2026.md` sebagai skenario E2E-00 lewat PR draft, supaya peserta UAT memakai urutan yang sama.

---

**Satu hal mendesak soal Cashflow Baseline.** #879 dan #880 sudah di-merge dan dideploy ke staging hari ini, pukul 10.33 dan 13.20 WIB. Artinya pengingat SLA penetapan sudah berjalan per jam di staging, sementara Q1–Q5 dari pesan sebelumnya belum dijawab.

Dampaknya pada UAT:
- Data contoh UAT menanam Baseline 0 untuk `UAT-2026-003`, `-004`, dan `-005` pada Maret–Agustus, dan tidak satu pun punya revisi Final Cashflow Baseline.
- Begitu data contoh ditanam 30 November, `FP-E2` langsung menerima tiga Alert H+1 untuk modul yang bertanda "Dijadwalkan 2027".
- Pimpro menyusul menerima pengingat untuk `UAT-2026-002`, mulai 6 Desember.

Kalau Q1 tidak dijawab sebelum code freeze 27 November, perilaku ini ikut ke cabang UAT. Kalau jawabannya (a), agen tinggal membuat satu PR kecil untuk mematikan SLA sampai modul go-live.