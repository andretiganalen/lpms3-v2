# Pelacakan Kepatuhan BOP-001 → LPMS3 (`:5100`)

- **Tanggal audit:** 2026-11-15 · **Rilis:** `17.9.7-lpms3.1.17` · **Branch:** `feat/inhouse-enterprise-hardening`
- **Acuan:** BOP-001 rev.01 beserta turunan dan dependensinya: formulir (`docs/template-bop001/form`, 27 berkas), prosedur (`docs/template-bop001/procedure`, 53 berkas), Nota 021/N/UQ/VIII/2026 (organisasi), CLP-001 (35 fungsi generik), FOP-700/705, SOP-004/009, BOG-003, Master Plan §0 J1–J7 dan §15, Buku Teknis §7.4 (go-live), `docs/CHECKLIST-GOLIVE-D12.md`.
- **Dependensi non-BOP yang ikut diaudit:** IDS (login), StarRocks (mirror), lisensi LPMS GPLv3 (`docs/plan/LEGAL_NOTICES.md`), hardening (`docs/plan/AUDIT_VERIFICATION_REPORT.md`).
- **Cara memverifikasi ulang:** `bash ops/audit_bop001.sh` (bukti data/konfigurasi, hanya membaca), `bash ops/verify.sh` (aplikasi), `bash lpms3/smoke/run.sh` (alur proyek uji), `bash ops/monitor.sh -v` (kesehatan).

## 1. Dasbor status

| Ukuran | Hasil 2026-11-15 |
| :-- | :-- |
| `ops/audit_bop001.sh` | **PASS 48 · GAP 9 · FAIL 1** |
| `ops/audit_mod08.rb` (aplikasi) | 36/36 PASS |
| Smoke D10 | PASS 22 · FAIL 0 · N/A 5 |
| Janji BOP-001 J1–J7 | Data/konfigurasi **siap**; antarmuka dan otomasi **belum** (lihat §2) |
| UAT U01–U31 | Lulus penuh 3, lulus sebagian 9, N/A 2, belum diuji 17 → **jauh di bawah target 95%** (§4) |
| Go-live D12 | **Belum layak** (butir 1, 2, 3, 6 parsial, 7, 8, 9 terbuka; §6) |

**Satu temuan FAIL (keamanan):** berkas `.env` di root repo berisi catatan kredensial root StarRocks produksi dalam teks biasa. Berkas itu berizin 664 dan nilainya sudah tampil di log sesi audit ini. Izin sudah diubah ke 600. **Wajib:** pindahkan ke pengelola rahasia, hapus berkas, dan rotasi password root StarRocks (nilai tidak dicantumkan di dokumen ini).

## 2. Janji LPMS3 terhadap BOP-001 (Master Plan §0)

| # | Janji | Status | Bukti (perintah / lokasi) | Kekurangan |
| :-: | :-- | :-: | :-- | :-- |
| J1 | 5 tahap + gate yang dapat diaudit | 🟡 (rilis 1.25: menu dan halaman per fase; alur diuji `lpms3/smoke/run_fase.sh`) | 4 fase P1–P4 dengan gate G1–G4; 3 template × 4 fase (`audit_bop001` J1.1–J1.4) | Validasi kriteria penutupan gate belum ada (U03); tidak ada template **Program** (Master Plan §15 menyebut Prediktif/Hibrid/Program/Purnajual; hanya 3 yang di-seed) |
| J2 | Semua formulir diisi di aplikasi, tabel/kolom sama, dapat dicetak resmi | 🟡 | 18 `form_definition`, skema `lpms3_form` 47 tabel (J2.1–J2.2) | **Tidak ada UI isian atau PDF resmi** di plugin (`form_instance`=0) |
| J3 | WBS Template LPMS = satu-satunya cara isi WBS, folder bukti, dasar Kurva-S | 🟡 | 5 tabel WBS/Kurva-S/baseline (J3.1) | Tidak ada UI/impor WBS (`wbs_node`=0) |
| J4 | RASCI & peserta rapat otomatis per proyek | ✅ data | `ref_rasci`=312, `ref_peserta_rapat`=9, organisasi 66 unit (5/18/43), pemetaan 81, grup fungsi 31 (J4.1–J4.5) | Posisi & user HC belum (D8) |
| J5 | Integrated Change Control (BFR-001, CCM, BOG-003) | ✅ alur · 🟡 aturan | `ref_matriks_kewenangan`=6; tipe CR; 11 workflow CR per peran; smoke U06 lulus (J5.1–J5.4) | Tiga ambang BOG-003 (U29) belum diuji |
| J6 | Pengawasan berkelanjutan (LKP bulanan, rapat, risiko, mutu, K3L, pengadaan) | 🟡 | 5 tabel FFR-708; 11 tipe WP pengawasan; `lpms3-data` berjalan; outbox 0 gagal (J6.1–J6.3) | LKP otomatis/golden-file E01–E10 belum diuji (J6.4); notifikasi email tidak jalan (SMTP) |
| J7 | Penutupan FOP-705 | 🟡 | 8 tabel FFR-710; BAST/bahan sisa/stock opname; smoke U16 arsip read-only (J7.1–J7.2) | Sub-project purnajual otomatis belum (J7.3); FFR-710 lengkap (U30) dan Closing penuh (U31) belum diuji |

## 3. Telusur BOP-001 §15 → status

| BOP-001 | Diwujudkan di | Data/konfigurasi | UI/otomasi |
| :-- | :-- | :-: | :-: |
| 1.0 Tujuan | J1–J7, Project Health | ✅ | 🟡 |
| 2.0 Ruang lingkup / tailoring | Template per jenis proyek | 🟡 (3 dari 4) | — |
| 3.x Definisi (39) | Glosarium in-app, objek data | 🟡 | ⛔ glosarium/tooltip belum ada |
| 4.0 Dokumen terkait | `docs/template-bop001` | ✅ | — |
| 5.1.x Inisiasi + Tabel 1 | Template, FFR-706, FLP-01, BOT-001 | ✅ | 🟡 (U02 due date +14 hari, U03 gate) |
| 5.2.x Perencanaan + Tabel 2 | 9 Dokumen Rencana, Kick-Off, Baseline 0, BOG-003 | ✅ | ⛔ (U04, U05) |
| 5.3.x Eksekusi + Tabel 3 | WP aktivitas, status per tipe | ✅ | 🟡 |
| 5.4.x Pengawasan + Tabel 4, 5 | CR, risiko, mutu, K3L, pengadaan, rapat | ✅ alur | 🟡 (aturan NCR/lampiran BA) |
| 5.5.x Penutupan + Tabel 6 | Jenis Penutupan, arsip, FFR-710 | ✅ | 🟡 (U16 purnajual, U17) |
| 6.0 Formulir terkait (7 utama) | 18 tabel formulir | ✅ | ⛔ UI & PDF |
| 7.0 Alur/flow | Gate sebagai milestone | ✅ | ⛔ stepper/beranda per persona |
| 8.0 Matriks perubahan Rev | `form_definition.rev` terisi 18/18 | ✅ | — |

## 4. Matriks UAT (Master Plan §10; sumber: smoke D10 2026-11-15)

Legenda: ✅ lulus penuh · 🟡 lulus sebagian (alur status lulus, aturan tambahan belum) · ➖ N/A (butuh fitur belum dibuat) · ⛔ belum diuji.

| U | Skenario | Status | Catatan |
| :-: | :-- | :-: | :-- |
| U01 | Proyek dari template, Kode Proyek | ✅ | 35 WP + 9 dokumen + 4 gate |
| U02 | Penetapan tim, due date +14 hari | ➖ | WP ada; aturan +14 hari belum |
| U03 | Charter → G1 dengan kriteria | ➖ | Milestone gate ada; validasi kriteria belum |
| U04 | Reviu 9 Dokumen Rencana → Disahkan | ⛔ | |
| U05 | Kick-Off, risalah CFR-022, Baseline 0 | ⛔ | Tabel ada, UI belum |
| U06 | CR end-to-end (Ditunda, Ditolak) | ✅ | Transisi terlarang ditolak |
| U07 | CR dengan adendum SOP-009 | ⛔ | |
| U08 | Risiko bulanan → isu | 🟡 | Status lulus; riwayat skor dan relasi Risiko→Isu belum |
| U09 | Bahaya K3L baru | 🟡 | Status lulus; pemicu CR belum |
| U10 | Item Pengadaan s.d. GR/SES | 🟡 | Status lulus; nomor referensi belum |
| U11 | Inspeksi gagal → NCR → tutup | 🟡 | Status lulus; blokir Deliverable bila NCR kritikal belum |
| U12 | Deliverable diterima dengan BA | 🟡 | Status lulus; lampiran BA wajib belum |
| U13 | FFR-708 bulanan + kurva-S | ⛔ | |
| U14 | Rapat tinjauan + action item | 🟡 | Status Action Item lulus; rapat berulang belum |
| U15 | Lessons Learned dipublikasikan | 🟡 | Status lulus; query global belum |
| U16 | Penutupan Selesai 100% | 🟡 | Arsip read-only lulus; purnajual belum |
| U17 | Penutupan Terminasi | ⛔ | |
| U18 | Hak akses Pembaca | ✅ | |
| U19 | Notifikasi email | ⛔ | **Terblokir SMTP** |
| U20 | Backup → restore ≤ 2 jam | 🟡 | Drill 2026-11-14: 9–19 dtk, jumlah baris identik; LPMS penuh di atas DB restore belum |
| U21–U26 | Sidebar, Add New, Procurement Pipeline, LKP L0→L5, Return, Backfill | ⛔ | Sidebar/plugin belum dibangun |
| U27–U31 | WBS Template, FLP-01 per jenis kode, BOG-003 tiga ambang, FFR-710, Closing FOP-705 | ⛔ | |

**Ringkasan:** ✅ 3 (U01, U06, U18) · 🟡 9 (U08–U12, U14–U16, U20) · ➖ 2 · ⛔ 17. Lulus penuh 3/31 = 9,7%; dengan lulus sebagian 12/31 = 38,7%. Target BOP/D12: ≥ 95% dan 0 defect kritikal.

## 5. Registri bukti

| Bukti | Lokasi | Penyegaran |
| :-- | :-- | :-- |
| Audit BOP-001 | `ops/audit_bop001.sh` | Setiap rilis dan sebelum BA |
| Audit aplikasi | `ops/audit_mod08.rb` via `ops/verify.sh`; `docs/plan/AUDIT_VERIFICATION_REPORT.md` | Setiap deploy |
| Smoke D10 | `lpms3/smoke/run.sh` | Setiap deploy |
| Backup + checksum | `data/backup/<tgl>/SHA256SUMS`, cron 02:00 | Harian; dipantau `ops/monitor.sh` |
| Restore drill | `ops/restore_drill.sh`; hasil di `docs/RUNBOOK-ADMIN.md` §8 | Sebelum go-live (ulang pada produksi bersih) |
| Monitoring | `ops/monitor.sh` (cron tiap 5 menit) → `data/monitor/alerts.log` | Berjalan sejak 2026-11-15 |
| Lisensi | `LICENSE`, `COPYRIGHT`, `COPYRIGHT_short` (SHA-256 sama dengan image), `docs/plan/LEGAL_NOTICES.md` | Setiap perubahan image |
| Catatan rilis | `CHANGELOG.md` | Setiap rilis |

## 6. Analisis kesenjangan dan rencana perbaikan

| # | Kesenjangan | Prioritas | Pemilik | Tindakan |
| :-: | :-- | :-: | :-- | :-- |
| 1 | `.env` berisi kredensial root StarRocks di root repo | **Tinggi** | TI | Pindahkan ke pengelola rahasia, hapus, rotasi password |
| 2 | UI formulir + PDF resmi (J2), WBS Template + Kurva-S (J3), sidebar/beranda (K, §4 UX) | Tinggi | Pengembangan | Bangun di plugin; urutan sesuai UAT U21–U31 |
| 3 | Aturan sistem: due date +14 hari (U02), kriteria gate (U03), blokir NCR kritikal (U11), lampiran BA (U12), purnajual otomatis (U16) | Tinggi | Pengembangan | Implementasi di plugin; ubah N/A smoke menjadi PASS |
| 4 | UAT penuh U01–U31 dan BA UAT/G-SB | Tinggi | PMO + TI | Jalankan setelah butir 2–3 |
| 5 | Backup terjadwal ≥ 7 hari berturut-turut | Sedang | TI | Otomatis; terpenuhi **2026-11-20 02:00** bila tidak ada hari terlewat (terjadwal: 14, 15 Nov) |
| 6 | 2FA admin (D12 butir 3) | Sedang | Tim IDS | Aktifkan di IDS; **tidak** di LPMS (menghentikan login bridge, RUNBOOK §6) |
| 7 | Saluran alert monitoring (email/Slack/telepon) | Sedang | TI | Tentukan saluran; `monitor.sh` kini hanya mencatat ke log |
| 8 | Template **Program** (tailoring §15) | Sedang | PMO | Putuskan perlu atau tidak; bila perlu tambah di `70_templates.rb` |
| 9 | Data HC: posisi dan user (D8); konfirmasi jenjang SKEP 001/2026 | Sedang | SDM + PMO | Muat dari data HC |
| 10 | Kolom mirror StarRocks NULL; snapshot harian StarRocks; koneksi LPMS 2 | Sedang | TI + admin StarRocks | Lihat `CHECKLIST-GOLIVE-D12.md` bagian D |
| 11 | Glosarium/tooltip BOP-001 §3.0 | Rendah | Pengembangan | Setelah UI inti |
| 12 | Job latar gagal `Notifications::WorkflowJob` ("undefined method 'project' for nil") setelah proyek uji smoke dihapus | Rendah | Pengembangan | Efek samping penghapusan proyek (journal sudah hilang); tidak muncul pada operasi normal. Terpantau sebagai WARN |
| 13 | Komunikasi go-live, BA go-live, hypercare 2 minggu, pelatihan, Help Center | Sedang | PMO | Setelah UAT |

## 7. Kalender audit

| Tanggal | Peristiwa |
| :-- | :-- |
| 2026-11-15 | Audit ini; monitoring aktif; `/panduan-internal` placeholder |
| 2026-11-20 02:00 | Backup terjadwal ke-7 → butir D12 #4 dapat dicentang (jalankan `bash ops/audit_bop001.sh`, S.7) |
| Menunggu keputusan | Parameter SMTP; saluran alert; data HC; rotasi password StarRocks |
| Sebelum go-live | Restore drill ulang di produksi bersih; smoke; UAT; BA G-SB, BA UAT, BA go-live |

## 8. Pekerjaan rumah (ditunda atas keputusan pemilik)

1. **SMTP internal (D2):** **ditunda; bukan kebutuhan saat ini** (keputusan pemilik 2026-11-15). Notifikasi task/worklist memakai notifikasi internal antar akun IDS yang terdaftar di Fungsi Organisasi/Fungsi Generik. 812 job email historis gagal `ECONNREFUSED localhost:25` (terbaru 2026-11-14); monitor memisahkannya sebagai WARN. U19 dicakup ulang menjadi uji notifikasi internal.
2. Item butir 1–13 pada §6 di luar yang sudah dikerjakan sesi ini.

## 9. Permintaan pendaftaran akun IDS (2026-11-15)

| Akun | Status |
| :-- | :-- |
| `hariyadi.maramis@len.co.id`, `ilham.nugraha@len.co.id`, `kristian@len.co.id`, `andre.tigana@len.co.id` | **Belum terdaftar di IDS** — IDS (`dev-ids-intern.len.co.id`) bukan bagian repo ini dan agen tidak memiliki akses admin IDS (hanya `client_id/secret` untuk login OIDC). Perlu didaftarkan oleh admin IDS. |

- Di sisi LPMS3 tidak ada yang perlu dibuat: IdsLogin membuat akun LPMS otomatis pada login IDS pertama (selalu non-admin). Sejak 20 Nov 2026 hanya ada satu pintu login (tanpa pilihan Pengguna/Admin, tanpa akun lokal); admin dan peran ditentukan di aplikasi (Administrasi › Pengguna) dan tidak pernah diubah oleh klaim IDS; akun yang dikunci di aplikasi ditolak saat login. Password lokal LPMS diacak dan tidak dipakai.
- Kata sandi awal bersama tidak dicatat di repo. Disarankan memaksa ganti saat login pertama di IDS.
- `andre.tigana@len.co.id` (akun baru) berbeda dari admin `andre.tigana.k@len.co.id`; pastikan peruntukannya jelas agar tidak membingungkan.
- Penempatan posisi/fungsi (`lpms3.position`, `lpms3.user_position`; saat ini kosong) ditentukan admin `andre.tigana.k@len.co.id`.
