#!/usr/bin/env bash
# Uji pergantian bahasa ID/EN. Membuat lalu menghapus proyek uji "smoke-lang-proyek".
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/upstream"
docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" < "$ROOT/lpms3/smoke/lang_switch.rb" 2>&1 | grep -v -i "warn" | grep -vE "^[IE], \[|^\s+from "
