#!/usr/bin/env bash
# Membangun image OpenProject + plugin LPMS3 (lpms3/openproject:${LPMS3_IMAGE_TAG:-local}). Cepat (tanpa compile aset).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
# Tag diambil dari deploy/.env (sumber yang sama dengan compose) agar image yang dibangun = image yang dijalankan.
[ -n "${LPMS3_IMAGE_TAG:-}" ] || LPMS3_IMAGE_TAG="$(grep -m1 '^LPMS3_IMAGE_TAG=' deploy/.env 2>/dev/null | cut -d= -f2-)"
TAG="${LPMS3_IMAGE_TAG:-local}"
docker build -f deploy/Dockerfile -t "lpms3/openproject:${TAG}" .
