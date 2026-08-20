# Chromium for webOS Homebrew

Experimental port of a modern Chromium browser to rooted LG webOS TVs.

The initial target is LG webOS TV 6.x. These televisions use a 64-bit ARM
kernel with a 32-bit ARM userspace and LG's private `webos-shell` Wayland
protocol. A stock Linux Chromium binary therefore cannot create a window.

## Current status

- Device audit completed on webOS 6.2.0 (`aarch64` kernel, ARMv7 userspace).
- Chromium 151 AArch64 executable verified on the target with a bundled
  userspace runtime.
- Stock Ozone/Wayland startup tested and confirmed to fail specifically because
  the compositor does not advertise `xdg-shell` or `wl_shell`.
- The existing `webos-wayland` and `webos-android-minimal` projects prove a
  SAM-managed `wl_shell` surface, Mali-G51 rendering, and an ARM64-to-ARM32
  VirGL bridge on this exact television.

The selected design is webOS OSE Chromium 120 compiled for the television's
ARMv7 userspace. It talks directly to LG's Wayland/EGL/GLES stack and Mali-G51;
there is no VirGL renderer, VM, protocol proxy, or framebuffer copy in the
graphics path. The fork already contains LG's private Ozone platform and its
browser shell supports Chromium extensions.

The GN graph currently generates successfully on an ARM64 Raspberry Pi host
(20,197 targets). Chromium 120 has now been fully linked for the TV's ARMv7
userspace: `browser_shell_webos` and `libcbe.so` are ELF32 ARM/EABI5 binaries,
with Chromium's extensions code enabled. The build artifact is kept on the
FMI cluster while the isolated SAM package and physical-device test are
prepared. The final Homebrew package will coexist with, and never overwrite,
LG's system browser.

## Repository layout

- `docs/feasibility.md`: measured device constraints and design decisions.
- `docs/build-result.md`: successful ARMv7 browser-shell link and checksums.
- `scripts/device-audit.sh`: read-only compatibility report for a TV.
- `scripts/probe-wayland.sh`: reproduces the stock Chromium incompatibility.
- `scripts/host-pkg-config`: ARM64 host helper for Debian/Ubuntu multiarch.
- `build/args.gn.in`: reproducible ARMv7 webOS build configuration.
- `patches/`: minimal changes needed to build LG's source on an ARM64 host.
- `package/org.webosbrew.chromium120/`: isolated SAM launcher and browser UI.
- `scripts/stage-chromium120.sh`: pulls the non-Git ELF payload into `dist/`.
- `scripts/install-tv.sh` and `scripts/launch-tv.sh`: direct-device test cycle.
- `upstream/`: pinned upstream source metadata.

Large Chromium sources, build output, downloaded runtimes, and IPKs are kept
out of Git. Releases will contain a small bootstrap IPK plus a versioned,
checksummed browser payload if the Homebrew repository's package-size rules
require it.

## Safety

Development artifacts are installed below `/mnt/lg/appstore`; no file under
`/usr/bin`, `/usr/lib`, or the built-in browser application is replaced.

## License

Project packaging and scripts are licensed under Apache-2.0. Chromium and its
third-party components retain their respective upstream licenses.
