
build/kernel/entry.o:     file format elf32-i386


Disassembly of section .text:

00000000 <_start>:
# The entry point.
#
	.globl	_start

_start:
	cli                        # seems to be reset on entry to p. mode
   0:	fa                   	cli    
	movb	$NMI_ENABLE, %al   # re-enable NMIs (bootstrap
   1:	b0 00                	mov    $0x0,%al
	outb	$CMOS_ADDR         #   turned them off)
   3:	e6 70                	out    %al,$0x70

#
# Set the data and stack segment registers (code segment register
# was set by the long jump that switched us into protected mode).
#
	xorl	%eax, %eax	# clear EAX
   5:	31 c0                	xor    %eax,%eax
	movw	$GDT_DATA, %ax	# GDT entry #3 - data segment
   7:	66 b8 18 00          	mov    $0x18,%ax
	movw	%ax, %ds	# for all four data segment registers
   b:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
   d:	8e c0                	mov    %eax,%es
	movw	%ax, %fs
   f:	8e e0                	mov    %eax,%fs
	movw	%ax, %gs
  11:	8e e8                	mov    %eax,%gs

	movw	$GDT_STACK, %ax	# entry #4 is the stack segment
  13:	66 b8 20 00          	mov    $0x20,%ax
	movw	%ax, %ss
  17:	8e d0                	mov    %eax,%ss

	movl	$SYSTEM_STACK, %ebp	# set up the system frame pointer
  19:	bd 00 00 01 00       	mov    $0x10000,%ebp
	movl	%ebp, %esp	# and stack pointer
  1e:	89 ec                	mov    %ebp,%esp
#
# These symbols are defined automatically by the linker.
#
	.globl	__bss_start, _end

	movl	$__bss_start, %edi
  20:	bf 00 00 00 00       	mov    $0x0,%edi

00000025 <clearbss>:
clearbss:
	movl	$0, (%edi)
  25:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	addl	$4, %edi
  2b:	83 c7 04             	add    $0x4,%edi
	cmpl	$_end, %edi
  2e:	81 ff 00 00 00 00    	cmp    $0x0,%edi
	jb	clearbss
  34:	72 ef                	jb     25 <clearbss>

#
# Call the system initialization routine.
#
	.globl	main
	call	main
  36:	e8 fc ff ff ff       	call   37 <clearbss+0x12>
# process, and we're ready to shift into user mode.  The user
# stack for that process must have the initial context in it;
# we treat this as a "return from interrupt" event, and just
# transfer to the code that restores the user context.
#
	jmp	isr_restore   # defined in isrs.S
  3b:	e9 fc ff ff ff       	jmp    3c <clearbss+0x17>
