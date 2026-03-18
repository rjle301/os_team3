/**
** @file	str2int.c
**
** @author	Numerous CSCI-452 classes
**
** @brief	C implementations of common library functions
*/

#ifndef STR2INT_SRC_INC
#define STR2INT_SRC_INC

#include <common.h>

#include <lib.h>

/**
** str2int(str,base) - convert a string to a number in the specified base
**
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
	register int num = 0;
	register char bchar = '9';
	int sign = 1;

	// check for leading '-'
	if( *str == '-' ) {
		sign = -1;
		++str;
	}

	if( base != 10 ) {
		// fix the bchar
		bchar = '0' + base - 1;
		// skip any prefix
		if( base == 16 ) {
			// bchar is wrong
			bchar = 'F';
			// prefix: 0x or 0X
			if( *str == '0' && (*(str+1) == 'x' || *(str+1) == 'X') ) {
				str += 2;
			}
		} else if( base == 2 ) {
			// prefix: 0b or 0B
			if( *str == '0' && (*(str+1) == 'b' || *(str+1) == 'B') ) {
				str += 2;
			}
		}
	}

	// iterate through the characters
	while( *str ) {
		char ch = UCASE(*str);
		char *ptr = strchr( hexdigits, ch );
		if( ptr == NULL ) {
			// impossible character
			break;
		} else if( *ptr > bchar ) {
			// outside the valid character range for this base
			break;
		}

		// convert character to integer
		int digit = ptr - hexdigits;
		num = num * base + digit;
		++str;
	}

	// return the converted value
	return( num * sign );
}

#endif
