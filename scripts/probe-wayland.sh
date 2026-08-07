#!/bin/sh
set -eu

target="${1:-root@192.168.2.121}"
probe_dir="${2:-/mnt/lg/appstore/webos-chromium-probe}"

ssh "$target" "
  XDG_RUNTIME_DIR=/tmp/xdg \\
  WAYLAND_DISPLAY=wayland-0 \\
  HOME=$probe_dir/profile \\
  LD_PRELOAD= \\
  $probe_dir/ld-linux-aarch64.so.1 \\
    --library-path $probe_dir/lib \\
    $probe_dir/chrome \\
    --ozone-platform=wayland \\
    --no-sandbox \\
    --disable-dev-shm-usage \\
    --disable-gpu \\
    --user-data-dir=$probe_dir/profile \\
    --no-first-run \\
    about:blank
"
