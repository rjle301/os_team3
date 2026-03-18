##
# @file		start.S
#
# @author	Warren R. Carithers
#
# @brief	User-level startup routine
#
# This code is the entry point for all user-level processes. The
# process begins execution at _start, which immediately calls
# the main() function. If/when main() returns, its return value
# is given as the exit status in a call to exit().
#
	.text
	.globl _start
	.globl	main
	.globl	exit

# entry point - this is where the kernel starts us running
_start:
	# we immediately call main()
	call main

	# if we come back from that, it means the user
	# program didn't call exit(), in which case the
	# value returned from main() is the exit status

	# push that value onto the stack and call exit()
	subl	$12, %esp
	pushl	%eax
	call	exit

	# if we come back from that, something bad has
	# happened, so we just lock up
1:	jmp 1b
