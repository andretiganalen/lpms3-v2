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
cd upstream && docker compose -p lpms3 ps # status
docker compose -p lpms3 logs -f --tail=100 idslogin   # atau web, proxy, db
docker compose -p lpms3 restart idslogin  # restart satu layanan
```
Selalu pakai `-p lpms3`. Menjalankan compose tanpa `-p lpms3` membuat project ganda (`upstream-*`) pada volume yang sama.

Health check cepat: `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5100/` (harus 200).

## 4. Backup & restore
- Otomatis: cron harian 02:00 menjalankan `ops/backup.sh` (log: `data/backup/backup.log`), retensi 14 hari.
- Manual: `bash ops/backup.sh`. Isi: `openproject.dump`, `opdata.tgz`, `lkp-raw.tgz`, `env.backup`, `config-commit.txt`, `SHA256SUMS`.
- StarRocks: BACKUP SNAPSHOT dikelola admin StarRocks.
- Verifikasi: `cd data/backup/<ts> && sha256sum -c SHA256SUMS`.

Restore database (downtime singkat):
```bash
cd ~/lpms3-v2/upstream
docker compose -p lpms3 stop web worker cron hocuspocus
docker compose -p lpms3 exec -T db dropdb -U postgres openproject
docker compose -p lpms3 exec -T db createdb -U postgres openproject
docker compose -p lpms3 exec -T db pg_restore -U postgres -d openproject < ../data/backup/<ts>/openproject.dump
tar -C ../data -xzf ../data/backup/<ts>/opdata.tgz     # bila aset ikut dipulihkan
docker compose -p lpms3 start web worker cron hocuspocus
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
- VM ini juga menjalankan aplikasi lain; jangan `docker system prune` atau `docker compose down -v` tanpa `-p lpms3` dan pengecekan.

## 8. Hal yang belum selesai
- Login IDS end-to-end (User dan Admin) sudah terverifikasi di browser pada 2026-11-13.
- Pembersihan `/srv/lpms3` lama (152 MB, tidak dipakai container mana pun) menunggu konfirmasi.
- Push ke GitLab `devops/lpms3-v2` ditolak (token tanpa izin Code: Download); GitHub sudah sinkron.
- Stack pernah mati dua kali tanpa sebab jelas; project compose `lpms3` sama dengan stack v1 (`lpms3-ui`, `lpms3-api`). Pertimbangkan nama project terpisah.
