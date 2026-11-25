# Laporan Audit Verifikasi — LPMS3 `:5100` (MOD-08)

- **Tanggal:** 2026-11-15
- **Rilis yang diaudit:** `17.9.7-lpms3.1.15` (branch `feat/inhouse-enterprise-hardening`)
- **Metode:** `bundle exec rails runner` di container `lpms3v2-web-1` (skrip uji sementara, tidak disimpan di repo). Permintaan HTTP dijalankan lewat `ActionDispatch::Integration::Session` dengan pengguna admin yang disimulasikan hanya di proses uji (tidak ada perubahan autentikasi di aplikasi).
- **Pendekatan:** fitur dikembangkan in-house; `EnterpriseToken` tidak diubah (Community Edition). Lihat revisi MOD-02/MOD-03 di `openproject_custom_plan.md`.

## Ringkasan

**34 dari 35 pemeriksaan LULUS; 1 temuan sisa (tidak kritis, di bawah).**

## Temuan selama audit (sudah diperbaiki)

| # | Temuan | Penyebab | Perbaikan |
|---|---|---|---|
| 1 | **Seluruh halaman Administration HTTP 500** (sejak rilis 1.8, MOD-03) | Ikon menu `settings` tidak ada di set Octicon | Ikon diganti `gear` (rilis 1.14). Cacat dari saya sendiri; tidak terdeteksi sebelumnya karena tidak ada uji halaman admin dengan sesi. |
| 2 | Teks sambutan Homescreen memuat 7 tautan pemasaran ke `openproject.org` | Data setting `welcome_text` bawaan | Diganti teks internal lewat seed `80_settings.rb` (rilis 1.15) |
| 3 | Tautan `<noscript>` ke `enable-javascript.com` di setiap halaman | Layout inti `base.html.erb` | Dihapus lewat `deploy/patch_mod07.rb` (rilis 1.15) |

## Hasil pemeriksaan (keluaran skrip uji)

```
PASS | setting default/kosong | []
PASS | setting tersimpan & tersaring katalog | [:board_view, :team_planner_view]
PASS | ON tapi belum diimplementasikan => enabled? false | 
PASS | ON + implemented => true | 
PASS | OFF => false | 
PASS | ON kembali => true | 
PASS | setting dipulihkan | 
PASS | katalog 35 (30 utama + 5 kompat.) | 
PASS | kunci katalog == Features::KEYS | 
PASS | semua kolom terisi | 
PASS | EnterpriseToken tidak diubah (allows_to? false utk 35 fitur) | 
PASS | GET / bukan 5xx | 200
PASS | GET /admin bukan 5xx | 200
PASS | GET /admin/info bukan 5xx | 200
PASS | GET /admin/enterprise bukan 5xx | 301
PASS | GET /admin/lpms3/organisasi bukan 5xx | 200
PASS | GET /admin/lpms3/internal_features bukan 5xx | 200
PASS | GET /projects bukan 5xx | 200
PASS | GET /my/page bukan 5xx | 200
PASS | GET /admin/settings/general bukan 5xx | 200
PASS | PATCH saklar (CSRF aktif di test? status) | 422
EXT_BY_PAGE [["/admin/info", ["github.com"]]]
FAIL | halaman tanpa host eksternal | ["github.com"]
PASS | tanpa gravatar | 
PASS | halaman fitur memuat 35 kunci | 
PASS | Gravatar nonaktif | 
PASS | security badge nonaktif | 
PASS | blok homescreen vendor dibuang | 
PASS | CSS sembunyikan banner Enterprise | 
PASS | CSP tanpa domain vendor | 
PASS | static_links tanpa openproject.org/.com | 
PASS | app_title = LPMS3 | LPMS3
PASS | IDS-only: self_registration 0, login_required | 
PASS | /app/LICENSE ada | 35147
PASS | /app/COPYRIGHT ada | 2438
PASS | /app/COPYRIGHT_short ada | 1141
RINGKASAN: 34 PASS, 1 FAIL dari 35
```

## Temuan sisa

- Halaman **Administration → Information** memuat tautan `https://github.com/opf/openproject/commits/v17.9.7` pada nomor versi. Hanya tautan yang diklik pengguna; tidak ada permintaan otomatis. Belum dipatch. Pemeriksaan "halaman tanpa host eksternal" karena itu bernilai FAIL.

## Cakupan dan batas audit

- **Saklar On/Off:** diuji pada `Setting.internal_enabled_features` (simpan, saring ke katalog, ON/OFF/ON, pemulihan). Karena belum ada fitur in-house yang selesai (`IMPLEMENTED` kosong), perilaku "ON + implemented" diuji dengan simulasi sementara di proses uji, bukan fitur nyata.
- **"35 fitur bebas Error 500":** berarti halaman katalog `/admin/lpms3/internal_features` (memuat 35 kunci) dan halaman admin lain bukan 5xx. Fitur Enterprise bawaan LPMS tetap terkunci dan tidak diuji karena memang tidak diaktifkan.
- **Gravatar:** `gravatar_enabled? == false` dan tidak ada string `gravatar` di halaman yang diuji. **Banner:** blok homescreen vendor dibuang dan CSS penyembunyi banner terpasang; elemen banner masih ada di DOM, hanya disembunyikan (tampilan tidak diperiksa di browser).
- **PATCH saklar via UI:** hanya diuji sampai penolakan CSRF (422); simpan lewat browser dengan token sah belum diuji.
- **Email:** isi dan tautan diperiksa pada MOD-07; pengiriman belum diuji (SMTP belum ada).
- **File lisensi:** `LICENSE`, `COPYRIGHT`, `COPYRIGHT_short` ada di root repo dan di image; checksum SHA-256 identik:

```
LICENSE repo=8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903 image=8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903 SAMA
COPYRIGHT repo=8b052a5b9fb2c3a9bfbe9ef7d71a97f542a702a0d64b3198a725f276e460f7e8 image=8b052a5b9fb2c3a9bfbe9ef7d71a97f542a702a0d64b3198a725f276e460f7e8 SAMA
COPYRIGHT_short repo=b8cf52fa8ca00d47fe2f223f4435c6de324b9f8db6fed82ef48bf94f4a7484f4 image=b8cf52fa8ca00d47fe2f223f4435c6de324b9f8db6fed82ef48bf94f4a7484f4 SAMA
```

`docs/plan/LEGAL_NOTICES.md` tersedia.

## Item terbuka di luar MOD-08

SMTP internal (host/port/kredensial), halaman `/panduan-internal`, keputusan `DROP_OLD_SESSIONS_ON_LOGOUT` (kini `false` sesuai plan, bawaan LPMS `true`), 2FA/monitoring/UAT (checklist D12), dan penghapusan tampilan fitur Enterprise terkunci (MOD-03 langkah 8).
