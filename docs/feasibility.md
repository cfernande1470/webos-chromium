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
webOS OSE Chromium 120 (ARM32, extensions enabled)
  -> LG Ozone webOS platform (wl_shell / wl_webos_shell)
  -> LG ARM32 Wayland + EGL/GLES
  -> Mali-G51
```

This is the only tested design that has no graphics translation or copying.
It also reuses two results already validated on the target:

- `cfernande1470/webos-wayland`: stable SAM lifecycle, `wl_shell`, remote
  input, and direct Mali EGL/GLES;
- `cfernande1470/webos-android-minimal`: Mesa 26 virpipe AArch64 to patched
  virglrenderer ARM32, shared memfd resources, and Mali-G51 presentation.

LG's open-source Chromium 120 fork has:

- the browser-shell-based UI introduced by webOS OSE 2.27;
- LG's `webos-shell` Ozone implementation;
- Chromium's extensions subsystem and Manifest V3 support;
- an upstream OpenEmbedded recipe at version `120.0.6099.269-16`.

Chromium 120 is behind desktop stable, but it is substantially newer than the
TV's Chromium 79 and is the newest LG fork currently available with the private
webOS window-system integration. A stock Chromium 151 adapter remains a future
upgrade path after the direct port is working.

## Remaining gates

1. Deploy the linked ARMv7 binary as an isolated SAM-managed application and
   validate direct EGL.
2. Implement remote-control key mapping, virtual keyboard, audio, downloads,
   and lifecycle handling.
3. Verify unpacked extension installation and persistence. Chrome Web Store
   installation may require Google service integration not present in Chromium;
   local CRX/unpacked installation remains the required acceptance criterion.
4. Measure memory pressure and video performance on the physical TV.
5. Package without modifying the built-in browser and publish reproducible
   release manifests for webOS Homebrew.
