# CHANGELOG
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
