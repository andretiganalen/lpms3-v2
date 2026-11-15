# SOP Deploy LPMS3 (:5100 saja)

1. Backup: `bash ops/backup.sh` (dump DB + env, checksum SHA256 di `data/backup/<tanggal>`).
2. Ubah `LPMS3_IMAGE_TAG` di `deploy/.env`.
3. Build + restart: `bash ops/compose_up.sh`. Isinya: `ops/build_image.sh` (`docker build -f deploy/Dockerfile -t lpms3/openproject:<tag> .`), `docker compose -p lpms3v2 build idslogin`, `docker compose -p lpms3v2 up -d`. Idempoten.
4. Verifikasi: `docker ps` (semua container lpms3v2-* Up), smoke test (target PASS=22 FAIL=0), cek halaman login IDS di :5100.
5. Rollback: kembalikan `LPMS3_IMAGE_TAG` ke tag sebelumnya, jalankan ulang `ops/compose_up.sh`; pulihkan DB dengan `ops/restore_drill.sh` bila perlu.
6. Catat rilis di `CHANGELOG.md`.
Jangan menyentuh v1/:5000.
