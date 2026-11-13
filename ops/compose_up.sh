#!/usr/bin/env bash
# Satu-satunya entrypoint deploy. Idempoten: aman dijalankan ulang setiap ada perubahan.
# Semua (kode, config, data, secret, backup) berada di dalam folder repo ini.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
[ -f deploy/.env ] || { echo "deploy/.env belum ada (salin dari deploy/.env.example)"; exit 1; }
mkdir -p data/{pgdata,opdata,lkp-raw,backup} deploy/secrets
[ -d upstream ] || git clone --depth=1 --branch=stable/17 https://github.com/opf/openproject-docker-compose.git upstream
cp deploy/.env upstream/.env && chmod 600 upstream/.env
ln -sf ../deploy/docker-compose.stock.yml upstream/docker-compose.override.yml
cd upstream
docker compose -p lpms3 config 2>&1 | grep -q 'variable is not set' && { echo "Ada variabel .env yang kosong"; exit 1; } || true
docker compose -p lpms3 build idslogin
docker compose -p lpms3 up -d
