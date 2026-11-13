# openproject-lpms3 (plugin)

Kerangka dan spesifikasi: `docs/plan/10_Spesifikasi_Teknis_v1.3.md` §12 (sidebar), §13 (LKP/approval), §14 (kapabilitas) dan `docs/plan/00_LPMS3_Master_Plan.md` §3–§7.

## Status (S1 - kerangka)
| Bagian | Status |
|---|---|
| Tema UIx (token, Poppins 400/500/600 dari server sendiri, warna desain OpenProject diselaraskan) | Dasar selesai; sidebar/kartu bawaan OpenProject belum disesuaikan penuh |
| Settings › Organisasi & Fungsi (`/admin/lpms3/organisasi`, khusus admin) | Selesai, baca-saja (data Nota 021) |
| Sidebar LPMS3 (§12.2), kapabilitas (§14), LKP (§13) | Belum |

## Cara kerja
- Plugin dimuat lewat `deploy/Gemfile.plugins`; `deploy/patch_gemfile_lock.rb` mendaftarkannya ke `Gemfile.lock` image tanpa `bundle install` (image slim tidak punya git).
- CSS/font dilayani `Lpms3::AssetsController` dari `assets/` (daftar putih berkas, URL ber-digest, publik karena dipakai halaman login) dan disuntik ke `<head>` lewat hook `view_layouts_base_html_head`.
- Model (`app/models/lpms3`) membaca skema `lpms3` (`db/020`, `db/040`) dan bersifat baca-saja.
- Teks UI ada di `config/locales/id.yml` dan `en.yml` (kunci harus sama persis).

## Build & deploy
```bash
bash ops/build_image.sh                              # image lpms3/openproject:local
cd upstream && docker compose -p lpms3v2 up -d --no-deps web worker cron
```
`web` restart sekitar 1–2 menit.
