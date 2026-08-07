#!/bin/sh
set -eu

target="${1:-root@192.168.2.121}"

ssh -o BatchMode=yes -o ConnectTimeout=8 "$target" '
echo "== operating system =="
uname -a
cat /etc/os-release 2>/dev/null || true

echo "== memory =="
free -m

echo "== application storage =="
df -h /mnt/lg/appstore

echo "== wayland =="
ls -l /tmp/xdg/wayland-* 2>/dev/null || true

echo "== browser =="
ps -ef | grep "[W]ebAppMgr" | head -1

echo "== package architectures =="
opkg print-architecture 2>/dev/null || true
'
