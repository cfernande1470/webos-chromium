# Chromium 120 app payload

`org.webosbrew.chromium120` is the isolated SAM application wrapper around
the ARMv7 webOS browser-shell binary. The large ELF payload is deliberately
not committed to Git. Build it on the FMI cluster, then stage it locally with:

```bash
./scripts/stage-chromium120.sh
```

The resulting `dist/org.webosbrew.chromium120` directory contains the
launcher, the browser-shell executable, `libcbe.so`, Chromium data files, and
the small browser UI. The launcher sets the webOS Wayland environment and
keeps the user data below `$HOME/.cache/chromium120`; it never replaces the
system browser.
