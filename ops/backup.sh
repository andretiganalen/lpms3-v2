#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M); DST=/srv/lpms3/backup/$TS; mkdir -p "$DST"
cd /srv/lpms3/app/upstream
docker compose -p lpms3 exec -T db pg_dump -U postgres -Fc openproject > "$DST/openproject.dump"
tar -C /srv/lpms3 -czf "$DST/opdata.tgz" opdata
tar -C /srv/lpms3 -czf "$DST/lkp-raw.tgz" lkp-raw
cp .env "$DST/env.backup" && chmod 600 "$DST/env.backup"
git -C /srv/lpms3/app rev-parse HEAD > "$DST/config-commit.txt"
sha256sum "$DST"/* > "$DST/SHA256SUMS"
find /srv/lpms3/backup -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +
# StarRocks: BACKUP SNAPSHOT lpms3 ke repository NAS dijadwalkan oleh admin StarRocks (lihat Master Plan §9)
