##
# @file		locations.S
#
# @author	CSCI-452 class of 20255
#
# @brief	Pointers to 'init' and 'fake_exit' in the user blob
#
# This file creates two 32-bit pointers at the beginning of the text
# section in the user blob; it must be linked in as the first object
# file when that is created. The kernel looks at those two locations
# to get the addresses of the 'init' program and the 'fake_exit'
# library function.
#
# Yes, it's ugly.
#
# THIS MUST BE LINKED AS THE FIRST THING IN THE USER BLOB.
#

# GNU's CPP predefines this
#undef i386
	.arch	i386

#define	ASM_SRC

	.text

#
# This allows us to fake out the linker if it expects these symbols
	.globl	begtext
begtext:
	.globl	_start
_start:

	.globl	locations
	.globl	init
	.globl	idle
	.globl	fake_exit
locations:
	.long	init
	.long	fake_exit

# This is here to make the GNU linker happy
	.section	.note.GNU-stack,"",@progbits
