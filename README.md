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

The preferred design is now a stock, current AArch64 Chromium plus a small
`xdg-shell` to webOS `wl_shell` adapter. This avoids maintaining a Chromium
fork. The webOS OSE Chromium 120 fork remains the fallback and reference
implementation. The final Homebrew package will not overwrite LG's system
browser.

## Repository layout

- `docs/feasibility.md`: measured device constraints and design decisions.
- `scripts/device-audit.sh`: read-only compatibility report for a TV.
- `scripts/probe-wayland.sh`: reproduces the stock Chromium incompatibility.
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
