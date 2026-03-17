/**
** @file	strchr.c
**
** @author	Numerous CSCI-452 classes
**
** @brief	C implementations of common library functions
*/

#ifndef STRCHR_SRC_INC
#define STRCHR_SRC_INC

#include <common.h>

#include <lib.h>

/**
** strchr(str,ch) - locate first occurrence a character in a string
**
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strchr( register const char *str, register char ch ) {

	if( str == NULL ) {
		return NULL;
	}

	// scan from the beginning of the string
	while( *str ) {
		if( *str == ch ) {
			return (char *) str;
		}
		++str;
	}

	return NULL;
}

/**
** strrchr(str,ch) - locate last occurrence of a character in a string
**
** @param str[in] The string to examine
** @param ch[in]  The character to look for
**
** @return Pointer to the first 'ch' in 'str', or NULL
*/
char *strrchr( register const char *str, register char ch ) {
	register char *ptr = (char *) str;

	if( str == NULL ) {
		return NULL;
	}

	// find the NUL, and back up one position
	ptr += strlen(str) - 1;

	// scan backward
	while( ptr >= str && *ptr ) {
		if( *ptr == ch ) {
			return ptr;
		}
		--ptr;
	}

	return NULL;
}
#endif
