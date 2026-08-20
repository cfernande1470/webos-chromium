#!/usr/bin/env bash
set -euo pipefail

BASE=/dev/shm/webos-chromium-${SLURM_JOB_ID:-manual}
SRC="$BASE/.cache/chromium120-full/src/src"
ROOT="$BASE/.cache/chromium120-full"
OUT="$BASE/out/chromium120-arm"

rm -rf "$BASE"
mkdir -p "$BASE/.cache/chromium120-full/src" "$BASE/out/chromium120-arm"

git clone --no-checkout --branch submissions/16 \
  https://github.com/webosose/chromium120.git "$ROOT/src"
git -C "$ROOT/src" checkout --quiet e6a73fffdbe3bcc6f7fc33316c74adc6e7c01853

git -C "$ROOT/src" apply \
  /tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/config/patches/0001-cross-build-host-and-locales.patch
mkdir -p "$SRC/buildtools/linux64"
cp /tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/tooling/gn \
  "$SRC/buildtools/linux64/gn"

cp /tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/out.args.gn "$OUT/args.gn"
"$SRC/buildtools/linux64/gn" --root="$SRC" gen "$OUT" --fail-on-unused-args
stdbuf -oL -eL ninja -C "$OUT" -j80 browser_shell_webos
