#!/usr/bin/env bash
set -euo pipefail

TV=${TV:-root@192.168.2.121}
APP_ID=org.webosbrew.chromium120
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/$APP_ID"
REMOTE="/media/developer/apps/usr/palm/applications/$APP_ID"
TMP="/tmp/webos-chromium120-upload"

test -x "$OUT/bin/browser_shell"
test -x "$OUT/bin/chromium120"

echo '===== LOCAL ABI ====='
file "$OUT/bin/browser_shell" "$OUT/bin/libcbe.so"
readelf -l "$OUT/bin/browser_shell" | grep -i interpreter || true
du -sh "$OUT"

echo '===== UPLOAD AND INSTALL ====='
tar -C "$OUT" -cf - . | ssh "$TV" "
  set -e
  luna-send -n 1 -f luna://com.webos.applicationManager/closeByAppId '{\"id\":\"$APP_ID\"}' >/dev/null 2>&1 || true
  pkill -f '$APP_ID/bin/browser_shell' 2>/dev/null || true
  rm -rf '$TMP'
  mkdir -p '$TMP'
  tar -xf - -C '$TMP'
  mkdir -p '$REMOTE'
  cp -a '$TMP'/\. '$REMOTE'/
  chmod 755 '$REMOTE/bin/browser_shell' '$REMOTE/bin/chromium120' '$REMOTE/bin/libcbe.so'
  chmod 644 '$REMOTE/appinfo.json' '$REMOTE/index.html' '$REMOTE/icon.png' '$REMOTE/bin'/*.dat '$REMOTE/bin'/*.pak '$REMOTE/bin'/*.bin 2>/dev/null || true
  rm -rf '$TMP'
  sync
  echo '===== INSTALLED ====='
  ls -lh '$REMOTE/bin/browser_shell' '$REMOTE/bin/libcbe.so'
  df -h /media/developer /tmp 2>/dev/null || df -h
"
