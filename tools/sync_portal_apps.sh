#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.."; pwd)"
mkdir -p "$ROOT/portal/assets"
cp "$ROOT/apps.json" "$ROOT/portal/assets/apps.json"
echo "Synced apps.json -> portal/assets/apps.json"