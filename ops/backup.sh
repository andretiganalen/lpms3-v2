#!/usr/bin/env bash
# Backup OpenProject: dump PostgreSQL + opdata + lkp-raw + env. Retensi 14 hari.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TS=$(date +%Y%m%d-%H%M); DST="$ROOT/data/backup/$TS"; mkdir -p "$DST"
cd "$ROOT/upstream"
docker compose -p lpms3 exec -T db pg_dump -U postgres -Fc openproject > "$DST/openproject.dump"
tar -C "$ROOT/data" -czf "$DST/opdata.tgz" opdata
tar -C "$ROOT/data" -czf "$DST/lkp-raw.tgz" lkp-raw
sudo -n tar -C "$ROOT/data" -czf "$DST/idslogin-keys.tgz" idslogin-keys
cp "$ROOT/deploy/.env" "$DST/env.backup" && chmod 600 "$DST/env.backup"
git -C "$ROOT" rev-parse HEAD > "$DST/config-commit.txt"
(cd "$DST" && sha256sum * > SHA256SUMS)
find "$ROOT/data/backup" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +
# StarRocks: BACKUP SNAPSHOT dijadwalkan oleh admin StarRocks (lihat Master Plan §9)
