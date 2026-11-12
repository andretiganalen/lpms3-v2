#!/usr/bin/env bash
# Membuat default_catalog.lpms3 & seluruh objek di StarRocks. Dijalankan SEKALI oleh admin saat deployment.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source deploy/.env; set +a
: "${STARROCKS_ROOT_PASSWORD:?isi sementara di deploy/.env}"
command -v mysql >/dev/null || sudo apt-get install -y mysql-client
for f in db/starrocks/000_init.sql db/starrocks/100_core_mirror.sql db/starrocks/110_lpms3_forms_mirror.sql \
         db/starrocks/200_lkp.sql db/starrocks/300_marts.sql db/starrocks/990_grants.sql; do
  echo ">> $f"
  envsubst '${STARROCKS_DATABASE} ${STARROCKS_APP_PASSWORD} ${STARROCKS_ETL_PASSWORD} ${STARROCKS_BI_PASSWORD}' < "$f" \
    | MYSQL_PWD="$STARROCKS_ROOT_PASSWORD" mysql -h "$STARROCKS_HOST" -P "$STARROCKS_PORT" -u "$STARROCKS_ROOT_USER"
done
MYSQL_PWD="$STARROCKS_APP_PASSWORD" mysql -h "$STARROCKS_HOST" -P "$STARROCKS_PORT" -u lpms3_app -e "SHOW TABLES FROM default_catalog.$STARROCKS_DATABASE" | wc -l
echo "Selesai. Kosongkan STARROCKS_ROOT_PASSWORD di deploy/.env."
