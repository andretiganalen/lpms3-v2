# CHANGELOG
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
