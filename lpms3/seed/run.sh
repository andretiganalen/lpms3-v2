#!/usr/bin/env bash
# Jalankan seed LPMS3 (idempoten) di container web. Pemakaian: lpms3/seed/run.sh [file.rb ...]
set -euo pipefail
cd "$(dirname "$0")/../.."
files=("$@"); [ ${#files[@]} -gt 0 ] || files=(lpms3/seed/[1-9]0_*.rb)
for f in "${files[@]}"; do
  echo ">> $f"
  cat lpms3/seed/00_data.rb <(grep -v '^require_relative' "$f") \
    | (cd upstream && docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" 2>&1) | grep -v -i "warn" || true
done
