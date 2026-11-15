#!/usr/bin/env bash
# Audit kepatuhan BOP-001 -> LPMS3 (Master Plan §0 J1-J7, §15) dan butir keamanan/operasional D12.
# Hanya membaca (psql, file). Status: PASS = bukti ada; GAP = belum terwujud (diketahui, bukan kesalahan); FAIL = menyimpang dari yang seharusnya ada.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
P() { docker exec lpms3v2-db-1 psql -U postgres -d openproject -Atc "$1" 2>/dev/null; }
PASS=0; GAP=0; FAIL=0
r() { # status id uraian bukti
  case "$1" in PASS) PASS=$((PASS+1));; GAP) GAP=$((GAP+1));; FAIL) FAIL=$((FAIL+1));; esac
  printf '%-4s | %-6s | %s | %s\n' "$1" "$2" "$3" "$4"; }
eq() { # id uraian aktual harap
  if [ "$3" = "$4" ]; then r PASS "$1" "$2" "aktual=$3"; else r FAIL "$1" "$2" "aktual=$3 harap=$4"; fi; }
ge() { if [ "${3:-0}" -ge "$4" ] 2>/dev/null; then r PASS "$1" "$2" "aktual=$3 (>= $4)"; else r FAIL "$1" "$2" "aktual=$3 harap>= $4"; fi; }
echo "== audit_bop001 $(date '+%Y-%m-%d %H:%M:%S%z') =="

echo "-- J1 Lima tahap + gate"
eq J1.1 "4 definisi fase P1-P4 (Eksekusi digabung Pengawasan)" "$(P "select count(*) from project_phase_definitions")" 4
eq J1.2 "gate penutup G1-G4 bernama" "$(P "select string_agg(substr(finish_gate_name,1,2),',' order by position) from project_phase_definitions")" "G1,G2,G3,G4"
eq J1.3 "3 template proyek (Prediktif/Hibrid/Purnajual), masing-masing 4 fase" "$(P "select count(*) from (select p.id from projects p join project_phases ph on ph.project_id=p.id where p.templated group by p.id having count(*)=4) x")" 3
eq J1.4 "template tidak publik" "$(P "select count(*) from projects where templated and public")" 0

echo "-- J2 Formulir & prosedur"
eq J2.1 "18 definisi formulir (form_definition)" "$(P "select count(*) from lpms3_form.form_definition")" 18
ge J2.2 "tabel skema lpms3_form (43 tabel formulir + infrastruktur)" "$(P "select count(*) from information_schema.tables where table_schema='lpms3_form'")" 43
ls plugin/openproject-lpms3/app/controllers/lpms3/ | grep -qi "form" && r PASS J2.3 "UI pengisian & cetak PDF formulir" "controller formulir ada" || r GAP J2.3 "UI pengisian & cetak PDF formulir resmi" "belum ada controller/halaman formulir di plugin (form_instance=$(P "select count(*) from lpms3_form.form_instance"))"

echo "-- J3 WBS Template LPMS"
ge J3.1 "tabel WBS/Kurva-S tersedia" "$(P "select count(*) from information_schema.tables where table_schema='lpms3' and table_name in ('wbs_node','wbs_progress','scurve_plan','baseline','baseline_item')")" 5
ls plugin/openproject-lpms3/app/controllers/lpms3/ | grep -qi "wbs" && r PASS J3.2 "impor WBS Template + folder bukti + Kurva-S" "controller WBS ada" || r GAP J3.2 "impor WBS Template, folder bukti, Kurva-S" "belum ada UI/impor WBS (wbs_node=$(P "select count(*) from lpms3.wbs_node"))"

echo "-- J4 RASCI, organisasi, fungsi"
eq J4.1 "ref_rasci (Tabel 1-6)" "$(P "select count(*) from lpms3.ref_rasci")" 312
eq J4.2 "ref_peserta_rapat (Tabel 2,4)" "$(P "select count(*) from lpms3.ref_peserta_rapat")" 9
eq J4.3 "organisasi Nota 021: 66 unit (5/18/43)" "$(P "select count(*)||' ('||count(*) filter (where grade='DIREKSI')||'/'||count(*) filter (where grade='ES1')||'/'||count(*) filter (where grade='ES2')||')' from lpms3.org_unit")" "66 (5/18/43)"
eq J4.4 "pemetaan fungsi->unit" "$(P "select count(*) from lpms3.fungsi_unit_map")" 81
eq J4.5 "grup fungsi di OpenProject" "$(P "select count(*) from users where type='Group'")" 31
hc="$(P "select count(*) from lpms3.position")"; [ "${hc:-0}" -ge 1 ] && r PASS J4.6 "posisi & user HC dimuat (D8)" "posisi=$hc" || r GAP J4.6 "posisi & user HC dimuat (D8)" "posisi=0, menunggu data HC dan SKEP 001/2026"

echo "-- J5 Integrated Change Control"
eq J5.1 "matriks kewenangan (CCM)" "$(P "select count(*) from lpms3.ref_matriks_kewenangan")" 6
eq J5.2 "tipe WP Change Request ada" "$(P "select count(*) from types where name='Change Request'")" 1
ge J5.3 "workflow Change Request per peran (BFR-001; OP 17 memakai type_variant)" "$(P "select count(*) from workflows w join type_variants v on v.id=w.type_variant_id join types t on t.id=v.type_id where t.name='Change Request'")" 5
eq J5.4 "tabel BFR-001 change request" "$(P "select count(*) from information_schema.tables where table_schema='lpms3_form' and table_name='bfr001_change_request'")" 1

echo "-- J6 Pengawasan (LKP, risiko, mutu, K3L, pengadaan)"
eq J6.1 "tabel FFR-708 (5 tabel LKP)" "$(P "select count(*) from information_schema.tables where table_schema='lpms3_form' and table_name like 'ffr708_%'")" 5
for t in "Risiko" "Bahaya K3L" "NCR" "Inspeksi Mutu" "Item Pengadaan" "Stakeholder" "Isu" "Action Item" "Lesson Learned" "Deliverable" "Top Up Anggaran"; do
  eq "J6.t" "tipe WP '$t'" "$(P "select count(*) from types where name='$t'")" 1; done
eq J6.2 "layanan lpms3-data berjalan" "$(docker inspect -f '{{.State.Status}}' lpms3v2-lpms3-data-1 2>/dev/null)" running
eq J6.3 "outbox sinkron: entri gagal (attempts>=10)" "$(P "select count(*) from lpms3.sync_outbox where attempts>=10")" 0
r GAP J6.4 "LKP bulanan otomatis (ETL golden-file E01-E10)" "belum diuji (Buku Teknis §13.9)"

echo "-- J7 Penutupan FOP-705"
eq J7.1 "tabel FFR-710 (8 tabel dokumentasi proyek)" "$(P "select count(*) from information_schema.tables where table_schema='lpms3_form' and table_name like 'ffr710_%'")" 8
eq J7.2 "tabel BAST, bahan sisa, stock opname" "$(P "select count(*) from information_schema.tables where table_schema='lpms3_form' and table_name in ('wfr014_bast','wfr010_header','wfr010_item','wfr028_stock_opname')")" 4
r GAP J7.3 "sub-project purnajual otomatis saat penutupan" "N/A di smoke D10 (butuh plugin)"

echo "-- Konfigurasi OpenProject (BOP-001 + seed)"
ge K.1 "status WP (55 seed + bawaan)" "$(P "select count(*) from statuses")" 55
ge K.2 "peran proyek (16 seed + bawaan)" "$(P "select count(*) from roles where type='ProjectRole'")" 17
ge K.3 "tipe WP (16 seed + bawaan)" "$(P "select count(*) from types")" 16
eq K.4 "custom field proyek (5 section, 19 atribut)" "$(P "select count(*) from custom_fields where type='ProjectCustomField'")" 19
eq K.5 "custom field WP (76)" "$(P "select count(*) from custom_fields where type='WorkPackageCustomField'")" 76
ge K.6 "workflow (seed 1028 + bawaan)" "$(P "select count(*) from workflows")" 1028
eq K.7 "halaman wiki template (5 x 3)" "$(P "select count(*) from wiki_pages")" 15

echo "-- Keamanan & operasional (D12)"
eq S.1 "akun 'admin' bawaan terkunci (status 3)" "$(P "select coalesce((select status from users where login='admin'),-1)")" 3
ge S.2 "akun admin aktif (bridge + pemilik) tercatat" "$(P "select count(*) from users where admin and status=1 and type='User'")" 2
grep -q '@oplogin' deploy/Caddyfile.landing && r PASS S.3 "login OpenProject lokal dialihkan ke IDS (proxy)" "@oplogin ada" || r FAIL S.3 "login lokal ditutup" "@oplogin hilang"
eq S.4 "2FA OpenProject sengaja nonaktif (login diautentikasi IDS)" "$(P "select (value ~ 'disabled: true')::text from settings where name='plugin_openproject_two_factor_authentication'")" true
r GAP S.5 "2FA admin (D12 butir 3)" "harus di IDS (dev-ids-intern.len.co.id); tidak dapat diaktifkan di OpenProject karena akan memutus login bridge"
sched="$(ls -1d data/backup/*-0200 2>/dev/null | wc -l)"
crontab -l 2>/dev/null | grep -q 'ops/backup.sh' && r PASS S.6 "cron backup 02:00 terpasang" "crontab ada" || r FAIL S.6 "cron backup" "tidak ada"
[ "$sched" -ge 7 ] && r PASS S.7 "backup terjadwal >= 7 hari" "$sched" || r GAP S.7 "backup terjadwal >= 7 hari berturut-turut (D12 butir 4)" "baru $sched (02:00 tanggal: $(ls -1d data/backup/*-0200 2>/dev/null | xargs -n1 basename | sed 's/-0200//' | tr '\n' ' '))"
crontab -l 2>/dev/null | grep -q 'ops/monitor.sh' && r PASS S.8 "monitoring ops/monitor.sh terjadwal (D12 butir 6)" "crontab ada" || r GAP S.8 "monitoring terjadwal" "belum dipasang di crontab"
eq S.9 "sisa proyek uji smoke-d10" "$(P "select count(*) from projects where identifier ilike 'smoke%'")" 0
eq S.10 "sisa data demo (pimpro.demo / demo-*)" "$(P "select (select count(*) from users where login='pimpro.demo')+(select count(*) from projects where identifier ilike 'demo%')")" 0
grep -q '^STARROCKS_ROOT_PASSWORD=$' deploy/.env && r PASS S.11 "STARROCKS_ROOT_PASSWORD kosong di deploy/.env (D6)" "kosong" || r FAIL S.11 "STARROCKS_ROOT_PASSWORD kosong" "terisi"
[ -f .env ] && r FAIL S.12 "tidak ada .env/catatan kredensial di root repo" "ADA (izin $(stat -c %a .env)): pindahkan ke pengelola rahasia, hapus, dan ROTASI password root StarRocks" || r PASS S.12 "tidak ada .env di root repo" "tidak ada"
r GAP S.13 "SMTP internal (D2): email/notifikasi U19" "ECONNREFUSED localhost:25 — homework"
r GAP S.14 "UAT U01-U31 >= 95%, 0 kritikal, BA UAT" "belum; lihat docs/COMPLIANCE-BOP001.md bagian UAT"
echo "== RINGKASAN: PASS=$PASS GAP=$GAP FAIL=$FAIL =="
[ "$FAIL" -eq 0 ]
