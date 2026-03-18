/*
** @file    klib.h
**
** @author  Various CSCI-452 classes
**
** @brief   Declarations for kernel-level library functions
**
** This header provides prototypes for library functions that are
** only callable from kernel-level code. "Common" library functions
** are detailed in <lib.h>, which will include this file when
** compiling kernel-level code.
*/

#ifndef KLIB_H_
#define KLIB_H_

#include <common.h>

#ifndef ASM_SRC

#include <x86/ops.h>

/**
** Name:    put_char_or_code( ch )
**
** Description: Prints a character on the console, unless it
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch );

/**
** Name:    backtrace
**
** Perform a simple stack backtrace. Could be augmented to use the
** symbol table to print function/variable names, etc., if so desired.
**
** @param[in] ebp   Initial EBP to use
** @param[in] args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args );

/*
** delay - pause for some length of time
**
** Notes:  The parameter to the delay() function is ambiguous; it
** purports to indicate a delay length, but that isn't really tied
** to any real-world time measurement.
**
** On the original systems we used (dual 500MHz Intel P3 CPUs), each
** "unit" was approximately one tenth of a second, so delay(10) would
** delay for about one second.
**
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
*/
void delay( int length );

/**
** Name:	kpanic
**
** Kernel-level panic routine
**
** usage:  kpanic( msg )
**
** Prefix routine for panic() - can be expanded to do other things
** (e.g., printing a stack traceback)
**
** @param[in] msg  String containing a relevant message to be printed,
**                 or NULL
*/
void kpanic( const char *msg );

#endif  /* !ASM_SRC */

#endif
