#!/usr/bin/env bash
# Pemeriksaan alur kerja 5 fase BOP-001 di container web. Membuat lalu menghapus proyek uji "smoke-fase-proyek".
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/upstream"
docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" < "$ROOT/lpms3/smoke/fase_walkthrough.rb" 2>&1 | grep -v -i "warn" | grep -vE "^[IE], \["
