/**
** @file	rename.h
**
** @author	CSCI-452 class of 20255
**
** @brief	Provide renaming for user-level library functions.
**
** In order to provide the same set of library functions at the user
** and kernel levels but ensure that the code blobs remain separate,
** we rename the library functions at user level by prepending a 'u'
** character to the actual name. This allows us to use one set of
** source files for the library.
*/

#ifndef RENAME_H_
#define RENAME_H_

// only process these if we're NOT compiling kernel code
#ifndef KERNEL_SRC

#define	blkmov	ublkmov
#define	bound	ubound
#define	cvtdec0	ucvtdec0
#define	cvtdec	ucvtdec
#define	cvthex	ucvthex
#define	cvtoct	ucvtoct
#define	cvtuns0	ucvtuns0
#define	cvtuns	ucvtuns
#define	memclr	umemclr
#define	memcpy	umemcpy
#define	memmove	umemmove
#define	memset	umemset
#define	padstr	upadstr
#define	pad	upad
#define	sprint	usprint
#define	str2int	ustr2int
#define	strcat	ustrcat
#define	strcmp	ustrcmp
#define	strcpy	ustrcpy
#define	strlen	ustrlen

#endif  /* KERNEL_SRC */

#endif
