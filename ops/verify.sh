#!/usr/bin/env bash
# Verifikasi pascadeploy :5100 (dipakai DEPLOY_SOP langkah 4). Hanya menyentuh stack lpms3v2.
set -uo pipefail
cd "$(dirname "$0")/.."
echo "== container =="; docker ps --format '{{.Names}} {{.Image}} {{.Status}}' | grep '^lpms3v2-'
echo "== audit rails runner =="
docker cp ops/audit_mod08.rb lpms3v2-web-1:/tmp/audit_mod08.rb
docker exec lpms3v2-web-1 bundle exec rails runner /tmp/audit_mod08.rb 2>&1 | grep -E '^(PASS|FAIL|RINGKASAN|EXT_BY)'
echo "== proxy :5100 =="
H='Host: 192.168.125.14:5100'
for u in / /ids/login /login /panduan-internal /admin/enterprise_trial /admin/enterprise_tokens/save_trial_key; do
  printf '%s -> %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -X GET localhost:5100$u)"
done
echo "== smoke D10 =="; bash lpms3/smoke/run.sh 2>&1 | grep -E '^(FAIL|RINGKASAN)'
echo "== audit BOP-001 =="; bash ops/audit_bop001.sh 2>&1 | grep -E '^(FAIL|RINGKASAN)'
echo "== monitor =="; bash ops/monitor.sh 2>&1 | tail -5; echo "(kosong = semua OK)"
