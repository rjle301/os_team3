/**
** @file    lib.h
**
** @author  Various CSCI-452 classes
**
** @brief   Declarations for library functions
**
** This header file provides prototypes for "common" library
** functions (i.e., ones that can be called from either user-level
** or kernel-level code). It then includes the appropriate header
** file for level-specific functions.
**
** Care should be taken that kernel- and user-level code use separate
** versions of these functions to avoid memory protection issues if
** virtual memory is implemented.
**
** Compile-time options - define in Makefile:
**
**    RENAME_LIB    Rename library functions for user-level code
*/

#ifndef LIB_H_
#define LIB_H_

#ifndef KERNEL_SRC

/*
** If we're compiling user-level code, make sure the rename.h header
** is pulled in first if we are renaming the functions
*/

#ifdef RENAME_LIB
#include <rename.h>
#endif

#endif  /* !KERNEL_SRC */

// some other things we need to be sure were included
#include <types.h>

/*
** General (C and/or assembly) definitions
*/

#ifndef ASM_SRC

// used by several functions
extern const char hexdigits[];

/*
**********************************************
** MEMORY MANIPULATION FUNCTIONS
**********************************************
*/

/**
** blkmov(dst,src,len)
**
** Copy a word-aligned block from src to dst. Deals with overlapping
** buffers.
**
** If the buffer addresses aren't word-aligned or the length is not a
** multiple of four, calls memmove().
**
** @param[out] dst   Destination buffer
** @param[in]  src   Source buffer
** @param[in]  len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len );

/**
** memset(buf,len,value)
**
** initialize all bytes of a block of memory to a specific value
**
** @param[out] buf    The buffer to initialize
** @param[in]  len    Buffer size (in bytes)
** @param[in]  value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value );

/**
** memclr(buf,len)
**
** Initialize all bytes of a block of memory to zero
**
** @param[out] buf    The buffer to initialize
** @param[in]  len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len );

/**
** memcpy(dst,src,len)
**
** Copy a block from one place to another
**
** May not correctly deal with overlapping buffers
**
** @param[out] dst   Destination buffer
** @param[in]  src   Source buffer
** @param[in]  len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len );

/**
** memmove(dst,src,len)
**
** Copy a block from one place to another. Deals with overlapping
** buffers
**
** @param[out] dst   Destination buffer
** @param[in]  src   Source buffer
** @param[in]  len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len );

/*
**********************************************
** STRING MANIPULATION FUNCTIONS
**********************************************
*/

/**
** str2int(str,base) - convert a string to a number in the specified base
**
** @param[in]  str   The string to examine
** @param[in]  base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base );

/**
** strlen(str) - return length of a NUL-terminated string
**
** @param[in]  str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str );

/**
** strcmp(s1,s2) - compare two NUL-terminated strings
**
** @param[in]  s1 The first source string
** @param[in]  s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 );

/**
** strcpy(dst,src) - copy a NUL-terminated string
**
** @param[out] dst The destination buffer
** @param[in]  src The source buffer
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src );

/**
** strcat(dst,src) - append one string to another
**
** @param[out] dst The destination buffer
** @param[in]  src The source buffer
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src );

/**
** strchr(str,ch) - locate first occurrence a character in a string
**
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strchr( register const char *str, register char ch );

/**
** strrchr(str,ch) - locate last occurrence of a character in a string
**
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strrchr( register const char *str, register char ch );

/**
** pad(dst,extra,padchar) - generate a padding string
**
** @param[out] dst     Pointer to where the padding should begin
** @param[in]  extra   How many padding bytes to add
** @param[in]  padchar What character to pad with
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar );

/**
** padstr(dst,str,len,width,leftadjust,padchar - add padding characters
**                                               to a string
**
** @param[out] dst        The destination buffer
** @param[in]  str        The string to be padded
** @param[in]  len        The string length, or -1
** @param[in]  width      The desired final length of the string
** @param[in]  leftadjust Should the string be left-justified?
** @param[in]  padchar    What character to pad with
**
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar );

/**
** sprint(dst,fmt,...) - formatted output into a string buffer
**
** @param[out] dst The string buffer
** @param[in]  fmt Format string
**
** The format string parameter is followed by zero or more additional
** parameters which are interpreted according to the format string.
**
** NOTE:  assumes the buffer is large enough to hold the result string
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... );

/*
**********************************************
** CONVERSION FUNCTIONS
**********************************************
*/

/**
** cvtuns0(buf,value) - local support routine for cvtuns()
**
** Convert a 32-bit unsigned value into a NUL-terminated character string
**
** @param[out] buf    Result buffer
** @param[in]  value  Value to be converted
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value );

/**
** cvtuns(buf,value)
**
** Convert a 32-bit unsigned value into a NUL-terminated character string
**
** @param[out] buf    Result buffer
** @param[in]  value  Value to be converted
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value );

/**
** cvtdec0(buf,value) - local support routine for cvtdec()
**
** convert a 32-bit unsigned integer into a NUL-terminated character string
**
** @param[out] buf    Destination buffer
** @param[in]  value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value );

/**
** cvtdec(buf,value)
**
** convert a 32-bit signed value into a NUL-terminated character string
**
** @param[out] buf    Destination buffer
** @param[in]  value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value );

/**
** cvthex(buf,value)
**
** convert a 32-bit unsigned value into a mininal-length (up to
** 8-character) NUL-terminated character string
**
** @param[out] buf    Destination buffer
** @param[in]  value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value );

/**
** cvtoct(buf,value)
**
** convert a 32-bit unsigned value into a mininal-length (up to
** 11-character) NUL-terminated character string
**
** @param[out] buf   Destination buffer
** @param[in]  value Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value );

/**
** bound(min,value,max)
**
** This function confines an argument within specified bounds.
**
** @param[in]  min    Lower bound
** @param[in]  value  Value to be constrained
** @param[in]  max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max );

/*
** Finally, pull in the level-specific library headers
*/
#ifdef KERNEL_SRC
#include <klib.h>
#else
#include <ulib.h>
#endif  /* KERNEL_SRC */

#endif /* !ASM_SRC */

#endif
