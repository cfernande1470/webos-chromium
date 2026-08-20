#!/usr/bin/env bash
set -euo pipefail

TV=${TV:-root@192.168.2.121}
APP_ID=org.webosbrew.chromium120

ssh "$TV" "
  set -e
  luna-send -n 1 -f luna://com.webos.applicationManager/launch '{\"id\":\"$APP_ID\"}'
  sleep 3
  echo '===== PROCESSES ====='
  ps -ef | grep -E 'browser_shell|chromium120' | grep -v grep || true
  echo '===== APP LOG ====='
  tail -120 /tmp/$APP_ID.log 2>/dev/null || true
"
