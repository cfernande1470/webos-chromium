#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_ID=${APP_ID:-org.webosbrew.chromium120}
VERSION=${VERSION:-0.1.0}
DIST="$ROOT/dist/$APP_ID"
OUT_DIR="$ROOT/dist/ipk"
IPK_NAME="${APP_ID}_arm_v${VERSION}.ipk"
IPK="$OUT_DIR/$IPK_NAME"
MANIFEST="$OUT_DIR/$APP_ID.manifest.json"

test -x "$DIST/bin/browser_shell"
test -r "$DIST/bin/libcbe.so"
test -r "$DIST/appinfo.json"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/webos-chromium-ipk.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/data/usr/palm/applications/$APP_ID" "$TMP/control"
cp -a "$DIST"/. "$TMP/data/usr/palm/applications/$APP_ID/"

INSTALLED_SIZE=$(du -sk "$DIST" | awk '{print $1 * 1024}')
printf '%s\n' \
  "Package: $APP_ID" \
  "Version: $VERSION" \
  'Section: misc' \
  'Priority: optional' \
  'Architecture: arm' \
  "Installed-Size: $INSTALLED_SIZE" \
  'Maintainer: webosbrew <nobody@example.com>' \
  'Description: Chromium 120 browser for rooted LG webOS TVs.' \
  'webOS-Package-Format-Version: 2' \
  'webOS-Packager-Version: webos-chromium' \
  > "$TMP/control/control"

(cd "$TMP" && tar -czf control.tar.gz -C control control)
(cd "$TMP/data" && tar -czf "$TMP/data.tar.gz" .)
printf '2.0\n' > "$TMP/debian-binary"

mkdir -p "$OUT_DIR"
ar rcs "$IPK" "$TMP/debian-binary" "$TMP/control.tar.gz" "$TMP/data.tar.gz"

HASH=$(sha256sum "$IPK" | awk '{print $1}')
SIZE=$(stat -c '%s' "$IPK")
cat > "$MANIFEST" <<EOF
{
  "id": "$APP_ID",
  "version": "$VERSION",
  "type": "native",
  "title": "Chromium 120",
  "appDescription": "Chromium 120 with direct webOS Wayland/Mali rendering and extension support.",
  "iconUri": "https://raw.githubusercontent.com/cfernande1470/webos-chromium/main/package/$APP_ID/icon.png",
  "sourceUrl": "https://github.com/cfernande1470/webos-chromium",
  "rootRequired": true,
  "ipkUrl": "https://github.com/cfernande1470/webos-chromium/releases/download/v$VERSION/$IPK_NAME",
  "ipkHash": { "sha256": "$HASH" },
  "ipkSize": $SIZE,
  "installedSize": $INSTALLED_SIZE
}
EOF

echo "Built $IPK"
echo "Manifest $MANIFEST"
sha256sum "$IPK"
