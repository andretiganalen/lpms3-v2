#!/usr/bin/env bash
# Pemeriksa UIx (docs/skills/uIx-len-web-apps.md §10) untuk berkas milik LPMS3. Hanya membaca. Exit 1 bila ada pelanggaran.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
FAIL=0
bad() { echo "FAIL | $1 | $2"; FAIL=$((FAIL+1)); }
ok()  { echo "PASS | $1 | $2"; }
CSS=plugin/openproject-lpms3/assets/uix/uix.css
# 1. Tidak ada hex/rgb di luar blok :root (aturan 4 dan §10) pada CSS tema
strip() { python3 - "$1" <<'PY'
import re,sys
t=open(sys.argv[1]).read()
t=re.sub(r'/\*.*?\*/','',t,flags=re.S)
t=re.sub(r':root(?::root)?\s*\{[^}]*\}','',t)
print(t)
PY
}
n=$(strip $CSS | grep -oE '#[0-9a-fA-F]{3,8}\b|rgba?\(' | grep -vc '^$' || true)
[ "${n:-0}" -eq 0 ] && ok CSS-hex "tidak ada hex/rgb di luar :root ($CSS)" || bad CSS-hex "$n nilai warna literal di luar :root"
# 2. Token yang dipakai harus terdefinisi
undef=$(python3 - <<'PY'
import re
t=open('plugin/openproject-lpms3/assets/uix/uix.css').read()
d=set(re.findall(r'(--uix-[a-z0-9-]+)\s*:',t)); u=set(re.findall(r'var\((--uix-[a-z0-9-]+)',t))
print(' '.join(sorted(u-d)))
PY
)
[ -z "$undef" ] && ok CSS-token "semua token --uix-* terdefinisi" || bad CSS-token "tak terdefinisi: $undef"
# 3. Font hanya UIx Poppins / var(--uix-font)
f=$(strip $CSS | grep -oE 'font-family:[^;]+' | grep -vE 'UIx Poppins|var\(--uix-font(-mono)?\)' | sort -u | tr '\n' ' ')
[ -z "$f" ] && ok CSS-font "hanya Poppins UIx" || bad CSS-font "$f"
# 4. Tidak ada bobot 700+ (Poppins hanya 400/500/600)
w=$(strip $CSS | grep -oE 'font-weight:\s*(700|800|900|bold)' | sort -u | tr '\n' ' ')
[ -z "$w" ] && ok CSS-weight "tanpa bobot 700+" || bad CSS-weight "$w"
# 5. View/partial plugin dan halaman panduan: tanpa hex warna, tanpa font-family, tanpa emoji
files=$(find plugin/openproject-lpms3/app/views -type f \( -name '*.erb' -o -name '*.html' \))
h=$(grep -nE '#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b' $files | grep -vE 'href="#|#RRGGBB|&#|id="#' | head -5)
[ -z "$h" ] && ok VIEW-hex "tanpa hex warna di view/halaman" || bad VIEW-hex "$h"
e=$(grep -nP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' $files plugin/openproject-lpms3/config/locales/*.yml 2>/dev/null | head -3)
[ -z "$e" ] && ok VIEW-emoji "tanpa emoji di antarmuka" || bad VIEW-emoji "$e"
# 6. Berkas font Poppins 400/500/600 tersedia di server sendiri
c=$(ls plugin/openproject-lpms3/assets/fonts/poppins-latin-{400,500,600}.woff2 2>/dev/null | wc -l)
[ "$c" -eq 3 ] && ok FONT "Poppins 400/500/600 dilayani dari server sendiri" || bad FONT "berkas woff2 kurang ($c/3)"
# 7. Token sama dengan artefak UIx referensi (leno.css) bila :8585 terjangkau
ref=$(mktemp); if curl -s -m 8 -o "$ref" -w '%{http_code}' localhost:8585/_leno/leno.css | grep -q 200; then
  d=$(python3 - "$ref" <<'PY'
import re,sys
def tok(t):
    d={}
    for blk in re.findall(r':root\s*\{([^}]*)\}',t):
        for k,v in re.findall(r'(--uix-(?:primary|primary-strong|on-primary|text-head|text-body|text-secondary|surface|border|border-strong|focus-ring|focus-border|shadow-xs|shadow-md)\b)\s*:\s*([^;]+);',blk): d[k]=re.sub(r'\s+','',v)
    return d
a=tok(open(sys.argv[1]).read())
b=tok(open('plugin/openproject-lpms3/assets/uix/uix.css').read())
alias={'--uix-text-head':'--uix-head','--uix-text-body':'--uix-body','--uix-text-secondary':'--uix-secondary'}
diff=[]
ref=open(sys.argv[1]).read()
def refval(k):
    kk=alias.get(k,k)
    m=re.search(re.escape(kk)+r'\s*:\s*([^;]+);',ref)
    return re.sub(r'\s+','',m.group(1)) if m else None
for k,v in b.items():
    r=refval(k)
    if r and r!=v: diff.append(f"{k}: ref={r} lpms3={v}")
print('; '.join(diff))
PY
)
  [ -z "$d" ] && ok TOKEN-REF "token inti sama dengan artefak UIx referensi (:8585 leno.css)" || bad TOKEN-REF "$d"
else echo "SKIP | TOKEN-REF | :8585 tidak terjangkau"; fi; rm -f "$ref"
echo "== uix_lint: FAIL=$FAIL =="
[ "$FAIL" -eq 0 ]
