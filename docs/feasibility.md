# Feasibility report

## Tested target

| Property | Measured value |
| --- | --- |
| OS | webOS TV 6.2.0 |
| Kernel | Linux 4.4.84, AArch64, `CONFIG_COMPAT=y` |
| LG userspace | ARM EABI5 / 32-bit |
| libc | glibc 2.28 (32-bit) |
| RAM | 2615 MiB + 599 MiB swap |
| Application storage | 2.7 GiB total, about 1.5 GiB initially free |
| Display | Wayland socket `/tmp/xdg/wayland-0` |
| Built-in engine | Chromium/WebAppMgr 79, extensions explicitly disabled |

## Experiments

An ungoogled-chromium 151.0.7922.71 ARM64 binary was run successfully on the
TV with its own AArch64 dynamic loader and libraries. This proves that an
AArch64 payload can coexist with the television's 32-bit userspace.

The same binary was then started with Ozone Wayland. It connected to the
compositor but exited with `No Wayland shell found`. A separate native probe
shows that the LG compositor advertises `wl_shell` and `wl_webos_shell`, while
current Chromium only supports desktop Linux `xdg-shell`. Bundling a normal
AppImage without a protocol adapter is consequently not a viable graphical
port.

## Selected architecture

The preferred architecture is:

```text
Chromium AArch64 (current upstream, extensions enabled)
  -> xdg-shell + wl_shm or Mesa virpipe
  -> ARM32 SAM-managed compatibility host
     - xdg-shell to wl_shell / wl_webos_shell
     - optional virglrenderer
  -> LG ARM32 Wayland + Mali EGL/GLES
  -> Mali-G51
```

This reuses two results already validated on the target:

- `cfernande1470/webos-wayland`: stable SAM lifecycle, `wl_shell`, remote
  input, and direct Mali EGL/GLES;
- `cfernande1470/webos-android-minimal`: Mesa 26 virpipe AArch64 to patched
  virglrenderer ARM32, shared memfd resources, and Mali-G51 presentation.

The display bridge should first pass Chromium's software-rendered `wl_shm`
buffers without copying. VirGL acceleration is a second milestone, not a
prerequisite for proving browser UI and extensions.

LG's open-source Chromium 120 fork remains the fallback. It has:

- the browser-shell-based UI introduced by webOS OSE 2.27;
- LG's `webos-shell` Ozone implementation;
- Chromium's extensions subsystem and Manifest V3 support;
- an upstream OpenEmbedded recipe at version `120.0.6099.269-16`.

Using it would avoid the protocol bridge but creates a large, security-sensitive
fork that is already behind current Chromium. It is useful as protocol and
lifecycle reference code, not the first choice for long-term maintenance.

## Remaining gates

1. Implement a minimal `xdg-shell` server backed by the proven SAM-managed
   `wl_shell` client; initially relay `wl_shm` buffers and input.
2. Launch Chromium 151 through that adapter and validate a visible browser UI.
3. Reuse the existing VirGL bridge for accelerated rendering if the software
   path is not sufficiently responsive.
4. Implement remote-control key mapping, virtual keyboard, audio, downloads,
   and lifecycle handling.
5. Verify unpacked extension installation and persistence. Chrome Web Store
   installation may require Google service integration not present in Chromium;
   local CRX/unpacked installation remains the required acceptance criterion.
6. Measure memory pressure and video performance on the physical TV.
7. Package without modifying the built-in browser and publish reproducible
release manifests for webOS Homebrew.
