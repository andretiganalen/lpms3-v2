#!/usr/bin/env bash
# Clone upstream OpenProject compose (stable/17), pasang override LPMS3, build & start.
set -euo pipefail
APP=/srv/lpms3/app; cd "$APP"
[ -d upstream ] || git clone --depth=1 --branch=stable/17 https://github.com/opf/openproject-docker-compose.git upstream
cp deploy/.env upstream/.env && chmod 600 upstream/.env
ln -sf ../deploy/docker-compose.override.yml upstream/docker-compose.override.yml
cd upstream
docker compose config | grep -q "p4ssw0rd" && { echo "Password DB default masih ada!"; exit 1; } || true
docker compose -p lpms3 build web lpms3-data
docker compose -p lpms3 up -d
