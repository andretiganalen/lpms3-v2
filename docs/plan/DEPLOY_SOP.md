# SOP Deploy LPMS3 (:5100 saja)

Cakupan: stack compose `lpms3v2` (:5100). Jangan menyentuh v1/:5000, `lpms3-ui`, `lpms3-api`, `lendatagovernance-*`.

1. **Backup:** `bash ops/backup.sh` (dump DB + env + checksum SHA-256 di `data/backup/<tanggal>`).
2. **Naikkan tag:** ubah `LPMS3_IMAGE_TAG` di `deploy/.env` dan `deploy/.env.example` (mis. `17.9.7-lpms3.1.N`).
3. **Build + restart:** `bash ops/compose_up.sh` (`ops/build_image.sh` → `docker build -f deploy/Dockerfile -t lpms3/openproject:<tag> .`; `docker compose -p lpms3v2 build idslogin`; `docker compose -p lpms3v2 up -d`). Idempoten. Build **gagal sengaja** bila pola source OpenProject yang dipatch (`deploy/patch_mod06.rb`, `deploy/patch_mod07.rb`, `RUN sed` di Dockerfile) tidak ditemukan.
4. **Bila Caddyfile atau `deploy/panduan/` berubah:** `docker restart lpms3v2-proxy-1` (proxy tidak otomatis memuat ulang konfigurasi).
5. **Tunggu sehat:** `docker inspect -f '{{.State.Health.Status}}' lpms3v2-web-1` = `healthy`.
6. **Seed pengaturan (bila `lpms3/seed/80_settings.rb` berubah):** `bash lpms3/seed/run.sh lpms3/seed/80_settings.rb`.
7. **Verifikasi:** `bash ops/verify.sh` (audit aplikasi, proxy, smoke, audit BOP-001, monitor) → audit `FAIL=0`, kode proxy sesuai (`/` 200, `/ids/login` 302, `/login` 302, `/panduan-internal` 200, jalur trial 404), smoke `PASS=22 FAIL=0`.
8. **Rollback:** kembalikan `LPMS3_IMAGE_TAG` ke tag sebelumnya, jalankan ulang `bash ops/compose_up.sh`; pulihkan DB dengan `ops/restore_drill.sh` bila perlu.
9. **Catat** rilis di `CHANGELOG.md`, lalu commit dan push.

Catatan: akses `curl localhost:5100` perlu header `Host: 192.168.125.14:5100` (host lain dijawab 400).

## Operasional rutin
- **Monitoring:** `ops/monitor.sh` berjalan lewat cron tiap 5 menit (`crontab -l`); alert tercatat di `data/monitor/alerts.log`, jalankan manual `bash ops/monitor.sh -v`. Melepas: hapus barisnya dari `crontab -e`.
- **Kepatuhan BOP-001:** `bash ops/audit_bop001.sh`; hasil dan kesenjangan di `docs/COMPLIANCE-BOP001.md`. Baris `FAIL` wajib ditangani; `GAP` = belum terwujud (diketahui).
