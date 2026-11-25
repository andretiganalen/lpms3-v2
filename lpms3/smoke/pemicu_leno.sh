#!/usr/bin/env bash
# Smoke test API pemicu LenO (rilis 1.35) lewat proxy :5100. Data uji (kode UJI-SMOKE-*) dihapus di akhir.
# Pemakaian: lpms3/smoke/pemicu_leno.sh [base_url]   (bawaan http://$OPENPROJECT_HOST__NAME dari deploy/.env;
# LPMS menolak host lain, termasuk localhost)
# Uji batas laju dijalankan terakhir karena mengunci alamat ini selama satu menit.
set -uo pipefail
cd "$(dirname "$0")/../.."
BASE="${1:-http://$(grep -m1 '^OPENPROJECT_HOST__NAME=' deploy/.env | cut -d= -f2-)}"
URL="$BASE/lpms3/api/pemicu-proyek"
KEY="$(grep -m1 '^LPMS3_LENO_KEYS=' deploy/.env | cut -d= -f2- | cut -d, -f1)"
[ ${#KEY} -ge 32 ] || { echo "LPMS3_LENO_KEYS di deploy/.env kosong"; exit 1; }
SFX="$(date +%s)"; K1="UJI-SMOKE-$SFX"; K2="UJI-SMOKE-$SFX-B"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then echo "PASS  $1"; PASS=$((PASS+1)); else echo "FAIL  $1 — harap $3, dapat $2 ${4:-}"; FAIL=$((FAIL+1)); fi; }
post() { curl -s -o /tmp/pemicu_body.$$ -w '%{http_code}' -X POST "$URL" -H 'Content-Type: application/json' "$@"; }
body() { cat /tmp/pemicu_body.$$; }
run_rails() { (cd upstream && docker compose -p lpms3v2 exec -T web bash -lc "cd /app && bin/rails runner -" 2>&1) | grep -v -iE "warn|INFO --"; }
cleanup() {
  echo "ids = Lpms3::ProjectTrigger.where('kode_proyek LIKE ?', 'UJI-SMOKE-%').pluck(:id)
Lpms3::ProjectTriggerEvent.where(project_trigger_id: ids).delete_all
puts \"bersih: #{Lpms3::ProjectTrigger.where(id: ids).delete_all} pemicu uji\"" | run_rails
  rm -f /tmp/pemicu_body.$$
}
trap cleanup EXIT

chk "tanpa kunci → 401" "$(post -d "{\"id_kiriman\":\"a\",\"kode_proyek\":\"$K1\"}")" 401
chk "kunci salah → 401" "$(post -H "X-Lpms3-Key: ${KEY}x" -d "{\"id_kiriman\":\"a\",\"kode_proyek\":\"$K1\"}")" 401
chk "JSON rusak → 400" "$(post -H "X-Lpms3-Key: $KEY" -d '{bukan json')" 400
chk "kode_proyek kosong → 400" "$(post -H "X-Lpms3-Key: $KEY" -d '{"id_kiriman":"a"}')" 400
chk "tanggal nota salah → 400" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"a\",\"kode_proyek\":\"$K1\",\"nota\":{\"tanggal\":\"23/11/2026\"}}")" 400
BIG="$(head -c 17000 /dev/zero | tr '\0' 'a')"
chk "body > 16 KB → 413" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"a\",\"kode_proyek\":\"$K1\",\"x\":\"$BIG\"}")" 413

chk "kiriman pertama → 202" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"k1\",\"kode_proyek\":\"${K1,,}\",\"lpms2_proyek_id\":77,\"nota\":{\"nomor\":\"N-1\",\"tanggal\":\"2026-11-23\"}}")" 202
chk "kode dinormalkan ke huruf besar" "$(body | python3 -c 'import sys,json;print(json.load(sys.stdin)["kode_proyek"])')" "$K1"
chk "id_kiriman sama diulang → 202" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"k1\",\"kode_proyek\":\"$K1\"}")" 202
chk "kiriman ulang id baru → 202" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"k2\",\"kode_proyek\":\"$K1\",\"lpms2_proyek_id\":77}")" 202
chk "jumlah_kiriman = 2 (duplikat tidak dihitung)" "$(body | python3 -c 'import sys,json;print(json.load(sys.stdin)["jumlah_kiriman"])')" 2
chk "lpms2_proyek_id berbeda → 409" "$(post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"k3\",\"kode_proyek\":\"$K1\",\"lpms2_proyek_id\":78}")" 409

code=$(curl -s -o /tmp/pemicu_body.$$ -w '%{http_code}' -H "X-Lpms3-Key: $KEY" "$URL/$K1")
chk "GET status → 200" "$code" 200
chk "status = diterima" "$(body | python3 -c 'import sys,json;print(json.load(sys.stdin)["status"])')" diterima
chk "GET tanpa kunci → 401" "$(curl -s -o /dev/null -w '%{http_code}' "$URL/$K1")" 401
chk "GET kode tak dikenal → 404" "$(curl -s -o /dev/null -w '%{http_code}' -H "X-Lpms3-Key: $KEY" "$URL/UJI-SMOKE-TIDAK-ADA")" 404

# Dua kiriman pertama bersamaan untuk kode yang sama: tepat satu baris.
post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"p1\",\"kode_proyek\":\"$K2\"}" >/dev/null &
post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"p2\",\"kode_proyek\":\"$K2\"}" >/dev/null &
wait

# Klaim macet > 10 menit dilepas oleh kiriman ulang; log append-only tidak bisa diubah.
out=$(echo "t = Lpms3::ProjectTrigger.find_by!(kode_proyek: '$K1')
t.update_columns(diklaim_pada: 11.minutes.ago)
puts \"baris_K2=#{Lpms3::ProjectTrigger.where(kode_proyek: '$K2').count}\"
ev = t.events.first
begin; ev.update!(note: 'diubah'); puts 'log_ubah=bisa'; rescue ActiveRecord::ReadOnlyRecord; puts 'log_ubah=ditolak'; end
puts \"log_hapus=#{ev.destroy ? 'bisa' : 'ditolak'}\"" | run_rails)
chk "kiriman bersamaan → satu baris" "$(grep -o 'baris_K2=[0-9]*' <<<"$out")" "baris_K2=1"
chk "log tidak bisa diubah" "$(grep -o 'log_ubah=[a-z]*' <<<"$out")" "log_ubah=ditolak"
chk "log tidak bisa dihapus" "$(grep -o 'log_hapus=[a-z]*' <<<"$out")" "log_hapus=ditolak"
post -H "X-Lpms3-Key: $KEY" -d "{\"id_kiriman\":\"k4\",\"kode_proyek\":\"$K1\"}" >/dev/null
out=$(echo "t = Lpms3::ProjectTrigger.find_by!(kode_proyek: '$K1'); puts \"klaim=#{t.diklaim_pada.nil? ? 'dilepas' : 'tetap'}\"" | run_rails)
chk "klaim macet dilepas kiriman ulang" "$(grep -o 'klaim=[a-z]*' <<<"$out")" "klaim=dilepas"

chk "halaman admin tanpa login → bukan 200" "$([ "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/admin/lpms3/pemicu-leno")" = 200 ] && echo 200 || echo ditolak)" ditolak

# Batas laju: 60 per menit per alamat (permintaan di atas ikut dihitung).
last=""; for i in $(seq 1 70); do last=$(curl -s -o /dev/null -w '%{http_code}' "$URL/$K1"); [ "$last" = 429 ] && break; done
chk "lebih dari 60/menit → 429" "$last" 429

echo "---"; echo "RINGKASAN: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
