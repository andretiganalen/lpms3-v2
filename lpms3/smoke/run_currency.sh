#!/usr/bin/env bash
# Uji menu Mata Uang & Kurs. Membuat lalu menghapus akun dan kurs uji.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/upstream"
docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" < "$ROOT/lpms3/smoke/currency.rb" 2>&1 | grep -v -i "warn" | grep -vE "^[IE], \["
