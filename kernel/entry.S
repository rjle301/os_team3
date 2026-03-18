##
# @file    entry.S
#
# @author  Jon Coles
# @author  Warren R. Carithers, K. Reek
#
# @brief   OS entry point.
#
# Based on   SCCS ID:	@(#)startup.S	2.6	1/23/25
#
# This code prepares the various registers for execution of
# the program.  It sets up all the segment registers and the
# runtime stack.  By the time this code is running, we're in
# protected mode already.
#
# Assembly-time options - define in Makefile
#
#    CLEAR_BSS    Include code to clear all BSS space
#    GET_MMAP     Retrieve the memory map from the BIOS
#

# GNU's CPP predefines i386
#undef i386
	.arch	i386

#define KERNEL_SRC
#define ASM_SRC

#include <memory.h>
#include <x86/arch.h>
#include <x86/bios.h>

#
# A symbol for locating the beginning of the code.
#
	.globl begtext

	.text
begtext:

#
# The entry point.
#
	.globl	_start

_start:
	cli                        # seems to be reset on entry to p. mode
	movb	$NMI_ENABLE, %al   # re-enable NMIs (bootstrap
	outb	$CMOS_ADDR         #   turned them off)

#
# Set the data and stack segment registers (code segment register
# was set by the long jump that switched us into protected mode).
#
	xorl	%eax, %eax	# clear EAX
	movw	$GDT_DATA, %ax	# GDT entry #3 - data segment
	movw	%ax, %ds	# for all four data segment registers
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs

	movw	$GDT_STACK, %ax	# entry #4 is the stack segment
	movw	%ax, %ss

	movl	$SYSTEM_STACK, %ebp	# set up the system frame pointer
	movl	%ebp, %esp	# and stack pointer

#ifdef CLEAR_BSS
#
# Zero the BSS segment
#
# These symbols are defined automatically by the linker.
#
	.globl	__bss_start, _end

	movl	$__bss_start, %edi
clearbss:
	movl	$0, (%edi)
	addl	$4, %edi
	cmpl	$_end, %edi
	jb	clearbss

#endif	/* CLEAR_BSS */

#
# Call the system initialization routine.
#
	.globl	main
	call	main

#
# At this point, main() must have created the first user
# process, and we're ready to shift into user mode.  The user
# stack for that process must have the initial context in it;
# we treat this as a "return from interrupt" event, and just
# transfer to the code that restores the user context.
#
	jmp	isr_restore   # defined in isrs.S

# This is here to make the GNU linker happy
	.section	.note.GNU-stack,"",@progbits
