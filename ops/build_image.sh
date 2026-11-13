#!/usr/bin/env bash
# Membangun image OpenProject + plugin LPMS3 (lpms3/openproject:${LPMS3_IMAGE_TAG:-local}). Cepat (tanpa compile aset).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
TAG="${LPMS3_IMAGE_TAG:-local}"
docker build -f deploy/Dockerfile -t "lpms3/openproject:${TAG}" .
