# Kepatuhan UIx — LPMS3 (`:5100`)

- **Tanggal:** 2026-11-15 · **Rilis:** `17.9.7-lpms3.1.22`
- **Standar:** `docs/skills/uIx-len-web-apps.md` (UIx Len) dan artefak referensi UIx yang berjalan di `:8585` (`/_leno/leno.css`, `leno-menu.js`, `leno-i18n.js`). `leno.css` dibaca saja; tidak ada yang diubah di `:8585`.
- **Pemeriksa otomatis:** `bash ops/uix_lint.sh` (juga dijalankan `ops/verify.sh`).

## 1. Yang diterapkan

| Area | Penerapan |
| :-- | :-- |
| Token | `uix.css` memakai token `--uix-*`; nilai inti sama dengan `leno.css` (warna, fokus). Bayangan `xs` dan `md` disamakan dengan artefak (cincin 1px + blur). Tidak ada hex/rgb di luar `:root`, tidak ada token tak terdefinisi |
| Font | Poppins 400/500/600 dari server sendiri (woff2 di `plugin/.../assets/fonts`), tanpa bobot 700, tanpa Google Fonts |
| Sidebar | Putih, baris radius 6px, terpilih = latar abu + bobot 500 + ikon merah + penanda 3px; **Pengaturan di kiri bawah** (pola `.bottom-menu` UIx): admin ke Administrasi, pengguna lain ke Pengaturan akun |
| Header | Pemilih bahasa **ID / EN di kanan atas** (mengubah bahasa akun; hanya bahasa yang aktif di sistem) |
| Kartu, judul, tabel, tombol | Halaman LPMS3 (Organisasi & Fungsi, Modul Fitur Internal, Tampilan): kartu radius 12 + garis + bayangan `xs`, judul kartu 16/600, kepala tabel 12/600 sekunder, tombol 34px radius 8, fokus cincin 3px |
| Merek | Admin dapat mengganti **logo** dan **ikon/thumbnail (favicon + apple-touch)** serta 4 warna di Administrasi → Tampilan (in-house; halaman Design OpenProject tetap terkunci Enterprise). Warna bawaan = token UIx; nilai sama dengan bawaan tidak disimpan |
| Bahasa (aturan 3) | 213 teks yang jatuh ke bahasa Inggris pada locale `id` (menu admin, sidebar, header, daftar project, notifikasi, pengaturan, dll.) diterjemahkan ke Indonesia formal lewat `config/lpms3_id_overrides.yml` (diterapkan sesudah kamus inti dimuat). Audit: 238 → 46 kunci |
| Halaman panduan | `/panduan-internal` memakai token UIx dan Poppins (sebelumnya hex dan tautan biru) |
| Ikon berlian Enterprise | Disembunyikan (rilis 1.18) |

## 2. Daftar periksa §10

| Butir | Status | Bukti |
| :-- | :-: | :-- |
| Hanya token `--uix-*`; tanpa hex/font/radius liar | ✅ | `ops/uix_lint.sh` (CSS-hex, CSS-token, CSS-font, VIEW-hex) |
| Poppins 400/500/600 dari server sendiri | ✅ | `FONT`; terlihat pada tangkapan layar |
| Merah hanya untuk aksi utama, tautan, penanda terpilih | 🟡 | Halaman LPMS3 sesuai. Halaman bawaan OpenProject: tautan, tombol utama, dan ikon kartu admin merah (tautan/aksi); status proyek memakai warna status bawaan data |
| Elemen baru sejajar dengan saudaranya | 🟡 | Dibandingkan lewat tangkapan layar (admin, Organisasi, Modul Fitur, Tampilan, daftar project). Belum seluruh halaman |
| Fokus cincin netral 3px; status dengan kata/ikon | ✅ | Aturan `:focus-visible` global dan pada komponen baru |
| Semua teks baru ada di kamus ID dan EN; tidak bercampur | 🟡 | Teks LPMS3: ID dan EN. Sisa 46 kunci: kata yang sama di dua bahasa (Project, Status, Email, Logo, Unit, Milestone), nama produk (reCAPTCHA, Imagemagick, Jemalloc), dan 16 teks bantuan panjang berisi HTML/markdown yang tetap Inggris. Teks yang dirender Angular dan tidak berasal dari kamus Rails belum diperiksa |
| Tidak ada `null` yang tampil | 🟡 | Tidak ditemukan di halaman yang diperiksa; belum dicek seluruh data |
| Tanpa rahasia/host internal/data pribadi di berkas commit | ✅ | Kata sandi awal akun IDS tidak dicatat; `.env` root ditandai di audit BOP-001 |

## 3. Batas yang diketahui

- Hanya tema terang (sesuai UIx).
- Tangkapan layar dibuat dari HTML server-side yang diambil lewat sesi admin simulasi di proses uji, dimuat di Chrome dengan aset dari server; halaman Angular yang bergantung API (daftar paket-penugasan, Gantt, Boards) belum diperiksa secara visual. Tidak ada sesi login nyata dibuat.
- Logo/ikon di halaman login IDS (aplikasi .NET `IdsLogin`) belum membaca pengaturan Tampilan; masih memakai merek bawaannya.
- Menu **Administrator/Tim/Pengguna** ala `:8585` (OpenMetadata) belum ditiru; OpenProject sudah memiliki Pengguna dan izin, Grup, dan Peran. Menunggu keputusan bentuk yang diinginkan.
