##
# @file		usys.S
#
# @author	CSCI-452 class of 20255
#
# @brief	assembly-language user-level library functions
#

# GNU's CPP predefines this
#undef i386
	.arch	i386

#define	ASM_SRC

# get the system call codes

#include <syscalls.h>

##
# System call stubs
#
# All have the same structure:
#
#      move a code into EAX
#      generate the interrupt
#      return to the caller
#
# As these are simple "leaf" routines, we don't use
# the standard enter/leave method to set up a stack
# frame - that takes time, and we don't really need it.
#
# Could be modified to use the UNIX/Linux convention of
# having the syscall code set the 'C' flag to indicate that
# the value being returned in %EAX is an error code:
#
#	  ...
#	int	$VEC_SYSCALL
#	jc	set_errno
#	ret
#	  ...
#
#	.globl	errno
# set_errno:
#	movl	%eax, errno
#	movl	$-1, %eax
#	ret
#

#define	SYSCALL(name) \
	.globl	name			; \
name:					; \
	movl	$SYS_##name, %eax	; \
	int	$VEC_SYSCALL	; \
	ret

#
# "real" system calls
#

SYSCALL(exit)
SYSCALL(wait)
SYSCALL(fork)
SYSCALL(exec)
SYSCALL(read)
SYSCALL(write)
SYSCALL(sleep)
SYSCALL(getpid)
SYSCALL(gettime)
SYSCALL(getprio)

#VGA syscalls
SYSCALL(setvga256linear)
SYSCALL(setvgatextmode)
SYSCALL(writepixel)
SYSCALL(getheight)
SYSCALL(getwidth)
SYSCALL(getfbsegment)

#p100 syscalls
SYSCALL(send)

#
# This is a bogus system call; it's here so that we can test
# our handling of out-of-range syscall codes in the syscall ISR.
#
SYSCALL(bogus)

#
# Other library functions
#

##
# fake_exit()
#
# This little function takes the place of a real crt0-style startup
# program. A real one would set up the environment, call main(), and
# then call exit(). We set up the stack for new processes so that
# it looks like 'fake_exit' is the address after the call instruction
# that transfers to the main function of the process. Upon return to
# this code, we call exit() with whatever value was returned from
# main().
#

	.globl	fake_exit
fake_exit:
	# alternate: could push a "fake exit" status
	subl	$12, %esp   # keep the stack aligned
	pushl	%eax        # termination status returned by main()
	call	exit        # terminate this process
	# we shouldn't come back from that, but just in case...
hang:
	jmp	hang

# This is here to make the GNU linker happy
	.section	.note.GNU-stack,"",@progbits
