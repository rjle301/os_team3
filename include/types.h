/**
** @file    types.h
**
** @author  Warren R. Carithers
**
** @brief   Common type declarations.
**
** This header file contains type declarations used throughout
** the kernel and user code.
*/

#ifndef TYPES_H_
#define TYPES_H_

#ifndef ASM_SRC

/*
** Start of C-only definitions
**
** Anything that should not be visible to something other than
** the C compiler should be put here.
*/

/*
** Types
*/

// standard integer sized types
typedef char                   int8_t;
typedef unsigned char          uint8_t;
typedef short                  int16_t;
typedef unsigned short         uint16_t;
typedef int                    int32_t;
typedef unsigned int           uint32_t;
typedef long long int          int64_t;
typedef unsigned long long int uint64_t;

// other integer types
typedef unsigned char          uchar_t;
typedef unsigned int           uint_t;
typedef unsigned long int      ulong_t;

// Boolean values
typedef uint8_t                bool_t;

// Process IDs
typedef int32_t                pid_t;

// Priorities
typedef uint8_t                prio_t;

// System time
typedef uint32_t               time_t;

#define true    1
#define false   0

#endif	/* !ASM_SRC */

#endif
