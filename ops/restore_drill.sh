#!/usr/bin/env bash
# Restore drill NON-DESTRUKTIF: pulihkan backup PG terbaru (atau $1) ke container sementara, bandingkan dengan DB live, lalu hapus.
# Tidak menyentuh database produksi. Pemakaian: ops/restore_drill.sh [data/backup/<ts>]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
B="${1:-$(ls -d "$ROOT"/data/backup/2*/ | tail -1)}"; B="${B%/}"
N=lpms3-restore-drill
trap 'docker rm -f $N >/dev/null 2>&1 || true' EXIT
(cd "$B" && sha256sum -c SHA256SUMS)
T0=$(date +%s); docker rm -f $N >/dev/null 2>&1 || true
docker run -d --name $N -e POSTGRES_PASSWORD=drill postgres:17 >/dev/null
until docker exec $N pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done; sleep 2
docker exec $N createdb -U postgres openproject
docker exec -i $N pg_restore -U postgres -d openproject --no-owner < "$B/openproject.dump"
echo "waktu restore: $(( $(date +%s)-T0 )) detik"
Q="select (select count(*) from projects),(select count(*) from work_packages),(select count(*) from users),(select count(*) from workflows),(select count(*) from lpms3_form.form_definition),(select count(*) from lpms3.org_unit),(select count(*) from lpms3.ref_rasci),(select count(*) from custom_fields)"
L=$(docker exec lpms3v2-db-1 psql -U postgres -d openproject -Atc "$Q"); R=$(docker exec $N psql -U postgres -d openproject -Atc "$Q")
echo "proyek|wp|user|workflow|form|org_unit|rasci|cf"; echo "LIVE   : $L"; echo "RESTORE: $R"
tar -tzf "$B/opdata.tgz" >/dev/null && tar -tzf "$B/lkp-raw.tgz" >/dev/null && echo "arsip opdata & lkp-raw utuh"
[ "$L" = "$R" ] && echo "DRILL OK (selisih dapat terjadi bila ada perubahan sejak backup)" || echo "DRILL: jumlah berbeda — periksa apakah ada perubahan sejak backup"
