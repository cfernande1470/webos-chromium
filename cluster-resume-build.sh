#!/usr/bin/env bash
set -euo pipefail

BASE=/dev/shm/webos-chromium-16195
SRC="$BASE/.cache/chromium120-full/src/src"
OUT="$BASE/out/chromium120-arm"
TOOLS=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/tooling
WRAPPER="$TOOLS/clang-webos-wrapper"
CLANG="$SRC/third_party/llvm-build/Release+Asserts/bin/clang"
CLANGXX="$SRC/third_party/llvm-build/Release+Asserts/bin/clang++"
LLVM_AR="$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-ar"
LLVM_NM="$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-nm"
LLVM_READELF="$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-readelf"
GCCLIB=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/toolchains/arm-gnu/usr/lib/gcc-cross/arm-linux-gnueabi/13
COMPAT_SRC="$TOOLS/webos-compat-getauxval.c"
COMPAT_OBJ="$TOOLS/webos-compat-getauxval.o"
COMPAT_LIB="$TOOLS/libwebos_compat.a"
V8ROOT="$TOOLS/v8-clang"
I386SYS=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/toolchains/i386-sysroot
I386GCCLIB="$I386SYS/usr/lib/gcc/x86_64-linux-gnu/13/32"
SYSROOT=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/.cache/webos-sysroot
PTRACE_HDR="$SYSROOT/usr/include/sys/ptrace.h"
V4L2_HDR="$TOOLS/videodev2.h"
MEMFD_HDR="$TOOLS/memfd.h"
UAPI_DIR="$TOOLS/linux-uapi"
SOURCE_PATCH="$TOOLS/chromium120-webos.patch"

test -d "$SRC"
test -f "$OUT/args.gn"
test -f "$V4L2_HDR"
test -f "$MEMFD_HDR"
test -f "$SOURCE_PATCH"
for uapi_header in kcmp.h libc-compat.h if.h wireless.h net.h netlink.h sockios.h socket.h hdlc_ioctl.h input.h input-event-codes.h; do
  test -f "$UAPI_DIR/$uapi_header"
done

# The TV sysroot carries an older V4L2 UAPI header which predates the color
# space and quantization enums used by Chromium's capture code.  The UAPI
# structs/ioctls are backwards-compatible, so overlay the current header for
# compilation while keeping the rest of the webOS sysroot unchanged.
cp "$V4L2_HDR" "$SYSROOT/usr/include/linux/videodev2.h"
cp "$MEMFD_HDR" "$SYSROOT/usr/include/linux/memfd.h"
for uapi_header in kcmp.h libc-compat.h if.h wireless.h net.h netlink.h sockios.h socket.h input.h input-event-codes.h; do
  cp "$UAPI_DIR/$uapi_header" "$SYSROOT/usr/include/linux/$uapi_header"
done
cp "$UAPI_DIR/hdlc_ioctl.h" "$SYSROOT/usr/include/linux/hdlc/ioctl.h"

# The webOS fork enables Chrome Root Store and PWA hooks while omitting the
# Linux/NSS pieces normally supplied by a desktop distribution. Apply the
# small, reproducible compatibility patch before regenerating GN files.
if ! grep -q 'WEBOS_CHROMIUM_LINUX_TRUST_STORE' "$SRC/net/cert/internal/system_trust_store.cc"; then
  # Some cluster Git builds silently skip patches whose synthetic index line
  # does not match the fork's blob hash. Keep the patch file for review, but
  # use an idempotent source insertion as the build-time fallback.
  git -C "$SRC" apply --whitespace=nowarn "$SOURCE_PATCH" || true
fi
if ! grep -q 'WEBOS_CHROMIUM_LINUX_TRUST_STORE' "$SRC/net/cert/internal/system_trust_store.cc"; then
  sed -i '/^std::unique_ptr<SystemTrustStore> CreateEmptySystemTrustStore()/i\
// WEBOS_CHROMIUM_LINUX_TRUST_STORE: use the Chrome Root Store with no NSS.\
#if BUILDFLAG(IS_LINUX)\
std::unique_ptr<SystemTrustStore> CreateSslSystemTrustStoreChromeRoot(\
    std::unique_ptr<TrustStoreChrome> chrome_root) {\
  return std::make_unique<SystemTrustStoreChrome>(\
      std::move(chrome_root), std::make_unique<TrustStoreCollection>());\
}\
#endif\
' "$SRC/net/cert/internal/system_trust_store.cc"
fi
if grep -q 'WEBOS_CHROMIUM_LINUX_TRUST_STORE' "$SRC/net/cert/internal/system_trust_store.cc"; then
  sed -i '/WEBOS_CHROMIUM_LINUX_TRUST_STORE/,/^#endif/ s/make_unique<DummySystemTrustStore>/make_unique<TrustStoreCollection>/' \
    "$SRC/net/cert/internal/system_trust_store.cc"
fi
if ! grep -q 'WEBOS_CHROMIUM_LINUX_TEST_ROOTS' "$SRC/net/BUILD.gn"; then
  sed -i '/^  if (is_linux || is_chromeos || is_android) {/i\
  # WEBOS_CHROMIUM_LINUX_TEST_ROOTS: provide the no-NSS test-root hooks.\
  if (is_linux \&\& !use_nss_certs) {\
    sources += [ "cert/test_root_certs_builtin.cc" ]\
  }\
' "$SRC/net/BUILD.gn"
fi
if ! grep -q 'neva/browser_shell/service:shell_service' "$SRC/webos/BUILD.gn"; then
  sed -i '/^    "\/\/ui\/gl",/a\
    "\/\/neva\/browser_shell\/service:shell_service",' "$SRC/webos/BUILD.gn"
fi
if ! grep -q 'third_party/wayland:wayland_client' "$SRC/webos/BUILD.gn"; then
  sed -i '/^    "\/\/neva\/browser_shell\/service:shell_service",/a\
    "\/\/third_party\/wayland:wayland_client",' "$SRC/webos/BUILD.gn"
fi
TLS_HDR="$SRC/third_party/blink/renderer/platform/heap/thread_local.h"
if ! grep -q 'WEBOS_CHROMIUM_GLOBAL_TLS' "$TLS_HDR"; then
  sed -i '/#elif BUILDFLAG(IS_ANDROID)/i\
#elif defined(OS_WEBOS)  // WEBOS_CHROMIUM_GLOBAL_TLS\
#define BLINK_HEAP_THREAD_LOCAL_MODEL "global-dynamic"\
' "$TLS_HDR"
fi
SHELL_BUILD="$SRC/webos/browser_shell/BUILD.gn"
sed -i 's#^    "//webos:weboswebruntime"$#    "//webos:weboswebruntime",#' "$SHELL_BUILD"
# Keep the runtime as a shared dependency; the two webOS implementation files
# below are added directly to the shell so their hidden vtables are available
# without linking the same objects twice.
sed -i '/^    "\/\/webos:webos_impl",$/d; /^    "\/\/neva\/app_runtime",$/d; /WEBOS_CHROMIUM_BROWSER_SHELL_IMPL_DEPS/d' "$SHELL_BUILD"
if ! grep -q 'WEBOS_CHROMIUM_BROWSER_SHELL_IMPL_SOURCES' "$SHELL_BUILD"; then
  sed -i '/^    "browser_shell_webos_main_delegate.h",/a\
    # WEBOS_CHROMIUM_BROWSER_SHELL_IMPL_SOURCES\
    "\/\/webos\/common\/webos_content_client.cc",\
    "\/\/webos\/renderer\/webos_content_renderer_client.cc",\
    "\/\/webos\/renderer\/webos_network_error_helper.cc",\
    "\/\/webos\/renderer\/webos_network_error_template_builder.cc",\
    "\/\/content\/shell\/common\/shell_neva_switches.cc",\
    "\/\/neva\/app_runtime\/browser\/app_runtime_browser_switches.cc",' "$SHELL_BUILD"
fi
# Older resumptions already have the marker above, so add newly discovered
# implementation sources independently and keep the edit idempotent.
if ! grep -q 'webos_network_error_helper.cc' "$SHELL_BUILD"; then
  sed -i '/^    "\/\/webos\/renderer\/webos_content_renderer_client.cc",/a\
    "\/\/webos\/renderer\/webos_network_error_helper.cc",\
    "\/\/webos\/renderer\/webos_network_error_template_builder.cc",' "$SHELL_BUILD"
fi
if ! grep -q 'shell_neva_switches.cc' "$SHELL_BUILD"; then
  sed -i '/^    "\/\/webos\/renderer\/webos_network_error_template_builder.cc",/a\
    "\/\/content\/shell\/common\/shell_neva_switches.cc",' "$SHELL_BUILD"
fi

# The webOS glibc headers predate the ARM ptrace request constants used by
# Crashpad.  Add the constants to the copied sysroot enum, rather than
# defining them as preprocessor integers (glibc's ptrace() takes the enum
# type, and Clang correctly rejects an untyped macro here).
if ! grep -q 'PTRACE_GET_THREAD_AREA = 22' "$PTRACE_HDR"; then
  sed -i '/PTRACE_SETFPXREGS = 19,/a\   PTRACE_GET_THREAD_AREA = 22,\n   PTRACE_GETVFPREGS = 27,\n   PTRACE_GETREGSET = 0x4204,' "$PTRACE_HDR"
fi
# Crashpad's compatibility header uses these self-aliases to detect whether
# glibc already supplied the request names.  Keep the enum values above while
# preventing that header from redeclaring them as constexpr variables.
if ! grep -q '#define PTRACE_GET_THREAD_AREA PTRACE_GET_THREAD_AREA' "$PTRACE_HDR"; then
  sed -i '/__END_DECLS/i\#define PTRACE_GET_THREAD_AREA PTRACE_GET_THREAD_AREA\n#define PTRACE_GETVFPREGS PTRACE_GETVFPREGS\n#define PTRACE_GETREGSET PTRACE_GETREGSET' "$PTRACE_HDR"
fi

# The cluster is a native Rocky/RHEL host.  Do not force the WSL host
# sysroot (/, with Debian's lib/x86_64-linux-gnu pkg-config layout).
sed -i \
  -e 's#^cros_host_sysroot = .*#cros_host_sysroot = ""#' \
  -e 's#^v8_snapshot_toolchain = .*#v8_snapshot_toolchain = "//build/toolchain/linux:clang_x86_v8_arm"#' \
  -e "s#^clang_base_path = .*#clang_base_path = \"$V8ROOT\"#" \
  -e 's#^cros_host_system_libdir = .*#cros_host_system_libdir = "lib64"#' \
  -e "s#^cros_host_cc = .*#cros_host_cc = \"$TOOLS/clang-host-webos\"#" \
  -e "s#^cros_host_cxx = .*#cros_host_cxx = \"$TOOLS/clang++-host-webos\"#" \
  -e "s#^cros_host_ld = .*#cros_host_ld = \"$TOOLS/clang++-host-webos\"#" \
  -e "s#^cros_host_nm = .*#cros_host_nm = \"$LLVM_NM\"#" \
  -e "s#^cros_target_ar = .*#cros_target_ar = \"$LLVM_AR\"#" \
  -e "s#^cros_target_cc = .*#cros_target_cc = \"$TOOLS/clang-webos\"#" \
  -e "s#^cros_target_cxx = .*#cros_target_cxx = \"$TOOLS/clang++-webos\"#" \
  -e "s#^cros_target_ld = .*#cros_target_ld = \"$TOOLS/clang++-webos\"#" \
  -e "s#^cros_target_nm = .*#cros_target_nm = \"$LLVM_NM\"#" \
  -e "s#^cros_target_readelf = .*#cros_target_readelf = \"$LLVM_READELF\"#" \
  -e "s#^cros_target_extra_cppflags = .*#cros_target_extra_cppflags = \"--target=arm-linux-gnueabi -B$GCCLIB -D_GNU_SOURCE -D_LIBCPP_HAS_NO_C11_ALIGNED_ALLOC -D__NR_getrandom=384 -D__NR_memfd_create=385 -DSYS_memfd_create=385 -DAT_HWCAP2=26 -DHWCAP2_AES=1 -DHWCAP2_PMULL=2 -DHWCAP2_SHA1=4 -DHWCAP2_SHA2=8 -DHWCAP2_CRC32=16 -DF_GET_SEALS=1034 -DF_ADD_SEALS=1033 -DF_SEAL_SEAL=1 -DF_SEAL_SHRINK=2 -DF_SEAL_GROW=4 -DSIOCGSTAMP_OLD=0x8906 -DSIOCGSTAMPNS_OLD=0x8907 -DO_TMPFILE=020400000 -march=armv7-a -mfloat-abi=softfp -mfpu=neon-fp16 -mfp16-format=ieee -I../../.cache/chromium120-full/src/src/third_party/vulkan-deps/vulkan-headers/src/include -I../../.cache/chromium120-full/src/src/third_party/wayland/src/src -I../../.cache/chromium120-full/src/src/third_party/wayland/include -I../../.cache/chromium120-full/src/src/third_party/wayland/src/egl -I../../.cache/chromium120-full/src/src/third_party/wayland/src/cursor -I../../.cache/chromium120-full/src/src/third_party/abseil-cpp\"#" \
  -e "s#^cros_target_extra_cflags = .*#cros_target_extra_cflags = \"--target=arm-linux-gnueabi -B$GCCLIB -march=armv7-a -mfloat-abi=softfp -mfpu=neon\"#" \
  -e "s#^cros_target_extra_asmflags = .*#cros_target_extra_asmflags = \"--target=arm-linux-gnueabi -B$GCCLIB -march=armv7-a -mfloat-abi=softfp -mfpu=neon-fp16\"#" \
  -e "s#^cros_target_extra_ldflags = .*#cros_target_extra_ldflags = \"--target=arm-linux-gnueabi -fuse-ld=lld -rtlib=libgcc -B$GCCLIB -L$GCCLIB -L$TOOLS -Wl,--whole-archive -lwebos_compat -Wl,--no-whole-archive\"#" \
  -e 's#^use_custom_libcxx = .*#use_custom_libcxx = true#' \
  -e 's#^use_custom_libcxx_for_host = .*#use_custom_libcxx_for_host = false#' \
  "$OUT/args.gn"
sed -i 's/ -mfp16-format=ieee//g' "$OUT/args.gn"

# The full webOS browser shell does not link the optional PWA manager helper;
# disable only that interface while retaining Chromium extensions themselves.
if grep -q '^enable_pwa_manager_webapi = ' "$OUT/args.gn"; then
  sed -i 's/^enable_pwa_manager_webapi = .*/enable_pwa_manager_webapi = false/' "$OUT/args.gn"
else
  printf 'enable_pwa_manager_webapi = false\n' >> "$OUT/args.gn"
fi

# The cluster has NSS runtime libraries but not the host nss-devel package.
# Chromium's bundled BoringSSL remains enabled; avoid the optional Linux
# system-trust-store integration for host tools.
if ! grep -q '^use_nss_certs = ' "$OUT/args.gn"; then
  printf '\nuse_nss_certs = false\n' >> "$OUT/args.gn"
fi
if ! grep -q '^enable_swiftshader = ' "$OUT/args.gn"; then
  printf 'enable_swiftshader = false\n' >> "$OUT/args.gn"
fi
if ! grep -q '^cros_target_extra_ldflags = ' "$OUT/args.gn"; then
  printf 'cros_target_extra_ldflags = "--target=arm-linux-gnueabi -fuse-ld=lld -rtlib=libgcc -B%s -L%s -L%s -Wl,--whole-archive -lwebos_compat -Wl,--no-whole-archive"\n' "$GCCLIB" "$GCCLIB" "$TOOLS" >> "$OUT/args.gn"
fi
if ! grep -q '^cros_target_extra_cflags = ' "$OUT/args.gn"; then
  printf 'cros_target_extra_cflags = "--target=arm-linux-gnueabi -B%s -march=armv7-a -mfloat-abi=softfp -mfpu=neon"\n' "$GCCLIB" >> "$OUT/args.gn"
fi
if ! grep -q '^clang_base_path = ' "$OUT/args.gn"; then
  printf 'clang_base_path = "%s"\n' "$V8ROOT" >> "$OUT/args.gn"
fi

mkdir -p "$SRC/buildtools/linux64"
mkdir -p "$V8ROOT/bin"
cp "$TOOLS/gn" "$SRC/buildtools/linux64/gn"
cp "$TOOLS/ninja" "$SRC/buildtools/linux64/ninja"
test -x "$WRAPPER"
ln -sfn clang-webos-wrapper "$TOOLS/clang-webos"
ln -sfn clang-webos-wrapper "$TOOLS/clang++-webos"
ln -sfn clang-webos-wrapper "$TOOLS/clang-host-webos"
ln -sfn clang-webos-wrapper "$TOOLS/clang++-host-webos"
cp "$TOOLS/v8-clang-wrapper" "$V8ROOT/bin/clang"
cp "$TOOLS/v8-clang-wrapper" "$V8ROOT/bin/clang++"
ln -sfn "$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-ar" "$V8ROOT/bin/llvm-ar"
ln -sfn "$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-nm" "$V8ROOT/bin/llvm-nm"
ln -sfn "$SRC/third_party/llvm-build/Release+Asserts/bin/llvm-readelf" "$V8ROOT/bin/llvm-readelf"
chmod +x "$SRC/buildtools/linux64/gn" "$SRC/buildtools/linux64/ninja"
chmod +x "$V8ROOT/bin/clang" "$V8ROOT/bin/clang++"

# The host wrappers and ARM assembly are now stable.  Keep their generated
# artifacts so subsequent source-only changes remain genuinely incremental.

"$CLANG" --target=arm-linux-gnueabi --sysroot=/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/.cache/webos-sysroot \
  -fPIC -c "$COMPAT_SRC" -o "$COMPAT_OBJ"
"$LLVM_AR" rcs "$COMPAT_LIB" "$COMPAT_OBJ"

"$SRC/buildtools/linux64/gn" --root="$SRC" gen "$OUT"
export WEBOS_CHROMIUM_SRC="$SRC"
export WEBOS_I386_SYSROOT="$I386SYS"
export WEBOS_I386_GCCLIB="$I386GCCLIB"
export PATH="$TOOLS:$PATH"
export PERL5LIB="$TOOLS/perl-lib${PERL5LIB:+:$PERL5LIB}"
# Build the bundled Wayland client explicitly. Its archive is an order-only
# GN dependency in this fork, so Ninja can otherwise reach the final link
# before materialising it.
stdbuf -oL -eL "$SRC/buildtools/linux64/ninja" -C "$OUT" -j80 wayland_client
stdbuf -oL -eL "$SRC/buildtools/linux64/ninja" -C "$OUT" -j80 browser_shell_webos
