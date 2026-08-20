#ifndef _LINUX_MEMFD_H
#define _LINUX_MEMFD_H

/* Minimal memfd_create() flags needed by Chromium's Mojo and allocator code.
 * The old webOS UAPI headers do not ship linux/memfd.h. */
#define MFD_CLOEXEC       0x0001U
#define MFD_ALLOW_SEALING 0x0002U

#endif
