# Chromium 120 ARMv7 build result

The first complete browser-shell link was performed on FMI node `vcl1100`
with Slurm job `16254` (80 CPUs, 300 GB RAM). The build completed with exit
code zero.

The persistent artifact directory is:

```text
/tachyon/groups/gstructb/ferncarl/software/webos-chromium-build/artifacts/chromium120-arm
```

The two ELF payloads are ARM EABI5, 32-bit, PIE/shared objects using the
television's `/lib/ld-linux.so.3` runtime:

```text
browser_shell_webos  ELF 32-bit LSB pie executable, ARM, EABI5
libcbe.so            ELF 32-bit LSB shared object, ARM, EABI5
```

Checksums from the successful link:

```text
bc3a85f8fec4589e6f234b000b69c11a52bc89e8b3d3161d48fafcdb023dc7d2  browser_shell_webos
cca1e1bd01bb20cee0d57aff775cc1a230cba7419629dbc3aed22ff5824c9150  libcbe.so
```

The runtime links against the webOS system Wayland/EGL/GLES stack and does
not replace or modify LG's built-in browser. Physical deployment and memory,
input, audio, and extension persistence tests are the next gates.
