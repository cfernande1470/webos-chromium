#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_ID=org.webosbrew.chromium120
OUT="$ROOT/dist/$APP_ID"

# By default pull the persistent artifact from the FMI node through the WSL
# laptop.  ARTIFACT_DIR can point at a local copy for offline packaging.
REMOTE=${REMOTE:-ferncarl@192.168.2.122}
REMOTE_NODE=${REMOTE_NODE:-vcl1100}
REMOTE_ARTIFACT=${REMOTE_ARTIFACT:-/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/artifacts/chromium120-arm}
ARTIFACT_DIR=${ARTIFACT_DIR:-}

rm -rf "$OUT"
mkdir -p "$OUT/bin"
cp -a "$ROOT/package/$APP_ID/appinfo.json" \
      "$ROOT/package/$APP_ID/index.html" \
      "$ROOT/package/$APP_ID/icon.png" "$OUT/"
cp -a "$ROOT/package/$APP_ID/bin/chromium120" "$OUT/bin/"

if [ -n "$ARTIFACT_DIR" ]; then
  cp -a "$ARTIFACT_DIR"/* "$OUT/bin/"
else
  ssh "$REMOTE" "ssh $REMOTE_NODE 'tar -C $(printf %q "$REMOTE_ARTIFACT") -cf - .'" \
    | tar -xpf - -C "$OUT/bin"
fi

chmod 755 "$OUT/bin/chromium120" "$OUT/bin/browser_shell"
chmod 644 "$OUT"/appinfo.json "$OUT"/index.html "$OUT"/icon.png "$OUT"/*.dat "$OUT"/*.pak "$OUT"/*.bin 2>/dev/null || true

echo "Staged $OUT"
file "$OUT/bin/browser_shell" "$OUT/bin/libcbe.so"
du -sh "$OUT"
