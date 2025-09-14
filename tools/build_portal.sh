#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.."; pwd)"

bash "$ROOT/tools/sync_portal_apps.sh"

pushd "$ROOT/portal" >/dev/null
flutter clean
flutter pub get
flutter build web
popd >/dev/null

rm -rf "$ROOT/hosting"
mkdir -p "$ROOT/hosting/thumbs"
cp -r "$ROOT/portal/build/web/"* "$ROOT/hosting/"
echo "Portal built → hosting/"