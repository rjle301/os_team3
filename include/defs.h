/**
** @file    defs.h
**
** @author  Warren R. Carithers
**
** @brief   Common definitions.
**
** This header file defines things which are neede by all
** parts of the system (OS and user levels).
**
** Things which are kernel-specific go in the kdefs.h file;
** things which are user-specific go in the udefs.h file.
** The correct one of these will be automatically included
** at the end of this file based on the (non-)existence of
** the symbol KERNEL_SRC.
*/

#ifndef DEFS_H_
#define DEFS_H_

#include <types.h>

/*
** General (C and/or assembly) definitions
**
** This section of the header file contains definitions that can be
** used in either C or assembly-language source code.
*/

// NULL pointer value
//
// we define this the traditional way so that
// it's usable from both C and assembly

#ifdef NULL
#undef NULL
#endif

#define NULL                0

// predefined i/o channels

#define CHAN_CIO            0
#define CHAN_SIO            1


// sizes of various things
#define NUM_1KB           0x00000400    // 2^10
#define NUM_4KB           0x00001000    // 2^12
#define NUM_1MB           0x00100000    // 2^20
#define NUM_4MB           0x00400000    // 2^22
#define NUM_1GB           0x40000000    // 2^30
#define NUM_2GB           0x80000000    // 2^31
#define NUM_3GB           0xc0000000    // 1GB + 2GB

#ifndef ASM_SRC

// macros to up/down case an alphabetic character
#define LCASE(c)          (((c) >= 'A' && (c) <= 'Z') ? ((c)|0x20) : (c))
#define UCASE(c)          (((c) >= 'a' && (c) <= 'z') ? ((c)&0xdf) : (c))

// quick-and-dirty ISPRINT() replacement
#define ISPRINT(c) (((c) >= ' ' && (c) < 0x7f) || (c) == '\n' || (c) == '\t')

/*
** Start of C-only definitions
**
** Anything that should not be visible to something other than
** the C compiler should be put here.
*/

// unit conversion macros
#define B_TO_KB(x)      (((uint_t)(x))>>10)
#define B_TO_MB(x)      (((uint_t)(x))>>20)
#define B_TO_GB(x)      (((uint_t)(x))>>30)

#define KB_TO_B(x)      (((uint_t)(x))<<10)
#define KB_TO_MB(x)     (((uint_t)(x))>>10)
#define KB_TO_GB(x)     (((uint_t)(x))>>20)

#define MB_TO_B(x)      (((uint_t)(x))<<20)
#define MB_TO_KB(x)     (((uint_t)(x))<<10)
#define MB_TO_GB(x)     (((uint_t)(x))>>10)

#define GB_TO_B(x)      (((uint_t)(x))<<30)
#define GB_TO_KB(x)     (((uint_t)(x))<<20)
#define GB_TO_MB(x)     (((uint_t)(x))<<10)

// potetially useful compiler attributes
#define ATTR_ALIGNED(x) __attribute__((__aligned__(x)))
#define ATTR_PACKED     __attribute__((__packed__))
#define ATTR_UNUSED     __attribute__((__unused__))

// macros to clear data structures (usable for clearing single-valued
// data times, such as structs or arrays of known dimension)
#define CLEAR(v)        memclr( &v, sizeof(v) )
#define CLEAR_PTR(p)    memclr( p, sizeof(*p) )

/*
** Process priority values
**
** Priority type prio_t is defined in <types.h>
*/
enum priority_e {
	PRIO_HIGH, PRIO_STD, PRIO_LOW,
	// sentinel
	N_PRIOS,
	// special "inherit parent's priority" value
	PRIO_INHERIT = 0x80
};

// standard priority boundaries
#define PRIO_FIRST    PRIO_HIGH
#define PRIO_LAST     PRIO_LOW

// halves of various data sizes

#define UI16_UPPER		0xff00
#define UI16_LOWER		0x00ff

#define UI32_UPPER		0xffff0000
#define UI32_LOWER		0x0000ffff

#define UI64_UPPER		0xffffffff00000000LL
#define UI64_LOWER		0x00000000ffffffffLL

// Simple conversion pseudo-functions usable by everyone

// convert seconds to ms
#define SEC_TO_MS(n)	((n) * 1000)

// Status return values from system calls
#define	S_OK            0
#define	S_ERROR         (-1)
#define S_NOT_FOUND     (-2)
#define S_BAD_SYSCALL   (-3)
#define S_NO_CHILD      (-4)
#define S_BAD_CHAN      (-5)

#endif	/* !ASM_SRC */

/*
** Level-specific definitions
*/
#ifdef KERNEL_SRC
#include <kdefs.h>
#else
#include <udefs.h>
#endif  /* KERNEL_SRC */

#endif
