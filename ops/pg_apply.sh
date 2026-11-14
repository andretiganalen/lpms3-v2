#!/usr/bin/env bash
# Menerapkan schema lpms3 & lpms3_form ke database OpenProject (idempoten).
set -euo pipefail
cd "$(dirname "$0")/.."
for f in db/010_lpms3_forms.sql db/020_lpms3_core.sql db/030_lpms3_seed_ref.sql db/040_lpms3_org_nota021.sql db/050_lpms3_rasci.sql db/060_lpms3_sync_triggers.sql; do
  echo ">> $f"
  docker exec -i lpms3v2-db-1 psql -U postgres -d openproject -v ON_ERROR_STOP=1 -q < "$f"
done
docker exec -i lpms3v2-db-1 psql -U postgres -d openproject -Atc "select count(*) from lpms3_form.form_definition"
