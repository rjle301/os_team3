/**
** @file	ulibc.c
**
** @author	numerous CSCI-452 classes
**
** @brief	C implementations of user-level library functions.
**
** We create a single object file with all the user-level functions
** in it so that we can bind it into the user blob and avoid having
** any name space contamination between kernel and user levels.
*/

#include <common.h>

#include <lib.h>

/*
**********************************************
** MEMORY MANIPULATION FUNCTIONS
**********************************************
*/

#include <lib/blkmov.c>
#include <lib/memclr.c>
#include <lib/memcpy.c>
#include <lib/memmove.c>
#include <lib/memset.c>

/*
**********************************************
** STRING MANIPULATION FUNCTIONS
**********************************************
*/

#include <lib/pad.c>
#include <lib/padstr.c>
#include <lib/sprint.c>
#include <lib/str2int.c>
#include <lib/strcat.c>
#include <lib/strcmp.c>
#include <lib/strcpy.c>
#include <lib/strlen.c>

/*
**********************************************
** CONVERSION FUNCTIONS
**********************************************
*/

#include <lib/bound.c>
#include <lib/cvtdec.c>
#include <lib/cvtdec0.c>
#include <lib/cvthex.c>
#include <lib/cvtoct.c>
#include <lib/cvtuns.c>
#include <lib/cvtuns0.c>

/*
**********************************************
** CONVENIENT "SHORTHAND" VERSIONS OF SYSCALLS
**********************************************
*/

#include <lib/uextras.c>
