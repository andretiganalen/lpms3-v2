# Runbook Admin — LPMS3 v2

Akses: http://192.168.125.14:5100 · Folder repo: `~/lpms3-v2` · Docker project: `lpms3`

## 1. Arsitektur singkat
- **Caddy (proxy)** memegang port 5100: landing IdsLogin di depan, OpenProject di belakang.
- **IdsLogin** (.NET): login User/Admin via IDS OIDC, lalu *bridge* membuat/memakai akun OpenProject (via API key `lpms3-bridge`).
- **OpenProject 17** (web, worker, cron, hocuspocus, cache, db PostgreSQL 17).
- **StarRocks** `192.168.123.13:9030`, database `medallion_lpms` (eksternal, bukan container).
- Catatan: login SSO bawaan OpenProject butuh Enterprise Edition, jadi IDS dijalankan lewat IdsLogin + bridge.

## 2. Lokasi penting
| Item | Path |
|---|---|
| Konfigurasi/env | `deploy/.env` (rahasia, jangan di-commit) |
| Compose override | `deploy/docker-compose.stock.yml` |
| Secret lokal | `deploy/secrets/` (`bridge.key`, `openproject-admin.txt`) |
| Data PostgreSQL | `data/pgdata` |
| Aset OpenProject | `data/opdata` |
| File mentah LKP | `data/lkp-raw` |
| Backup | `data/backup/<timestamp>/` |

## 3. Operasi harian
```bash
cd ~/lpms3-v2
ops/compose_up.sh                         # deploy/restart idempoten (aman diulang)
cd upstream && docker compose -p lpms3v2 ps # status
docker compose -p lpms3v2 logs -f --tail=100 idslogin   # atau web, proxy, db
docker compose -p lpms3v2 restart idslogin  # restart satu layanan
```
Selalu pakai `-p lpms3v2`. Menjalankan compose tanpa `-p lpms3v2` membuat project ganda (`upstream-*`) pada volume yang sama.

Health check cepat: `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5100/` (harus 200).

## 4. Backup & restore
- Otomatis: cron harian 02:00 menjalankan `ops/backup.sh` (log: `data/backup/backup.log`), retensi 14 hari.
- Manual: `bash ops/backup.sh`. Isi: `openproject.dump`, `opdata.tgz`, `lkp-raw.tgz`, `env.backup`, `config-commit.txt`, `SHA256SUMS`.
- StarRocks: BACKUP SNAPSHOT dikelola admin StarRocks.
- Verifikasi: `cd data/backup/<ts> && sha256sum -c SHA256SUMS`.

Restore database (downtime singkat):
```bash
cd ~/lpms3-v2/upstream
docker compose -p lpms3v2 stop web worker cron hocuspocus
docker compose -p lpms3v2 exec -T db dropdb -U postgres openproject
docker compose -p lpms3v2 exec -T db createdb -U postgres openproject
docker compose -p lpms3v2 exec -T db pg_restore -U postgres -d openproject < ../data/backup/<ts>/openproject.dump
tar -C ../data -xzf ../data/backup/<ts>/opdata.tgz     # bila aset ikut dipulihkan
docker compose -p lpms3v2 start web worker cron hocuspocus
```
Latih restore di lingkungan uji sebelum dibutuhkan saat insiden.

## 5. Akun & login
- **User biasa**: tombol Login User di landing, autentikasi IDS, akun OpenProject dibuat otomatis oleh bridge.
- **Admin**: Login Admin via IDS, hanya untuk role di `IDS_ADMIN_ROLES` (default `admin,administrator`) atau email di `IDS_ADMIN_EMAILS` (pisah koma); ubah di `deploy/.env`.
- **Admin lokal OpenProject / akun bridge**: kredensial ada di `deploy/secrets/`. Akun `lpms3-bridge` adalah admin layanan, jangan dihapus atau dinonaktifkan.
- Rotasi API key bridge: buat key baru di akun `lpms3-bridge` (OpenProject → My account → Access tokens), simpan ke `LPMS3_BRIDGE_API_KEY` di `deploy/.env` dan `deploy/secrets/bridge.key`, lalu `ops/compose_up.sh`.
- Rails runner di image ini (Rails 8.1/Ruby 4.0) bisa gagal; kebijakan password OpenProject berlaku untuk akun yang dibuat manual.

## 6. Troubleshooting
| Gejala | Penyebab/tindakan |
|---|---|
| Semua halaman HTTP 400 "Invalid host_name" | `OPENPROJECT_HOST__NAME` di `.env` harus `192.168.125.14:5100`; jalankan `ops/compose_up.sh`. |
| `/ids/*` 404 dari proxy | IdsLogin tidak ada di project `lpms3` (mungkin jalan di project lain). Cek `docker ps`, jalankan ulang lewat `compose_up.sh`. |
| `seeder` restart terus / web tidak sehat | Password di `DATABASE_URL` tidak sama dengan password PostgreSQL. Samakan di `deploy/.env` lalu `ops/compose_up.sh`. Seeder normalnya exit setelah selesai. |
| Login IDS gagal | Cek `logs idslogin`; pastikan `IDS_CLIENT_ID/SECRET` benar dan `dev-ids-intern.len.co.id` terjangkau dari VM. |
| Bridge HTTP 400/401 | API key salah/kedaluwarsa, atau host_name salah (lihat atas). |
| Koneksi StarRocks gagal | Uji `mysql -h 192.168.123.13 -P 9030 -u root`; cek `STARROCKS_*` di `.env`. Gunakan `replication_num=1`. |
| `/ids/enter` HTTP 500, log `OP-LOGIN ... location=.../two_factor_authentication/request cookies=0` | 2FA OpenProject aktif. Dinonaktifkan (`disabled=true` pada `plugin_openproject_two_factor_authentication`) karena login sudah diautentikasi IDS. Bila terulang, set ulang lewat `rails runner`. |
| Login OpenProject HTTP 429 "Too many login attempts" | Ban per-username 30 menit bila >20 POST `/login` per menit. Jangan uji berulang cepat; hapus ban dengan menghapus key `rack::attack:allow2ban:ban:login:<email>`. |
| `Unprotect ticket failed` | Kunci data-protection IdsLogin kini dipersist di `data/idslogin-keys` (sesi bertahan setelah restart). Bila folder itu dihapus, hapus cookie / pakai incognito. Sesi lama sebelum 2026-11-13 harus login ulang sekali. |
| Container mati sendiri | `autoheal` me-restart yang unhealthy; lihat `docker logs` sebelum restart manual berulang. |

## 7. Aturan keamanan
- `deploy/.env` dan `deploy/secrets/` jangan di-commit, jangan ditempel di chat/tiket.
- Jangan menampilkan isi `.env` mentah di terminal bersama (berisi `DATABASE_URL` dengan password).
- Ganti password PostgreSQL dan secret IDS bila pernah terpapar; ubah di `.env` dan di database, lalu deploy ulang.
- VM ini juga menjalankan aplikasi lain; jangan `docker system prune` atau `docker compose down -v` tanpa `-p lpms3v2` dan pengecekan.

## 8. Hal yang belum selesai
- Login IDS end-to-end (User dan Admin) sudah terverifikasi di browser pada 2026-11-13.
- `/srv/lpms3` lama sudah dihapus (2026-11-13).
- Project compose sudah dipisah dari v1: `lpms3v2` (2026-11-13).
- Deployment D0–D6 selesai & terverifikasi (2026-11-13): health check PASSED, StarRocks `lpms3` ±83 objek, `form_definition` = 18, `STARROCKS_ROOT_PASSWORD` sudah dikosongkan, backup harian 02:00 aktif.
- D8 data organisasi dimuat dari Nota 021 (`db/040_lpms3_org_nota021.sql`, dijalankan oleh `ops/pg_apply.sh`): 66 unit (5 direktorat, 18 divisi, 43 bagian), 81 pemetaan fungsi→unit. Jenjang diasumsikan Direktorat=DIREKSI, Divisi=ES1, Bagian=ES2 (menunggu SKEP 001/2026). Posisi dan user belum dimuat (menunggu data HC).
- D7 seed LPMS3 (parsial) via `lpms3/seed/run.sh` (idempoten, dijalankan 2×): 55 status, 16 peran proyek, 16 tipe WP, 982 workflow (CR per peran §5.5). Workflow di OP 17 memakai `type_variant_id`. Custom field (`40_custom_fields.rb`): 19 atribut proyek dalam 5 section, 76 field WP termasuk Supporting (S)/Consulted (C) untuk 16 tipe (idempoten, dijalankan 2×). Lifecycle (`60_lifecycle.rb`): 4 fase P1–P4 dengan gate penutup G1–G4 (memakai 4 definisi bawaan OP, diganti nama). Template (`70_templates.rb`): 3 template proyek (Prediktif, Hibrid, Purnajual), 31 grup fungsi, 35 WP aktivitas BOP-001 dengan RASCI (`lpms3/templates/rasci.yml`, juga di `lpms3.ref_rasci`, `db/050`), 9 Dokumen Rencana, 4 milestone gate, 14 query, 5 halaman wiki. Belum: meeting template, pengisian S/C sebagai field user, penataan form tipe.
- D9 selesai (2026-11-14): trigger outbox `db/060` + layanan `lpms3-data` (`etl/`, container `lpms3v2-lpms3-data-1`) menyinkronkan PG→StarRocks (`medallion_lpms`, host 192.168.123.13). Proyek uji muncul di mirror dalam 3 detik; update dan delete juga tersinkron; outbox 0 tertunda. Nama database StarRocks sebenarnya `medallion_lpms` (bukan `lpms3`). Kolom `jenis_kode`, `kelas_kontrak`, `lini_bisnis`, `current_phase` masih NULL (belum ada sumber).
- Belum: D10 smoke test, restore drill backup, D12 go-live.
