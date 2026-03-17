/**
** @file    debug.h
**
** @author  Numerous CSCI-452 classes
**
** @brief   Debugging macros and constants.
**
*/

#ifndef DEBUG_H_
#define DEBUG_H_

// Standard system headers

#include <cio.h>
#include <support.h>

// Kernel library

#include <lib.h>

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

/**********************************************
** General function entry/exit announcements **
**********************************************/

#ifdef ANNOUNCE_ENTRY
// Announce that we have entered a kernel function
// usage: ENTERING( "name" ), EXITING( "name" )
// currently, these do not use the macro parameter, but could be
// modified to do so; instead, we use the __func__ CPP pseudo-macro
// to get the function name
#define ENTERING(n)    do { cio_puts( " enter " __func__ ); } while(0)
#define EXITING(n)     do { cio_puts( " exit "  __func__ ); } while(0)
#else
#define ENTERING(m)    // do nothing
#define EXITING(m)     // do nothing
#endif

/*****************************************************
** Console messages when error conditions are noted **
*****************************************************/

// Warning messages to the console
// m: message (condition, etc.)
#define WARNING(m)  do { \
		cio_printf( "\n** %s (%s @ %d): ", __func__, __FILE__, __LINE__ ); \
		cio_puts( m ); \
		cio_putchar( '\n' ); \
	} while(0)

// Panic messages to the console
// n: severity level - integer
// m: message (condition, etc.)
#define PANIC(n,m)  do { \
		sprint( bpanic, "%s (%s @ %d), %d: %s\n", \
				__func__, __FILE__, __LINE__, n, m ); \
		kpanic( bpanic ); \
	} while(0)

/***************************************
** Printing out system table contents **
***************************************/

// IDT entries are eight bytes
#define IDT_PRINT(v) cio_printf( \
		" [%02x] = %08x %08x @ %08x " # v "\n", (v), \
		*(uint32_t *) (IDT_ADDR + ((v)<<3)), \
		*(uint32_t *) (IDT_ADDR + ((v)<<3) + 4), \
		(IDT_ADDR + ((v)<<3)) )

// longword printing
#define MEM_PRINT_LW(base,v) cio_printf( \
		" [%02x] = %08x @ %08x " # v "\n", (v), \
		(base)[(v)], &((base)[(v)]) );

/***************
** Assertions **
***************/

/*
** Assertions are categorized by the "debug level" being used in this
** compilation; each only triggers a fault if the debug level is at or
** above a specific value.  This allows selective enabling/disabling of
** debugging checks.
**
** The debug level is set during compilation with the CPP macro
** "DBLV".  A debug level of 0 disables conditional assertions,
** but not the basic assert() version.
*/

#ifndef DBLV
// default debug check level: check everything!
#define DBLV  9999
#endif

// Always-active assertions
// usage:  assert(expr)
#define assert(x)  if( !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assertion %s failed\n", \
				__func__, __FILE__, __LINE__, # x ); \
		kpanic( bpanic ); \
	} while(0)

// only provide these macros if the debug check level is positive
// usage:  assert1(expr) etc.

#if DBLV > 0

#define assert1(x)  if( DBLV >= 1 && !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assert1 %s failed\n", \
				__func__, __FILE__, __LINE__, # x ); \
		kpanic( bpanic ); \
	} while(0)

#define assert2(x)  if( DBLV >= 2 && !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assert2 %s failed\n", \
				__func__, __FILE__, __LINE__, # x ); \
		kpanic( bpanic ); \
	} while(0)

#define assert3(x)  if( DBLV >= 3 && !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assert3 %s failed\n", \
				__func__, __FILE__, __LINE__, # x ); \
		kpanic( bpanic ); \
	} while(0)

#define assert4(x)  if( DBLV >= 4 && !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assert4 %s failed\n", \
				__func__, __FILE__, __LINE__, # x ); \
		kpanic( bpanic ); \
	} while(0)

// arbitrary debug level
#define assertN(n,x) if(DBLV >= (n) &&  !(x) ) { \
		sprint( bpanic, "%s (%s @ %d), assert%d %s failed\n", \
				__func__, __FILE__, __LINE__, n, # x ); \
		kpanic( bpanic ); \
	} while(0)

#else

#define	assert1(x)		// do nothing
#define	assert2(x)		// do nothing
#define	assert3(x)		// do nothing
#define	assert4(x)		// do nothing
#define	assertN(n,x)	// do nothing

#endif /* DBLV > 0 */

/************
** Tracing **
************/

/*
** Tracing options are enabled by defining one or more of the T_
** macros described in the Makefile.
**
** To add a tracing option:
**
**  1) Pick a short name for it (e.g., "PCB", "VM", ...)
**
**  2) At the end of this list, add code like this, with "name"
**     replaced by your short name, and "nnnnnnnn" replaced by a
**     unique bit that will designate this tracing option:
**
**        #ifdef T_name
**        #define TRname     0xnnnnnnnn
**        #else
**        #define TRname     0
**        #endif
**
**    Use the next bit position following the one in last list entry.
**
**  3) Add this to the end of the "TRACE" macro definition:
**
**        | TRname
**
**  4) In the list of "TRACING_*" macros, add one for your option
**     (using a name that might be more descriptive) in the 'then' clause:
**
**        #define TRACING_bettername  ((TRACE & TRname) != 0)
**
**  5) Also add a "null" version in the 'else' clause:
**
**        #define TRACING_bettername  0
**
**  6) Maybe add your T_name choice to the Makefile with an explanation
**     on the off chance you want anyone else to be able to understand
**     what it's used for. :-)
**
** We're making CPP work for its pay with this file.
*/

// 2^0 bit
#ifdef T_PCB
#define TRPCB           0x00000001
#else
#define TRPCB           0
#endif

#ifdef T_QUE
#define TRQUEUE         0x00000002
#else
#define TRQUEUE         0
#endif

#ifdef T_SCH
#define TRSCHED         0x00000004
#else
#define TRSCHED         0
#endif

#ifdef T_DSP
#define TRDISP          0x00000008
#else
#define TRDISP          0
#endif

// 2^4 bit
#ifdef T_SCALL
#define TRSCALLS        0x00000010
#else
#define TRSCALLS        0
#endif

#ifdef T_SRET
#define TRSRETS         0x00000020
#else
#define TRSRETS         0
#endif

#ifdef T_EXIT
#define TREXIT          0x00000040
#else
#define TREXIT          0
#endif

#ifdef T_KM
#define TRKMEM          0x00000080
#else
#define TRKMEM          0
#endif

// 2^8 bit
#ifdef T_INIT
#define TRINIT          0x00000100
#else
#define TRINIT          0
#endif

#ifdef T_SIO
#define TRSIO_ST        0x00000200
#else
#define TRSIO_ST        0
#endif

#ifdef T_SIOR
#define TRSIO_RD        0x00000400
#else
#define TRSIO_RD        0
#endif

#ifdef T_SIOW
#define TRSIO_WR        0x00000800
#else
#define TRSIO_WR        0
#endif

// 2^12 bit
#ifdef T_STK
#define TRSTK           0x00001000
#else
#define TRSTK           0
#endif

#ifdef T_STKS
#define TRSTKS          0x00002000
#else
#define TRSTKS          0
#endif

#ifdef T_KMI
#define TRKMIN          0x00004000
#else
#define TRKMIN          0
#endif

#ifdef T_KMF
#define TRKMFL          0x00008000
#else
#define TRKMFL          0
#endif

// 16 bits remaining for tracing options
// next available bit: 0x00010000

// macro for tracing everything
#define TRACE (TRPCB | TRQUEUE | TRSCHED | TRDISP | TRSCALLS | TRSRETS | TREXIT | TRKMEM | TRINIT | TRSIO_ST | TRSIO_RD | TRSIO_WR | TRSTK | TRSTKS | TRKMIN | TRKMFL)

#if TRACE > 0

// compile-time expressions for testing trace options
// usage:  #if TRACING_thing
#define TRACING_PCB             ((TRACE & TRPCB) != 0)
#define TRACING_QUEUE           ((TRACE & TRQUEUE) != 0)
#define TRACING_SCHED           ((TRACE & TRSCHED) != 0)
#define TRACING_DISPATCH        ((TRACE & TRDISP) != 0)
#define TRACING_SYSCALLS        ((TRACE & TRSCALLS) != 0)
#define TRACING_SYSRETS         ((TRACE & TRSRETS) != 0)
#define TRACING_EXIT            ((TRACE & TREXIT) != 0)
#define TRACING_KMEM            ((TRACE & TRKMEM) != 0)
#define TRACING_INIT            ((TRACE & TRINIT) != 0)
#define TRACING_SIO_ST          ((TRACE & TRSIO_ST) != 0)
#define TRACING_SIO_RD          ((TRACE & TRSIO_RD) != 0)
#define TRACING_SIO_WR          ((TRACE & TRSIO_WR) != 0)
#define TRACING_STACK           ((TRACE & TRSTK) != 0)
#define TRACING_STACK_SETUP     ((TRACE & TRSTKS) != 0)
#define TRACING_KMEM_INIT       ((TRACE & TRKMIN) != 0 )
#define TRACING_KMEM_LIST       ((TRACE & TRKMFL) != 0 )

// more generic tests
#define TRACING_ANYTHING        (TRACE != 0)

#else

// TRACE == 0, so just define these all as "false"

#define TRACING_PCB             0
#define TRACING_QUEUE           0
#define TRACING_SCHED           0
#define TRACING_DISPATCH        0
#define TRACING_SYSCALLS        0
#define TRACING_SYSRET          0
#define TRACING_EXIT            0
#define TRACING_KMEM            0
#define TRACING_INIT            0
#define TRACING_SI_ST           0
#define TRACING_SIO_RD          0
#define TRACING_SIO_WR          0
#define TRACING_STACK           0
#define TRACING_STACK_SETUP     0
#define TRACING_KMEM_INIT       0
#define TRACING_KMEM_LIST       0

#define TRACING_ANYTHING        0

#endif /* TRACE */

#endif /* !ASM_SRC */

#endif
