#!/usr/bin/env bash
# Monitoring minimal :5100 (D12 butir 6, Buku Teknis §8.2). Hanya membaca; hanya stack lpms3v2.
# Keluaran: baris "ts LEVEL cek: pesan" ke data/monitor/alerts.log (hanya WARN/CRIT) dan stdout bila -v.
# Exit 0 = semua OK/WARN, 1 = ada CRIT. Saluran notifikasi (email/Slack) belum ada: lihat homework SMTP.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
LOG="$ROOT/data/monitor/alerts.log"; mkdir -p "$(dirname "$LOG")"
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1
TS() { date '+%Y-%m-%d %H:%M:%S%z'; }
CRIT=0
say() { # level cek pesan
  local line; line="$(TS) $1 $2: $3"
  { [ "$1" != OK ] || [ "$VERBOSE" = 1 ]; } && echo "$line"
  [ "$1" != OK ] && echo "$line" >> "$LOG"
  [ "$1" = CRIT ] && CRIT=1
  return 0
}
PSQL() { docker exec lpms3v2-db-1 psql -U postgres -d lpms3 -Atc "$1" 2>/dev/null; }

# 1. Kontainer inti harus berjalan (dan sehat bila punya healthcheck)
for c in web worker cron db proxy idslogin lpms3-data cache hocuspocus; do
  n="lpms3v2-$c-1"
  st="$(docker inspect -f '{{.State.Status}}' "$n" 2>/dev/null || echo hilang)"
  hl="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}-{{end}}' "$n" 2>/dev/null || echo -)"
  if [ "$st" != running ]; then say CRIT container "$n status=$st"
  elif [ "$hl" != - ] && [ "$hl" != healthy ]; then say CRIT container "$n health=$hl"
  else say OK container "$n running ($hl)"; fi
done

# 2. HTTP :5100 (header Host wajib)
H='Host: 192.168.125.14:5100'
chk_http() { code="$(curl -s -o /dev/null -m 15 -w '%{http_code}' -H "$H" "localhost:5100$1")"
  if [ "$code" = "$2" ]; then say OK http "$1 -> $code"; else say CRIT http "$1 -> $code (harap $2)"; fi; }
chk_http / 200; chk_http /ids/login 302; chk_http /panduan-internal 302; chk_http /lpms3/panduan 200

# 3. Disk
use="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
if [ "$use" -ge 90 ]; then say CRIT disk "/ terpakai ${use}%"; elif [ "$use" -ge 80 ]; then say WARN disk "/ terpakai ${use}%"; else say OK disk "/ ${use}%"; fi

# 4. Backup terjadwal (02:00) tidak boleh lebih tua dari 26 jam; checksum utuh
last="$(ls -1d data/backup/*-0200 2>/dev/null | tail -1)"
if [ -z "$last" ]; then say CRIT backup "belum ada backup terjadwal (*-0200)"
else
  age_h=$(( ( $(date +%s) - $(stat -c %Y "$last") ) / 3600 ))
  if [ "$age_h" -gt 26 ]; then say CRIT backup "backup terjadwal terakhir $(basename "$last") berumur ${age_h} jam"
  elif (cd "$last" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then say OK backup "$(basename "$last") ${age_h} jam, checksum OK"
  else say CRIT backup "$(basename "$last") checksum TIDAK cocok"; fi
fi

# 5. Outbox sinkron StarRocks (alarm: attempts >= 10; antrean menumpuk)
bad="$(PSQL "select count(*) from lpms3.sync_outbox where attempts >= 10")"
old="$(PSQL "select count(*) from lpms3.sync_outbox where synced_at is null and created_at < now() - interval '15 minutes'" 2>/dev/null)"
[ -z "$bad" ] && say CRIT outbox "tidak dapat membaca lpms3.sync_outbox" || {
  [ "$bad" -gt 0 ] && say CRIT outbox "$bad entri attempts>=10" || say OK outbox "tidak ada entri attempts>=10"
  [ -n "$old" ] && [ "$old" -gt 0 ] && say WARN outbox "$old entri belum tersinkron >15 menit"
}
if docker logs --since 10m lpms3v2-lpms3-data-1 2>&1 | grep -q "ALARM"; then say CRIT lpms3-data "log memuat ALARM (10 menit terakhir)"; else say OK lpms3-data "tanpa ALARM"; fi

# 6. Job latar: gagal 1 jam terakhir (SMTP localhost:25 dipisah karena masih homework)
tot="$(PSQL "select count(*) from good_jobs where error is not null and created_at > now() - interval '1 hour'")"
smtp="$(PSQL "select count(*) from good_jobs where error ilike '%port 25%' and created_at > now() - interval '1 hour'")"
if [ -z "$tot" ]; then say CRIT jobs "tidak dapat membaca good_jobs"
else other=$(( tot - ${smtp:-0} ))
  [ "$other" -gt 0 ] && say WARN jobs "$other job gagal (non-SMTP) dalam 1 jam" || say OK jobs "tanpa job gagal non-SMTP"
  [ "${smtp:-0}" -gt 0 ] && say WARN jobs "${smtp} job gagal karena SMTP (homework D2)"
fi

# 7. Kesalahan 5xx di log web (15 menit terakhir)
e5="$(docker logs --since 15m lpms3v2-web-1 2>&1 | grep -c 'status=5[0-9][0-9]')"
[ "$e5" -gt 0 ] && say WARN web "$e5 respons 5xx dalam 15 menit" || say OK web "tanpa 5xx"

exit $CRIT
