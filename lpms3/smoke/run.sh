#!/usr/bin/env bash
# Smoke test D10 di container web. Membuat lalu menghapus proyek uji "smoke-d10-proyek".
set -euo pipefail
cd "$(dirname "$0")/../.."
cat lpms3/seed/00_data.rb <(grep -v '^require_relative' lpms3/smoke/d10_smoke.rb) \
  | (cd upstream && docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" 2>&1) | grep -v -i "warn"
