/**
** @file    kdefs.h
**
** @author  CSCI-452 class of 20255
** @author  Numerous CSCI-452 classes
**
** @brief   Kernel-only declarations.
*/

#ifndef KDEFS_H_
#define KDEFS_H_

// debugging macros
#include <debug.h>
#include <x86/arch.h>

/*
** General (C and/or assembly) definitions
*/

// default contents of EFLAGS for new processes
#define DEFAULT_EFLAGS   (EFL_MB1 | EFL_IF)

// page sizes
#define	SZ_PAGE          NUM_4KB
#define SZ_BIGPAGE       NUM_4MB

// declarations for modulus checking of (e.g.) sizes and addresses

#define LOW_9_BITS       0x00000fff
#define LOW_22_BITS      0x003fffff
#define HIGH_20_BITS     0xfffff000
#define HIGH_10_BITS     0xffc00000

#define MOD4_BITS        0x00000003
#define MOD4_MASK        0xfffffffc
#define MOD4_INC         0x00000004
#define MOD4_SHIFT       2
#define DIV4(x)          ((x) >> MOD4_SHIFT)
#define MOD4(x)          ((x) & MOD4_BITS)
#define MUL4(x)          ((x) << MOD4_SHIFT)

#define MOD16_BITS       0x0000000f
#define MOD16_MASK       0xfffffff0
#define MOD16_INC        0x00000010
#define MOD16_SHIFT      4
#define DIV16(x)         ((x) >> MOD16_SHIFT)
#define MOD16(x)         ((x) & MOD16_BITS)
#define MUL16(x)         ((x) << MOD16_SHIFT)

#define	MOD1K_BITS       0x000003ff
#define MOD1K_MASK       0xfffffc00
#define MOD1K_INC        0x00000400
#define MOD1K_SHIFT      10
#define DIV1K(x)         ((x) >> MOD1K_SHIFT)
#define MOD1K(x)         ((x) & MOD1K_BITS)
#define MUL1K(x)         ((x) << MOD1K_SHIFT)

#define	MOD4K_BITS       0x00000fff
#define MOD4K_MASK       0xfffff000
#define MOD4K_INC        0x00001000
#define MOD4K_SHIFT      12
#define DIV4K(x)         ((x) >> MOD4K_SHIFT)
#define MOD4K(x)         ((x) & MOD4K_BITS)
#define MUL4K(x)         ((x) << MOD4K_SHIFT)

#define	MOD1M_BITS       0x000fffff
#define MOD1M_MASK       0xfff00000
#define MOD1M_INC        0x00100000
#define MOD1M_SHIFT      20
#define DIV1M(x)         ((x) >> MOD1M_SHIFT)
#define MOD1M(x)         ((x) & MOD1M_BITS)
#define MUL1M(x)         ((x) << MOD1M_SHIFT)

#define	MOD4M_BITS       0x003fffff
#define MOD4M_MASK       0xffc00000
#define MOD4M_INC        0x00400000
#define MOD4M_SHIFT      22
#define DIV4M(x)         ((x) >> MOD4M_SHIFT)
#define MOD4M(x)         ((x) & MOD4M_BITS)
#define MUL4M(x)         ((x) << MOD4M_SHIFT)

#define	MOD1G_BITS       0x3fffffff
#define MOD1G_MASK       0xc0000000
#define MOD1G_INC        0x40000000
#define MOD1G_SHIFT      30
#define DIV1G(x)         ((x) >> MOD1G_SHIFT)
#define MOD1G(x)         ((x) & MOD1G_BITS)
#define MUL1G(x)         ((x) << MOD1G_SHIFT)

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

/*
** Utility macros
*/

//
// macros for access registers and system call arguments
//

// REG(pcb,x) -- access a specific register in a process context
#define REG(pcb,x)  ((pcb)->context->x)

// RET(pcb) -- access return value register in a process context
#define RET(pcb)    ((pcb)->context->eax)

// ARG(pcb,n) -- access argument #n from the indicated process
//
// ARG(pcb,0) --> return address
// ARG(pcb,1) --> first parameter
// ARG(pcb,2) --> second parameter
// etc.
//
// ASSUMES THE STANDARD 32-BIT ABI, WITH PARAMETERS PUSHED ONTO THE
// STACK.  IF THE PARAMETER PASSING MECHANISM CHANGES, SO MUST THIS!
#define ARG(pcb,n)  ( ( (uint32_t *) (((pcb)->context) + 1) ) [(n)] )

/*
** Types
*/

/*
** Error codes for internal function calls
*/

enum ecode_e {
	E_SUCCESS = 0,        // "no error" error
	E_FAILURE,            // generic "something went wrong"
	E_BAD_CHAN,           // invalid i/o channel number
	E_BAD_PARAM,          // unexpected parameter value
	E_EMPTY,              // (queue) is empty
	E_NOT_FOUND,          // (queue) item was not found
	E_NO_CHILDREN,        // no child processes found
	E_NO_PCBS,            // (proc) cannot find an unused PCB
	E_NO_QNODES,          // (queue) cannot allocate a qnode
	// sentinel
	N_ECODES
};

// aliases
#define	SUCCESS    E_SUCCESS
#define FAILURE    E_FAILURE

/*
** Globals
*/

// general-purpose character buffers
extern char b256[256];
extern char b512[512];

// buffer for use by PANIC() macro
extern char bpanic[512];

// array containing important user-space addresses
// the kernel needs to know about
extern uint32_t *user_locs;      // the address as a pointer

// "user blob" location information
extern uint16_t user_offset;
extern uint16_t user_segment;
extern uint16_t user_sectors;

// indices into that array
#define	ULOC_INIT    0
#define ULOC_FAKE    1

/*
** Prototypes
*/

#endif  /* !ASM_SRC */

#endif
