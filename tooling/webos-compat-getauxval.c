/* Minimal getauxval shim for the old webOS glibc 2.12 userspace.
 * Chromium/BoringSSL only needs capability probes; returning the ARM NEON
 * bit and zero for optional entries is sufficient and keeps the shim ABI
 * compatible with glibc's getauxval().
 */
#define AT_HWCAP 16
#define AT_HWCAP2 26

unsigned long getauxval(unsigned long type) {
  if (type == AT_HWCAP)
    return 1UL << 12; /* HWCAP_NEON on ARM EABI. */
  if (type == AT_HWCAP2)
    return 0;
  return 0;
}
