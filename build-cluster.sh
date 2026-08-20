#!/usr/bin/env bash
set -euo pipefail

ROOT=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build
SRC="$ROOT/.cache/chromium120-full/src/src"
OUT="$ROOT/out/chromium120-arm"
SYSROOT="$ROOT/.cache/webos-sysroot"
GN="$SRC/buildtools/linux64/gn"

mkdir -p "$OUT"
cat > "$OUT/args.gn" <<EOF
target_os = "linux"
target_cpu = "arm"
arm_arch = "armv7-a"
arm_float_abi = "softfp"
arm_use_neon = true
is_debug = false
is_official_build = true
is_component_build = false
is_webos = true
is_cross_linux_build = true
is_clang = false
use_cbe = false
use_neva_chrome_extensions = true
use_ozone = true
ozone_auto_platforms = false
ozone_platform_wayland = false
ozone_platform_wayland_external = true
use_dbus = false
use_system_libdrm = false
use_libpci = false
enable_vulkan = false
angle_enable_vulkan = false
dawn_enable_vulkan = false
dawn_enable_vulkan_validation_layers = false
dawn_use_swiftshader = false
enable_swiftshader_vulkan = false
use_dawn = false
build_dawn_tests = false
use_pangocairo = false
use_pmlog = true
target_sysroot = "$SYSROOT"
target_cc = "/usr/bin/arm-linux-gnueabi-gcc"
target_cxx = "/usr/bin/arm-linux-gnueabi-g++"
target_ar = "/usr/bin/arm-linux-gnueabi-ar"
target_ld = "/usr/bin/arm-linux-gnueabi-ld"
cros_target_extra_cppflags = "-march=armv7-a -mfloat-abi=softfp -mfpu=neon-fp16 -mfp16-format=ieee -I$SRC/third_party/vulkan-deps/vulkan-headers/src/include"
cros_target_extra_asmflags = "-march=armv7-a -mfloat-abi=softfp -mfpu=neon-fp16"
EOF

"$GN" --root="$SRC" gen "$OUT" --fail-on-unused-args
exec ninja -C "$OUT" -j80 browser_shell_webos
