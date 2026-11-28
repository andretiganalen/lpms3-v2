#!/usr/bin/env bash
# Salin backup terbaru ke luar host, terenkripsi (GPG simetris AES256).
# Tujuan wajib diisi lewat OFFHOST_TARGET (rsync/SSH), mis. user@host:/srv/backup-lpms3/
# Passphrase: deploy/secrets/backup-offhost.pass (di-ignore git, chmod 600).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${OFFHOST_TARGET:?Isi OFFHOST_TARGET (user@host:/path/) - tujuan luar host belum ditentukan}"
PASS="$ROOT/deploy/secrets/backup-offhost.pass"
[ -s "$PASS" ] || { echo "Passphrase $PASS belum ada" >&2; exit 1; }
LATEST=$(ls -1d "$ROOT"/data/backup/2*/ | sort | tail -1); NAME=$(basename "$LATEST")
OUT="$ROOT/data/backup/offhost-$NAME.tar.gpg"
(cd "$LATEST" && sha256sum -c SHA256SUMS >/dev/null)   # jangan kirim backup yang rusak
sudo -n tar -C "$ROOT/data/backup" -cf - "$NAME" \
  | gpg --batch --yes --pinentry-mode loopback --passphrase-file "$PASS" --symmetric --cipher-algo AES256 -o "$OUT"
rsync -t --partial "$OUT" "$OFFHOST_TARGET"
sha256sum "$OUT" | tee "$OUT.sha256"
rm -f "$OUT"
echo "OK: $NAME terkirim ke $OFFHOST_TARGET"
