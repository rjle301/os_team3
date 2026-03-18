
build/kernel/kernel:     file format elf32-i386


Disassembly of section .text:

00010000 <_start>:
# The entry point.
#
	.globl	_start

_start:
	cli                        # seems to be reset on entry to p. mode
   10000:	fa                   	cli    
	movb	$NMI_ENABLE, %al   # re-enable NMIs (bootstrap
   10001:	b0 00                	mov    $0x0,%al
	outb	$CMOS_ADDR         #   turned them off)
   10003:	e6 70                	out    %al,$0x70

#
# Set the data and stack segment registers (code segment register
# was set by the long jump that switched us into protected mode).
#
	xorl	%eax, %eax	# clear EAX
   10005:	31 c0                	xor    %eax,%eax
	movw	$GDT_DATA, %ax	# GDT entry #3 - data segment
   10007:	66 b8 18 00          	mov    $0x18,%ax
	movw	%ax, %ds	# for all four data segment registers
   1000b:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
   1000d:	8e c0                	mov    %eax,%es
	movw	%ax, %fs
   1000f:	8e e0                	mov    %eax,%fs
	movw	%ax, %gs
   10011:	8e e8                	mov    %eax,%gs

	movw	$GDT_STACK, %ax	# entry #4 is the stack segment
   10013:	66 b8 20 00          	mov    $0x20,%ax
	movw	%ax, %ss
   10017:	8e d0                	mov    %eax,%ss

	movl	$SYSTEM_STACK, %ebp	# set up the system frame pointer
   10019:	bd 00 00 01 00       	mov    $0x10000,%ebp
	movl	%ebp, %esp	# and stack pointer
   1001e:	89 ec                	mov    %ebp,%esp
#
# These symbols are defined automatically by the linker.
#
	.globl	__bss_start, _end

	movl	$__bss_start, %edi
   10020:	bf 00 a0 01 00       	mov    $0x1a000,%edi

00010025 <clearbss>:
clearbss:
	movl	$0, (%edi)
   10025:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	addl	$4, %edi
   1002b:	83 c7 04             	add    $0x4,%edi
	cmpl	$_end, %edi
   1002e:	81 ff c0 b6 01 00    	cmp    $0x1b6c0,%edi
	jb	clearbss
   10034:	72 ef                	jb     10025 <clearbss>

#
# Call the system initialization routine.
#
	.globl	main
	call	main
   10036:	e8 f7 1e 00 00       	call   11f32 <main>
# process, and we're ready to shift into user mode.  The user
# stack for that process must have the initial context in it;
# we treat this as a "return from interrupt" event, and just
# transfer to the code that restores the user context.
#
	jmp	isr_restore   # defined in isrs.S
   1003b:	e9 2f 00 00 00       	jmp    1006f <isr_restore>

00010040 <isr_save>:
#           0, or error code    saved by the hardware, or the entry macro
#           saved EIP           saved by the hardware
#           saved CS            saved by the hardware
#           saved EFLAGS        saved by the hardware
#
	pusha			# save E*X, ESP, EBP, ESI, EDI
   10040:	60                   	pusha  
	pushl	%ds		# save segment registers
   10041:	1e                   	push   %ds
	pushl	%es
   10042:	06                   	push   %es
	pushl	%fs
   10043:	0f a0                	push   %fs
	pushl	%gs
   10045:	0f a8                	push   %gs
	pushl	%ss
   10047:	16                   	push   %ss
#
# Note that the saved ESP is the contents before the PUSHA.
#
# Set up parameters for the ISR call.
#
	movl	52(%esp), %eax   # get vector number and error code
   10048:	8b 44 24 34          	mov    0x34(%esp),%eax
	movl	56(%esp), %ebx
   1004c:	8b 5c 24 38          	mov    0x38(%esp),%ebx

	.globl	current
	.globl	kesp

	# save the context pointer
	movl	current, %edx
   10050:	8b 15 5c a6 01 00    	mov    0x1a65c,%edx
	movl	%esp, (%edx)    # assumes this is the first field
   10056:	89 22                	mov    %esp,(%edx)
	# THIS CODE IS INHERENTLY NON-REENTRANT! If/when the OS
	# is converted from monolithic to something that supports
	# reentrant or interruptable ISRs, this code will need to
	# be changed to support that!

	movl	kesp, %esp
   10058:	8b 25 b8 b2 01 00    	mov    0x1b2b8,%esp

############################################################################
# End of stack switch mod.
############################################################################

	subl	$8, %esp        # preserve stack alignment!
   1005e:	83 ec 08             	sub    $0x8,%esp
	pushl	%ebx		# put them on the top of the stack ...
   10061:	53                   	push   %ebx
	pushl	%eax		# ... as parameters for the ISR
   10062:	50                   	push   %eax

#
# Call the ISR
#
	movl	isr_table(,%eax,4),%ebx
   10063:	8b 1c 85 c0 b2 01 00 	mov    0x1b2c0(,%eax,4),%ebx
	call	*%ebx
   1006a:	ff d3                	call   *%ebx
	addl	$16,%esp        # pop the parameters
   1006c:	83 c4 10             	add    $0x10,%esp

0001006f <isr_restore>:
# We're running using the kernel stack, so we need to switch back to the
# stack for the current process.
############################################################################

        # get the context pointer
        movl    current, %ebx
   1006f:	8b 1d 5c a6 01 00    	mov    0x1a65c,%ebx
	movl	(%ebx), %esp    # again, assumes this is the first field
   10075:	8b 23                	mov    (%ebx),%esp
#ifdef CX_SANITY_CHK
	# perform a "sanity check" on the context before
	# we restore it, just in case....
	.globl	ctx_sanity_check
	
	movl	%esp, %eax      # context pointer
   10077:	89 e0                	mov    %esp,%eax
	subl	$12, %esp
   10079:	83 ec 0c             	sub    $0xc,%esp
	pushl	%eax
   1007c:	50                   	push   %eax
	call	ctx_sanity_check
   1007d:	e8 9c 2b 00 00       	call   12c1e <ctx_sanity_check>
	addl	$16, %esp
   10082:	83 c4 10             	add    $0x10,%esp
# By default, it prints out the CPU context being restored; it
# relies on the standard save sequence (see above).
#
	.globl	cio_printf_at

	pushl	$fmt
   10085:	68 a2 00 01 00       	push   $0x100a2
	pushl	$1
   1008a:	6a 01                	push   $0x1
	pushl	$0
   1008c:	6a 00                	push   $0x0
	call	cio_printf_at
   1008e:	e8 54 16 00 00       	call   116e7 <cio_printf_at>
	addl	$12,%esp
   10093:	83 c4 0c             	add    $0xc,%esp
#endif

#
# Restore the context.
#
	popl	%ss		# restore the segment registers
   10096:	17                   	pop    %ss
	popl	%gs
   10097:	0f a9                	pop    %gs
	popl	%fs
   10099:	0f a1                	pop    %fs
	popl	%es
   1009b:	07                   	pop    %es
	popl	%ds
   1009c:	1f                   	pop    %ds
	popa			# restore others
   1009d:	61                   	popa   
	addl	$8, %esp	# discard the error code and vector
   1009e:	83 c4 08             	add    $0x8,%esp
	iret			# and return
   100a1:	cf                   	iret   

000100a2 <fmt>:
   100a2:	20 73 73             	and    %dh,0x73(%ebx)
   100a5:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   100aa:	20 20                	and    %ah,(%eax)
   100ac:	67 73 3d             	addr16 jae 100ec <fmt+0x4a>
   100af:	25 30 38 78 20       	and    $0x20783830,%eax
   100b4:	20 66 73             	and    %ah,0x73(%esi)
   100b7:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   100bc:	20 20                	and    %ah,(%eax)
   100be:	65 73 3d             	gs jae 100fe <fmt+0x5c>
   100c1:	25 30 38 78 20       	and    $0x20783830,%eax
   100c6:	20 64 73 3d          	and    %ah,0x3d(%ebx,%esi,2)
   100ca:	25 30 38 78 0a       	and    $0xa783830,%eax
   100cf:	65 64 69 3d 25 30 38 	gs imul $0x69736520,%fs:0x78383025,%edi
   100d6:	78 20 65 73 69 
   100db:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   100e0:	20 65 62             	and    %ah,0x62(%ebp)
   100e3:	70 3d                	jo     10122 <fmt+0x80>
   100e5:	25 30 38 78 20       	and    $0x20783830,%eax
   100ea:	65 73 70             	gs jae 1015d <isr_0x02+0x6>
   100ed:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   100f2:	20 65 62             	and    %ah,0x62(%ebp)
   100f5:	78 3d                	js     10134 <fmt+0x92>
   100f7:	25 30 38 78 0a       	and    $0xa783830,%eax
   100fc:	65 64 78 3d          	gs fs js 1013d <fmt+0x9b>
   10100:	25 30 38 78 20       	and    $0x20783830,%eax
   10105:	65 63 78 3d          	arpl   %di,%gs:0x3d(%eax)
   10109:	25 30 38 78 20       	and    $0x20783830,%eax
   1010e:	65 61                	gs popa 
   10110:	78 3d                	js     1014f <isr_0x01+0x1>
   10112:	25 30 38 78 20       	and    $0x20783830,%eax
   10117:	76 65                	jbe    1017e <isr_0x06+0x3>
   10119:	63 3d 25 30 38 78    	arpl   %di,0x78383025
   1011f:	20 63 6f             	and    %ah,0x6f(%ebx)
   10122:	64 3d 25 30 38 78    	fs cmp $0x78383025,%eax
   10128:	0a 65 69             	or     0x69(%ebp),%ah
   1012b:	70 3d                	jo     1016a <isr_0x04+0x1>
   1012d:	25 30 38 78 20       	and    $0x20783830,%eax
   10132:	20 63 73             	and    %ah,0x73(%ebx)
   10135:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   1013a:	20 65 66             	and    %ah,0x66(%ebp)
   1013d:	6c                   	insb   (%dx),%es:(%edi)
   1013e:	3d 25 30 38 78       	cmp    $0x78383025,%eax
   10143:	0a 00                	or     (%eax),%al

00010145 <isr_0x00>:
#endif

#
# Here we generate the individual stubs for each interrupt.
#
ISR(0x00);	ISR(0x01);	ISR(0x02);	ISR(0x03);
   10145:	6a 00                	push   $0x0
   10147:	6a 00                	push   $0x0
   10149:	e9 f2 fe ff ff       	jmp    10040 <isr_save>

0001014e <isr_0x01>:
   1014e:	6a 00                	push   $0x0
   10150:	6a 01                	push   $0x1
   10152:	e9 e9 fe ff ff       	jmp    10040 <isr_save>

00010157 <isr_0x02>:
   10157:	6a 00                	push   $0x0
   10159:	6a 02                	push   $0x2
   1015b:	e9 e0 fe ff ff       	jmp    10040 <isr_save>

00010160 <isr_0x03>:
   10160:	6a 00                	push   $0x0
   10162:	6a 03                	push   $0x3
   10164:	e9 d7 fe ff ff       	jmp    10040 <isr_save>

00010169 <isr_0x04>:
ISR(0x04);	ISR(0x05);	ISR(0x06);	ISR(0x07);
   10169:	6a 00                	push   $0x0
   1016b:	6a 04                	push   $0x4
   1016d:	e9 ce fe ff ff       	jmp    10040 <isr_save>

00010172 <isr_0x05>:
   10172:	6a 00                	push   $0x0
   10174:	6a 05                	push   $0x5
   10176:	e9 c5 fe ff ff       	jmp    10040 <isr_save>

0001017b <isr_0x06>:
   1017b:	6a 00                	push   $0x0
   1017d:	6a 06                	push   $0x6
   1017f:	e9 bc fe ff ff       	jmp    10040 <isr_save>

00010184 <isr_0x07>:
   10184:	6a 00                	push   $0x0
   10186:	6a 07                	push   $0x7
   10188:	e9 b3 fe ff ff       	jmp    10040 <isr_save>

0001018d <isr_0x08>:
ERR_ISR(0x08);	ISR(0x09);	ERR_ISR(0x0a);	ERR_ISR(0x0b);
   1018d:	6a 08                	push   $0x8
   1018f:	e9 ac fe ff ff       	jmp    10040 <isr_save>

00010194 <isr_0x09>:
   10194:	6a 00                	push   $0x0
   10196:	6a 09                	push   $0x9
   10198:	e9 a3 fe ff ff       	jmp    10040 <isr_save>

0001019d <isr_0x0a>:
   1019d:	6a 0a                	push   $0xa
   1019f:	e9 9c fe ff ff       	jmp    10040 <isr_save>

000101a4 <isr_0x0b>:
   101a4:	6a 0b                	push   $0xb
   101a6:	e9 95 fe ff ff       	jmp    10040 <isr_save>

000101ab <isr_0x0c>:
ERR_ISR(0x0c);	ERR_ISR(0x0d);	ERR_ISR(0x0e);	ISR(0x0f);
   101ab:	6a 0c                	push   $0xc
   101ad:	e9 8e fe ff ff       	jmp    10040 <isr_save>

000101b2 <isr_0x0d>:
   101b2:	6a 0d                	push   $0xd
   101b4:	e9 87 fe ff ff       	jmp    10040 <isr_save>

000101b9 <isr_0x0e>:
   101b9:	6a 0e                	push   $0xe
   101bb:	e9 80 fe ff ff       	jmp    10040 <isr_save>

000101c0 <isr_0x0f>:
   101c0:	6a 00                	push   $0x0
   101c2:	6a 0f                	push   $0xf
   101c4:	e9 77 fe ff ff       	jmp    10040 <isr_save>

000101c9 <isr_0x10>:
ISR(0x10);	ERR_ISR(0x11);	ISR(0x12);	ISR(0x13);
   101c9:	6a 00                	push   $0x0
   101cb:	6a 10                	push   $0x10
   101cd:	e9 6e fe ff ff       	jmp    10040 <isr_save>

000101d2 <isr_0x11>:
   101d2:	6a 11                	push   $0x11
   101d4:	e9 67 fe ff ff       	jmp    10040 <isr_save>

000101d9 <isr_0x12>:
   101d9:	6a 00                	push   $0x0
   101db:	6a 12                	push   $0x12
   101dd:	e9 5e fe ff ff       	jmp    10040 <isr_save>

000101e2 <isr_0x13>:
   101e2:	6a 00                	push   $0x0
   101e4:	6a 13                	push   $0x13
   101e6:	e9 55 fe ff ff       	jmp    10040 <isr_save>

000101eb <isr_0x14>:
ISR(0x14);	ERR_ISR(0x15);	ISR(0x16);	ISR(0x17);
   101eb:	6a 00                	push   $0x0
   101ed:	6a 14                	push   $0x14
   101ef:	e9 4c fe ff ff       	jmp    10040 <isr_save>

000101f4 <isr_0x15>:
   101f4:	6a 15                	push   $0x15
   101f6:	e9 45 fe ff ff       	jmp    10040 <isr_save>

000101fb <isr_0x16>:
   101fb:	6a 00                	push   $0x0
   101fd:	6a 16                	push   $0x16
   101ff:	e9 3c fe ff ff       	jmp    10040 <isr_save>

00010204 <isr_0x17>:
   10204:	6a 00                	push   $0x0
   10206:	6a 17                	push   $0x17
   10208:	e9 33 fe ff ff       	jmp    10040 <isr_save>

0001020d <isr_0x18>:
ISR(0x18);	ISR(0x19);	ISR(0x1a);	ISR(0x1b);
   1020d:	6a 00                	push   $0x0
   1020f:	6a 18                	push   $0x18
   10211:	e9 2a fe ff ff       	jmp    10040 <isr_save>

00010216 <isr_0x19>:
   10216:	6a 00                	push   $0x0
   10218:	6a 19                	push   $0x19
   1021a:	e9 21 fe ff ff       	jmp    10040 <isr_save>

0001021f <isr_0x1a>:
   1021f:	6a 00                	push   $0x0
   10221:	6a 1a                	push   $0x1a
   10223:	e9 18 fe ff ff       	jmp    10040 <isr_save>

00010228 <isr_0x1b>:
   10228:	6a 00                	push   $0x0
   1022a:	6a 1b                	push   $0x1b
   1022c:	e9 0f fe ff ff       	jmp    10040 <isr_save>

00010231 <isr_0x1c>:
ISR(0x1c);	ISR(0x1d);	ISR(0x1e);	ISR(0x1f);
   10231:	6a 00                	push   $0x0
   10233:	6a 1c                	push   $0x1c
   10235:	e9 06 fe ff ff       	jmp    10040 <isr_save>

0001023a <isr_0x1d>:
   1023a:	6a 00                	push   $0x0
   1023c:	6a 1d                	push   $0x1d
   1023e:	e9 fd fd ff ff       	jmp    10040 <isr_save>

00010243 <isr_0x1e>:
   10243:	6a 00                	push   $0x0
   10245:	6a 1e                	push   $0x1e
   10247:	e9 f4 fd ff ff       	jmp    10040 <isr_save>

0001024c <isr_0x1f>:
   1024c:	6a 00                	push   $0x0
   1024e:	6a 1f                	push   $0x1f
   10250:	e9 eb fd ff ff       	jmp    10040 <isr_save>

00010255 <isr_0x20>:
ISR(0x20);	ISR(0x21);	ISR(0x22);	ISR(0x23);
   10255:	6a 00                	push   $0x0
   10257:	6a 20                	push   $0x20
   10259:	e9 e2 fd ff ff       	jmp    10040 <isr_save>

0001025e <isr_0x21>:
   1025e:	6a 00                	push   $0x0
   10260:	6a 21                	push   $0x21
   10262:	e9 d9 fd ff ff       	jmp    10040 <isr_save>

00010267 <isr_0x22>:
   10267:	6a 00                	push   $0x0
   10269:	6a 22                	push   $0x22
   1026b:	e9 d0 fd ff ff       	jmp    10040 <isr_save>

00010270 <isr_0x23>:
   10270:	6a 00                	push   $0x0
   10272:	6a 23                	push   $0x23
   10274:	e9 c7 fd ff ff       	jmp    10040 <isr_save>

00010279 <isr_0x24>:
ISR(0x24);	ISR(0x25);	ISR(0x26);	ISR(0x27);
   10279:	6a 00                	push   $0x0
   1027b:	6a 24                	push   $0x24
   1027d:	e9 be fd ff ff       	jmp    10040 <isr_save>

00010282 <isr_0x25>:
   10282:	6a 00                	push   $0x0
   10284:	6a 25                	push   $0x25
   10286:	e9 b5 fd ff ff       	jmp    10040 <isr_save>

0001028b <isr_0x26>:
   1028b:	6a 00                	push   $0x0
   1028d:	6a 26                	push   $0x26
   1028f:	e9 ac fd ff ff       	jmp    10040 <isr_save>

00010294 <isr_0x27>:
   10294:	6a 00                	push   $0x0
   10296:	6a 27                	push   $0x27
   10298:	e9 a3 fd ff ff       	jmp    10040 <isr_save>

0001029d <isr_0x28>:
ISR(0x28);	ISR(0x29);	ISR(0x2a);	ISR(0x2b);
   1029d:	6a 00                	push   $0x0
   1029f:	6a 28                	push   $0x28
   102a1:	e9 9a fd ff ff       	jmp    10040 <isr_save>

000102a6 <isr_0x29>:
   102a6:	6a 00                	push   $0x0
   102a8:	6a 29                	push   $0x29
   102aa:	e9 91 fd ff ff       	jmp    10040 <isr_save>

000102af <isr_0x2a>:
   102af:	6a 00                	push   $0x0
   102b1:	6a 2a                	push   $0x2a
   102b3:	e9 88 fd ff ff       	jmp    10040 <isr_save>

000102b8 <isr_0x2b>:
   102b8:	6a 00                	push   $0x0
   102ba:	6a 2b                	push   $0x2b
   102bc:	e9 7f fd ff ff       	jmp    10040 <isr_save>

000102c1 <isr_0x2c>:
ISR(0x2c);	ISR(0x2d);	ISR(0x2e);	ISR(0x2f);
   102c1:	6a 00                	push   $0x0
   102c3:	6a 2c                	push   $0x2c
   102c5:	e9 76 fd ff ff       	jmp    10040 <isr_save>

000102ca <isr_0x2d>:
   102ca:	6a 00                	push   $0x0
   102cc:	6a 2d                	push   $0x2d
   102ce:	e9 6d fd ff ff       	jmp    10040 <isr_save>

000102d3 <isr_0x2e>:
   102d3:	6a 00                	push   $0x0
   102d5:	6a 2e                	push   $0x2e
   102d7:	e9 64 fd ff ff       	jmp    10040 <isr_save>

000102dc <isr_0x2f>:
   102dc:	6a 00                	push   $0x0
   102de:	6a 2f                	push   $0x2f
   102e0:	e9 5b fd ff ff       	jmp    10040 <isr_save>

000102e5 <isr_0x30>:
ISR(0x30);	ISR(0x31);	ISR(0x32);	ISR(0x33);
   102e5:	6a 00                	push   $0x0
   102e7:	6a 30                	push   $0x30
   102e9:	e9 52 fd ff ff       	jmp    10040 <isr_save>

000102ee <isr_0x31>:
   102ee:	6a 00                	push   $0x0
   102f0:	6a 31                	push   $0x31
   102f2:	e9 49 fd ff ff       	jmp    10040 <isr_save>

000102f7 <isr_0x32>:
   102f7:	6a 00                	push   $0x0
   102f9:	6a 32                	push   $0x32
   102fb:	e9 40 fd ff ff       	jmp    10040 <isr_save>

00010300 <isr_0x33>:
   10300:	6a 00                	push   $0x0
   10302:	6a 33                	push   $0x33
   10304:	e9 37 fd ff ff       	jmp    10040 <isr_save>

00010309 <isr_0x34>:
ISR(0x34);	ISR(0x35);	ISR(0x36);	ISR(0x37);
   10309:	6a 00                	push   $0x0
   1030b:	6a 34                	push   $0x34
   1030d:	e9 2e fd ff ff       	jmp    10040 <isr_save>

00010312 <isr_0x35>:
   10312:	6a 00                	push   $0x0
   10314:	6a 35                	push   $0x35
   10316:	e9 25 fd ff ff       	jmp    10040 <isr_save>

0001031b <isr_0x36>:
   1031b:	6a 00                	push   $0x0
   1031d:	6a 36                	push   $0x36
   1031f:	e9 1c fd ff ff       	jmp    10040 <isr_save>

00010324 <isr_0x37>:
   10324:	6a 00                	push   $0x0
   10326:	6a 37                	push   $0x37
   10328:	e9 13 fd ff ff       	jmp    10040 <isr_save>

0001032d <isr_0x38>:
ISR(0x38);	ISR(0x39);	ISR(0x3a);	ISR(0x3b);
   1032d:	6a 00                	push   $0x0
   1032f:	6a 38                	push   $0x38
   10331:	e9 0a fd ff ff       	jmp    10040 <isr_save>

00010336 <isr_0x39>:
   10336:	6a 00                	push   $0x0
   10338:	6a 39                	push   $0x39
   1033a:	e9 01 fd ff ff       	jmp    10040 <isr_save>

0001033f <isr_0x3a>:
   1033f:	6a 00                	push   $0x0
   10341:	6a 3a                	push   $0x3a
   10343:	e9 f8 fc ff ff       	jmp    10040 <isr_save>

00010348 <isr_0x3b>:
   10348:	6a 00                	push   $0x0
   1034a:	6a 3b                	push   $0x3b
   1034c:	e9 ef fc ff ff       	jmp    10040 <isr_save>

00010351 <isr_0x3c>:
ISR(0x3c);	ISR(0x3d);	ISR(0x3e);	ISR(0x3f);
   10351:	6a 00                	push   $0x0
   10353:	6a 3c                	push   $0x3c
   10355:	e9 e6 fc ff ff       	jmp    10040 <isr_save>

0001035a <isr_0x3d>:
   1035a:	6a 00                	push   $0x0
   1035c:	6a 3d                	push   $0x3d
   1035e:	e9 dd fc ff ff       	jmp    10040 <isr_save>

00010363 <isr_0x3e>:
   10363:	6a 00                	push   $0x0
   10365:	6a 3e                	push   $0x3e
   10367:	e9 d4 fc ff ff       	jmp    10040 <isr_save>

0001036c <isr_0x3f>:
   1036c:	6a 00                	push   $0x0
   1036e:	6a 3f                	push   $0x3f
   10370:	e9 cb fc ff ff       	jmp    10040 <isr_save>

00010375 <isr_0x40>:
ISR(0x40);	ISR(0x41);	ISR(0x42);	ISR(0x43);
   10375:	6a 00                	push   $0x0
   10377:	6a 40                	push   $0x40
   10379:	e9 c2 fc ff ff       	jmp    10040 <isr_save>

0001037e <isr_0x41>:
   1037e:	6a 00                	push   $0x0
   10380:	6a 41                	push   $0x41
   10382:	e9 b9 fc ff ff       	jmp    10040 <isr_save>

00010387 <isr_0x42>:
   10387:	6a 00                	push   $0x0
   10389:	6a 42                	push   $0x42
   1038b:	e9 b0 fc ff ff       	jmp    10040 <isr_save>

00010390 <isr_0x43>:
   10390:	6a 00                	push   $0x0
   10392:	6a 43                	push   $0x43
   10394:	e9 a7 fc ff ff       	jmp    10040 <isr_save>

00010399 <isr_0x44>:
ISR(0x44);	ISR(0x45);	ISR(0x46);	ISR(0x47);
   10399:	6a 00                	push   $0x0
   1039b:	6a 44                	push   $0x44
   1039d:	e9 9e fc ff ff       	jmp    10040 <isr_save>

000103a2 <isr_0x45>:
   103a2:	6a 00                	push   $0x0
   103a4:	6a 45                	push   $0x45
   103a6:	e9 95 fc ff ff       	jmp    10040 <isr_save>

000103ab <isr_0x46>:
   103ab:	6a 00                	push   $0x0
   103ad:	6a 46                	push   $0x46
   103af:	e9 8c fc ff ff       	jmp    10040 <isr_save>

000103b4 <isr_0x47>:
   103b4:	6a 00                	push   $0x0
   103b6:	6a 47                	push   $0x47
   103b8:	e9 83 fc ff ff       	jmp    10040 <isr_save>

000103bd <isr_0x48>:
ISR(0x48);	ISR(0x49);	ISR(0x4a);	ISR(0x4b);
   103bd:	6a 00                	push   $0x0
   103bf:	6a 48                	push   $0x48
   103c1:	e9 7a fc ff ff       	jmp    10040 <isr_save>

000103c6 <isr_0x49>:
   103c6:	6a 00                	push   $0x0
   103c8:	6a 49                	push   $0x49
   103ca:	e9 71 fc ff ff       	jmp    10040 <isr_save>

000103cf <isr_0x4a>:
   103cf:	6a 00                	push   $0x0
   103d1:	6a 4a                	push   $0x4a
   103d3:	e9 68 fc ff ff       	jmp    10040 <isr_save>

000103d8 <isr_0x4b>:
   103d8:	6a 00                	push   $0x0
   103da:	6a 4b                	push   $0x4b
   103dc:	e9 5f fc ff ff       	jmp    10040 <isr_save>

000103e1 <isr_0x4c>:
ISR(0x4c);	ISR(0x4d);	ISR(0x4e);	ISR(0x4f);
   103e1:	6a 00                	push   $0x0
   103e3:	6a 4c                	push   $0x4c
   103e5:	e9 56 fc ff ff       	jmp    10040 <isr_save>

000103ea <isr_0x4d>:
   103ea:	6a 00                	push   $0x0
   103ec:	6a 4d                	push   $0x4d
   103ee:	e9 4d fc ff ff       	jmp    10040 <isr_save>

000103f3 <isr_0x4e>:
   103f3:	6a 00                	push   $0x0
   103f5:	6a 4e                	push   $0x4e
   103f7:	e9 44 fc ff ff       	jmp    10040 <isr_save>

000103fc <isr_0x4f>:
   103fc:	6a 00                	push   $0x0
   103fe:	6a 4f                	push   $0x4f
   10400:	e9 3b fc ff ff       	jmp    10040 <isr_save>

00010405 <isr_0x50>:
ISR(0x50);	ISR(0x51);	ISR(0x52);	ISR(0x53);
   10405:	6a 00                	push   $0x0
   10407:	6a 50                	push   $0x50
   10409:	e9 32 fc ff ff       	jmp    10040 <isr_save>

0001040e <isr_0x51>:
   1040e:	6a 00                	push   $0x0
   10410:	6a 51                	push   $0x51
   10412:	e9 29 fc ff ff       	jmp    10040 <isr_save>

00010417 <isr_0x52>:
   10417:	6a 00                	push   $0x0
   10419:	6a 52                	push   $0x52
   1041b:	e9 20 fc ff ff       	jmp    10040 <isr_save>

00010420 <isr_0x53>:
   10420:	6a 00                	push   $0x0
   10422:	6a 53                	push   $0x53
   10424:	e9 17 fc ff ff       	jmp    10040 <isr_save>

00010429 <isr_0x54>:
ISR(0x54);	ISR(0x55);	ISR(0x56);	ISR(0x57);
   10429:	6a 00                	push   $0x0
   1042b:	6a 54                	push   $0x54
   1042d:	e9 0e fc ff ff       	jmp    10040 <isr_save>

00010432 <isr_0x55>:
   10432:	6a 00                	push   $0x0
   10434:	6a 55                	push   $0x55
   10436:	e9 05 fc ff ff       	jmp    10040 <isr_save>

0001043b <isr_0x56>:
   1043b:	6a 00                	push   $0x0
   1043d:	6a 56                	push   $0x56
   1043f:	e9 fc fb ff ff       	jmp    10040 <isr_save>

00010444 <isr_0x57>:
   10444:	6a 00                	push   $0x0
   10446:	6a 57                	push   $0x57
   10448:	e9 f3 fb ff ff       	jmp    10040 <isr_save>

0001044d <isr_0x58>:
ISR(0x58);	ISR(0x59);	ISR(0x5a);	ISR(0x5b);
   1044d:	6a 00                	push   $0x0
   1044f:	6a 58                	push   $0x58
   10451:	e9 ea fb ff ff       	jmp    10040 <isr_save>

00010456 <isr_0x59>:
   10456:	6a 00                	push   $0x0
   10458:	6a 59                	push   $0x59
   1045a:	e9 e1 fb ff ff       	jmp    10040 <isr_save>

0001045f <isr_0x5a>:
   1045f:	6a 00                	push   $0x0
   10461:	6a 5a                	push   $0x5a
   10463:	e9 d8 fb ff ff       	jmp    10040 <isr_save>

00010468 <isr_0x5b>:
   10468:	6a 00                	push   $0x0
   1046a:	6a 5b                	push   $0x5b
   1046c:	e9 cf fb ff ff       	jmp    10040 <isr_save>

00010471 <isr_0x5c>:
ISR(0x5c);	ISR(0x5d);	ISR(0x5e);	ISR(0x5f);
   10471:	6a 00                	push   $0x0
   10473:	6a 5c                	push   $0x5c
   10475:	e9 c6 fb ff ff       	jmp    10040 <isr_save>

0001047a <isr_0x5d>:
   1047a:	6a 00                	push   $0x0
   1047c:	6a 5d                	push   $0x5d
   1047e:	e9 bd fb ff ff       	jmp    10040 <isr_save>

00010483 <isr_0x5e>:
   10483:	6a 00                	push   $0x0
   10485:	6a 5e                	push   $0x5e
   10487:	e9 b4 fb ff ff       	jmp    10040 <isr_save>

0001048c <isr_0x5f>:
   1048c:	6a 00                	push   $0x0
   1048e:	6a 5f                	push   $0x5f
   10490:	e9 ab fb ff ff       	jmp    10040 <isr_save>

00010495 <isr_0x60>:
ISR(0x60);	ISR(0x61);	ISR(0x62);	ISR(0x63);
   10495:	6a 00                	push   $0x0
   10497:	6a 60                	push   $0x60
   10499:	e9 a2 fb ff ff       	jmp    10040 <isr_save>

0001049e <isr_0x61>:
   1049e:	6a 00                	push   $0x0
   104a0:	6a 61                	push   $0x61
   104a2:	e9 99 fb ff ff       	jmp    10040 <isr_save>

000104a7 <isr_0x62>:
   104a7:	6a 00                	push   $0x0
   104a9:	6a 62                	push   $0x62
   104ab:	e9 90 fb ff ff       	jmp    10040 <isr_save>

000104b0 <isr_0x63>:
   104b0:	6a 00                	push   $0x0
   104b2:	6a 63                	push   $0x63
   104b4:	e9 87 fb ff ff       	jmp    10040 <isr_save>

000104b9 <isr_0x64>:
ISR(0x64);	ISR(0x65);	ISR(0x66);	ISR(0x67);
   104b9:	6a 00                	push   $0x0
   104bb:	6a 64                	push   $0x64
   104bd:	e9 7e fb ff ff       	jmp    10040 <isr_save>

000104c2 <isr_0x65>:
   104c2:	6a 00                	push   $0x0
   104c4:	6a 65                	push   $0x65
   104c6:	e9 75 fb ff ff       	jmp    10040 <isr_save>

000104cb <isr_0x66>:
   104cb:	6a 00                	push   $0x0
   104cd:	6a 66                	push   $0x66
   104cf:	e9 6c fb ff ff       	jmp    10040 <isr_save>

000104d4 <isr_0x67>:
   104d4:	6a 00                	push   $0x0
   104d6:	6a 67                	push   $0x67
   104d8:	e9 63 fb ff ff       	jmp    10040 <isr_save>

000104dd <isr_0x68>:
ISR(0x68);	ISR(0x69);	ISR(0x6a);	ISR(0x6b);
   104dd:	6a 00                	push   $0x0
   104df:	6a 68                	push   $0x68
   104e1:	e9 5a fb ff ff       	jmp    10040 <isr_save>

000104e6 <isr_0x69>:
   104e6:	6a 00                	push   $0x0
   104e8:	6a 69                	push   $0x69
   104ea:	e9 51 fb ff ff       	jmp    10040 <isr_save>

000104ef <isr_0x6a>:
   104ef:	6a 00                	push   $0x0
   104f1:	6a 6a                	push   $0x6a
   104f3:	e9 48 fb ff ff       	jmp    10040 <isr_save>

000104f8 <isr_0x6b>:
   104f8:	6a 00                	push   $0x0
   104fa:	6a 6b                	push   $0x6b
   104fc:	e9 3f fb ff ff       	jmp    10040 <isr_save>

00010501 <isr_0x6c>:
ISR(0x6c);	ISR(0x6d);	ISR(0x6e);	ISR(0x6f);
   10501:	6a 00                	push   $0x0
   10503:	6a 6c                	push   $0x6c
   10505:	e9 36 fb ff ff       	jmp    10040 <isr_save>

0001050a <isr_0x6d>:
   1050a:	6a 00                	push   $0x0
   1050c:	6a 6d                	push   $0x6d
   1050e:	e9 2d fb ff ff       	jmp    10040 <isr_save>

00010513 <isr_0x6e>:
   10513:	6a 00                	push   $0x0
   10515:	6a 6e                	push   $0x6e
   10517:	e9 24 fb ff ff       	jmp    10040 <isr_save>

0001051c <isr_0x6f>:
   1051c:	6a 00                	push   $0x0
   1051e:	6a 6f                	push   $0x6f
   10520:	e9 1b fb ff ff       	jmp    10040 <isr_save>

00010525 <isr_0x70>:
ISR(0x70);	ISR(0x71);	ISR(0x72);	ISR(0x73);
   10525:	6a 00                	push   $0x0
   10527:	6a 70                	push   $0x70
   10529:	e9 12 fb ff ff       	jmp    10040 <isr_save>

0001052e <isr_0x71>:
   1052e:	6a 00                	push   $0x0
   10530:	6a 71                	push   $0x71
   10532:	e9 09 fb ff ff       	jmp    10040 <isr_save>

00010537 <isr_0x72>:
   10537:	6a 00                	push   $0x0
   10539:	6a 72                	push   $0x72
   1053b:	e9 00 fb ff ff       	jmp    10040 <isr_save>

00010540 <isr_0x73>:
   10540:	6a 00                	push   $0x0
   10542:	6a 73                	push   $0x73
   10544:	e9 f7 fa ff ff       	jmp    10040 <isr_save>

00010549 <isr_0x74>:
ISR(0x74);	ISR(0x75);	ISR(0x76);	ISR(0x77);
   10549:	6a 00                	push   $0x0
   1054b:	6a 74                	push   $0x74
   1054d:	e9 ee fa ff ff       	jmp    10040 <isr_save>

00010552 <isr_0x75>:
   10552:	6a 00                	push   $0x0
   10554:	6a 75                	push   $0x75
   10556:	e9 e5 fa ff ff       	jmp    10040 <isr_save>

0001055b <isr_0x76>:
   1055b:	6a 00                	push   $0x0
   1055d:	6a 76                	push   $0x76
   1055f:	e9 dc fa ff ff       	jmp    10040 <isr_save>

00010564 <isr_0x77>:
   10564:	6a 00                	push   $0x0
   10566:	6a 77                	push   $0x77
   10568:	e9 d3 fa ff ff       	jmp    10040 <isr_save>

0001056d <isr_0x78>:
ISR(0x78);	ISR(0x79);	ISR(0x7a);	ISR(0x7b);
   1056d:	6a 00                	push   $0x0
   1056f:	6a 78                	push   $0x78
   10571:	e9 ca fa ff ff       	jmp    10040 <isr_save>

00010576 <isr_0x79>:
   10576:	6a 00                	push   $0x0
   10578:	6a 79                	push   $0x79
   1057a:	e9 c1 fa ff ff       	jmp    10040 <isr_save>

0001057f <isr_0x7a>:
   1057f:	6a 00                	push   $0x0
   10581:	6a 7a                	push   $0x7a
   10583:	e9 b8 fa ff ff       	jmp    10040 <isr_save>

00010588 <isr_0x7b>:
   10588:	6a 00                	push   $0x0
   1058a:	6a 7b                	push   $0x7b
   1058c:	e9 af fa ff ff       	jmp    10040 <isr_save>

00010591 <isr_0x7c>:
ISR(0x7c);	ISR(0x7d);	ISR(0x7e);	ISR(0x7f);
   10591:	6a 00                	push   $0x0
   10593:	6a 7c                	push   $0x7c
   10595:	e9 a6 fa ff ff       	jmp    10040 <isr_save>

0001059a <isr_0x7d>:
   1059a:	6a 00                	push   $0x0
   1059c:	6a 7d                	push   $0x7d
   1059e:	e9 9d fa ff ff       	jmp    10040 <isr_save>

000105a3 <isr_0x7e>:
   105a3:	6a 00                	push   $0x0
   105a5:	6a 7e                	push   $0x7e
   105a7:	e9 94 fa ff ff       	jmp    10040 <isr_save>

000105ac <isr_0x7f>:
   105ac:	6a 00                	push   $0x0
   105ae:	6a 7f                	push   $0x7f
   105b0:	e9 8b fa ff ff       	jmp    10040 <isr_save>

000105b5 <isr_0x80>:
ISR(0x80);	ISR(0x81);	ISR(0x82);	ISR(0x83);
   105b5:	6a 00                	push   $0x0
   105b7:	68 80 00 00 00       	push   $0x80
   105bc:	e9 7f fa ff ff       	jmp    10040 <isr_save>

000105c1 <isr_0x81>:
   105c1:	6a 00                	push   $0x0
   105c3:	68 81 00 00 00       	push   $0x81
   105c8:	e9 73 fa ff ff       	jmp    10040 <isr_save>

000105cd <isr_0x82>:
   105cd:	6a 00                	push   $0x0
   105cf:	68 82 00 00 00       	push   $0x82
   105d4:	e9 67 fa ff ff       	jmp    10040 <isr_save>

000105d9 <isr_0x83>:
   105d9:	6a 00                	push   $0x0
   105db:	68 83 00 00 00       	push   $0x83
   105e0:	e9 5b fa ff ff       	jmp    10040 <isr_save>

000105e5 <isr_0x84>:
ISR(0x84);	ISR(0x85);	ISR(0x86);	ISR(0x87);
   105e5:	6a 00                	push   $0x0
   105e7:	68 84 00 00 00       	push   $0x84
   105ec:	e9 4f fa ff ff       	jmp    10040 <isr_save>

000105f1 <isr_0x85>:
   105f1:	6a 00                	push   $0x0
   105f3:	68 85 00 00 00       	push   $0x85
   105f8:	e9 43 fa ff ff       	jmp    10040 <isr_save>

000105fd <isr_0x86>:
   105fd:	6a 00                	push   $0x0
   105ff:	68 86 00 00 00       	push   $0x86
   10604:	e9 37 fa ff ff       	jmp    10040 <isr_save>

00010609 <isr_0x87>:
   10609:	6a 00                	push   $0x0
   1060b:	68 87 00 00 00       	push   $0x87
   10610:	e9 2b fa ff ff       	jmp    10040 <isr_save>

00010615 <isr_0x88>:
ISR(0x88);	ISR(0x89);	ISR(0x8a);	ISR(0x8b);
   10615:	6a 00                	push   $0x0
   10617:	68 88 00 00 00       	push   $0x88
   1061c:	e9 1f fa ff ff       	jmp    10040 <isr_save>

00010621 <isr_0x89>:
   10621:	6a 00                	push   $0x0
   10623:	68 89 00 00 00       	push   $0x89
   10628:	e9 13 fa ff ff       	jmp    10040 <isr_save>

0001062d <isr_0x8a>:
   1062d:	6a 00                	push   $0x0
   1062f:	68 8a 00 00 00       	push   $0x8a
   10634:	e9 07 fa ff ff       	jmp    10040 <isr_save>

00010639 <isr_0x8b>:
   10639:	6a 00                	push   $0x0
   1063b:	68 8b 00 00 00       	push   $0x8b
   10640:	e9 fb f9 ff ff       	jmp    10040 <isr_save>

00010645 <isr_0x8c>:
ISR(0x8c);	ISR(0x8d);	ISR(0x8e);	ISR(0x8f);
   10645:	6a 00                	push   $0x0
   10647:	68 8c 00 00 00       	push   $0x8c
   1064c:	e9 ef f9 ff ff       	jmp    10040 <isr_save>

00010651 <isr_0x8d>:
   10651:	6a 00                	push   $0x0
   10653:	68 8d 00 00 00       	push   $0x8d
   10658:	e9 e3 f9 ff ff       	jmp    10040 <isr_save>

0001065d <isr_0x8e>:
   1065d:	6a 00                	push   $0x0
   1065f:	68 8e 00 00 00       	push   $0x8e
   10664:	e9 d7 f9 ff ff       	jmp    10040 <isr_save>

00010669 <isr_0x8f>:
   10669:	6a 00                	push   $0x0
   1066b:	68 8f 00 00 00       	push   $0x8f
   10670:	e9 cb f9 ff ff       	jmp    10040 <isr_save>

00010675 <isr_0x90>:
ISR(0x90);	ISR(0x91);	ISR(0x92);	ISR(0x93);
   10675:	6a 00                	push   $0x0
   10677:	68 90 00 00 00       	push   $0x90
   1067c:	e9 bf f9 ff ff       	jmp    10040 <isr_save>

00010681 <isr_0x91>:
   10681:	6a 00                	push   $0x0
   10683:	68 91 00 00 00       	push   $0x91
   10688:	e9 b3 f9 ff ff       	jmp    10040 <isr_save>

0001068d <isr_0x92>:
   1068d:	6a 00                	push   $0x0
   1068f:	68 92 00 00 00       	push   $0x92
   10694:	e9 a7 f9 ff ff       	jmp    10040 <isr_save>

00010699 <isr_0x93>:
   10699:	6a 00                	push   $0x0
   1069b:	68 93 00 00 00       	push   $0x93
   106a0:	e9 9b f9 ff ff       	jmp    10040 <isr_save>

000106a5 <isr_0x94>:
ISR(0x94);	ISR(0x95);	ISR(0x96);	ISR(0x97);
   106a5:	6a 00                	push   $0x0
   106a7:	68 94 00 00 00       	push   $0x94
   106ac:	e9 8f f9 ff ff       	jmp    10040 <isr_save>

000106b1 <isr_0x95>:
   106b1:	6a 00                	push   $0x0
   106b3:	68 95 00 00 00       	push   $0x95
   106b8:	e9 83 f9 ff ff       	jmp    10040 <isr_save>

000106bd <isr_0x96>:
   106bd:	6a 00                	push   $0x0
   106bf:	68 96 00 00 00       	push   $0x96
   106c4:	e9 77 f9 ff ff       	jmp    10040 <isr_save>

000106c9 <isr_0x97>:
   106c9:	6a 00                	push   $0x0
   106cb:	68 97 00 00 00       	push   $0x97
   106d0:	e9 6b f9 ff ff       	jmp    10040 <isr_save>

000106d5 <isr_0x98>:
ISR(0x98);	ISR(0x99);	ISR(0x9a);	ISR(0x9b);
   106d5:	6a 00                	push   $0x0
   106d7:	68 98 00 00 00       	push   $0x98
   106dc:	e9 5f f9 ff ff       	jmp    10040 <isr_save>

000106e1 <isr_0x99>:
   106e1:	6a 00                	push   $0x0
   106e3:	68 99 00 00 00       	push   $0x99
   106e8:	e9 53 f9 ff ff       	jmp    10040 <isr_save>

000106ed <isr_0x9a>:
   106ed:	6a 00                	push   $0x0
   106ef:	68 9a 00 00 00       	push   $0x9a
   106f4:	e9 47 f9 ff ff       	jmp    10040 <isr_save>

000106f9 <isr_0x9b>:
   106f9:	6a 00                	push   $0x0
   106fb:	68 9b 00 00 00       	push   $0x9b
   10700:	e9 3b f9 ff ff       	jmp    10040 <isr_save>

00010705 <isr_0x9c>:
ISR(0x9c);	ISR(0x9d);	ISR(0x9e);	ISR(0x9f);
   10705:	6a 00                	push   $0x0
   10707:	68 9c 00 00 00       	push   $0x9c
   1070c:	e9 2f f9 ff ff       	jmp    10040 <isr_save>

00010711 <isr_0x9d>:
   10711:	6a 00                	push   $0x0
   10713:	68 9d 00 00 00       	push   $0x9d
   10718:	e9 23 f9 ff ff       	jmp    10040 <isr_save>

0001071d <isr_0x9e>:
   1071d:	6a 00                	push   $0x0
   1071f:	68 9e 00 00 00       	push   $0x9e
   10724:	e9 17 f9 ff ff       	jmp    10040 <isr_save>

00010729 <isr_0x9f>:
   10729:	6a 00                	push   $0x0
   1072b:	68 9f 00 00 00       	push   $0x9f
   10730:	e9 0b f9 ff ff       	jmp    10040 <isr_save>

00010735 <isr_0xa0>:
ISR(0xa0);	ISR(0xa1);	ISR(0xa2);	ISR(0xa3);
   10735:	6a 00                	push   $0x0
   10737:	68 a0 00 00 00       	push   $0xa0
   1073c:	e9 ff f8 ff ff       	jmp    10040 <isr_save>

00010741 <isr_0xa1>:
   10741:	6a 00                	push   $0x0
   10743:	68 a1 00 00 00       	push   $0xa1
   10748:	e9 f3 f8 ff ff       	jmp    10040 <isr_save>

0001074d <isr_0xa2>:
   1074d:	6a 00                	push   $0x0
   1074f:	68 a2 00 00 00       	push   $0xa2
   10754:	e9 e7 f8 ff ff       	jmp    10040 <isr_save>

00010759 <isr_0xa3>:
   10759:	6a 00                	push   $0x0
   1075b:	68 a3 00 00 00       	push   $0xa3
   10760:	e9 db f8 ff ff       	jmp    10040 <isr_save>

00010765 <isr_0xa4>:
ISR(0xa4);	ISR(0xa5);	ISR(0xa6);	ISR(0xa7);
   10765:	6a 00                	push   $0x0
   10767:	68 a4 00 00 00       	push   $0xa4
   1076c:	e9 cf f8 ff ff       	jmp    10040 <isr_save>

00010771 <isr_0xa5>:
   10771:	6a 00                	push   $0x0
   10773:	68 a5 00 00 00       	push   $0xa5
   10778:	e9 c3 f8 ff ff       	jmp    10040 <isr_save>

0001077d <isr_0xa6>:
   1077d:	6a 00                	push   $0x0
   1077f:	68 a6 00 00 00       	push   $0xa6
   10784:	e9 b7 f8 ff ff       	jmp    10040 <isr_save>

00010789 <isr_0xa7>:
   10789:	6a 00                	push   $0x0
   1078b:	68 a7 00 00 00       	push   $0xa7
   10790:	e9 ab f8 ff ff       	jmp    10040 <isr_save>

00010795 <isr_0xa8>:
ISR(0xa8);	ISR(0xa9);	ISR(0xaa);	ISR(0xab);
   10795:	6a 00                	push   $0x0
   10797:	68 a8 00 00 00       	push   $0xa8
   1079c:	e9 9f f8 ff ff       	jmp    10040 <isr_save>

000107a1 <isr_0xa9>:
   107a1:	6a 00                	push   $0x0
   107a3:	68 a9 00 00 00       	push   $0xa9
   107a8:	e9 93 f8 ff ff       	jmp    10040 <isr_save>

000107ad <isr_0xaa>:
   107ad:	6a 00                	push   $0x0
   107af:	68 aa 00 00 00       	push   $0xaa
   107b4:	e9 87 f8 ff ff       	jmp    10040 <isr_save>

000107b9 <isr_0xab>:
   107b9:	6a 00                	push   $0x0
   107bb:	68 ab 00 00 00       	push   $0xab
   107c0:	e9 7b f8 ff ff       	jmp    10040 <isr_save>

000107c5 <isr_0xac>:
ISR(0xac);	ISR(0xad);	ISR(0xae);	ISR(0xaf);
   107c5:	6a 00                	push   $0x0
   107c7:	68 ac 00 00 00       	push   $0xac
   107cc:	e9 6f f8 ff ff       	jmp    10040 <isr_save>

000107d1 <isr_0xad>:
   107d1:	6a 00                	push   $0x0
   107d3:	68 ad 00 00 00       	push   $0xad
   107d8:	e9 63 f8 ff ff       	jmp    10040 <isr_save>

000107dd <isr_0xae>:
   107dd:	6a 00                	push   $0x0
   107df:	68 ae 00 00 00       	push   $0xae
   107e4:	e9 57 f8 ff ff       	jmp    10040 <isr_save>

000107e9 <isr_0xaf>:
   107e9:	6a 00                	push   $0x0
   107eb:	68 af 00 00 00       	push   $0xaf
   107f0:	e9 4b f8 ff ff       	jmp    10040 <isr_save>

000107f5 <isr_0xb0>:
ISR(0xb0);	ISR(0xb1);	ISR(0xb2);	ISR(0xb3);
   107f5:	6a 00                	push   $0x0
   107f7:	68 b0 00 00 00       	push   $0xb0
   107fc:	e9 3f f8 ff ff       	jmp    10040 <isr_save>

00010801 <isr_0xb1>:
   10801:	6a 00                	push   $0x0
   10803:	68 b1 00 00 00       	push   $0xb1
   10808:	e9 33 f8 ff ff       	jmp    10040 <isr_save>

0001080d <isr_0xb2>:
   1080d:	6a 00                	push   $0x0
   1080f:	68 b2 00 00 00       	push   $0xb2
   10814:	e9 27 f8 ff ff       	jmp    10040 <isr_save>

00010819 <isr_0xb3>:
   10819:	6a 00                	push   $0x0
   1081b:	68 b3 00 00 00       	push   $0xb3
   10820:	e9 1b f8 ff ff       	jmp    10040 <isr_save>

00010825 <isr_0xb4>:
ISR(0xb4);	ISR(0xb5);	ISR(0xb6);	ISR(0xb7);
   10825:	6a 00                	push   $0x0
   10827:	68 b4 00 00 00       	push   $0xb4
   1082c:	e9 0f f8 ff ff       	jmp    10040 <isr_save>

00010831 <isr_0xb5>:
   10831:	6a 00                	push   $0x0
   10833:	68 b5 00 00 00       	push   $0xb5
   10838:	e9 03 f8 ff ff       	jmp    10040 <isr_save>

0001083d <isr_0xb6>:
   1083d:	6a 00                	push   $0x0
   1083f:	68 b6 00 00 00       	push   $0xb6
   10844:	e9 f7 f7 ff ff       	jmp    10040 <isr_save>

00010849 <isr_0xb7>:
   10849:	6a 00                	push   $0x0
   1084b:	68 b7 00 00 00       	push   $0xb7
   10850:	e9 eb f7 ff ff       	jmp    10040 <isr_save>

00010855 <isr_0xb8>:
ISR(0xb8);	ISR(0xb9);	ISR(0xba);	ISR(0xbb);
   10855:	6a 00                	push   $0x0
   10857:	68 b8 00 00 00       	push   $0xb8
   1085c:	e9 df f7 ff ff       	jmp    10040 <isr_save>

00010861 <isr_0xb9>:
   10861:	6a 00                	push   $0x0
   10863:	68 b9 00 00 00       	push   $0xb9
   10868:	e9 d3 f7 ff ff       	jmp    10040 <isr_save>

0001086d <isr_0xba>:
   1086d:	6a 00                	push   $0x0
   1086f:	68 ba 00 00 00       	push   $0xba
   10874:	e9 c7 f7 ff ff       	jmp    10040 <isr_save>

00010879 <isr_0xbb>:
   10879:	6a 00                	push   $0x0
   1087b:	68 bb 00 00 00       	push   $0xbb
   10880:	e9 bb f7 ff ff       	jmp    10040 <isr_save>

00010885 <isr_0xbc>:
ISR(0xbc);	ISR(0xbd);	ISR(0xbe);	ISR(0xbf);
   10885:	6a 00                	push   $0x0
   10887:	68 bc 00 00 00       	push   $0xbc
   1088c:	e9 af f7 ff ff       	jmp    10040 <isr_save>

00010891 <isr_0xbd>:
   10891:	6a 00                	push   $0x0
   10893:	68 bd 00 00 00       	push   $0xbd
   10898:	e9 a3 f7 ff ff       	jmp    10040 <isr_save>

0001089d <isr_0xbe>:
   1089d:	6a 00                	push   $0x0
   1089f:	68 be 00 00 00       	push   $0xbe
   108a4:	e9 97 f7 ff ff       	jmp    10040 <isr_save>

000108a9 <isr_0xbf>:
   108a9:	6a 00                	push   $0x0
   108ab:	68 bf 00 00 00       	push   $0xbf
   108b0:	e9 8b f7 ff ff       	jmp    10040 <isr_save>

000108b5 <isr_0xc0>:
ISR(0xc0);	ISR(0xc1);	ISR(0xc2);	ISR(0xc3);
   108b5:	6a 00                	push   $0x0
   108b7:	68 c0 00 00 00       	push   $0xc0
   108bc:	e9 7f f7 ff ff       	jmp    10040 <isr_save>

000108c1 <isr_0xc1>:
   108c1:	6a 00                	push   $0x0
   108c3:	68 c1 00 00 00       	push   $0xc1
   108c8:	e9 73 f7 ff ff       	jmp    10040 <isr_save>

000108cd <isr_0xc2>:
   108cd:	6a 00                	push   $0x0
   108cf:	68 c2 00 00 00       	push   $0xc2
   108d4:	e9 67 f7 ff ff       	jmp    10040 <isr_save>

000108d9 <isr_0xc3>:
   108d9:	6a 00                	push   $0x0
   108db:	68 c3 00 00 00       	push   $0xc3
   108e0:	e9 5b f7 ff ff       	jmp    10040 <isr_save>

000108e5 <isr_0xc4>:
ISR(0xc4);	ISR(0xc5);	ISR(0xc6);	ISR(0xc7);
   108e5:	6a 00                	push   $0x0
   108e7:	68 c4 00 00 00       	push   $0xc4
   108ec:	e9 4f f7 ff ff       	jmp    10040 <isr_save>

000108f1 <isr_0xc5>:
   108f1:	6a 00                	push   $0x0
   108f3:	68 c5 00 00 00       	push   $0xc5
   108f8:	e9 43 f7 ff ff       	jmp    10040 <isr_save>

000108fd <isr_0xc6>:
   108fd:	6a 00                	push   $0x0
   108ff:	68 c6 00 00 00       	push   $0xc6
   10904:	e9 37 f7 ff ff       	jmp    10040 <isr_save>

00010909 <isr_0xc7>:
   10909:	6a 00                	push   $0x0
   1090b:	68 c7 00 00 00       	push   $0xc7
   10910:	e9 2b f7 ff ff       	jmp    10040 <isr_save>

00010915 <isr_0xc8>:
ISR(0xc8);	ISR(0xc9);	ISR(0xca);	ISR(0xcb);
   10915:	6a 00                	push   $0x0
   10917:	68 c8 00 00 00       	push   $0xc8
   1091c:	e9 1f f7 ff ff       	jmp    10040 <isr_save>

00010921 <isr_0xc9>:
   10921:	6a 00                	push   $0x0
   10923:	68 c9 00 00 00       	push   $0xc9
   10928:	e9 13 f7 ff ff       	jmp    10040 <isr_save>

0001092d <isr_0xca>:
   1092d:	6a 00                	push   $0x0
   1092f:	68 ca 00 00 00       	push   $0xca
   10934:	e9 07 f7 ff ff       	jmp    10040 <isr_save>

00010939 <isr_0xcb>:
   10939:	6a 00                	push   $0x0
   1093b:	68 cb 00 00 00       	push   $0xcb
   10940:	e9 fb f6 ff ff       	jmp    10040 <isr_save>

00010945 <isr_0xcc>:
ISR(0xcc);	ISR(0xcd);	ISR(0xce);	ISR(0xcf);
   10945:	6a 00                	push   $0x0
   10947:	68 cc 00 00 00       	push   $0xcc
   1094c:	e9 ef f6 ff ff       	jmp    10040 <isr_save>

00010951 <isr_0xcd>:
   10951:	6a 00                	push   $0x0
   10953:	68 cd 00 00 00       	push   $0xcd
   10958:	e9 e3 f6 ff ff       	jmp    10040 <isr_save>

0001095d <isr_0xce>:
   1095d:	6a 00                	push   $0x0
   1095f:	68 ce 00 00 00       	push   $0xce
   10964:	e9 d7 f6 ff ff       	jmp    10040 <isr_save>

00010969 <isr_0xcf>:
   10969:	6a 00                	push   $0x0
   1096b:	68 cf 00 00 00       	push   $0xcf
   10970:	e9 cb f6 ff ff       	jmp    10040 <isr_save>

00010975 <isr_0xd0>:
ISR(0xd0);	ISR(0xd1);	ISR(0xd2);	ISR(0xd3);
   10975:	6a 00                	push   $0x0
   10977:	68 d0 00 00 00       	push   $0xd0
   1097c:	e9 bf f6 ff ff       	jmp    10040 <isr_save>

00010981 <isr_0xd1>:
   10981:	6a 00                	push   $0x0
   10983:	68 d1 00 00 00       	push   $0xd1
   10988:	e9 b3 f6 ff ff       	jmp    10040 <isr_save>

0001098d <isr_0xd2>:
   1098d:	6a 00                	push   $0x0
   1098f:	68 d2 00 00 00       	push   $0xd2
   10994:	e9 a7 f6 ff ff       	jmp    10040 <isr_save>

00010999 <isr_0xd3>:
   10999:	6a 00                	push   $0x0
   1099b:	68 d3 00 00 00       	push   $0xd3
   109a0:	e9 9b f6 ff ff       	jmp    10040 <isr_save>

000109a5 <isr_0xd4>:
ISR(0xd4);	ISR(0xd5);	ISR(0xd6);	ISR(0xd7);
   109a5:	6a 00                	push   $0x0
   109a7:	68 d4 00 00 00       	push   $0xd4
   109ac:	e9 8f f6 ff ff       	jmp    10040 <isr_save>

000109b1 <isr_0xd5>:
   109b1:	6a 00                	push   $0x0
   109b3:	68 d5 00 00 00       	push   $0xd5
   109b8:	e9 83 f6 ff ff       	jmp    10040 <isr_save>

000109bd <isr_0xd6>:
   109bd:	6a 00                	push   $0x0
   109bf:	68 d6 00 00 00       	push   $0xd6
   109c4:	e9 77 f6 ff ff       	jmp    10040 <isr_save>

000109c9 <isr_0xd7>:
   109c9:	6a 00                	push   $0x0
   109cb:	68 d7 00 00 00       	push   $0xd7
   109d0:	e9 6b f6 ff ff       	jmp    10040 <isr_save>

000109d5 <isr_0xd8>:
ISR(0xd8);	ISR(0xd9);	ISR(0xda);	ISR(0xdb);
   109d5:	6a 00                	push   $0x0
   109d7:	68 d8 00 00 00       	push   $0xd8
   109dc:	e9 5f f6 ff ff       	jmp    10040 <isr_save>

000109e1 <isr_0xd9>:
   109e1:	6a 00                	push   $0x0
   109e3:	68 d9 00 00 00       	push   $0xd9
   109e8:	e9 53 f6 ff ff       	jmp    10040 <isr_save>

000109ed <isr_0xda>:
   109ed:	6a 00                	push   $0x0
   109ef:	68 da 00 00 00       	push   $0xda
   109f4:	e9 47 f6 ff ff       	jmp    10040 <isr_save>

000109f9 <isr_0xdb>:
   109f9:	6a 00                	push   $0x0
   109fb:	68 db 00 00 00       	push   $0xdb
   10a00:	e9 3b f6 ff ff       	jmp    10040 <isr_save>

00010a05 <isr_0xdc>:
ISR(0xdc);	ISR(0xdd);	ISR(0xde);	ISR(0xdf);
   10a05:	6a 00                	push   $0x0
   10a07:	68 dc 00 00 00       	push   $0xdc
   10a0c:	e9 2f f6 ff ff       	jmp    10040 <isr_save>

00010a11 <isr_0xdd>:
   10a11:	6a 00                	push   $0x0
   10a13:	68 dd 00 00 00       	push   $0xdd
   10a18:	e9 23 f6 ff ff       	jmp    10040 <isr_save>

00010a1d <isr_0xde>:
   10a1d:	6a 00                	push   $0x0
   10a1f:	68 de 00 00 00       	push   $0xde
   10a24:	e9 17 f6 ff ff       	jmp    10040 <isr_save>

00010a29 <isr_0xdf>:
   10a29:	6a 00                	push   $0x0
   10a2b:	68 df 00 00 00       	push   $0xdf
   10a30:	e9 0b f6 ff ff       	jmp    10040 <isr_save>

00010a35 <isr_0xe0>:
ISR(0xe0);	ISR(0xe1);	ISR(0xe2);	ISR(0xe3);
   10a35:	6a 00                	push   $0x0
   10a37:	68 e0 00 00 00       	push   $0xe0
   10a3c:	e9 ff f5 ff ff       	jmp    10040 <isr_save>

00010a41 <isr_0xe1>:
   10a41:	6a 00                	push   $0x0
   10a43:	68 e1 00 00 00       	push   $0xe1
   10a48:	e9 f3 f5 ff ff       	jmp    10040 <isr_save>

00010a4d <isr_0xe2>:
   10a4d:	6a 00                	push   $0x0
   10a4f:	68 e2 00 00 00       	push   $0xe2
   10a54:	e9 e7 f5 ff ff       	jmp    10040 <isr_save>

00010a59 <isr_0xe3>:
   10a59:	6a 00                	push   $0x0
   10a5b:	68 e3 00 00 00       	push   $0xe3
   10a60:	e9 db f5 ff ff       	jmp    10040 <isr_save>

00010a65 <isr_0xe4>:
ISR(0xe4);	ISR(0xe5);	ISR(0xe6);	ISR(0xe7);
   10a65:	6a 00                	push   $0x0
   10a67:	68 e4 00 00 00       	push   $0xe4
   10a6c:	e9 cf f5 ff ff       	jmp    10040 <isr_save>

00010a71 <isr_0xe5>:
   10a71:	6a 00                	push   $0x0
   10a73:	68 e5 00 00 00       	push   $0xe5
   10a78:	e9 c3 f5 ff ff       	jmp    10040 <isr_save>

00010a7d <isr_0xe6>:
   10a7d:	6a 00                	push   $0x0
   10a7f:	68 e6 00 00 00       	push   $0xe6
   10a84:	e9 b7 f5 ff ff       	jmp    10040 <isr_save>

00010a89 <isr_0xe7>:
   10a89:	6a 00                	push   $0x0
   10a8b:	68 e7 00 00 00       	push   $0xe7
   10a90:	e9 ab f5 ff ff       	jmp    10040 <isr_save>

00010a95 <isr_0xe8>:
ISR(0xe8);	ISR(0xe9);	ISR(0xea);	ISR(0xeb);
   10a95:	6a 00                	push   $0x0
   10a97:	68 e8 00 00 00       	push   $0xe8
   10a9c:	e9 9f f5 ff ff       	jmp    10040 <isr_save>

00010aa1 <isr_0xe9>:
   10aa1:	6a 00                	push   $0x0
   10aa3:	68 e9 00 00 00       	push   $0xe9
   10aa8:	e9 93 f5 ff ff       	jmp    10040 <isr_save>

00010aad <isr_0xea>:
   10aad:	6a 00                	push   $0x0
   10aaf:	68 ea 00 00 00       	push   $0xea
   10ab4:	e9 87 f5 ff ff       	jmp    10040 <isr_save>

00010ab9 <isr_0xeb>:
   10ab9:	6a 00                	push   $0x0
   10abb:	68 eb 00 00 00       	push   $0xeb
   10ac0:	e9 7b f5 ff ff       	jmp    10040 <isr_save>

00010ac5 <isr_0xec>:
ISR(0xec);	ISR(0xed);	ISR(0xee);	ISR(0xef);
   10ac5:	6a 00                	push   $0x0
   10ac7:	68 ec 00 00 00       	push   $0xec
   10acc:	e9 6f f5 ff ff       	jmp    10040 <isr_save>

00010ad1 <isr_0xed>:
   10ad1:	6a 00                	push   $0x0
   10ad3:	68 ed 00 00 00       	push   $0xed
   10ad8:	e9 63 f5 ff ff       	jmp    10040 <isr_save>

00010add <isr_0xee>:
   10add:	6a 00                	push   $0x0
   10adf:	68 ee 00 00 00       	push   $0xee
   10ae4:	e9 57 f5 ff ff       	jmp    10040 <isr_save>

00010ae9 <isr_0xef>:
   10ae9:	6a 00                	push   $0x0
   10aeb:	68 ef 00 00 00       	push   $0xef
   10af0:	e9 4b f5 ff ff       	jmp    10040 <isr_save>

00010af5 <isr_0xf0>:
ISR(0xf0);	ISR(0xf1);	ISR(0xf2);	ISR(0xf3);
   10af5:	6a 00                	push   $0x0
   10af7:	68 f0 00 00 00       	push   $0xf0
   10afc:	e9 3f f5 ff ff       	jmp    10040 <isr_save>

00010b01 <isr_0xf1>:
   10b01:	6a 00                	push   $0x0
   10b03:	68 f1 00 00 00       	push   $0xf1
   10b08:	e9 33 f5 ff ff       	jmp    10040 <isr_save>

00010b0d <isr_0xf2>:
   10b0d:	6a 00                	push   $0x0
   10b0f:	68 f2 00 00 00       	push   $0xf2
   10b14:	e9 27 f5 ff ff       	jmp    10040 <isr_save>

00010b19 <isr_0xf3>:
   10b19:	6a 00                	push   $0x0
   10b1b:	68 f3 00 00 00       	push   $0xf3
   10b20:	e9 1b f5 ff ff       	jmp    10040 <isr_save>

00010b25 <isr_0xf4>:
ISR(0xf4);	ISR(0xf5);	ISR(0xf6);	ISR(0xf7);
   10b25:	6a 00                	push   $0x0
   10b27:	68 f4 00 00 00       	push   $0xf4
   10b2c:	e9 0f f5 ff ff       	jmp    10040 <isr_save>

00010b31 <isr_0xf5>:
   10b31:	6a 00                	push   $0x0
   10b33:	68 f5 00 00 00       	push   $0xf5
   10b38:	e9 03 f5 ff ff       	jmp    10040 <isr_save>

00010b3d <isr_0xf6>:
   10b3d:	6a 00                	push   $0x0
   10b3f:	68 f6 00 00 00       	push   $0xf6
   10b44:	e9 f7 f4 ff ff       	jmp    10040 <isr_save>

00010b49 <isr_0xf7>:
   10b49:	6a 00                	push   $0x0
   10b4b:	68 f7 00 00 00       	push   $0xf7
   10b50:	e9 eb f4 ff ff       	jmp    10040 <isr_save>

00010b55 <isr_0xf8>:
ISR(0xf8);	ISR(0xf9);	ISR(0xfa);	ISR(0xfb);
   10b55:	6a 00                	push   $0x0
   10b57:	68 f8 00 00 00       	push   $0xf8
   10b5c:	e9 df f4 ff ff       	jmp    10040 <isr_save>

00010b61 <isr_0xf9>:
   10b61:	6a 00                	push   $0x0
   10b63:	68 f9 00 00 00       	push   $0xf9
   10b68:	e9 d3 f4 ff ff       	jmp    10040 <isr_save>

00010b6d <isr_0xfa>:
   10b6d:	6a 00                	push   $0x0
   10b6f:	68 fa 00 00 00       	push   $0xfa
   10b74:	e9 c7 f4 ff ff       	jmp    10040 <isr_save>

00010b79 <isr_0xfb>:
   10b79:	6a 00                	push   $0x0
   10b7b:	68 fb 00 00 00       	push   $0xfb
   10b80:	e9 bb f4 ff ff       	jmp    10040 <isr_save>

00010b85 <isr_0xfc>:
ISR(0xfc);	ISR(0xfd);	ISR(0xfe);	ISR(0xff);
   10b85:	6a 00                	push   $0x0
   10b87:	68 fc 00 00 00       	push   $0xfc
   10b8c:	e9 af f4 ff ff       	jmp    10040 <isr_save>

00010b91 <isr_0xfd>:
   10b91:	6a 00                	push   $0x0
   10b93:	68 fd 00 00 00       	push   $0xfd
   10b98:	e9 a3 f4 ff ff       	jmp    10040 <isr_save>

00010b9d <isr_0xfe>:
   10b9d:	6a 00                	push   $0x0
   10b9f:	68 fe 00 00 00       	push   $0xfe
   10ba4:	e9 97 f4 ff ff       	jmp    10040 <isr_save>

00010ba9 <isr_0xff>:
   10ba9:	6a 00                	push   $0x0
   10bab:	68 ff 00 00 00       	push   $0xff
   10bb0:	e9 8b f4 ff ff       	jmp    10040 <isr_save>

00010bb5 <setcursor>:
*/

/*
** setcursor: set the cursor location (screen coordinates)
*/
static void setcursor( void ) {
   10bb5:	55                   	push   %ebp
   10bb6:	89 e5                	mov    %esp,%ebp
   10bb8:	83 ec 30             	sub    $0x30,%esp
	unsigned addr;
	unsigned int y = curr_y;
   10bbb:	a1 18 a0 01 00       	mov    0x1a018,%eax
   10bc0:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( y > scroll_max_y ) {
   10bc3:	a1 10 a0 01 00       	mov    0x1a010,%eax
   10bc8:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   10bcb:	76 08                	jbe    10bd5 <setcursor+0x20>
		y = scroll_max_y;
   10bcd:	a1 10 a0 01 00       	mov    0x1a010,%eax
   10bd2:	89 45 fc             	mov    %eax,-0x4(%ebp)
	}

	addr = (unsigned)( y * SCREEN_X_SIZE + curr_x );
   10bd5:	8b 55 fc             	mov    -0x4(%ebp),%edx
   10bd8:	89 d0                	mov    %edx,%eax
   10bda:	c1 e0 02             	shl    $0x2,%eax
   10bdd:	01 d0                	add    %edx,%eax
   10bdf:	c1 e0 04             	shl    $0x4,%eax
   10be2:	89 c2                	mov    %eax,%edx
   10be4:	a1 14 a0 01 00       	mov    0x1a014,%eax
   10be9:	01 d0                	add    %edx,%eax
   10beb:	89 45 f8             	mov    %eax,-0x8(%ebp)
   10bee:	c7 45 dc d4 03 00 00 	movl   $0x3d4,-0x24(%ebp)
   10bf5:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
** @return The data read from the specified port
*/
OPSINLINED static inline void
outb( int port, uint8_t data )
{
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   10bf9:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   10bfd:	8b 55 dc             	mov    -0x24(%ebp),%edx
   10c00:	ee                   	out    %al,(%dx)
}
   10c01:	90                   	nop

	outb( VGA_CTRL_IX_ADDR, VGA_CTRL_CUR_HIGH );
	outb( VGA_CTRL_IX_DATA, ( addr >> 8 ) & BMASK8 );
   10c02:	8b 45 f8             	mov    -0x8(%ebp),%eax
   10c05:	c1 e8 08             	shr    $0x8,%eax
   10c08:	0f b6 c0             	movzbl %al,%eax
   10c0b:	c7 45 e4 d5 03 00 00 	movl   $0x3d5,-0x1c(%ebp)
   10c12:	88 45 e3             	mov    %al,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   10c15:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   10c19:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   10c1c:	ee                   	out    %al,(%dx)
}
   10c1d:	90                   	nop
   10c1e:	c7 45 ec d4 03 00 00 	movl   $0x3d4,-0x14(%ebp)
   10c25:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   10c29:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   10c2d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   10c30:	ee                   	out    %al,(%dx)
}
   10c31:	90                   	nop
	outb( VGA_CTRL_IX_ADDR, VGA_CTRL_CUR_LOW );
	outb( VGA_CTRL_IX_DATA, addr & BMASK8 );
   10c32:	8b 45 f8             	mov    -0x8(%ebp),%eax
   10c35:	0f b6 c0             	movzbl %al,%eax
   10c38:	c7 45 f4 d5 03 00 00 	movl   $0x3d5,-0xc(%ebp)
   10c3f:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   10c42:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   10c46:	8b 55 f4             	mov    -0xc(%ebp),%edx
   10c49:	ee                   	out    %al,(%dx)
}
   10c4a:	90                   	nop
}
   10c4b:	90                   	nop
   10c4c:	c9                   	leave  
   10c4d:	c3                   	ret    

00010c4e <putchar_at>:

/*
** putchar_at: physical output to the video memory
*/
static void putchar_at( unsigned int x, unsigned int y, unsigned int c ) {
   10c4e:	55                   	push   %ebp
   10c4f:	89 e5                	mov    %esp,%ebp
   10c51:	83 ec 28             	sub    $0x28,%esp
	/*
	** If x or y is too big or small, don't do any output.
	*/
	if( x <= max_x && y <= max_y ) {
   10c54:	a1 24 a0 01 00       	mov    0x1a024,%eax
   10c59:	39 45 08             	cmp    %eax,0x8(%ebp)
   10c5c:	0f 87 eb 00 00 00    	ja     10d4d <putchar_at+0xff>
   10c62:	a1 28 a0 01 00       	mov    0x1a028,%eax
   10c67:	39 45 0c             	cmp    %eax,0xc(%ebp)
   10c6a:	0f 87 dd 00 00 00    	ja     10d4d <putchar_at+0xff>
		unsigned short *addr = VIDEO_ADDR( x, y );
   10c70:	8b 55 0c             	mov    0xc(%ebp),%edx
   10c73:	89 d0                	mov    %edx,%eax
   10c75:	c1 e0 02             	shl    $0x2,%eax
   10c78:	01 d0                	add    %edx,%eax
   10c7a:	c1 e0 04             	shl    $0x4,%eax
   10c7d:	89 c2                	mov    %eax,%edx
   10c7f:	8b 45 08             	mov    0x8(%ebp),%eax
   10c82:	01 d0                	add    %edx,%eax
   10c84:	05 00 c0 05 00       	add    $0x5c000,%eax
   10c89:	01 c0                	add    %eax,%eax
   10c8b:	89 45 f4             	mov    %eax,-0xc(%ebp)

		/*
		** The character may have attributes associated with it; if
		** so, use those, otherwise use white on black.
		*/
		c &= 0xffff;	// keep only the lower bytes
   10c8e:	81 65 10 ff ff 00 00 	andl   $0xffff,0x10(%ebp)
		if( c > BMASK8 ) {
   10c95:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
   10c9c:	76 0d                	jbe    10cab <putchar_at+0x5d>
			*addr = (unsigned short)c;
   10c9e:	8b 45 10             	mov    0x10(%ebp),%eax
   10ca1:	89 c2                	mov    %eax,%edx
   10ca3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   10ca6:	66 89 10             	mov    %dx,(%eax)
   10ca9:	eb 0e                	jmp    10cb9 <putchar_at+0x6b>
		} else {
			*addr = (unsigned short)c | VGA_DEFAULT;
   10cab:	8b 45 10             	mov    0x10(%ebp),%eax
   10cae:	80 cc 70             	or     $0x70,%ah
   10cb1:	89 c2                	mov    %eax,%edx
   10cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   10cb6:	66 89 10             	mov    %dx,(%eax)
		}
#ifdef CIO_DUP2_SIO
		// only dup if it's been enabled and we're within the scrolling region
		if( !dup_to_sio ||
   10cb9:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   10cc0:	84 c0                	test   %al,%al
   10cc2:	0f 84 84 00 00 00    	je     10d4c <putchar_at+0xfe>
			x < scroll_min_x || x > scroll_max_x ||
   10cc8:	a1 04 a0 01 00       	mov    0x1a004,%eax
		if( !dup_to_sio ||
   10ccd:	39 45 08             	cmp    %eax,0x8(%ebp)
   10cd0:	72 7a                	jb     10d4c <putchar_at+0xfe>
			x < scroll_min_x || x > scroll_max_x ||
   10cd2:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   10cd7:	39 45 08             	cmp    %eax,0x8(%ebp)
   10cda:	77 70                	ja     10d4c <putchar_at+0xfe>
			y < scroll_min_y || y > scroll_max_y ) {
   10cdc:	a1 08 a0 01 00       	mov    0x1a008,%eax
			x < scroll_min_x || x > scroll_max_x ||
   10ce1:	39 45 0c             	cmp    %eax,0xc(%ebp)
   10ce4:	72 66                	jb     10d4c <putchar_at+0xfe>
			y < scroll_min_y || y > scroll_max_y ) {
   10ce6:	a1 10 a0 01 00       	mov    0x1a010,%eax
   10ceb:	39 45 0c             	cmp    %eax,0xc(%ebp)
   10cee:	77 5c                	ja     10d4c <putchar_at+0xfe>
			return;
		}
		unsigned int ch = c & 0xff;
   10cf0:	8b 45 10             	mov    0x10(%ebp),%eax
   10cf3:	0f b6 c0             	movzbl %al,%eax
   10cf6:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if( ISPRINT(ch) ) {
   10cf9:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
   10cfd:	76 06                	jbe    10d05 <putchar_at+0xb7>
   10cff:	83 7d f0 7e          	cmpl   $0x7e,-0x10(%ebp)
   10d03:	76 0c                	jbe    10d11 <putchar_at+0xc3>
   10d05:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
   10d09:	74 06                	je     10d11 <putchar_at+0xc3>
   10d0b:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
   10d0f:	75 11                	jne    10d22 <putchar_at+0xd4>
			// only the "character" part
			sio_writec( ch );
   10d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
   10d14:	83 ec 0c             	sub    $0xc,%esp
   10d17:	50                   	push   %eax
   10d18:	e8 ef 3b 00 00       	call   1490c <sio_writec>
   10d1d:	83 c4 10             	add    $0x10,%esp
   10d20:	eb 2b                	jmp    10d4d <putchar_at+0xff>
		} else {
			char buf[16];
			sprint( buf, "\\x%02x", ch );
   10d22:	83 ec 04             	sub    $0x4,%esp
   10d25:	ff 75 f0             	push   -0x10(%ebp)
   10d28:	68 00 70 01 00       	push   $0x17000
   10d2d:	8d 45 e0             	lea    -0x20(%ebp),%eax
   10d30:	50                   	push   %eax
   10d31:	e8 c4 5a 00 00       	call   167fa <sprint>
   10d36:	83 c4 10             	add    $0x10,%esp
			sio_write( buf, 4 );
   10d39:	83 ec 08             	sub    $0x8,%esp
   10d3c:	6a 04                	push   $0x4
   10d3e:	8d 45 e0             	lea    -0x20(%ebp),%eax
   10d41:	50                   	push   %eax
   10d42:	e8 3b 3c 00 00       	call   14982 <sio_write>
   10d47:	83 c4 10             	add    $0x10,%esp
   10d4a:	eb 01                	jmp    10d4d <putchar_at+0xff>
			return;
   10d4c:	90                   	nop
		}
#endif
	}
}
   10d4d:	c9                   	leave  
   10d4e:	c3                   	ret    

00010d4f <cio_setscroll>:

/*
** Set the scrolling region
*/
void cio_setscroll( unsigned int s_min_x, unsigned int s_min_y,
					  unsigned int s_max_x, unsigned int s_max_y ) {
   10d4f:	55                   	push   %ebp
   10d50:	89 e5                	mov    %esp,%ebp
   10d52:	83 ec 08             	sub    $0x8,%esp
	scroll_min_x = bound( min_x, s_min_x, max_x );
   10d55:	8b 15 24 a0 01 00    	mov    0x1a024,%edx
   10d5b:	a1 1c a0 01 00       	mov    0x1a01c,%eax
   10d60:	83 ec 04             	sub    $0x4,%esp
   10d63:	52                   	push   %edx
   10d64:	ff 75 08             	push   0x8(%ebp)
   10d67:	50                   	push   %eax
   10d68:	e8 44 57 00 00       	call   164b1 <bound>
   10d6d:	83 c4 10             	add    $0x10,%esp
   10d70:	a3 04 a0 01 00       	mov    %eax,0x1a004
	scroll_min_y = bound( min_y, s_min_y, max_y );
   10d75:	8b 15 28 a0 01 00    	mov    0x1a028,%edx
   10d7b:	a1 20 a0 01 00       	mov    0x1a020,%eax
   10d80:	83 ec 04             	sub    $0x4,%esp
   10d83:	52                   	push   %edx
   10d84:	ff 75 0c             	push   0xc(%ebp)
   10d87:	50                   	push   %eax
   10d88:	e8 24 57 00 00       	call   164b1 <bound>
   10d8d:	83 c4 10             	add    $0x10,%esp
   10d90:	a3 08 a0 01 00       	mov    %eax,0x1a008
	scroll_max_x = bound( scroll_min_x, s_max_x, max_x );
   10d95:	8b 15 24 a0 01 00    	mov    0x1a024,%edx
   10d9b:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10da0:	83 ec 04             	sub    $0x4,%esp
   10da3:	52                   	push   %edx
   10da4:	ff 75 10             	push   0x10(%ebp)
   10da7:	50                   	push   %eax
   10da8:	e8 04 57 00 00       	call   164b1 <bound>
   10dad:	83 c4 10             	add    $0x10,%esp
   10db0:	a3 0c a0 01 00       	mov    %eax,0x1a00c
	scroll_max_y = bound( scroll_min_y, s_max_y, max_y );
   10db5:	8b 15 28 a0 01 00    	mov    0x1a028,%edx
   10dbb:	a1 08 a0 01 00       	mov    0x1a008,%eax
   10dc0:	83 ec 04             	sub    $0x4,%esp
   10dc3:	52                   	push   %edx
   10dc4:	ff 75 14             	push   0x14(%ebp)
   10dc7:	50                   	push   %eax
   10dc8:	e8 e4 56 00 00       	call   164b1 <bound>
   10dcd:	83 c4 10             	add    $0x10,%esp
   10dd0:	a3 10 a0 01 00       	mov    %eax,0x1a010
	curr_x = scroll_min_x;
   10dd5:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10dda:	a3 14 a0 01 00       	mov    %eax,0x1a014
	curr_y = scroll_min_y;
   10ddf:	a1 08 a0 01 00       	mov    0x1a008,%eax
   10de4:	a3 18 a0 01 00       	mov    %eax,0x1a018
	setcursor();
   10de9:	e8 c7 fd ff ff       	call   10bb5 <setcursor>
}
   10dee:	90                   	nop
   10def:	c9                   	leave  
   10df0:	c3                   	ret    

00010df1 <cio_moveto>:

/*
** Cursor movement in the scroll region
*/
void cio_moveto( unsigned int x, unsigned int y ) {
   10df1:	55                   	push   %ebp
   10df2:	89 e5                	mov    %esp,%ebp
   10df4:	83 ec 08             	sub    $0x8,%esp
	curr_x = bound( scroll_min_x, x + scroll_min_x, scroll_max_x );
   10df7:	8b 15 0c a0 01 00    	mov    0x1a00c,%edx
   10dfd:	8b 0d 04 a0 01 00    	mov    0x1a004,%ecx
   10e03:	8b 45 08             	mov    0x8(%ebp),%eax
   10e06:	01 c1                	add    %eax,%ecx
   10e08:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10e0d:	83 ec 04             	sub    $0x4,%esp
   10e10:	52                   	push   %edx
   10e11:	51                   	push   %ecx
   10e12:	50                   	push   %eax
   10e13:	e8 99 56 00 00       	call   164b1 <bound>
   10e18:	83 c4 10             	add    $0x10,%esp
   10e1b:	a3 14 a0 01 00       	mov    %eax,0x1a014
	curr_y = bound( scroll_min_y, y + scroll_min_y, scroll_max_y );
   10e20:	8b 15 10 a0 01 00    	mov    0x1a010,%edx
   10e26:	8b 0d 08 a0 01 00    	mov    0x1a008,%ecx
   10e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
   10e2f:	01 c1                	add    %eax,%ecx
   10e31:	a1 08 a0 01 00       	mov    0x1a008,%eax
   10e36:	83 ec 04             	sub    $0x4,%esp
   10e39:	52                   	push   %edx
   10e3a:	51                   	push   %ecx
   10e3b:	50                   	push   %eax
   10e3c:	e8 70 56 00 00       	call   164b1 <bound>
   10e41:	83 c4 10             	add    $0x10,%esp
   10e44:	a3 18 a0 01 00       	mov    %eax,0x1a018
	setcursor();
   10e49:	e8 67 fd ff ff       	call   10bb5 <setcursor>
}
   10e4e:	90                   	nop
   10e4f:	c9                   	leave  
   10e50:	c3                   	ret    

00010e51 <cio_putchar_at>:

/*
** The putchar family
*/
void cio_putchar_at( unsigned int x, unsigned int y, unsigned int c ) {
   10e51:	55                   	push   %ebp
   10e52:	89 e5                	mov    %esp,%ebp
   10e54:	83 ec 18             	sub    $0x18,%esp
	if( ( c & 0x7f ) == '\n' ) {
   10e57:	8b 45 10             	mov    0x10(%ebp),%eax
   10e5a:	83 e0 7f             	and    $0x7f,%eax
   10e5d:	83 f8 0a             	cmp    $0xa,%eax
   10e60:	0f 85 8f 00 00 00    	jne    10ef5 <cio_putchar_at+0xa4>
		/*
		** If we're in the scroll region, don't let this loop
		** leave it. If we're not in the scroll region, don't
		** let this loop enter it.
		*/
		if( x > scroll_max_x ) {
   10e66:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   10e6b:	39 45 08             	cmp    %eax,0x8(%ebp)
   10e6e:	76 0a                	jbe    10e7a <cio_putchar_at+0x29>
			limit = max_x;
   10e70:	a1 24 a0 01 00       	mov    0x1a024,%eax
   10e75:	89 45 f4             	mov    %eax,-0xc(%ebp)
   10e78:	eb 1f                	jmp    10e99 <cio_putchar_at+0x48>
		}
		else if( x >= scroll_min_x ) {
   10e7a:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10e7f:	39 45 08             	cmp    %eax,0x8(%ebp)
   10e82:	72 0a                	jb     10e8e <cio_putchar_at+0x3d>
			limit = scroll_max_x;
   10e84:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   10e89:	89 45 f4             	mov    %eax,-0xc(%ebp)
   10e8c:	eb 0b                	jmp    10e99 <cio_putchar_at+0x48>
		}
		else {
			limit = scroll_min_x - 1;
   10e8e:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10e93:	83 e8 01             	sub    $0x1,%eax
   10e96:	89 45 f4             	mov    %eax,-0xc(%ebp)
		}
#ifdef CIO_DUP2_SIO
		dup2sio_bak = dup_to_sio;  // remember the current setting
   10e99:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   10ea0:	a2 2d a0 01 00       	mov    %al,0x1a02d
		dup_to_sio = 0;             // turn it off for now
   10ea5:	c6 05 2c a0 01 00 00 	movb   $0x0,0x1a02c
#endif
		while( x <= limit ) {
   10eac:	eb 17                	jmp    10ec5 <cio_putchar_at+0x74>
			putchar_at( x, y, ' ' );
   10eae:	83 ec 04             	sub    $0x4,%esp
   10eb1:	6a 20                	push   $0x20
   10eb3:	ff 75 0c             	push   0xc(%ebp)
   10eb6:	ff 75 08             	push   0x8(%ebp)
   10eb9:	e8 90 fd ff ff       	call   10c4e <putchar_at>
   10ebe:	83 c4 10             	add    $0x10,%esp
			x += 1;
   10ec1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		while( x <= limit ) {
   10ec5:	8b 45 08             	mov    0x8(%ebp),%eax
   10ec8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   10ecb:	76 e1                	jbe    10eae <cio_putchar_at+0x5d>
		}
#ifdef CIO_DUP2_SIO
		if( dup_to_sio ) {
   10ecd:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   10ed4:	84 c0                	test   %al,%al
   10ed6:	74 0f                	je     10ee7 <cio_putchar_at+0x96>
			sio_writec( '\n' );
   10ed8:	83 ec 0c             	sub    $0xc,%esp
   10edb:	6a 0a                	push   $0xa
   10edd:	e8 2a 3a 00 00       	call   1490c <sio_writec>
   10ee2:	83 c4 10             	add    $0x10,%esp
#endif
	}
	else {
		putchar_at( x, y, c );
	}
}
   10ee5:	eb 22                	jmp    10f09 <cio_putchar_at+0xb8>
			dup_to_sio = dup2sio_bak;   // restore the setting
   10ee7:	0f b6 05 2d a0 01 00 	movzbl 0x1a02d,%eax
   10eee:	a2 2c a0 01 00       	mov    %al,0x1a02c
}
   10ef3:	eb 14                	jmp    10f09 <cio_putchar_at+0xb8>
		putchar_at( x, y, c );
   10ef5:	83 ec 04             	sub    $0x4,%esp
   10ef8:	ff 75 10             	push   0x10(%ebp)
   10efb:	ff 75 0c             	push   0xc(%ebp)
   10efe:	ff 75 08             	push   0x8(%ebp)
   10f01:	e8 48 fd ff ff       	call   10c4e <putchar_at>
   10f06:	83 c4 10             	add    $0x10,%esp
}
   10f09:	90                   	nop
   10f0a:	c9                   	leave  
   10f0b:	c3                   	ret    

00010f0c <cio_putchar>:

void cio_putchar( unsigned int c ) {
   10f0c:	55                   	push   %ebp
   10f0d:	89 e5                	mov    %esp,%ebp
   10f0f:	83 ec 08             	sub    $0x8,%esp
	/*
	** If we're off the bottom of the screen, scroll the window.
	*/
	if( curr_y > scroll_max_y ) {
   10f12:	8b 15 18 a0 01 00    	mov    0x1a018,%edx
   10f18:	a1 10 a0 01 00       	mov    0x1a010,%eax
   10f1d:	39 c2                	cmp    %eax,%edx
   10f1f:	76 23                	jbe    10f44 <cio_putchar+0x38>
		cio_scroll( curr_y - scroll_max_y );
   10f21:	a1 18 a0 01 00       	mov    0x1a018,%eax
   10f26:	8b 15 10 a0 01 00    	mov    0x1a010,%edx
   10f2c:	29 d0                	sub    %edx,%eax
   10f2e:	83 ec 0c             	sub    $0xc,%esp
   10f31:	50                   	push   %eax
   10f32:	e8 a8 02 00 00       	call   111df <cio_scroll>
   10f37:	83 c4 10             	add    $0x10,%esp
		curr_y = scroll_max_y;
   10f3a:	a1 10 a0 01 00       	mov    0x1a010,%eax
   10f3f:	a3 18 a0 01 00       	mov    %eax,0x1a018
	}

	switch( c & BMASK8 ) {
   10f44:	8b 45 08             	mov    0x8(%ebp),%eax
   10f47:	0f b6 c0             	movzbl %al,%eax
   10f4a:	83 f8 0a             	cmp    $0xa,%eax
   10f4d:	74 0e                	je     10f5d <cio_putchar+0x51>
   10f4f:	83 f8 0d             	cmp    $0xd,%eax
   10f52:	0f 84 8f 00 00 00    	je     10fe7 <cio_putchar+0xdb>
   10f58:	e9 96 00 00 00       	jmp    10ff3 <cio_putchar+0xe7>
		/*
		** Erase to the end of the line, then move to new line
		** (actual scroll is delayed until next output appears).
		*/
#ifdef CIO_DUP2_SIO
		dup2sio_bak = dup_to_sio;  // remember the current setting
   10f5d:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   10f64:	a2 2d a0 01 00       	mov    %al,0x1a02d
		dup_to_sio = 0;             // turn it off for now
   10f69:	c6 05 2c a0 01 00 00 	movb   $0x0,0x1a02c
#endif
		while( curr_x <= scroll_max_x ) {
   10f70:	eb 27                	jmp    10f99 <cio_putchar+0x8d>
			putchar_at( curr_x, curr_y, ' ' );
   10f72:	8b 15 18 a0 01 00    	mov    0x1a018,%edx
   10f78:	a1 14 a0 01 00       	mov    0x1a014,%eax
   10f7d:	83 ec 04             	sub    $0x4,%esp
   10f80:	6a 20                	push   $0x20
   10f82:	52                   	push   %edx
   10f83:	50                   	push   %eax
   10f84:	e8 c5 fc ff ff       	call   10c4e <putchar_at>
   10f89:	83 c4 10             	add    $0x10,%esp
			curr_x += 1;
   10f8c:	a1 14 a0 01 00       	mov    0x1a014,%eax
   10f91:	83 c0 01             	add    $0x1,%eax
   10f94:	a3 14 a0 01 00       	mov    %eax,0x1a014
		while( curr_x <= scroll_max_x ) {
   10f99:	8b 15 14 a0 01 00    	mov    0x1a014,%edx
   10f9f:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   10fa4:	39 c2                	cmp    %eax,%edx
   10fa6:	76 ca                	jbe    10f72 <cio_putchar+0x66>
		}
#ifdef CIO_DUP2_SIO
		if( dup_to_sio ) {
   10fa8:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   10faf:	84 c0                	test   %al,%al
   10fb1:	74 0f                	je     10fc2 <cio_putchar+0xb6>
			sio_writec( '\n' );
   10fb3:	83 ec 0c             	sub    $0xc,%esp
   10fb6:	6a 0a                	push   $0xa
   10fb8:	e8 4f 39 00 00       	call   1490c <sio_writec>
   10fbd:	83 c4 10             	add    $0x10,%esp
   10fc0:	eb 0c                	jmp    10fce <cio_putchar+0xc2>
		} else {
			dup_to_sio = dup2sio_bak;   // restore the setting
   10fc2:	0f b6 05 2d a0 01 00 	movzbl 0x1a02d,%eax
   10fc9:	a2 2c a0 01 00       	mov    %al,0x1a02c
		}
#endif
		curr_x = scroll_min_x;
   10fce:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10fd3:	a3 14 a0 01 00       	mov    %eax,0x1a014
		curr_y += 1;
   10fd8:	a1 18 a0 01 00       	mov    0x1a018,%eax
   10fdd:	83 c0 01             	add    $0x1,%eax
   10fe0:	a3 18 a0 01 00       	mov    %eax,0x1a018
		break;
   10fe5:	eb 5b                	jmp    11042 <cio_putchar+0x136>

	case '\r':
		curr_x = scroll_min_x;
   10fe7:	a1 04 a0 01 00       	mov    0x1a004,%eax
   10fec:	a3 14 a0 01 00       	mov    %eax,0x1a014
		break;
   10ff1:	eb 4f                	jmp    11042 <cio_putchar+0x136>

	default:
		putchar_at( curr_x, curr_y, c );
   10ff3:	8b 15 18 a0 01 00    	mov    0x1a018,%edx
   10ff9:	a1 14 a0 01 00       	mov    0x1a014,%eax
   10ffe:	83 ec 04             	sub    $0x4,%esp
   11001:	ff 75 08             	push   0x8(%ebp)
   11004:	52                   	push   %edx
   11005:	50                   	push   %eax
   11006:	e8 43 fc ff ff       	call   10c4e <putchar_at>
   1100b:	83 c4 10             	add    $0x10,%esp
		curr_x += 1;
   1100e:	a1 14 a0 01 00       	mov    0x1a014,%eax
   11013:	83 c0 01             	add    $0x1,%eax
   11016:	a3 14 a0 01 00       	mov    %eax,0x1a014
		if( curr_x > scroll_max_x ) {
   1101b:	8b 15 14 a0 01 00    	mov    0x1a014,%edx
   11021:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   11026:	39 c2                	cmp    %eax,%edx
   11028:	76 17                	jbe    11041 <cio_putchar+0x135>
			curr_x = scroll_min_x;
   1102a:	a1 04 a0 01 00       	mov    0x1a004,%eax
   1102f:	a3 14 a0 01 00       	mov    %eax,0x1a014
			curr_y += 1;
   11034:	a1 18 a0 01 00       	mov    0x1a018,%eax
   11039:	83 c0 01             	add    $0x1,%eax
   1103c:	a3 18 a0 01 00       	mov    %eax,0x1a018
		}
		break;
   11041:	90                   	nop
	}
	setcursor();
   11042:	e8 6e fb ff ff       	call   10bb5 <setcursor>
}
   11047:	90                   	nop
   11048:	c9                   	leave  
   11049:	c3                   	ret    

0001104a <cio_puts_at>:

/*
** The puts family
*/
void cio_puts_at( unsigned int x, unsigned int y, const char *str ) {
   1104a:	55                   	push   %ebp
   1104b:	89 e5                	mov    %esp,%ebp
   1104d:	83 ec 18             	sub    $0x18,%esp
	unsigned int ch;

	while( (ch = *str++) != '\0' && x <= max_x ) {
   11050:	eb 18                	jmp    1106a <cio_puts_at+0x20>
		cio_putchar_at( x, y, ch );
   11052:	83 ec 04             	sub    $0x4,%esp
   11055:	ff 75 f4             	push   -0xc(%ebp)
   11058:	ff 75 0c             	push   0xc(%ebp)
   1105b:	ff 75 08             	push   0x8(%ebp)
   1105e:	e8 ee fd ff ff       	call   10e51 <cio_putchar_at>
   11063:	83 c4 10             	add    $0x10,%esp
		x += 1;
   11066:	83 45 08 01          	addl   $0x1,0x8(%ebp)
	while( (ch = *str++) != '\0' && x <= max_x ) {
   1106a:	8b 45 10             	mov    0x10(%ebp),%eax
   1106d:	8d 50 01             	lea    0x1(%eax),%edx
   11070:	89 55 10             	mov    %edx,0x10(%ebp)
   11073:	0f b6 00             	movzbl (%eax),%eax
   11076:	0f be c0             	movsbl %al,%eax
   11079:	89 45 f4             	mov    %eax,-0xc(%ebp)
   1107c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   11080:	74 0a                	je     1108c <cio_puts_at+0x42>
   11082:	a1 24 a0 01 00       	mov    0x1a024,%eax
   11087:	39 45 08             	cmp    %eax,0x8(%ebp)
   1108a:	76 c6                	jbe    11052 <cio_puts_at+0x8>
	}
}
   1108c:	90                   	nop
   1108d:	c9                   	leave  
   1108e:	c3                   	ret    

0001108f <cio_puts>:

void cio_puts( const char *str ) {
   1108f:	55                   	push   %ebp
   11090:	89 e5                	mov    %esp,%ebp
   11092:	83 ec 18             	sub    $0x18,%esp
	unsigned int ch;

	while( (ch = *str++) != '\0' ) {
   11095:	eb 0e                	jmp    110a5 <cio_puts+0x16>
		cio_putchar( ch );
   11097:	83 ec 0c             	sub    $0xc,%esp
   1109a:	ff 75 f4             	push   -0xc(%ebp)
   1109d:	e8 6a fe ff ff       	call   10f0c <cio_putchar>
   110a2:	83 c4 10             	add    $0x10,%esp
	while( (ch = *str++) != '\0' ) {
   110a5:	8b 45 08             	mov    0x8(%ebp),%eax
   110a8:	8d 50 01             	lea    0x1(%eax),%edx
   110ab:	89 55 08             	mov    %edx,0x8(%ebp)
   110ae:	0f b6 00             	movzbl (%eax),%eax
   110b1:	0f be c0             	movsbl %al,%eax
   110b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
   110b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   110bb:	75 da                	jne    11097 <cio_puts+0x8>
	}
}
   110bd:	90                   	nop
   110be:	90                   	nop
   110bf:	c9                   	leave  
   110c0:	c3                   	ret    

000110c1 <cio_write>:

/*
** Write a "sized" buffer (like cio_puts(), but no NUL)
*/
void cio_write( const char *buf, int length ) {
   110c1:	55                   	push   %ebp
   110c2:	89 e5                	mov    %esp,%ebp
   110c4:	83 ec 18             	sub    $0x18,%esp
	for( int i = 0; i < length; ++i ) {
   110c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   110ce:	eb 1e                	jmp    110ee <cio_write+0x2d>
		cio_putchar( buf[i] );
   110d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
   110d3:	8b 45 08             	mov    0x8(%ebp),%eax
   110d6:	01 d0                	add    %edx,%eax
   110d8:	0f b6 00             	movzbl (%eax),%eax
   110db:	0f be c0             	movsbl %al,%eax
   110de:	83 ec 0c             	sub    $0xc,%esp
   110e1:	50                   	push   %eax
   110e2:	e8 25 fe ff ff       	call   10f0c <cio_putchar>
   110e7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < length; ++i ) {
   110ea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   110ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
   110f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
   110f4:	7c da                	jl     110d0 <cio_write+0xf>
	}
}
   110f6:	90                   	nop
   110f7:	90                   	nop
   110f8:	c9                   	leave  
   110f9:	c3                   	ret    

000110fa <cio_clearscroll>:
**
** These clear the screen directly, without going through the
** putchar_at() function, so they won't be echoed to SIO.
*/

void cio_clearscroll( void ) {
   110fa:	55                   	push   %ebp
   110fb:	89 e5                	mov    %esp,%ebp
   110fd:	83 ec 10             	sub    $0x10,%esp
	unsigned int nchars = scroll_max_x - scroll_min_x + 1;
   11100:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   11105:	8b 15 04 a0 01 00    	mov    0x1a004,%edx
   1110b:	29 d0                	sub    %edx,%eax
   1110d:	83 c0 01             	add    $0x1,%eax
   11110:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned int l;
	unsigned int c;

	for( l = scroll_min_y; l <= scroll_max_y; l += 1 ) {
   11113:	a1 08 a0 01 00       	mov    0x1a008,%eax
   11118:	89 45 fc             	mov    %eax,-0x4(%ebp)
   1111b:	eb 47                	jmp    11164 <cio_clearscroll+0x6a>
		unsigned short *to = VIDEO_ADDR( scroll_min_x, l );
   1111d:	8b 55 fc             	mov    -0x4(%ebp),%edx
   11120:	89 d0                	mov    %edx,%eax
   11122:	c1 e0 02             	shl    $0x2,%eax
   11125:	01 d0                	add    %edx,%eax
   11127:	c1 e0 04             	shl    $0x4,%eax
   1112a:	89 c2                	mov    %eax,%edx
   1112c:	a1 04 a0 01 00       	mov    0x1a004,%eax
   11131:	01 d0                	add    %edx,%eax
   11133:	05 00 c0 05 00       	add    $0x5c000,%eax
   11138:	01 c0                	add    %eax,%eax
   1113a:	89 45 f4             	mov    %eax,-0xc(%ebp)

		for( c = 0; c < nchars; c += 1 ) {
   1113d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   11144:	eb 12                	jmp    11158 <cio_clearscroll+0x5e>
			*to++ = ' ' | VGA_DEFAULT;
   11146:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11149:	8d 50 02             	lea    0x2(%eax),%edx
   1114c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1114f:	66 c7 00 20 70       	movw   $0x7020,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   11154:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   11158:	8b 45 f8             	mov    -0x8(%ebp),%eax
   1115b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   1115e:	72 e6                	jb     11146 <cio_clearscroll+0x4c>
	for( l = scroll_min_y; l <= scroll_max_y; l += 1 ) {
   11160:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   11164:	a1 10 a0 01 00       	mov    0x1a010,%eax
   11169:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   1116c:	76 af                	jbe    1111d <cio_clearscroll+0x23>
		}
	}
}
   1116e:	90                   	nop
   1116f:	90                   	nop
   11170:	c9                   	leave  
   11171:	c3                   	ret    

00011172 <cio_clearscreen>:

void cio_clearscreen( void ) {
   11172:	55                   	push   %ebp
   11173:	89 e5                	mov    %esp,%ebp
   11175:	83 ec 10             	sub    $0x10,%esp
	unsigned short *to = VIDEO_ADDR( min_x, min_y );
   11178:	8b 15 20 a0 01 00    	mov    0x1a020,%edx
   1117e:	89 d0                	mov    %edx,%eax
   11180:	c1 e0 02             	shl    $0x2,%eax
   11183:	01 d0                	add    %edx,%eax
   11185:	c1 e0 04             	shl    $0x4,%eax
   11188:	89 c2                	mov    %eax,%edx
   1118a:	a1 1c a0 01 00       	mov    0x1a01c,%eax
   1118f:	01 d0                	add    %edx,%eax
   11191:	05 00 c0 05 00       	add    $0x5c000,%eax
   11196:	01 c0                	add    %eax,%eax
   11198:	89 45 fc             	mov    %eax,-0x4(%ebp)
	unsigned int    nchars = ( max_y - min_y + 1 ) * ( max_x - min_x + 1 );
   1119b:	a1 28 a0 01 00       	mov    0x1a028,%eax
   111a0:	8b 15 20 a0 01 00    	mov    0x1a020,%edx
   111a6:	29 d0                	sub    %edx,%eax
   111a8:	8d 50 01             	lea    0x1(%eax),%edx
   111ab:	a1 24 a0 01 00       	mov    0x1a024,%eax
   111b0:	8b 0d 1c a0 01 00    	mov    0x1a01c,%ecx
   111b6:	29 c8                	sub    %ecx,%eax
   111b8:	83 c0 01             	add    $0x1,%eax
   111bb:	0f af c2             	imul   %edx,%eax
   111be:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while( nchars > 0 ) {
   111c1:	eb 12                	jmp    111d5 <cio_clearscreen+0x63>
		*to++ = ' ' | VGA_DEFAULT;
   111c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
   111c6:	8d 50 02             	lea    0x2(%eax),%edx
   111c9:	89 55 fc             	mov    %edx,-0x4(%ebp)
   111cc:	66 c7 00 20 70       	movw   $0x7020,(%eax)
		nchars -= 1;
   111d1:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
	while( nchars > 0 ) {
   111d5:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   111d9:	75 e8                	jne    111c3 <cio_clearscreen+0x51>
	}
}
   111db:	90                   	nop
   111dc:	90                   	nop
   111dd:	c9                   	leave  
   111de:	c3                   	ret    

000111df <cio_scroll>:


void cio_scroll( unsigned int lines ) {
   111df:	55                   	push   %ebp
   111e0:	89 e5                	mov    %esp,%ebp
   111e2:	83 ec 20             	sub    $0x20,%esp
	unsigned short *from;
	unsigned short *to;
	int nchars = scroll_max_x - scroll_min_x + 1;
   111e5:	a1 0c a0 01 00       	mov    0x1a00c,%eax
   111ea:	8b 15 04 a0 01 00    	mov    0x1a004,%edx
   111f0:	29 d0                	sub    %edx,%eax
   111f2:	83 c0 01             	add    $0x1,%eax
   111f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int line, c;

	/*
	** If # of lines is the whole scrolling region or more, just clear.
	*/
	if( lines > scroll_max_y - scroll_min_y ) {
   111f8:	a1 10 a0 01 00       	mov    0x1a010,%eax
   111fd:	8b 15 08 a0 01 00    	mov    0x1a008,%edx
   11203:	29 d0                	sub    %edx,%eax
   11205:	39 45 08             	cmp    %eax,0x8(%ebp)
   11208:	76 23                	jbe    1122d <cio_scroll+0x4e>
		cio_clearscroll();
   1120a:	e8 eb fe ff ff       	call   110fa <cio_clearscroll>
		curr_x = scroll_min_x;
   1120f:	a1 04 a0 01 00       	mov    0x1a004,%eax
   11214:	a3 14 a0 01 00       	mov    %eax,0x1a014
		curr_y = scroll_min_y;
   11219:	a1 08 a0 01 00       	mov    0x1a008,%eax
   1121e:	a3 18 a0 01 00       	mov    %eax,0x1a018
		setcursor();
   11223:	e8 8d f9 ff ff       	call   10bb5 <setcursor>
		return;
   11228:	e9 ea 00 00 00       	jmp    11317 <cio_scroll+0x138>
	}

	/*
	** Must copy it line by line.
	*/
	for( line = scroll_min_y; line <= scroll_max_y - lines; line += 1 ) {
   1122d:	a1 08 a0 01 00       	mov    0x1a008,%eax
   11232:	89 45 f4             	mov    %eax,-0xc(%ebp)
   11235:	eb 76                	jmp    112ad <cio_scroll+0xce>
		from = VIDEO_ADDR( scroll_min_x, line + lines );
   11237:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1123a:	8b 45 08             	mov    0x8(%ebp),%eax
   1123d:	01 c2                	add    %eax,%edx
   1123f:	89 d0                	mov    %edx,%eax
   11241:	c1 e0 02             	shl    $0x2,%eax
   11244:	01 d0                	add    %edx,%eax
   11246:	c1 e0 04             	shl    $0x4,%eax
   11249:	89 c2                	mov    %eax,%edx
   1124b:	a1 04 a0 01 00       	mov    0x1a004,%eax
   11250:	01 d0                	add    %edx,%eax
   11252:	05 00 c0 05 00       	add    $0x5c000,%eax
   11257:	01 c0                	add    %eax,%eax
   11259:	89 45 fc             	mov    %eax,-0x4(%ebp)
		to = VIDEO_ADDR( scroll_min_x, line );
   1125c:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1125f:	89 d0                	mov    %edx,%eax
   11261:	c1 e0 02             	shl    $0x2,%eax
   11264:	01 d0                	add    %edx,%eax
   11266:	c1 e0 04             	shl    $0x4,%eax
   11269:	89 c2                	mov    %eax,%edx
   1126b:	a1 04 a0 01 00       	mov    0x1a004,%eax
   11270:	01 d0                	add    %edx,%eax
   11272:	05 00 c0 05 00       	add    $0x5c000,%eax
   11277:	01 c0                	add    %eax,%eax
   11279:	89 45 f8             	mov    %eax,-0x8(%ebp)
		for( c = 0; c < nchars; c += 1 ) {
   1127c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   11283:	eb 1c                	jmp    112a1 <cio_scroll+0xc2>
			*to++ = *from++;
   11285:	8b 55 fc             	mov    -0x4(%ebp),%edx
   11288:	8d 42 02             	lea    0x2(%edx),%eax
   1128b:	89 45 fc             	mov    %eax,-0x4(%ebp)
   1128e:	8b 45 f8             	mov    -0x8(%ebp),%eax
   11291:	8d 48 02             	lea    0x2(%eax),%ecx
   11294:	89 4d f8             	mov    %ecx,-0x8(%ebp)
   11297:	0f b7 12             	movzwl (%edx),%edx
   1129a:	66 89 10             	mov    %dx,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   1129d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   112a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   112a4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   112a7:	7c dc                	jl     11285 <cio_scroll+0xa6>
	for( line = scroll_min_y; line <= scroll_max_y - lines; line += 1 ) {
   112a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   112ad:	a1 10 a0 01 00       	mov    0x1a010,%eax
   112b2:	2b 45 08             	sub    0x8(%ebp),%eax
   112b5:	89 c2                	mov    %eax,%edx
   112b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   112ba:	39 c2                	cmp    %eax,%edx
   112bc:	0f 83 75 ff ff ff    	jae    11237 <cio_scroll+0x58>
		}
	}

	for( ; line <= scroll_max_y; line += 1 ) {
   112c2:	eb 47                	jmp    1130b <cio_scroll+0x12c>
		to = VIDEO_ADDR( scroll_min_x, line );
   112c4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   112c7:	89 d0                	mov    %edx,%eax
   112c9:	c1 e0 02             	shl    $0x2,%eax
   112cc:	01 d0                	add    %edx,%eax
   112ce:	c1 e0 04             	shl    $0x4,%eax
   112d1:	89 c2                	mov    %eax,%edx
   112d3:	a1 04 a0 01 00       	mov    0x1a004,%eax
   112d8:	01 d0                	add    %edx,%eax
   112da:	05 00 c0 05 00       	add    $0x5c000,%eax
   112df:	01 c0                	add    %eax,%eax
   112e1:	89 45 f8             	mov    %eax,-0x8(%ebp)
		for( c = 0; c < nchars; c += 1 ) {
   112e4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   112eb:	eb 12                	jmp    112ff <cio_scroll+0x120>
			*to++ = ' ' | VGA_DEFAULT;
   112ed:	8b 45 f8             	mov    -0x8(%ebp),%eax
   112f0:	8d 50 02             	lea    0x2(%eax),%edx
   112f3:	89 55 f8             	mov    %edx,-0x8(%ebp)
   112f6:	66 c7 00 20 70       	movw   $0x7020,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   112fb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   112ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11302:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   11305:	7c e6                	jl     112ed <cio_scroll+0x10e>
	for( ; line <= scroll_max_y; line += 1 ) {
   11307:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   1130b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1130e:	a1 10 a0 01 00       	mov    0x1a010,%eax
   11313:	39 c2                	cmp    %eax,%edx
   11315:	76 ad                	jbe    112c4 <cio_scroll+0xe5>
		}
	}
}
   11317:	c9                   	leave  
   11318:	c3                   	ret    

00011319 <mypad>:

static int mypad( int x, int y, int extra, int padchar ) {
   11319:	55                   	push   %ebp
   1131a:	89 e5                	mov    %esp,%ebp
   1131c:	83 ec 08             	sub    $0x8,%esp
	while( extra > 0 ) {
   1131f:	eb 3c                	jmp    1135d <mypad+0x44>
		if( x != -1 || y != -1 ) {
   11321:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11325:	75 06                	jne    1132d <mypad+0x14>
   11327:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   1132b:	74 1d                	je     1134a <mypad+0x31>
			cio_putchar_at( x, y, padchar );
   1132d:	8b 4d 14             	mov    0x14(%ebp),%ecx
   11330:	8b 55 0c             	mov    0xc(%ebp),%edx
   11333:	8b 45 08             	mov    0x8(%ebp),%eax
   11336:	83 ec 04             	sub    $0x4,%esp
   11339:	51                   	push   %ecx
   1133a:	52                   	push   %edx
   1133b:	50                   	push   %eax
   1133c:	e8 10 fb ff ff       	call   10e51 <cio_putchar_at>
   11341:	83 c4 10             	add    $0x10,%esp
			x += 1;
   11344:	83 45 08 01          	addl   $0x1,0x8(%ebp)
   11348:	eb 0f                	jmp    11359 <mypad+0x40>
		}
		else {
			cio_putchar( padchar );
   1134a:	8b 45 14             	mov    0x14(%ebp),%eax
   1134d:	83 ec 0c             	sub    $0xc,%esp
   11350:	50                   	push   %eax
   11351:	e8 b6 fb ff ff       	call   10f0c <cio_putchar>
   11356:	83 c4 10             	add    $0x10,%esp
		}
		extra -= 1;
   11359:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
	while( extra > 0 ) {
   1135d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   11361:	7f be                	jg     11321 <mypad+0x8>
	}
	return x;
   11363:	8b 45 08             	mov    0x8(%ebp),%eax
}
   11366:	c9                   	leave  
   11367:	c3                   	ret    

00011368 <mypadstr>:

static int mypadstr( int x, int y, char *str, int len, int width,
				   int leftadjust, int padchar ) {
   11368:	55                   	push   %ebp
   11369:	89 e5                	mov    %esp,%ebp
   1136b:	83 ec 18             	sub    $0x18,%esp
	int extra;

	if( len < 0 ) {
   1136e:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
   11372:	79 11                	jns    11385 <mypadstr+0x1d>
		len = strlen( str );
   11374:	83 ec 0c             	sub    $0xc,%esp
   11377:	ff 75 10             	push   0x10(%ebp)
   1137a:	e8 26 57 00 00       	call   16aa5 <strlen>
   1137f:	83 c4 10             	add    $0x10,%esp
   11382:	89 45 14             	mov    %eax,0x14(%ebp)
	}
	extra = width - len;
   11385:	8b 45 18             	mov    0x18(%ebp),%eax
   11388:	2b 45 14             	sub    0x14(%ebp),%eax
   1138b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( extra > 0 && !leftadjust ) {
   1138e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   11392:	7e 1d                	jle    113b1 <mypadstr+0x49>
   11394:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
   11398:	75 17                	jne    113b1 <mypadstr+0x49>
		x = mypad( x, y, extra, padchar );
   1139a:	ff 75 20             	push   0x20(%ebp)
   1139d:	ff 75 f4             	push   -0xc(%ebp)
   113a0:	ff 75 0c             	push   0xc(%ebp)
   113a3:	ff 75 08             	push   0x8(%ebp)
   113a6:	e8 6e ff ff ff       	call   11319 <mypad>
   113ab:	83 c4 10             	add    $0x10,%esp
   113ae:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	if( x != -1 || y != -1 ) {
   113b1:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   113b5:	75 06                	jne    113bd <mypadstr+0x55>
   113b7:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   113bb:	74 1e                	je     113db <mypadstr+0x73>
		cio_puts_at( x, y, str );
   113bd:	8b 55 0c             	mov    0xc(%ebp),%edx
   113c0:	8b 45 08             	mov    0x8(%ebp),%eax
   113c3:	83 ec 04             	sub    $0x4,%esp
   113c6:	ff 75 10             	push   0x10(%ebp)
   113c9:	52                   	push   %edx
   113ca:	50                   	push   %eax
   113cb:	e8 7a fc ff ff       	call   1104a <cio_puts_at>
   113d0:	83 c4 10             	add    $0x10,%esp
		x += len;
   113d3:	8b 45 14             	mov    0x14(%ebp),%eax
   113d6:	01 45 08             	add    %eax,0x8(%ebp)
   113d9:	eb 0e                	jmp    113e9 <mypadstr+0x81>
	}
	else {
		cio_puts( str );
   113db:	83 ec 0c             	sub    $0xc,%esp
   113de:	ff 75 10             	push   0x10(%ebp)
   113e1:	e8 a9 fc ff ff       	call   1108f <cio_puts>
   113e6:	83 c4 10             	add    $0x10,%esp
	}
	if( extra > 0 && leftadjust ) {
   113e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   113ed:	7e 1d                	jle    1140c <mypadstr+0xa4>
   113ef:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
   113f3:	74 17                	je     1140c <mypadstr+0xa4>
		x = mypad( x, y, extra, padchar );
   113f5:	ff 75 20             	push   0x20(%ebp)
   113f8:	ff 75 f4             	push   -0xc(%ebp)
   113fb:	ff 75 0c             	push   0xc(%ebp)
   113fe:	ff 75 08             	push   0x8(%ebp)
   11401:	e8 13 ff ff ff       	call   11319 <mypad>
   11406:	83 c4 10             	add    $0x10,%esp
   11409:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	return x;
   1140c:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1140f:	c9                   	leave  
   11410:	c3                   	ret    

00011411 <do_printf>:

static void do_printf( int x, int y, char **f ) {
   11411:	55                   	push   %ebp
   11412:	89 e5                	mov    %esp,%ebp
   11414:	83 ec 38             	sub    $0x38,%esp
	char *fmt = *f;
   11417:	8b 45 10             	mov    0x10(%ebp),%eax
   1141a:	8b 00                	mov    (%eax),%eax
   1141c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	/*
	** Get characters from the format string and process them
	*/

	ap = (int *)( f + 1 );
   1141f:	8b 45 10             	mov    0x10(%ebp),%eax
   11422:	83 c0 04             	add    $0x4,%eax
   11425:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( (ch = *fmt++) != '\0' ) {
   11428:	e9 9d 02 00 00       	jmp    116ca <do_printf+0x2b9>

		/*
		** Is it the start of a format code?
		*/

		if( ch == '%' ) {
   1142d:	80 7d ef 25          	cmpb   $0x25,-0x11(%ebp)
   11431:	0f 85 3b 02 00 00    	jne    11672 <do_printf+0x261>
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/

			leftadjust = 0;
   11437:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			padchar = ' ';
   1143e:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			width = 0;
   11445:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

			ch = *fmt++;
   1144c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1144f:	8d 50 01             	lea    0x1(%eax),%edx
   11452:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11455:	0f b6 00             	movzbl (%eax),%eax
   11458:	88 45 ef             	mov    %al,-0x11(%ebp)

			if( ch == '-' ) {
   1145b:	80 7d ef 2d          	cmpb   $0x2d,-0x11(%ebp)
   1145f:	75 16                	jne    11477 <do_printf+0x66>
				leftadjust = 1;
   11461:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
				ch = *fmt++;
   11468:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1146b:	8d 50 01             	lea    0x1(%eax),%edx
   1146e:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11471:	0f b6 00             	movzbl (%eax),%eax
   11474:	88 45 ef             	mov    %al,-0x11(%ebp)
			}

			if( ch == '0' ) {
   11477:	80 7d ef 30          	cmpb   $0x30,-0x11(%ebp)
   1147b:	75 40                	jne    114bd <do_printf+0xac>
				padchar = '0';
   1147d:	c7 45 e0 30 00 00 00 	movl   $0x30,-0x20(%ebp)
				ch = *fmt++;
   11484:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11487:	8d 50 01             	lea    0x1(%eax),%edx
   1148a:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1148d:	0f b6 00             	movzbl (%eax),%eax
   11490:	88 45 ef             	mov    %al,-0x11(%ebp)
			}

			while( ch >= '0' && ch <= '9' ) {
   11493:	eb 28                	jmp    114bd <do_printf+0xac>
				width *= 10;
   11495:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   11498:	89 d0                	mov    %edx,%eax
   1149a:	c1 e0 02             	shl    $0x2,%eax
   1149d:	01 d0                	add    %edx,%eax
   1149f:	01 c0                	add    %eax,%eax
   114a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				width += ch - '0';
   114a4:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   114a8:	83 e8 30             	sub    $0x30,%eax
   114ab:	01 45 e4             	add    %eax,-0x1c(%ebp)
				ch = *fmt++;
   114ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
   114b1:	8d 50 01             	lea    0x1(%eax),%edx
   114b4:	89 55 f4             	mov    %edx,-0xc(%ebp)
   114b7:	0f b6 00             	movzbl (%eax),%eax
   114ba:	88 45 ef             	mov    %al,-0x11(%ebp)
			while( ch >= '0' && ch <= '9' ) {
   114bd:	80 7d ef 2f          	cmpb   $0x2f,-0x11(%ebp)
   114c1:	7e 06                	jle    114c9 <do_printf+0xb8>
   114c3:	80 7d ef 39          	cmpb   $0x39,-0x11(%ebp)
   114c7:	7e cc                	jle    11495 <do_printf+0x84>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   114c9:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   114cd:	83 e8 63             	sub    $0x63,%eax
   114d0:	83 f8 15             	cmp    $0x15,%eax
   114d3:	0f 87 f1 01 00 00    	ja     116ca <do_printf+0x2b9>
   114d9:	8b 04 85 08 70 01 00 	mov    0x17008(,%eax,4),%eax
   114e0:	ff e0                	jmp    *%eax

			case 'c':
				// ch = *( (int *)ap )++;
				ch = *ap++;
   114e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   114e5:	8d 50 04             	lea    0x4(%eax),%edx
   114e8:	89 55 f0             	mov    %edx,-0x10(%ebp)
   114eb:	8b 00                	mov    (%eax),%eax
   114ed:	88 45 ef             	mov    %al,-0x11(%ebp)
				buf[ 0 ] = ch;
   114f0:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   114f4:	88 45 cc             	mov    %al,-0x34(%ebp)
				buf[ 1 ] = '\0';
   114f7:	c6 45 cd 00          	movb   $0x0,-0x33(%ebp)
				x = mypadstr( x, y, buf, 1, width, leftadjust, padchar );
   114fb:	83 ec 04             	sub    $0x4,%esp
   114fe:	ff 75 e0             	push   -0x20(%ebp)
   11501:	ff 75 e8             	push   -0x18(%ebp)
   11504:	ff 75 e4             	push   -0x1c(%ebp)
   11507:	6a 01                	push   $0x1
   11509:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1150c:	50                   	push   %eax
   1150d:	ff 75 0c             	push   0xc(%ebp)
   11510:	ff 75 08             	push   0x8(%ebp)
   11513:	e8 50 fe ff ff       	call   11368 <mypadstr>
   11518:	83 c4 20             	add    $0x20,%esp
   1151b:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1151e:	e9 a7 01 00 00       	jmp    116ca <do_printf+0x2b9>

			case 'd':
				// len = cvtdec( buf, *( (int *)ap )++ );
				len = cvtdec( buf, *ap++ );
   11523:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11526:	8d 50 04             	lea    0x4(%eax),%edx
   11529:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1152c:	8b 00                	mov    (%eax),%eax
   1152e:	83 ec 08             	sub    $0x8,%esp
   11531:	50                   	push   %eax
   11532:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11535:	50                   	push   %eax
   11536:	e8 9a 4f 00 00       	call   164d5 <cvtdec>
   1153b:	83 c4 10             	add    $0x10,%esp
   1153e:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   11541:	83 ec 04             	sub    $0x4,%esp
   11544:	ff 75 e0             	push   -0x20(%ebp)
   11547:	ff 75 e8             	push   -0x18(%ebp)
   1154a:	ff 75 e4             	push   -0x1c(%ebp)
   1154d:	ff 75 dc             	push   -0x24(%ebp)
   11550:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11553:	50                   	push   %eax
   11554:	ff 75 0c             	push   0xc(%ebp)
   11557:	ff 75 08             	push   0x8(%ebp)
   1155a:	e8 09 fe ff ff       	call   11368 <mypadstr>
   1155f:	83 c4 20             	add    $0x20,%esp
   11562:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11565:	e9 60 01 00 00       	jmp    116ca <do_printf+0x2b9>

			case 's':
				// str = *( (char **)ap )++;
				str = (char *) (*ap++);
   1156a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1156d:	8d 50 04             	lea    0x4(%eax),%edx
   11570:	89 55 f0             	mov    %edx,-0x10(%ebp)
   11573:	8b 00                	mov    (%eax),%eax
   11575:	89 45 d8             	mov    %eax,-0x28(%ebp)
				x = mypadstr( x, y, str, -1, width, leftadjust, padchar );
   11578:	83 ec 04             	sub    $0x4,%esp
   1157b:	ff 75 e0             	push   -0x20(%ebp)
   1157e:	ff 75 e8             	push   -0x18(%ebp)
   11581:	ff 75 e4             	push   -0x1c(%ebp)
   11584:	6a ff                	push   $0xffffffff
   11586:	ff 75 d8             	push   -0x28(%ebp)
   11589:	ff 75 0c             	push   0xc(%ebp)
   1158c:	ff 75 08             	push   0x8(%ebp)
   1158f:	e8 d4 fd ff ff       	call   11368 <mypadstr>
   11594:	83 c4 20             	add    $0x20,%esp
   11597:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1159a:	e9 2b 01 00 00       	jmp    116ca <do_printf+0x2b9>

			case 'x':
				// len = cvthex( buf, *( (int *)ap )++ );
				len = cvthex( buf, *ap++ );
   1159f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   115a2:	8d 50 04             	lea    0x4(%eax),%edx
   115a5:	89 55 f0             	mov    %edx,-0x10(%ebp)
   115a8:	8b 00                	mov    (%eax),%eax
   115aa:	83 ec 08             	sub    $0x8,%esp
   115ad:	50                   	push   %eax
   115ae:	8d 45 cc             	lea    -0x34(%ebp),%eax
   115b1:	50                   	push   %eax
   115b2:	e8 f2 4f 00 00       	call   165a9 <cvthex>
   115b7:	83 c4 10             	add    $0x10,%esp
   115ba:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   115bd:	83 ec 04             	sub    $0x4,%esp
   115c0:	ff 75 e0             	push   -0x20(%ebp)
   115c3:	ff 75 e8             	push   -0x18(%ebp)
   115c6:	ff 75 e4             	push   -0x1c(%ebp)
   115c9:	ff 75 dc             	push   -0x24(%ebp)
   115cc:	8d 45 cc             	lea    -0x34(%ebp),%eax
   115cf:	50                   	push   %eax
   115d0:	ff 75 0c             	push   0xc(%ebp)
   115d3:	ff 75 08             	push   0x8(%ebp)
   115d6:	e8 8d fd ff ff       	call   11368 <mypadstr>
   115db:	83 c4 20             	add    $0x20,%esp
   115de:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   115e1:	e9 e4 00 00 00       	jmp    116ca <do_printf+0x2b9>

			case 'o':
				// len = cvtoct( buf, *( (int *)ap )++ );
				len = cvtoct( buf, *ap++ );
   115e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   115e9:	8d 50 04             	lea    0x4(%eax),%edx
   115ec:	89 55 f0             	mov    %edx,-0x10(%ebp)
   115ef:	8b 00                	mov    (%eax),%eax
   115f1:	83 ec 08             	sub    $0x8,%esp
   115f4:	50                   	push   %eax
   115f5:	8d 45 cc             	lea    -0x34(%ebp),%eax
   115f8:	50                   	push   %eax
   115f9:	e8 16 50 00 00       	call   16614 <cvtoct>
   115fe:	83 c4 10             	add    $0x10,%esp
   11601:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   11604:	83 ec 04             	sub    $0x4,%esp
   11607:	ff 75 e0             	push   -0x20(%ebp)
   1160a:	ff 75 e8             	push   -0x18(%ebp)
   1160d:	ff 75 e4             	push   -0x1c(%ebp)
   11610:	ff 75 dc             	push   -0x24(%ebp)
   11613:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11616:	50                   	push   %eax
   11617:	ff 75 0c             	push   0xc(%ebp)
   1161a:	ff 75 08             	push   0x8(%ebp)
   1161d:	e8 46 fd ff ff       	call   11368 <mypadstr>
   11622:	83 c4 20             	add    $0x20,%esp
   11625:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11628:	e9 9d 00 00 00       	jmp    116ca <do_printf+0x2b9>

			case 'u':
				len = cvtuns( buf, *ap++ );
   1162d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11630:	8d 50 04             	lea    0x4(%eax),%edx
   11633:	89 55 f0             	mov    %edx,-0x10(%ebp)
   11636:	8b 00                	mov    (%eax),%eax
   11638:	83 ec 08             	sub    $0x8,%esp
   1163b:	50                   	push   %eax
   1163c:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1163f:	50                   	push   %eax
   11640:	e8 55 50 00 00       	call   1669a <cvtuns>
   11645:	83 c4 10             	add    $0x10,%esp
   11648:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   1164b:	83 ec 04             	sub    $0x4,%esp
   1164e:	ff 75 e0             	push   -0x20(%ebp)
   11651:	ff 75 e8             	push   -0x18(%ebp)
   11654:	ff 75 e4             	push   -0x1c(%ebp)
   11657:	ff 75 dc             	push   -0x24(%ebp)
   1165a:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1165d:	50                   	push   %eax
   1165e:	ff 75 0c             	push   0xc(%ebp)
   11661:	ff 75 08             	push   0x8(%ebp)
   11664:	e8 ff fc ff ff       	call   11368 <mypadstr>
   11669:	83 c4 20             	add    $0x20,%esp
   1166c:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1166f:	90                   	nop
   11670:	eb 58                	jmp    116ca <do_printf+0x2b9>

			/*
			** No - just print it normally.
			*/

			if( x != -1 || y != -1 ) {
   11672:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11676:	75 06                	jne    1167e <do_printf+0x26d>
   11678:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   1167c:	74 3c                	je     116ba <do_printf+0x2a9>
				cio_putchar_at( x, y, ch );
   1167e:	0f be 4d ef          	movsbl -0x11(%ebp),%ecx
   11682:	8b 55 0c             	mov    0xc(%ebp),%edx
   11685:	8b 45 08             	mov    0x8(%ebp),%eax
   11688:	83 ec 04             	sub    $0x4,%esp
   1168b:	51                   	push   %ecx
   1168c:	52                   	push   %edx
   1168d:	50                   	push   %eax
   1168e:	e8 be f7 ff ff       	call   10e51 <cio_putchar_at>
   11693:	83 c4 10             	add    $0x10,%esp
				switch( ch ) {
   11696:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   1169a:	83 f8 0a             	cmp    $0xa,%eax
   1169d:	74 07                	je     116a6 <do_printf+0x295>
   1169f:	83 f8 0d             	cmp    $0xd,%eax
   116a2:	74 06                	je     116aa <do_printf+0x299>
   116a4:	eb 0e                	jmp    116b4 <do_printf+0x2a3>
				case '\n':
					y += 1;
   116a6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
					/* FALL THRU */

				case '\r':
					x = scroll_min_x;
   116aa:	a1 04 a0 01 00       	mov    0x1a004,%eax
   116af:	89 45 08             	mov    %eax,0x8(%ebp)
					break;
   116b2:	eb 04                	jmp    116b8 <do_printf+0x2a7>

				default:
					x += 1;
   116b4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
				switch( ch ) {
   116b8:	eb 10                	jmp    116ca <do_printf+0x2b9>
				}
			}
			else {
				cio_putchar( ch );
   116ba:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   116be:	83 ec 0c             	sub    $0xc,%esp
   116c1:	50                   	push   %eax
   116c2:	e8 45 f8 ff ff       	call   10f0c <cio_putchar>
   116c7:	83 c4 10             	add    $0x10,%esp
	while( (ch = *fmt++) != '\0' ) {
   116ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
   116cd:	8d 50 01             	lea    0x1(%eax),%edx
   116d0:	89 55 f4             	mov    %edx,-0xc(%ebp)
   116d3:	0f b6 00             	movzbl (%eax),%eax
   116d6:	88 45 ef             	mov    %al,-0x11(%ebp)
   116d9:	80 7d ef 00          	cmpb   $0x0,-0x11(%ebp)
   116dd:	0f 85 4a fd ff ff    	jne    1142d <do_printf+0x1c>
			}
		}
	}
}
   116e3:	90                   	nop
   116e4:	90                   	nop
   116e5:	c9                   	leave  
   116e6:	c3                   	ret    

000116e7 <cio_printf_at>:

void cio_printf_at( unsigned int x, unsigned int y, char *fmt, ... ) {
   116e7:	55                   	push   %ebp
   116e8:	89 e5                	mov    %esp,%ebp
   116ea:	83 ec 08             	sub    $0x8,%esp
	do_printf( x, y, &fmt );
   116ed:	8b 55 0c             	mov    0xc(%ebp),%edx
   116f0:	8b 45 08             	mov    0x8(%ebp),%eax
   116f3:	83 ec 04             	sub    $0x4,%esp
   116f6:	8d 4d 10             	lea    0x10(%ebp),%ecx
   116f9:	51                   	push   %ecx
   116fa:	52                   	push   %edx
   116fb:	50                   	push   %eax
   116fc:	e8 10 fd ff ff       	call   11411 <do_printf>
   11701:	83 c4 10             	add    $0x10,%esp
}
   11704:	90                   	nop
   11705:	c9                   	leave  
   11706:	c3                   	ret    

00011707 <cio_printf>:

void cio_printf( char *fmt, ... ) {
   11707:	55                   	push   %ebp
   11708:	89 e5                	mov    %esp,%ebp
   1170a:	83 ec 08             	sub    $0x8,%esp
	do_printf( -1, -1, &fmt );
   1170d:	83 ec 04             	sub    $0x4,%esp
   11710:	8d 45 08             	lea    0x8(%ebp),%eax
   11713:	50                   	push   %eax
   11714:	6a ff                	push   $0xffffffff
   11716:	6a ff                	push   $0xffffffff
   11718:	e8 f4 fc ff ff       	call   11411 <do_printf>
   1171d:	83 c4 10             	add    $0x10,%esp
}
   11720:	90                   	nop
   11721:	c9                   	leave  
   11722:	c3                   	ret    

00011723 <increment>:

static char input_buffer[ C_BUFSIZE ];
static volatile char *next_char = input_buffer;
static volatile char *next_space = input_buffer;

static volatile char *increment( volatile char *pointer ) {
   11723:	55                   	push   %ebp
   11724:	89 e5                	mov    %esp,%ebp
	if( ++pointer >= input_buffer + C_BUFSIZE ) {
   11726:	83 45 08 01          	addl   $0x1,0x8(%ebp)
   1172a:	b8 08 a1 01 00       	mov    $0x1a108,%eax
   1172f:	39 45 08             	cmp    %eax,0x8(%ebp)
   11732:	72 07                	jb     1173b <increment+0x18>
		pointer = input_buffer;
   11734:	c7 45 08 40 a0 01 00 	movl   $0x1a040,0x8(%ebp)
	}
	return pointer;
   1173b:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1173e:	5d                   	pop    %ebp
   1173f:	c3                   	ret    

00011740 <input_scan_code>:

static int input_scan_code( int code ) {
   11740:	55                   	push   %ebp
   11741:	89 e5                	mov    %esp,%ebp
   11743:	83 ec 10             	sub    $0x10,%esp
	static  int shift = 0;
	static  int ctrl_mask = BMASK8;
	int rval = -1;
   11746:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	/*
	** Do the shift processing
	*/
	code &= BMASK8;
   1174d:	81 65 08 ff 00 00 00 	andl   $0xff,0x8(%ebp)
	switch( code ) {
   11754:	81 7d 08 b6 00 00 00 	cmpl   $0xb6,0x8(%ebp)
   1175b:	74 54                	je     117b1 <input_scan_code+0x71>
   1175d:	81 7d 08 b6 00 00 00 	cmpl   $0xb6,0x8(%ebp)
   11764:	7f 72                	jg     117d8 <input_scan_code+0x98>
   11766:	81 7d 08 aa 00 00 00 	cmpl   $0xaa,0x8(%ebp)
   1176d:	74 42                	je     117b1 <input_scan_code+0x71>
   1176f:	81 7d 08 aa 00 00 00 	cmpl   $0xaa,0x8(%ebp)
   11776:	7f 60                	jg     117d8 <input_scan_code+0x98>
   11778:	81 7d 08 9d 00 00 00 	cmpl   $0x9d,0x8(%ebp)
   1177f:	74 4b                	je     117cc <input_scan_code+0x8c>
   11781:	81 7d 08 9d 00 00 00 	cmpl   $0x9d,0x8(%ebp)
   11788:	7f 4e                	jg     117d8 <input_scan_code+0x98>
   1178a:	83 7d 08 36          	cmpl   $0x36,0x8(%ebp)
   1178e:	74 12                	je     117a2 <input_scan_code+0x62>
   11790:	83 7d 08 36          	cmpl   $0x36,0x8(%ebp)
   11794:	7f 42                	jg     117d8 <input_scan_code+0x98>
   11796:	83 7d 08 1d          	cmpl   $0x1d,0x8(%ebp)
   1179a:	74 24                	je     117c0 <input_scan_code+0x80>
   1179c:	83 7d 08 2a          	cmpl   $0x2a,0x8(%ebp)
   117a0:	75 36                	jne    117d8 <input_scan_code+0x98>
	case L_SHIFT_DN:
	case R_SHIFT_DN:
		shift = 1;
   117a2:	c7 05 08 a1 01 00 01 	movl   $0x1,0x1a108
   117a9:	00 00 00 
		break;
   117ac:	e9 99 00 00 00       	jmp    1184a <input_scan_code+0x10a>

	case L_SHIFT_UP:
	case R_SHIFT_UP:
		shift = 0;
   117b1:	c7 05 08 a1 01 00 00 	movl   $0x0,0x1a108
   117b8:	00 00 00 
		break;
   117bb:	e9 8a 00 00 00       	jmp    1184a <input_scan_code+0x10a>

	case L_CTRL_DN:
		ctrl_mask = BMASK5;
   117c0:	c7 05 08 95 01 00 1f 	movl   $0x1f,0x19508
   117c7:	00 00 00 
		break;
   117ca:	eb 7e                	jmp    1184a <input_scan_code+0x10a>

	case L_CTRL_UP:
		ctrl_mask = BMASK8;
   117cc:	c7 05 08 95 01 00 ff 	movl   $0xff,0x19508
   117d3:	00 00 00 
		break;
   117d6:	eb 72                	jmp    1184a <input_scan_code+0x10a>
	default:
		/*
		** Process ordinary characters only on the press (to handle
		** autorepeat).  Ignore undefined scan codes.
		*/
		if( IS_PRESS(code) ) {
   117d8:	8b 45 08             	mov    0x8(%ebp),%eax
   117db:	25 80 00 00 00       	and    $0x80,%eax
   117e0:	85 c0                	test   %eax,%eax
   117e2:	75 66                	jne    1184a <input_scan_code+0x10a>
			code = scan_code[ shift ][ (int)code ];
   117e4:	a1 08 a1 01 00       	mov    0x1a108,%eax
   117e9:	c1 e0 07             	shl    $0x7,%eax
   117ec:	89 c2                	mov    %eax,%edx
   117ee:	8b 45 08             	mov    0x8(%ebp),%eax
   117f1:	01 d0                	add    %edx,%eax
   117f3:	05 00 94 01 00       	add    $0x19400,%eax
   117f8:	0f b6 00             	movzbl (%eax),%eax
   117fb:	0f b6 c0             	movzbl %al,%eax
   117fe:	89 45 08             	mov    %eax,0x8(%ebp)
			if( code != '\377' ) {
   11801:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11805:	74 43                	je     1184a <input_scan_code+0x10a>
				volatile char   *next = increment( next_space );
   11807:	a1 04 95 01 00       	mov    0x19504,%eax
   1180c:	50                   	push   %eax
   1180d:	e8 11 ff ff ff       	call   11723 <increment>
   11812:	83 c4 04             	add    $0x4,%esp
   11815:	89 45 f8             	mov    %eax,-0x8(%ebp)

				/*
				** Store character only if there's room
				*/
				rval = code & ctrl_mask;
   11818:	a1 08 95 01 00       	mov    0x19508,%eax
   1181d:	23 45 08             	and    0x8(%ebp),%eax
   11820:	89 45 fc             	mov    %eax,-0x4(%ebp)
				if( next != next_char ) {
   11823:	a1 00 95 01 00       	mov    0x19500,%eax
   11828:	39 45 f8             	cmp    %eax,-0x8(%ebp)
   1182b:	74 1d                	je     1184a <input_scan_code+0x10a>
					*next_space = code & ctrl_mask;
   1182d:	8b 45 08             	mov    0x8(%ebp),%eax
   11830:	89 c1                	mov    %eax,%ecx
   11832:	a1 08 95 01 00       	mov    0x19508,%eax
   11837:	89 c2                	mov    %eax,%edx
   11839:	a1 04 95 01 00       	mov    0x19504,%eax
   1183e:	21 ca                	and    %ecx,%edx
   11840:	88 10                	mov    %dl,(%eax)
					next_space = next;
   11842:	8b 45 f8             	mov    -0x8(%ebp),%eax
   11845:	a3 04 95 01 00       	mov    %eax,0x19504
				}
			}
		}
	}
	return( rval );
   1184a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1184d:	c9                   	leave  
   1184e:	c3                   	ret    

0001184f <keyboard_isr>:

static void keyboard_isr( int vector, int code ) {
   1184f:	55                   	push   %ebp
   11850:	89 e5                	mov    %esp,%ebp
   11852:	83 ec 28             	sub    $0x28,%esp
   11855:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1185c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1185f:	89 c2                	mov    %eax,%edx
   11861:	ec                   	in     (%dx),%al
   11862:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
   11865:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax

	int data = inb( KBD_DATA );
   11869:	0f b6 c0             	movzbl %al,%eax
   1186c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int val  = input_scan_code( data );
   1186f:	ff 75 f4             	push   -0xc(%ebp)
   11872:	e8 c9 fe ff ff       	call   11740 <input_scan_code>
   11877:	83 c4 04             	add    $0x4,%esp
   1187a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if there is a notification function, call it
	if( val != -1 && notify )
   1187d:	83 7d f0 ff          	cmpl   $0xffffffff,-0x10(%ebp)
   11881:	74 19                	je     1189c <keyboard_isr+0x4d>
   11883:	a1 30 a0 01 00       	mov    0x1a030,%eax
   11888:	85 c0                	test   %eax,%eax
   1188a:	74 10                	je     1189c <keyboard_isr+0x4d>
		notify( val );
   1188c:	a1 30 a0 01 00       	mov    0x1a030,%eax
   11891:	83 ec 0c             	sub    $0xc,%esp
   11894:	ff 75 f0             	push   -0x10(%ebp)
   11897:	ff d0                	call   *%eax
   11899:	83 c4 10             	add    $0x10,%esp
   1189c:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
   118a3:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   118a7:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   118ab:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   118ae:	ee                   	out    %al,(%dx)
}
   118af:	90                   	nop

	outb( PIC1_CMD, PIC_EOI );
}
   118b0:	90                   	nop
   118b1:	c9                   	leave  
   118b2:	c3                   	ret    

000118b3 <cio_getchar>:

int cio_getchar( void ) {
   118b3:	55                   	push   %ebp
   118b4:	89 e5                	mov    %esp,%ebp
   118b6:	83 ec 28             	sub    $0x28,%esp
	__asm__ __volatile__( "pushfl; popl %0" : "=r" (val) );
   118b9:	9c                   	pushf  
   118ba:	58                   	pop    %eax
   118bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	return val;
   118be:	8b 45 ec             	mov    -0x14(%ebp),%eax
	char    c;
	int interrupts_enabled = r_eflags() & EFL_IF;
   118c1:	25 00 02 00 00       	and    $0x200,%eax
   118c6:	89 45 f4             	mov    %eax,-0xc(%ebp)

	while( next_char == next_space ) {
   118c9:	eb 45                	jmp    11910 <cio_getchar+0x5d>
		if( !interrupts_enabled ) {
   118cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   118cf:	75 3f                	jne    11910 <cio_getchar+0x5d>
			/*
			** Must read the next keystroke ourselves.
			*/
			while( ( inb( KBD_STATUS ) & KBD_IN_READY ) == 0 ) {
   118d1:	90                   	nop
   118d2:	c7 45 e8 64 00 00 00 	movl   $0x64,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   118d9:	8b 45 e8             	mov    -0x18(%ebp),%eax
   118dc:	89 c2                	mov    %eax,%edx
   118de:	ec                   	in     (%dx),%al
   118df:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   118e2:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
   118e6:	0f b6 c0             	movzbl %al,%eax
   118e9:	83 e0 01             	and    $0x1,%eax
   118ec:	85 c0                	test   %eax,%eax
   118ee:	74 e2                	je     118d2 <cio_getchar+0x1f>
   118f0:	c7 45 e0 60 00 00 00 	movl   $0x60,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   118f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   118fa:	89 c2                	mov    %eax,%edx
   118fc:	ec                   	in     (%dx),%al
   118fd:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   11900:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
				;
			}
			(void) input_scan_code( inb( KBD_DATA ) );
   11904:	0f b6 c0             	movzbl %al,%eax
   11907:	50                   	push   %eax
   11908:	e8 33 fe ff ff       	call   11740 <input_scan_code>
   1190d:	83 c4 04             	add    $0x4,%esp
	while( next_char == next_space ) {
   11910:	8b 15 00 95 01 00    	mov    0x19500,%edx
   11916:	a1 04 95 01 00       	mov    0x19504,%eax
   1191b:	39 c2                	cmp    %eax,%edx
   1191d:	74 ac                	je     118cb <cio_getchar+0x18>
		}
	}

	c = *next_char & BMASK8;
   1191f:	a1 00 95 01 00       	mov    0x19500,%eax
   11924:	0f b6 00             	movzbl (%eax),%eax
   11927:	88 45 f3             	mov    %al,-0xd(%ebp)
	next_char = increment( next_char );
   1192a:	a1 00 95 01 00       	mov    0x19500,%eax
   1192f:	50                   	push   %eax
   11930:	e8 ee fd ff ff       	call   11723 <increment>
   11935:	83 c4 04             	add    $0x4,%esp
   11938:	a3 00 95 01 00       	mov    %eax,0x19500
	if( c != EOT ) {
   1193d:	80 7d f3 04          	cmpb   $0x4,-0xd(%ebp)
   11941:	74 10                	je     11953 <cio_getchar+0xa0>
		cio_putchar( c );
   11943:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   11947:	83 ec 0c             	sub    $0xc,%esp
   1194a:	50                   	push   %eax
   1194b:	e8 bc f5 ff ff       	call   10f0c <cio_putchar>
   11950:	83 c4 10             	add    $0x10,%esp
	}
	return c;
   11953:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
}
   11957:	c9                   	leave  
   11958:	c3                   	ret    

00011959 <cio_gets>:

int cio_gets( char *buffer, unsigned int size ) {
   11959:	55                   	push   %ebp
   1195a:	89 e5                	mov    %esp,%ebp
   1195c:	83 ec 18             	sub    $0x18,%esp
	char    ch;
	int count = 0;
   1195f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	while( size > 1 ) {
   11966:	eb 2b                	jmp    11993 <cio_gets+0x3a>
		ch = cio_getchar();
   11968:	e8 46 ff ff ff       	call   118b3 <cio_getchar>
   1196d:	88 45 f3             	mov    %al,-0xd(%ebp)
		if( ch == EOT ) {
   11970:	80 7d f3 04          	cmpb   $0x4,-0xd(%ebp)
   11974:	74 25                	je     1199b <cio_gets+0x42>
			break;
		}
		*buffer++ = ch;
   11976:	8b 45 08             	mov    0x8(%ebp),%eax
   11979:	8d 50 01             	lea    0x1(%eax),%edx
   1197c:	89 55 08             	mov    %edx,0x8(%ebp)
   1197f:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   11983:	88 10                	mov    %dl,(%eax)
		count += 1;
   11985:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		size -= 1;
   11989:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
		if( ch == '\n' ) {
   1198d:	80 7d f3 0a          	cmpb   $0xa,-0xd(%ebp)
   11991:	74 0b                	je     1199e <cio_gets+0x45>
	while( size > 1 ) {
   11993:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
   11997:	77 cf                	ja     11968 <cio_gets+0xf>
   11999:	eb 04                	jmp    1199f <cio_gets+0x46>
			break;
   1199b:	90                   	nop
   1199c:	eb 01                	jmp    1199f <cio_gets+0x46>
			break;
   1199e:	90                   	nop
		}
	}
	*buffer = '\0';
   1199f:	8b 45 08             	mov    0x8(%ebp),%eax
   119a2:	c6 00 00             	movb   $0x0,(%eax)
	return count;
   119a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   119a8:	c9                   	leave  
   119a9:	c3                   	ret    

000119aa <cio_input_queue>:

int cio_input_queue( void ) {
   119aa:	55                   	push   %ebp
   119ab:	89 e5                	mov    %esp,%ebp
   119ad:	83 ec 10             	sub    $0x10,%esp
	int n_chars = next_space - next_char;
   119b0:	a1 04 95 01 00       	mov    0x19504,%eax
   119b5:	8b 15 00 95 01 00    	mov    0x19500,%edx
   119bb:	29 d0                	sub    %edx,%eax
   119bd:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( n_chars < 0 ) {
   119c0:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   119c4:	79 07                	jns    119cd <cio_input_queue+0x23>
		n_chars += C_BUFSIZE;
   119c6:	81 45 fc c8 00 00 00 	addl   $0xc8,-0x4(%ebp)
	}
	return n_chars;
   119cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   119d0:	c9                   	leave  
   119d1:	c3                   	ret    

000119d2 <cio_init>:

/*
** Initialization routines
*/
void cio_init( void (*fcn)(int) ) {
   119d2:	55                   	push   %ebp
   119d3:	89 e5                	mov    %esp,%ebp
   119d5:	83 ec 08             	sub    $0x8,%esp
	/*
	** Screen dimensions
	*/
	min_x  = SCREEN_MIN_X;  
   119d8:	c7 05 1c a0 01 00 00 	movl   $0x0,0x1a01c
   119df:	00 00 00 
	min_y  = SCREEN_MIN_Y;
   119e2:	c7 05 20 a0 01 00 00 	movl   $0x0,0x1a020
   119e9:	00 00 00 
	max_x  = SCREEN_MAX_X;
   119ec:	c7 05 24 a0 01 00 4f 	movl   $0x4f,0x1a024
   119f3:	00 00 00 
	max_y  = SCREEN_MAX_Y;
   119f6:	c7 05 28 a0 01 00 18 	movl   $0x18,0x1a028
   119fd:	00 00 00 

	/*
	** Scrolling region
	*/
	scroll_min_x = SCREEN_MIN_X;
   11a00:	c7 05 04 a0 01 00 00 	movl   $0x0,0x1a004
   11a07:	00 00 00 
	scroll_min_y = SCREEN_MIN_Y;
   11a0a:	c7 05 08 a0 01 00 00 	movl   $0x0,0x1a008
   11a11:	00 00 00 
	scroll_max_x = SCREEN_MAX_X;
   11a14:	c7 05 0c a0 01 00 4f 	movl   $0x4f,0x1a00c
   11a1b:	00 00 00 
	scroll_max_y = SCREEN_MAX_Y;
   11a1e:	c7 05 10 a0 01 00 18 	movl   $0x18,0x1a010
   11a25:	00 00 00 

	/*
	** Initial cursor location
	*/
	curr_y = min_y;
   11a28:	a1 20 a0 01 00       	mov    0x1a020,%eax
   11a2d:	a3 18 a0 01 00       	mov    %eax,0x1a018
	curr_x = min_x;
   11a32:	a1 1c a0 01 00       	mov    0x1a01c,%eax
   11a37:	a3 14 a0 01 00       	mov    %eax,0x1a014
	setcursor();
   11a3c:	e8 74 f1 ff ff       	call   10bb5 <setcursor>

	/*
	** Notification function (or NULL)
	*/
	notify = fcn;
   11a41:	8b 45 08             	mov    0x8(%ebp),%eax
   11a44:	a3 30 a0 01 00       	mov    %eax,0x1a030

	/*
	** Set up the interrupt handler for the keyboard
	*/
	install_isr( VEC_KBD, keyboard_isr );
   11a49:	83 ec 08             	sub    $0x8,%esp
   11a4c:	68 4f 18 01 00       	push   $0x1184f
   11a51:	6a 21                	push   $0x21
   11a53:	e8 4a 3a 00 00       	call   154a2 <install_isr>
   11a58:	83 c4 10             	add    $0x10,%esp

	/*
	** clear the console screen, and report that we're ready
	*/
	cio_clearscreen();
   11a5b:	e8 12 f7 ff ff       	call   11172 <cio_clearscreen>
	cio_puts( "Console I/O is active\n" );
   11a60:	83 ec 0c             	sub    $0xc,%esp
   11a63:	68 60 70 01 00       	push   $0x17060
   11a68:	e8 22 f6 ff ff       	call   1108f <cio_puts>
   11a6d:	83 c4 10             	add    $0x10,%esp

	cio_ready = 1;
   11a70:	c7 05 00 a0 01 00 01 	movl   $0x1,0x1a000
   11a77:	00 00 00 
}
   11a7a:	90                   	nop
   11a7b:	c9                   	leave  
   11a7c:	c3                   	ret    

00011a7d <cio_opt_set>:
**
** @param[in] opt    The option to set
**
** @return The previous state of the option, or -1 on error
*/
int cio_opt_set( int opt ) {
   11a7d:	55                   	push   %ebp
   11a7e:	89 e5                	mov    %esp,%ebp
   11a80:	83 ec 10             	sub    $0x10,%esp

	if( opt != CIO_OPT_DUP ) {
   11a83:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   11a87:	74 07                	je     11a90 <cio_opt_set+0x13>
		return -1;
   11a89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   11a8e:	eb 17                	jmp    11aa7 <cio_opt_set+0x2a>
	}

	int old = dup_to_sio;
   11a90:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   11a97:	0f b6 c0             	movzbl %al,%eax
   11a9a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	dup_to_sio = 1;
   11a9d:	c6 05 2c a0 01 00 01 	movb   $0x1,0x1a02c

	return old;
   11aa4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   11aa7:	c9                   	leave  
   11aa8:	c3                   	ret    

00011aa9 <cio_opt_clear>:
**
** @param[in] opt    The option to clear
**
** @return The previous state of the option, or -1 on error
*/
int cio_opt_clear( int opt ) {
   11aa9:	55                   	push   %ebp
   11aaa:	89 e5                	mov    %esp,%ebp
   11aac:	83 ec 10             	sub    $0x10,%esp

	if( opt != CIO_OPT_DUP ) {
   11aaf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   11ab3:	74 07                	je     11abc <cio_opt_clear+0x13>
		return -1;
   11ab5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   11aba:	eb 17                	jmp    11ad3 <cio_opt_clear+0x2a>
	}

	int old = dup_to_sio;
   11abc:	0f b6 05 2c a0 01 00 	movzbl 0x1a02c,%eax
   11ac3:	0f b6 c0             	movzbl %al,%eax
   11ac6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	dup_to_sio = 0;
   11ac9:	c6 05 2c a0 01 00 00 	movb   $0x0,0x1a02c

	return old;
   11ad0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   11ad3:	c9                   	leave  
   11ad4:	c3                   	ret    

00011ad5 <clk_isr>:
** The ISR for the clock
**
** @param vector    Vector number for the clock interrupt
** @param code      Error code (0 for this interrupt)
*/
static void clk_isr( int vector, int code ) {
   11ad5:	55                   	push   %ebp
   11ad6:	89 e5                	mov    %esp,%ebp
   11ad8:	57                   	push   %edi
   11ad9:	56                   	push   %esi
   11ada:	53                   	push   %ebx
   11adb:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	(void) vector;
	(void) code;

	// spin the pinwheel

	++pinwheel;
   11ae1:	a1 10 a1 01 00       	mov    0x1a110,%eax
   11ae6:	83 c0 01             	add    $0x1,%eax
   11ae9:	a3 10 a1 01 00       	mov    %eax,0x1a110
	if( pinwheel == (CLOCK_FREQ / 10) ) {
   11aee:	a1 10 a1 01 00       	mov    0x1a110,%eax
   11af3:	83 f8 64             	cmp    $0x64,%eax
   11af6:	75 39                	jne    11b31 <clk_isr+0x5c>
		pinwheel = 0;
   11af8:	c7 05 10 a1 01 00 00 	movl   $0x0,0x1a110
   11aff:	00 00 00 
		++pindex;
   11b02:	a1 14 a1 01 00       	mov    0x1a114,%eax
   11b07:	83 c0 01             	add    $0x1,%eax
   11b0a:	a3 14 a1 01 00       	mov    %eax,0x1a114
		cio_putchar_at( 0, 0, "|/-\\"[ pindex & 3 ] );
   11b0f:	a1 14 a1 01 00       	mov    0x1a114,%eax
   11b14:	83 e0 03             	and    $0x3,%eax
   11b17:	0f b6 80 53 71 01 00 	movzbl 0x17153(%eax),%eax
   11b1e:	0f be c0             	movsbl %al,%eax
   11b21:	83 ec 04             	sub    $0x4,%esp
   11b24:	50                   	push   %eax
   11b25:	6a 00                	push   $0x0
   11b27:	6a 00                	push   $0x0
   11b29:	e8 23 f3 ff ff       	call   10e51 <cio_putchar_at>
   11b2e:	83 c4 10             	add    $0x10,%esp
	// with the SIO buffers, if non-empty).
	//
	// Define the symbol SYSTEM_STATUS with a value equal to the desired
	// reporting frequency, in seconds.

	cio_printf_at( 1, 0, " time %08x", system_time );
   11b31:	a1 0c a1 01 00       	mov    0x1a10c,%eax
   11b36:	50                   	push   %eax
   11b37:	68 78 70 01 00       	push   $0x17078
   11b3c:	6a 00                	push   $0x0
   11b3e:	6a 01                	push   $0x1
   11b40:	e8 a2 fb ff ff       	call   116e7 <cio_printf_at>
   11b45:	83 c4 10             	add    $0x10,%esp
	if( (system_time % SEC_TO_TICKS(SYSTEM_STATUS)) == 0 ) {
   11b48:	8b 0d 0c a1 01 00    	mov    0x1a10c,%ecx
   11b4e:	ba 59 17 b7 d1       	mov    $0xd1b71759,%edx
   11b53:	89 c8                	mov    %ecx,%eax
   11b55:	f7 e2                	mul    %edx
   11b57:	89 d0                	mov    %edx,%eax
   11b59:	c1 e8 0c             	shr    $0xc,%eax
   11b5c:	69 d0 88 13 00 00    	imul   $0x1388,%eax,%edx
   11b62:	89 c8                	mov    %ecx,%eax
   11b64:	29 d0                	sub    %edx,%eax
   11b66:	85 c0                	test   %eax,%eax
   11b68:	0f 85 39 01 00 00    	jne    11ca7 <clk_isr+0x1d2>

		// get process table counts
		uint32_t nst[N_STATES];
		uint32_t nunk;
		nunk = ptable_dump_stats( nst );
   11b6e:	83 ec 0c             	sub    $0xc,%esp
   11b71:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
   11b77:	50                   	push   %eax
   11b78:	e8 a1 15 00 00       	call   1311e <ptable_dump_stats>
   11b7d:	83 c4 10             	add    $0x10,%esp
   11b80:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// report queue info and wait/unknown states
		char tbuf[128]; // extra space, just in case
		sprint( tbuf,
   11b83:	8b bd 4c ff ff ff    	mov    -0xb4(%ebp),%edi
   11b89:	a1 58 a6 01 00       	mov    0x1a658,%eax
   11b8e:	83 ec 0c             	sub    $0xc,%esp
   11b91:	50                   	push   %eax
   11b92:	e8 d7 20 00 00       	call   13c6e <que_length>
   11b97:	83 c4 10             	add    $0x10,%esp
   11b9a:	89 c6                	mov    %eax,%esi
   11b9c:	a1 54 a6 01 00       	mov    0x1a654,%eax
   11ba1:	83 ec 0c             	sub    $0xc,%esp
   11ba4:	50                   	push   %eax
   11ba5:	e8 c4 20 00 00       	call   13c6e <que_length>
   11baa:	83 c4 10             	add    $0x10,%esp
   11bad:	89 85 24 ff ff ff    	mov    %eax,-0xdc(%ebp)
   11bb3:	a1 50 a6 01 00       	mov    0x1a650,%eax
   11bb8:	83 ec 0c             	sub    $0xc,%esp
   11bbb:	50                   	push   %eax
   11bbc:	e8 ad 20 00 00       	call   13c6e <que_length>
   11bc1:	83 c4 10             	add    $0x10,%esp
   11bc4:	89 85 20 ff ff ff    	mov    %eax,-0xe0(%ebp)
   11bca:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   11bcf:	83 ec 0c             	sub    $0xc,%esp
   11bd2:	50                   	push   %eax
   11bd3:	e8 96 20 00 00       	call   13c6e <que_length>
   11bd8:	83 c4 10             	add    $0x10,%esp
   11bdb:	89 85 1c ff ff ff    	mov    %eax,-0xe4(%ebp)
   11be1:	a1 48 a6 01 00       	mov    0x1a648,%eax
   11be6:	83 ec 0c             	sub    $0xc,%esp
   11be9:	50                   	push   %eax
   11bea:	e8 7f 20 00 00       	call   13c6e <que_length>
   11bef:	83 c4 10             	add    $0x10,%esp
   11bf2:	89 85 18 ff ff ff    	mov    %eax,-0xe8(%ebp)
   11bf8:	a1 44 a6 01 00       	mov    0x1a644,%eax
   11bfd:	83 ec 0c             	sub    $0xc,%esp
   11c00:	50                   	push   %eax
   11c01:	e8 68 20 00 00       	call   13c6e <que_length>
   11c06:	83 c4 10             	add    $0x10,%esp
   11c09:	89 c3                	mov    %eax,%ebx
   11c0b:	a1 40 a6 01 00       	mov    0x1a640,%eax
   11c10:	83 ec 0c             	sub    $0xc,%esp
   11c13:	50                   	push   %eax
   11c14:	e8 55 20 00 00       	call   13c6e <que_length>
   11c19:	83 c4 10             	add    $0x10,%esp
   11c1c:	89 c2                	mov    %eax,%edx
				" curr %d, Qs: R[%d,%d,%d] S[%d] Z[%d] B[%d] I[%d] W[%u] ?[%u]",
				current ? current->pid : -1,
   11c1e:	a1 5c a6 01 00       	mov    0x1a65c,%eax
		sprint( tbuf,
   11c23:	85 c0                	test   %eax,%eax
   11c25:	74 0a                	je     11c31 <clk_isr+0x15c>
				current ? current->pid : -1,
   11c27:	a1 5c a6 01 00       	mov    0x1a65c,%eax
		sprint( tbuf,
   11c2c:	8b 40 14             	mov    0x14(%eax),%eax
   11c2f:	eb 05                	jmp    11c36 <clk_isr+0x161>
   11c31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   11c36:	ff 75 e4             	push   -0x1c(%ebp)
   11c39:	57                   	push   %edi
   11c3a:	56                   	push   %esi
   11c3b:	ff b5 24 ff ff ff    	push   -0xdc(%ebp)
   11c41:	ff b5 20 ff ff ff    	push   -0xe0(%ebp)
   11c47:	ff b5 1c ff ff ff    	push   -0xe4(%ebp)
   11c4d:	ff b5 18 ff ff ff    	push   -0xe8(%ebp)
   11c53:	53                   	push   %ebx
   11c54:	52                   	push   %edx
   11c55:	50                   	push   %eax
   11c56:	68 84 70 01 00       	push   $0x17084
   11c5b:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   11c61:	50                   	push   %eax
   11c62:	e8 93 4b 00 00       	call   167fa <sprint>
   11c67:	83 c4 30             	add    $0x30,%esp
				que_length(sioread),
				nst[STATE_WAITING],
				nunk
		);
		// make sure we don't run off the end of our line
		if( strlen(tbuf) > 60 ) {
   11c6a:	83 ec 0c             	sub    $0xc,%esp
   11c6d:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   11c73:	50                   	push   %eax
   11c74:	e8 2c 4e 00 00       	call   16aa5 <strlen>
   11c79:	83 c4 10             	add    $0x10,%esp
   11c7c:	83 f8 3c             	cmp    $0x3c,%eax
   11c7f:	76 10                	jbe    11c91 <clk_isr+0x1bc>
			tbuf[60] = ' ';
   11c81:	c6 45 90 20          	movb   $0x20,-0x70(%ebp)
			tbuf[61] = '*';
   11c85:	c6 45 91 2a          	movb   $0x2a,-0x6f(%ebp)
			tbuf[62] = '*';
   11c89:	c6 45 92 2a          	movb   $0x2a,-0x6e(%ebp)
			tbuf[63] = '\0';
   11c8d:	c6 45 93 00          	movb   $0x0,-0x6d(%ebp)
		}
		cio_puts_at( 15, 0, tbuf );
   11c91:	83 ec 04             	sub    $0x4,%esp
   11c94:	8d 85 54 ff ff ff    	lea    -0xac(%ebp),%eax
   11c9a:	50                   	push   %eax
   11c9b:	6a 00                	push   $0x0
   11c9d:	6a 0f                	push   $0xf
   11c9f:	e8 a6 f3 ff ff       	call   1104a <cio_puts_at>
   11ca4:	83 c4 10             	add    $0x10,%esp
	}
#endif

	// time marches on!
	++system_time;
   11ca7:	a1 0c a1 01 00       	mov    0x1a10c,%eax
   11cac:	83 c0 01             	add    $0x1,%eax
   11caf:	a3 0c a1 01 00       	mov    %eax,0x1a10c

	do {
		pcb_t *pcb;

		// peek at the first member of the queue
		int status = que_peek( sleeping, (void **) &pcb );
   11cb4:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   11cb9:	83 ec 08             	sub    $0x8,%esp
   11cbc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
   11cbf:	52                   	push   %edx
   11cc0:	50                   	push   %eax
   11cc1:	e8 d9 21 00 00       	call   13e9f <que_peek>
   11cc6:	83 c4 10             	add    $0x10,%esp
   11cc9:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// it's possible there's nobody to awaken
		if( status == E_EMPTY ) {
   11ccc:	83 7d e0 04          	cmpl   $0x4,-0x20(%ebp)
   11cd0:	0f 84 a4 00 00 00    	je     11d7a <clk_isr+0x2a5>
			break;
		}

		// if the queue wasn't empty, make sure we got something useful
		if( pcb == NULL ) {
   11cd6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   11cd9:	85 c0                	test   %eax,%eax
   11cdb:	75 28                	jne    11d05 <clk_isr+0x230>
			sprint( b256, "clk_isr: sleeping peek status %d, pcb NULL\n",
   11cdd:	83 ec 04             	sub    $0x4,%esp
   11ce0:	ff 75 e0             	push   -0x20(%ebp)
   11ce3:	68 c4 70 01 00       	push   $0x170c4
   11ce8:	68 20 a1 01 00       	push   $0x1a120
   11ced:	e8 08 4b 00 00       	call   167fa <sprint>
   11cf2:	83 c4 10             	add    $0x10,%esp
					status );
			kpanic( b256 );
   11cf5:	83 ec 0c             	sub    $0xc,%esp
   11cf8:	68 20 a1 01 00       	push   $0x1a120
   11cfd:	e8 bf 45 00 00       	call   162c1 <kpanic>
   11d02:	83 c4 10             	add    $0x10,%esp
		** time, so we know that the retrieved PCB's wakeup time is
		** the earliest of any process on the queue. If that time
		** hasn't arrived yet, there's nobody left to awaken.
		*/

		if( pcb->wakeup > system_time ) {
   11d05:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   11d08:	8b 50 0c             	mov    0xc(%eax),%edx
   11d0b:	a1 0c a1 01 00       	mov    0x1a10c,%eax
   11d10:	39 c2                	cmp    %eax,%edx
   11d12:	77 69                	ja     11d7d <clk_isr+0x2a8>
			break;
		}

		// OK, we need to wake this process up
		assert( que_remove(sleeping,(void **)&pcb) == E_SUCCESS );
   11d14:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   11d19:	83 ec 08             	sub    $0x8,%esp
   11d1c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
   11d1f:	52                   	push   %edx
   11d20:	50                   	push   %eax
   11d21:	e8 3b 22 00 00       	call   13f61 <que_remove>
   11d26:	83 c4 10             	add    $0x10,%esp
   11d29:	85 c0                	test   %eax,%eax
   11d2b:	74 39                	je     11d66 <clk_isr+0x291>
   11d2d:	83 ec 08             	sub    $0x8,%esp
   11d30:	68 f0 70 01 00       	push   $0x170f0
   11d35:	68 9e 00 00 00       	push   $0x9e
   11d3a:	68 20 71 01 00       	push   $0x17120
   11d3f:	68 60 71 01 00       	push   $0x17160
   11d44:	68 30 71 01 00       	push   $0x17130
   11d49:	68 20 a4 01 00       	push   $0x1a420
   11d4e:	e8 a7 4a 00 00       	call   167fa <sprint>
   11d53:	83 c4 20             	add    $0x20,%esp
   11d56:	83 ec 0c             	sub    $0xc,%esp
   11d59:	68 20 a4 01 00       	push   $0x1a420
   11d5e:	e8 5e 45 00 00       	call   162c1 <kpanic>
   11d63:	83 c4 10             	add    $0x10,%esp
		schedule( pcb );
   11d66:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   11d69:	83 ec 0c             	sub    $0xc,%esp
   11d6c:	50                   	push   %eax
   11d6d:	e8 aa 19 00 00       	call   1371c <schedule>
   11d72:	83 c4 10             	add    $0x10,%esp
	do {
   11d75:	e9 3a ff ff ff       	jmp    11cb4 <clk_isr+0x1df>
			break;
   11d7a:	90                   	nop
   11d7b:	eb 01                	jmp    11d7e <clk_isr+0x2a9>
			break;
   11d7d:	90                   	nop

	} while( 1 );

	// next, we decrement the current process' remaining time
	current->quantum -= 1;
   11d7e:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   11d83:	0f b6 50 1a          	movzbl 0x1a(%eax),%edx
   11d87:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   11d8c:	83 ea 01             	sub    $0x1,%edx
   11d8f:	88 50 1a             	mov    %dl,0x1a(%eax)

	// has it expired?
	if( current->quantum < 1 ) {
   11d92:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   11d97:	0f b6 40 1a          	movzbl 0x1a(%eax),%eax
   11d9b:	84 c0                	test   %al,%al
   11d9d:	75 16                	jne    11db5 <clk_isr+0x2e0>
		// yes! reschedule it
		schedule( current );
   11d9f:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   11da4:	83 ec 0c             	sub    $0xc,%esp
   11da7:	50                   	push   %eax
   11da8:	e8 6f 19 00 00       	call   1371c <schedule>
   11dad:	83 c4 10             	add    $0x10,%esp
		// and pick a new process
		dispatch();
   11db0:	e8 62 1a 00 00       	call   13817 <dispatch>
   11db5:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
   11dbc:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   11dc0:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   11dc4:	8b 55 dc             	mov    -0x24(%ebp),%edx
   11dc7:	ee                   	out    %al,(%dx)
}
   11dc8:	90                   	nop
	}

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   11dc9:	90                   	nop
   11dca:	8d 65 f4             	lea    -0xc(%ebp),%esp
   11dcd:	5b                   	pop    %ebx
   11dce:	5e                   	pop    %esi
   11dcf:	5f                   	pop    %edi
   11dd0:	5d                   	pop    %ebp
   11dd1:	c3                   	ret    

00011dd2 <clk_init>:
** Name:  clk_init
**
** Initializes the clock module
**
*/
void clk_init( void ) {
   11dd2:	55                   	push   %ebp
   11dd3:	89 e5                	mov    %esp,%ebp
   11dd5:	83 ec 28             	sub    $0x28,%esp

#if TRACING_INIT
	cio_puts( " Clk" );
   11dd8:	83 ec 0c             	sub    $0xc,%esp
   11ddb:	68 58 71 01 00       	push   $0x17158
   11de0:	e8 aa f2 ff ff       	call   1108f <cio_puts>
   11de5:	83 c4 10             	add    $0x10,%esp
#endif

	// start the pinwheel
	pinwheel = -1;
   11de8:	c7 05 10 a1 01 00 ff 	movl   $0xffffffff,0x1a110
   11def:	ff ff ff 
	pindex = 0;
   11df2:	c7 05 14 a1 01 00 00 	movl   $0x0,0x1a114
   11df9:	00 00 00 

	// return to the dawn of time
	system_time = 0;
   11dfc:	c7 05 0c a1 01 00 00 	movl   $0x0,0x1a10c
   11e03:	00 00 00 

	// configure the clock
	uint32_t divisor = PIT_FREQ / CLOCK_FREQ;
   11e06:	c7 45 f4 a9 04 00 00 	movl   $0x4a9,-0xc(%ebp)
   11e0d:	c7 45 e0 43 00 00 00 	movl   $0x43,-0x20(%ebp)
   11e14:	c6 45 df 36          	movb   $0x36,-0x21(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   11e18:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   11e1c:	8b 55 e0             	mov    -0x20(%ebp),%edx
   11e1f:	ee                   	out    %al,(%dx)
}
   11e20:	90                   	nop
	outb( PIT_CONTROL_PORT, PIT_0_SELECT |
	                        PIT_LOAD |
	                        PIT_SQUARE |
	                        PIT_DECIMAL );

	outb( PIT_0_PORT, divisor & 0xff );        // LSB of divisor
   11e21:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11e24:	0f b6 c0             	movzbl %al,%eax
   11e27:	c7 45 e8 40 00 00 00 	movl   $0x40,-0x18(%ebp)
   11e2e:	88 45 e7             	mov    %al,-0x19(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   11e31:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
   11e35:	8b 55 e8             	mov    -0x18(%ebp),%edx
   11e38:	ee                   	out    %al,(%dx)
}
   11e39:	90                   	nop
	outb( PIT_0_PORT, (divisor >> 8) & 0xff ); // MSB of divisor
   11e3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11e3d:	c1 e8 08             	shr    $0x8,%eax
   11e40:	0f b6 c0             	movzbl %al,%eax
   11e43:	c7 45 f0 40 00 00 00 	movl   $0x40,-0x10(%ebp)
   11e4a:	88 45 ef             	mov    %al,-0x11(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   11e4d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   11e51:	8b 55 f0             	mov    -0x10(%ebp),%edx
   11e54:	ee                   	out    %al,(%dx)
}
   11e55:	90                   	nop

	// register the second-stage ISR
	install_isr( VEC_TIMER, clk_isr );
   11e56:	83 ec 08             	sub    $0x8,%esp
   11e59:	68 d5 1a 01 00       	push   $0x11ad5
   11e5e:	6a 20                	push   $0x20
   11e60:	e8 3d 36 00 00       	call   154a2 <install_isr>
   11e65:	83 c4 10             	add    $0x10,%esp
}
   11e68:	90                   	nop
   11e69:	c9                   	leave  
   11e6a:	c3                   	ret    

00011e6b <kreport>:
**
** Prints configuration information about the OS on the console monitor.
**
** @param dtrace  Decode the TRACE options
*/
static void kreport( bool_t dtrace ) {
   11e6b:	55                   	push   %ebp
   11e6c:	89 e5                	mov    %esp,%ebp
   11e6e:	83 ec 18             	sub    $0x18,%esp
   11e71:	8b 45 08             	mov    0x8(%ebp),%eax
   11e74:	88 45 f4             	mov    %al,-0xc(%ebp)

	cio_puts( "\n-------------------------------\n" );
   11e77:	83 ec 0c             	sub    $0xc,%esp
   11e7a:	68 68 71 01 00       	push   $0x17168
   11e7f:	e8 0b f2 ff ff       	call   1108f <cio_puts>
   11e84:	83 c4 10             	add    $0x10,%esp
	cio_printf( "Config:  N_PROCS = %d", N_PROCS );
   11e87:	83 ec 08             	sub    $0x8,%esp
   11e8a:	6a 19                	push   $0x19
   11e8c:	68 8a 71 01 00       	push   $0x1718a
   11e91:	e8 71 f8 ff ff       	call   11707 <cio_printf>
   11e96:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_PRIOS = %d", N_PRIOS );
   11e99:	83 ec 08             	sub    $0x8,%esp
   11e9c:	6a 03                	push   $0x3
   11e9e:	68 a0 71 01 00       	push   $0x171a0
   11ea3:	e8 5f f8 ff ff       	call   11707 <cio_printf>
   11ea8:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_STATES = %d", N_STATES );
   11eab:	83 ec 08             	sub    $0x8,%esp
   11eae:	6a 08                	push   $0x8
   11eb0:	68 ae 71 01 00       	push   $0x171ae
   11eb5:	e8 4d f8 ff ff       	call   11707 <cio_printf>
   11eba:	83 c4 10             	add    $0x10,%esp
	cio_printf( " CLOCK = %dHz\n", CLOCK_FREQ );
   11ebd:	83 ec 08             	sub    $0x8,%esp
   11ec0:	68 e8 03 00 00       	push   $0x3e8
   11ec5:	68 bd 71 01 00       	push   $0x171bd
   11eca:	e8 38 f8 ff ff       	call   11707 <cio_printf>
   11ecf:	83 c4 10             	add    $0x10,%esp

	// This code is ugly, but it's the simplest way to
	// print out the values of compile-time options
	// without spending a lot of execution time at it.

	cio_puts( "Options: "
   11ed2:	83 ec 0c             	sub    $0xc,%esp
   11ed5:	68 cc 71 01 00       	push   $0x171cc
   11eda:	e8 b0 f1 ff ff       	call   1108f <cio_puts>
   11edf:	83 c4 10             	add    $0x10,%esp
		" Cstats"
#endif
		); // end of cio_puts() call

#ifdef DBLV
	cio_printf( " DBLV = %d", DBLV );
   11ee2:	83 ec 08             	sub    $0x8,%esp
   11ee5:	68 0f 27 00 00       	push   $0x270f
   11eea:	68 e0 71 01 00       	push   $0x171e0
   11eef:	e8 13 f8 ff ff       	call   11707 <cio_printf>
   11ef4:	83 c4 10             	add    $0x10,%esp
#endif

#if TRACE > 0
	cio_printf( " TRACE = 0x%04x\n", TRACE );
   11ef7:	83 ec 08             	sub    $0x8,%esp
   11efa:	68 00 01 00 00       	push   $0x100
   11eff:	68 eb 71 01 00       	push   $0x171eb
   11f04:	e8 fe f7 ff ff       	call   11707 <cio_printf>
   11f09:	83 c4 10             	add    $0x10,%esp

	// decode the trace settings if that was requested
	if( TRACING_ANYTHING && dtrace ) {
   11f0c:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   11f10:	74 10                	je     11f22 <kreport+0xb7>

		// this one is simpler - we rely on string literal
		// concatenation in the C compiler to create one
		// long string to print out

		cio_puts( "Tracing:"
   11f12:	83 ec 0c             	sub    $0xc,%esp
   11f15:	68 fc 71 01 00       	push   $0x171fc
   11f1a:	e8 70 f1 ff ff       	call   1108f <cio_puts>
   11f1f:	83 c4 10             	add    $0x10,%esp
#endif
			 ); // end of cio_puts() call
	}
#endif  /* TRACE > 0 */

	cio_putchar( '\n' );
   11f22:	83 ec 0c             	sub    $0xc,%esp
   11f25:	6a 0a                	push   $0xa
   11f27:	e8 e0 ef ff ff       	call   10f0c <cio_putchar>
   11f2c:	83 c4 10             	add    $0x10,%esp
}
   11f2f:	90                   	nop
   11f30:	c9                   	leave  
   11f31:	c3                   	ret    

00011f32 <main>:
** Called by the startup code immediately before returning into the
** first user process.
**
** Typing this as 'int' keeps the compiler happy.
*/
int main( void ) {
   11f32:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   11f36:	83 e4 f0             	and    $0xfffffff0,%esp
   11f39:	ff 71 fc             	push   -0x4(%ecx)
   11f3c:	55                   	push   %ebp
   11f3d:	89 e5                	mov    %esp,%ebp
   11f3f:	53                   	push   %ebx
   11f40:	51                   	push   %ecx
   11f41:	83 ec 10             	sub    $0x10,%esp
	** making it difficult to get it any other way. We do this by
	** directly accessing the "user blob" information at the end
	** of the second bootstrap sector. This works ONLY because
	** nothing has touched that section of memory yet.
	*/
	uint16_t *blobdata = (uint16_t *) USER_BLOB_DATA;
   11f44:	c7 45 f4 f4 7f 00 00 	movl   $0x7ff4,-0xc(%ebp)
	user_offset  = *blobdata++;
   11f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11f4e:	8d 50 02             	lea    0x2(%eax),%edx
   11f51:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11f54:	0f b7 00             	movzwl (%eax),%eax
   11f57:	66 a3 24 a6 01 00    	mov    %ax,0x1a624
	user_segment = *blobdata++;
   11f5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11f60:	8d 50 02             	lea    0x2(%eax),%edx
   11f63:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11f66:	0f b7 00             	movzwl (%eax),%eax
   11f69:	66 a3 26 a6 01 00    	mov    %ax,0x1a626
	user_sectors = *blobdata++;
   11f6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11f72:	8d 50 02             	lea    0x2(%eax),%edx
   11f75:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11f78:	0f b7 00             	movzwl (%eax),%eax
   11f7b:	66 a3 28 a6 01 00    	mov    %ax,0x1a628

	/*
	** Initialize interrupt stuff.
	*/

	init_interrupts();  // IDT and PIC initialization
   11f81:	e8 09 35 00 00       	call   1548f <init_interrupts>
	** Does not depend on the other kernel modules, so we can
	** initialize it before we initialize the kernel memory
	** and queue modules.
	*/

	cio_init( NULL );	// no console callback routine
   11f86:	83 ec 0c             	sub    $0xc,%esp
   11f89:	6a 00                	push   $0x0
   11f8b:	e8 42 fa ff ff       	call   119d2 <cio_init>
   11f90:	83 c4 10             	add    $0x10,%esp

	// cio_clearscreen();  // moved into cio_init()

	// report on the segment boundaries
	cio_printf( "Text: %08x to %08x\n",
   11f93:	ba 88 6b 01 00       	mov    $0x16b88,%edx
   11f98:	b8 00 00 01 00       	mov    $0x10000,%eax
   11f9d:	83 ec 04             	sub    $0x4,%esp
   11fa0:	52                   	push   %edx
   11fa1:	50                   	push   %eax
   11fa2:	68 0a 72 01 00       	push   $0x1720a
   11fa7:	e8 5b f7 ff ff       	call   11707 <cio_printf>
   11fac:	83 c4 10             	add    $0x10,%esp
			(uint32_t) _start, (uint32_t) _etext );
	cio_printf( "Rdat: %08x to %08x\n",
   11faf:	ba c8 84 01 00       	mov    $0x184c8,%edx
   11fb4:	b8 00 70 01 00       	mov    $0x17000,%eax
   11fb9:	83 ec 04             	sub    $0x4,%esp
   11fbc:	52                   	push   %edx
   11fbd:	50                   	push   %eax
   11fbe:	68 1e 72 01 00       	push   $0x1721e
   11fc3:	e8 3f f7 ff ff       	call   11707 <cio_printf>
   11fc8:	83 c4 10             	add    $0x10,%esp
			(uint32_t) _rodata, (uint32_t) _erodata );
	cio_printf( "Data: %08x to %08x\n",
   11fcb:	ba 0c 95 01 00       	mov    $0x1950c,%edx
   11fd0:	b8 00 90 01 00       	mov    $0x19000,%eax
   11fd5:	83 ec 04             	sub    $0x4,%esp
   11fd8:	52                   	push   %edx
   11fd9:	50                   	push   %eax
   11fda:	68 32 72 01 00       	push   $0x17232
   11fdf:	e8 23 f7 ff ff       	call   11707 <cio_printf>
   11fe4:	83 c4 10             	add    $0x10,%esp
			(uint32_t) _data, (uint32_t) _edata );
	cio_printf( "BSS:  %08x to %08x\n",
   11fe7:	ba c0 b6 01 00       	mov    $0x1b6c0,%edx
   11fec:	b8 00 a0 01 00       	mov    $0x1a000,%eax
   11ff1:	83 ec 04             	sub    $0x4,%esp
   11ff4:	52                   	push   %edx
   11ff5:	50                   	push   %eax
   11ff6:	68 46 72 01 00       	push   $0x17246
   11ffb:	e8 07 f7 ff ff       	call   11707 <cio_printf>
   12000:	83 c4 10             	add    $0x10,%esp
			(uint32_t) __bss_start, (uint32_t) _end );

	// the actual memory address of the user blob
	user_locs = (uint32_t *)
		((uint32_t)(user_segment << 4) + (uint32_t) user_offset);
   12003:	0f b7 05 26 a6 01 00 	movzwl 0x1a626,%eax
   1200a:	0f b7 c0             	movzwl %ax,%eax
   1200d:	c1 e0 04             	shl    $0x4,%eax
   12010:	89 c2                	mov    %eax,%edx
   12012:	0f b7 05 24 a6 01 00 	movzwl 0x1a624,%eax
   12019:	0f b7 c0             	movzwl %ax,%eax
   1201c:	01 d0                	add    %edx,%eax
	user_locs = (uint32_t *)
   1201e:	a3 20 a6 01 00       	mov    %eax,0x1a620

	// report info on the user blob
	cio_printf( "User blob %u sectors @ %04x:%04x (%08x)\n",
   12023:	a1 20 a6 01 00       	mov    0x1a620,%eax
   12028:	89 c3                	mov    %eax,%ebx
   1202a:	0f b7 05 24 a6 01 00 	movzwl 0x1a624,%eax
   12031:	0f b7 c8             	movzwl %ax,%ecx
   12034:	0f b7 05 26 a6 01 00 	movzwl 0x1a626,%eax
   1203b:	0f b7 d0             	movzwl %ax,%edx
   1203e:	0f b7 05 28 a6 01 00 	movzwl 0x1a628,%eax
   12045:	0f b7 c0             	movzwl %ax,%eax
   12048:	83 ec 0c             	sub    $0xc,%esp
   1204b:	53                   	push   %ebx
   1204c:	51                   	push   %ecx
   1204d:	52                   	push   %edx
   1204e:	50                   	push   %eax
   1204f:	68 5c 72 01 00       	push   $0x1725c
   12054:	e8 ae f6 ff ff       	call   11707 <cio_printf>
   12059:	83 c4 20             	add    $0x20,%esp
	**
	** Other modules (clock, SIO, syscall, etc.) are expected to
	** install their own ISRs in their initialization routines.
	*/

	cio_puts( "System initialization starting.\n" );
   1205c:	83 ec 0c             	sub    $0xc,%esp
   1205f:	68 88 72 01 00       	push   $0x17288
   12064:	e8 26 f0 ff ff       	call   1108f <cio_puts>
   12069:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   1206c:	83 ec 0c             	sub    $0xc,%esp
   1206f:	68 ac 72 01 00       	push   $0x172ac
   12074:	e8 16 f0 ff ff       	call   1108f <cio_puts>
   12079:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
	cio_puts( "Modules:" );
   1207c:	83 ec 0c             	sub    $0xc,%esp
   1207f:	68 cd 72 01 00       	push   $0x172cd
   12084:	e8 06 f0 ff ff       	call   1108f <cio_puts>
   12089:	83 c4 10             	add    $0x10,%esp
#endif

	// call the module initialization functions, being
	// careful to follow any module precedence requirements

	km_init();		// MUST BE FIRST
   1208c:	e8 5e 03 00 00       	call   123ef <km_init>
	que_init();     // MUST BE SECOND
   12091:	e8 89 1a 00 00       	call   13b1f <que_init>

	sio_init();     // serial i/o module
   12096:	e8 3b 24 00 00       	call   144d6 <sio_init>
#ifdef SLOW_INIT
	delay( DELAY_2_SEC );
#endif

	// other module initialization calls here
	pcb_init();     // process (PCBs, scheduler)
   1209b:	e8 75 11 00 00       	call   13215 <pcb_init>
	stk_init();     // stacks
   120a0:	e8 54 2b 00 00       	call   14bf9 <stk_init>
	clk_init();     // clock
   120a5:	e8 28 fd ff ff       	call   11dd2 <clk_init>
	sys_init();     // system call
   120aa:	e8 b0 40 00 00       	call   1615f <sys_init>

	// once they're all set up, begin echoing CIO to SIO

	(void) cio_opt_set( CIO_OPT_DUP );
   120af:	83 ec 0c             	sub    $0xc,%esp
   120b2:	6a 00                	push   $0x0
   120b4:	e8 c4 f9 ff ff       	call   11a7d <cio_opt_set>
   120b9:	83 c4 10             	add    $0x10,%esp

	cio_puts( "\nModule initialization complete.\n" );
   120bc:	83 ec 0c             	sub    $0xc,%esp
   120bf:	68 d8 72 01 00       	push   $0x172d8
   120c4:	e8 c6 ef ff ff       	call   1108f <cio_puts>
   120c9:	83 c4 10             	add    $0x10,%esp

	// report our configuration options
	kreport( true );
   120cc:	83 ec 0c             	sub    $0xc,%esp
   120cf:	6a 01                	push   $0x1
   120d1:	e8 95 fd ff ff       	call   11e6b <kreport>
   120d6:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   120d9:	83 ec 0c             	sub    $0xc,%esp
   120dc:	68 ac 72 01 00       	push   $0x172ac
   120e1:	e8 a9 ef ff ff       	call   1108f <cio_puts>
   120e6:	83 c4 10             	add    $0x10,%esp
	** This code is largely stolen from the fork() and exec()
	** implementations in syscalls.c; if those change, this must
	** also change.
	*/

	cio_puts( "Creating initial user process..." );
   120e9:	83 ec 0c             	sub    $0xc,%esp
   120ec:	68 fc 72 01 00       	push   $0x172fc
   120f1:	e8 99 ef ff ff       	call   1108f <cio_puts>
   120f6:	83 c4 10             	add    $0x10,%esp

	// if we can't get a PCB, there's no use continuing!
	assert( pcb_alloc(&init_pcb) == E_SUCCESS );
   120f9:	83 ec 0c             	sub    $0xc,%esp
   120fc:	68 84 a9 01 00       	push   $0x1a984
   12101:	e8 aa 13 00 00       	call   134b0 <pcb_alloc>
   12106:	83 c4 10             	add    $0x10,%esp
   12109:	85 c0                	test   %eax,%eax
   1210b:	74 39                	je     12146 <main+0x214>
   1210d:	83 ec 08             	sub    $0x8,%esp
   12110:	68 20 73 01 00       	push   $0x17320
   12115:	68 2b 01 00 00       	push   $0x12b
   1211a:	68 42 73 01 00       	push   $0x17342
   1211f:	68 8c 74 01 00       	push   $0x1748c
   12124:	68 54 73 01 00       	push   $0x17354
   12129:	68 20 a4 01 00       	push   $0x1a420
   1212e:	e8 c7 46 00 00       	call   167fa <sprint>
   12133:	83 c4 20             	add    $0x20,%esp
   12136:	83 ec 0c             	sub    $0xc,%esp
   12139:	68 20 a4 01 00       	push   $0x1a420
   1213e:	e8 7e 41 00 00       	call   162c1 <kpanic>
   12143:	83 c4 10             	add    $0x10,%esp

	// fill in the necessary details
	init_pcb->pid = PID_INIT;
   12146:	a1 84 a9 01 00       	mov    0x1a984,%eax
   1214b:	c7 40 14 01 00 00 00 	movl   $0x1,0x14(%eax)
	init_pcb->state = STATE_NEW;
   12152:	a1 84 a9 01 00       	mov    0x1a984,%eax
   12157:	c6 40 18 01          	movb   $0x1,0x18(%eax)
	init_pcb->priority = PRIO_HIGH;
   1215b:	a1 84 a9 01 00       	mov    0x1a984,%eax
   12160:	c6 40 19 00          	movb   $0x0,0x19(%eax)

	// command-line for 'init': "init +"
	const char *args = "init\r+";
   12164:	c7 45 f0 77 73 01 00 	movl   $0x17377,-0x10(%ebp)

	// allocate a stack
	uint32_t *stk;
	assert( stk_alloc(&stk) == E_SUCCESS );
   1216b:	83 ec 0c             	sub    $0xc,%esp
   1216e:	8d 45 ec             	lea    -0x14(%ebp),%eax
   12171:	50                   	push   %eax
   12172:	e8 fe 2a 00 00       	call   14c75 <stk_alloc>
   12177:	83 c4 10             	add    $0x10,%esp
   1217a:	85 c0                	test   %eax,%eax
   1217c:	74 39                	je     121b7 <main+0x285>
   1217e:	83 ec 08             	sub    $0x8,%esp
   12181:	68 7e 73 01 00       	push   $0x1737e
   12186:	68 37 01 00 00       	push   $0x137
   1218b:	68 42 73 01 00       	push   $0x17342
   12190:	68 8c 74 01 00       	push   $0x1748c
   12195:	68 54 73 01 00       	push   $0x17354
   1219a:	68 20 a4 01 00       	push   $0x1a420
   1219f:	e8 56 46 00 00       	call   167fa <sprint>
   121a4:	83 c4 20             	add    $0x20,%esp
   121a7:	83 ec 0c             	sub    $0xc,%esp
   121aa:	68 20 a4 01 00       	push   $0x1a420
   121af:	e8 0d 41 00 00       	call   162c1 <kpanic>
   121b4:	83 c4 10             	add    $0x10,%esp

	init_pcb->stack = stk;
   121b7:	a1 84 a9 01 00       	mov    0x1a984,%eax
   121bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
   121bf:	89 50 04             	mov    %edx,0x4(%eax)

	// initialize the stack and the context to be restored
	//
	// user_locs is a pointer to the entry point location array
	// at the beginning of the code blob
	init_pcb->context = stk_setup( stk, user_locs[ULOC_INIT], args );
   121c2:	a1 20 a6 01 00       	mov    0x1a620,%eax
   121c7:	8b 10                	mov    (%eax),%edx
   121c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   121cc:	8b 1d 84 a9 01 00    	mov    0x1a984,%ebx
   121d2:	83 ec 04             	sub    $0x4,%esp
   121d5:	ff 75 f0             	push   -0x10(%ebp)
   121d8:	52                   	push   %edx
   121d9:	50                   	push   %eax
   121da:	e8 5d 2b 00 00       	call   14d3c <stk_setup>
   121df:	83 c4 10             	add    $0x10,%esp
   121e2:	89 03                	mov    %eax,(%ebx)
	assert( init_pcb->context != NULL );
   121e4:	a1 84 a9 01 00       	mov    0x1a984,%eax
   121e9:	8b 00                	mov    (%eax),%eax
   121eb:	85 c0                	test   %eax,%eax
   121ed:	75 39                	jne    12228 <main+0x2f6>
   121ef:	83 ec 08             	sub    $0x8,%esp
   121f2:	68 9b 73 01 00       	push   $0x1739b
   121f7:	68 40 01 00 00       	push   $0x140
   121fc:	68 42 73 01 00       	push   $0x17342
   12201:	68 8c 74 01 00       	push   $0x1748c
   12206:	68 54 73 01 00       	push   $0x17354
   1220b:	68 20 a4 01 00       	push   $0x1a420
   12210:	e8 e5 45 00 00       	call   167fa <sprint>
   12215:	83 c4 20             	add    $0x20,%esp
   12218:	83 ec 0c             	sub    $0xc,%esp
   1221b:	68 20 a4 01 00       	push   $0x1a420
   12220:	e8 9c 40 00 00       	call   162c1 <kpanic>
   12225:	83 c4 10             	add    $0x10,%esp

	// "i'm my own grandpa...."
	init_pcb->parent = init_pcb;
   12228:	a1 84 a9 01 00       	mov    0x1a984,%eax
   1222d:	8b 15 84 a9 01 00    	mov    0x1a984,%edx
   12233:	89 50 08             	mov    %edx,0x8(%eax)

	// send it on its merry way
	schedule( init_pcb );
   12236:	a1 84 a9 01 00       	mov    0x1a984,%eax
   1223b:	83 ec 0c             	sub    $0xc,%esp
   1223e:	50                   	push   %eax
   1223f:	e8 d8 14 00 00       	call   1371c <schedule>
   12244:	83 c4 10             	add    $0x10,%esp

	// and let it start to execute
	dispatch();
   12247:	e8 cb 15 00 00       	call   13817 <dispatch>

	cio_puts( " done.\n" );
   1224c:	83 ec 0c             	sub    $0xc,%esp
   1224f:	68 b5 73 01 00       	push   $0x173b5
   12254:	e8 36 ee ff ff       	call   1108f <cio_puts>
   12259:	83 c4 10             	add    $0x10,%esp
#endif

#ifdef TRACE_CX

	// wipe out whatever is on the screen at the moment
	cio_clearscreen();
   1225c:	e8 11 ef ff ff       	call   11172 <cio_clearscreen>

	// define a scrolling region in the top 7 lines of the screen
	cio_setscroll( 0, 7, 99, 99 );
   12261:	6a 63                	push   $0x63
   12263:	6a 63                	push   $0x63
   12265:	6a 07                	push   $0x7
   12267:	6a 00                	push   $0x0
   12269:	e8 e1 ea ff ff       	call   10d4f <cio_setscroll>
   1226e:	83 c4 10             	add    $0x10,%esp

	// clear it
	cio_clearscroll();
   12271:	e8 84 ee ff ff       	call   110fa <cio_clearscroll>

	// clear the top line
	cio_puts_at( 0, 0, "*                                                                               " );
   12276:	83 ec 04             	sub    $0x4,%esp
   12279:	68 c0 73 01 00       	push   $0x173c0
   1227e:	6a 00                	push   $0x0
   12280:	6a 00                	push   $0x0
   12282:	e8 c3 ed ff ff       	call   1104a <cio_puts_at>
   12287:	83 c4 10             	add    $0x10,%esp
	// separator
	cio_puts_at( 0, 6, "================================================================================" );
   1228a:	83 ec 04             	sub    $0x4,%esp
   1228d:	68 14 74 01 00       	push   $0x17414
   12292:	6a 06                	push   $0x6
   12294:	6a 00                	push   $0x0
   12296:	e8 af ed ff ff       	call   1104a <cio_puts_at>
   1229b:	83 c4 10             	add    $0x10,%esp

	/*
	** END OF TERM-SPECIFIC CODE
	*/

	sio_flush( SIO_RX | SIO_TX );
   1229e:	83 ec 0c             	sub    $0xc,%esp
   122a1:	6a 03                	push   $0x3
   122a3:	e8 a8 24 00 00       	call   14750 <sio_flush>
   122a8:	83 c4 10             	add    $0x10,%esp
	sio_enable( SIO_RX );
   122ab:	83 ec 0c             	sub    $0xc,%esp
   122ae:	6a 02                	push   $0x2
   122b0:	e8 a9 23 00 00       	call   1465e <sio_enable>
   122b5:	83 c4 10             	add    $0x10,%esp

	cio_puts( "System initialization complete.\n" );
   122b8:	83 ec 0c             	sub    $0xc,%esp
   122bb:	68 68 74 01 00       	push   $0x17468
   122c0:	e8 ca ed ff ff       	call   1108f <cio_puts>
   122c5:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   122c8:	83 ec 0c             	sub    $0xc,%esp
   122cb:	68 ac 72 01 00       	push   $0x172ac
   122d0:	e8 ba ed ff ff       	call   1108f <cio_puts>
   122d5:	83 c4 10             	add    $0x10,%esp

	return 0;
   122d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
   122dd:	8d 65 f8             	lea    -0x8(%ebp),%esp
   122e0:	59                   	pop    %ecx
   122e1:	5b                   	pop    %ebx
   122e2:	5d                   	pop    %ebp
   122e3:	8d 61 fc             	lea    -0x4(%ecx),%esp
   122e6:	c3                   	ret    

000122e7 <add_block>:
** Add a block to the free list
**
** @param[in,out] base   Base address of the block
** @param[in]     length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {
   122e7:	55                   	push   %ebp
   122e8:	89 e5                	mov    %esp,%ebp
   122ea:	83 ec 18             	sub    $0x18,%esp

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
   122ed:	81 7d 0c ff 0f 00 00 	cmpl   $0xfff,0xc(%ebp)
   122f4:	0f 86 f2 00 00 00    	jbe    123ec <add_block+0x105>
#if TRACING_KMEM_LIST
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
   122fa:	8b 45 0c             	mov    0xc(%ebp),%eax
   122fd:	25 ff 0f 00 00       	and    $0xfff,%eax
   12302:	85 c0                	test   %eax,%eax
   12304:	74 07                	je     1230d <add_block+0x26>
		// round it down to 4K
		length &= 0xfffff000;
   12306:	81 65 0c 00 f0 ff ff 	andl   $0xfffff000,0xc(%ebp)
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	blkinfo_t *block = (blkinfo_t *) base;
   1230d:	8b 45 08             	mov    0x8(%ebp),%eax
   12310:	89 45 ec             	mov    %eax,-0x14(%ebp)
	block->pages = B2P(length);
   12313:	8b 45 0c             	mov    0xc(%ebp),%eax
   12316:	c1 e8 0c             	shr    $0xc,%eax
   12319:	89 c2                	mov    %eax,%edx
   1231b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1231e:	89 10                	mov    %edx,(%eax)
	block->next = NULL;
   12320:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12323:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
   1232a:	a1 2c a6 01 00       	mov    0x1a62c,%eax
   1232f:	85 c0                	test   %eax,%eax
   12331:	75 17                	jne    1234a <add_block+0x63>
		free_pages = block;
   12333:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12336:	a3 2c a6 01 00       	mov    %eax,0x1a62c
		n_pages = block->pages;
   1233b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1233e:	8b 00                	mov    (%eax),%eax
   12340:	a3 34 a6 01 00       	mov    %eax,0x1a634
		return;
   12345:	e9 a3 00 00 00       	jmp    123ed <add_block+0x106>
	** Find the correct insertion spot.
	*/

	blkinfo_t *prev, *curr;

	prev = NULL;
   1234a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	curr = free_pages;
   12351:	a1 2c a6 01 00       	mov    0x1a62c,%eax
   12356:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr && curr < block ) {
   12359:	eb 0f                	jmp    1236a <add_block+0x83>
		prev = curr;
   1235b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1235e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   12361:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12364:	8b 40 04             	mov    0x4(%eax),%eax
   12367:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr && curr < block ) {
   1236a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1236e:	74 08                	je     12378 <add_block+0x91>
   12370:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12373:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   12376:	72 e3                	jb     1235b <add_block+0x74>
	}

	// the new block always points to its successor
	block->next = curr;
   12378:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1237b:	8b 55 f0             	mov    -0x10(%ebp),%edx
   1237e:	89 50 04             	mov    %edx,0x4(%eax)
	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
   12381:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12385:	75 49                	jne    123d0 <add_block+0xe9>
		// sanity check - both pointers can't be NULL
		assert( curr );
   12387:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1238b:	75 39                	jne    123c6 <add_block+0xdf>
   1238d:	83 ec 08             	sub    $0x8,%esp
   12390:	68 94 74 01 00       	push   $0x17494
   12395:	68 0c 01 00 00       	push   $0x10c
   1239a:	68 99 74 01 00       	push   $0x17499
   1239f:	68 bc 75 01 00       	push   $0x175bc
   123a4:	68 a8 74 01 00       	push   $0x174a8
   123a9:	68 20 a4 01 00       	push   $0x1a420
   123ae:	e8 47 44 00 00       	call   167fa <sprint>
   123b3:	83 c4 20             	add    $0x20,%esp
   123b6:	83 ec 0c             	sub    $0xc,%esp
   123b9:	68 20 a4 01 00       	push   $0x1a420
   123be:	e8 fe 3e 00 00       	call   162c1 <kpanic>
   123c3:	83 c4 10             	add    $0x10,%esp
		// add at the beginning
		free_pages = block;
   123c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   123c9:	a3 2c a6 01 00       	mov    %eax,0x1a62c
   123ce:	eb 09                	jmp    123d9 <add_block+0xf2>
	} else {
		// inserting in the middle or at the end
		prev->next = block;
   123d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   123d3:	8b 55 ec             	mov    -0x14(%ebp),%edx
   123d6:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// bump the count of available pages
	n_pages += block->pages;
   123d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   123dc:	8b 10                	mov    (%eax),%edx
   123de:	a1 34 a6 01 00       	mov    0x1a634,%eax
   123e3:	01 d0                	add    %edx,%eax
   123e5:	a3 34 a6 01 00       	mov    %eax,0x1a634
   123ea:	eb 01                	jmp    123ed <add_block+0x106>
		return;
   123ec:	90                   	nop
}
   123ed:	c9                   	leave  
   123ee:	c3                   	ret    

000123ef <km_init>:
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
   123ef:	55                   	push   %ebp
   123f0:	89 e5                	mov    %esp,%ebp
   123f2:	53                   	push   %ebx
   123f3:	83 ec 34             	sub    $0x34,%esp
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " KM" );
   123f6:	83 ec 0c             	sub    $0xc,%esp
   123f9:	68 cb 74 01 00       	push   $0x174cb
   123fe:	e8 8c ec ff ff       	call   1108f <cio_puts>
   12403:	83 c4 10             	add    $0x10,%esp
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
   12406:	c7 05 30 a6 01 00 00 	movl   $0x0,0x1a630
   1240d:	00 00 00 
	free_pages = NULL;
   12410:	c7 05 2c a6 01 00 00 	movl   $0x0,0x1a62c
   12417:	00 00 00 
	n_pages = n_slices = 0;
   1241a:	c7 05 38 a6 01 00 00 	movl   $0x0,0x1a638
   12421:	00 00 00 
   12424:	a1 38 a6 01 00       	mov    0x1a638,%eax
   12429:	a3 34 a6 01 00       	mov    %eax,0x1a634
	km_initialized = 0;
   1242e:	c7 05 3c a6 01 00 00 	movl   $0x0,0x1a63c
   12435:	00 00 00 

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);
   12438:	b8 00 2d 00 00       	mov    $0x2d00,%eax
   1243d:	8b 00                	mov    (%eax),%eax
   1243f:	89 45 dc             	mov    %eax,-0x24(%ebp)
#if ANY_KMEM
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
   12442:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   12446:	0f 8e 61 01 00 00    	jle    125ad <km_init+0x1be>
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));
   1244c:	c7 45 f4 04 2d 00 00 	movl   $0x2d04,-0xc(%ebp)

	for( int i = 0; i < entries; ++i, ++region ) {
   12453:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   1245a:	e9 36 01 00 00       	jmp    12595 <km_init+0x1a6>
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
   1245f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12462:	8b 40 14             	mov    0x14(%eax),%eax
   12465:	83 e0 01             	and    $0x1,%eax
   12468:	85 c0                	test   %eax,%eax
   1246a:	0f 84 10 01 00 00    	je     12580 <km_init+0x191>
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
   12470:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12473:	8b 40 14             	mov    0x14(%eax),%eax
   12476:	83 e0 02             	and    $0x2,%eax
   12479:	85 c0                	test   %eax,%eax
   1247b:	0f 85 02 01 00 00    	jne    12583 <km_init+0x194>
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
   12481:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12484:	8b 40 10             	mov    0x10(%eax),%eax
   12487:	83 f8 01             	cmp    $0x1,%eax
   1248a:	0f 85 f6 00 00 00    	jne    12586 <km_init+0x197>
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
   12490:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12493:	8b 50 04             	mov    0x4(%eax),%edx
   12496:	8b 00                	mov    (%eax),%eax
   12498:	89 45 e8             	mov    %eax,-0x18(%ebp)
   1249b:	89 55 ec             	mov    %edx,-0x14(%ebp)
		uint64_t length = region->length.all;
   1249e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   124a1:	8b 50 0c             	mov    0xc(%eax),%edx
   124a4:	8b 40 08             	mov    0x8(%eax),%eax
   124a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
   124aa:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		uint64_t endpt  = base + length;
   124ad:	8b 4d e8             	mov    -0x18(%ebp),%ecx
   124b0:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   124b3:	8b 45 d0             	mov    -0x30(%ebp),%eax
   124b6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   124b9:	01 c8                	add    %ecx,%eax
   124bb:	11 da                	adc    %ebx,%edx
   124bd:	89 45 e0             	mov    %eax,-0x20(%ebp)
   124c0:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {
   124c3:	ba ff ff ff 3f       	mov    $0x3fffffff,%edx
   124c8:	b8 00 00 00 00       	mov    $0x0,%eax
   124cd:	3b 55 e8             	cmp    -0x18(%ebp),%edx
   124d0:	1b 45 ec             	sbb    -0x14(%ebp),%eax
   124d3:	72 12                	jb     124e7 <km_init+0xf8>
   124d5:	ba ff ff ff 3f       	mov    $0x3fffffff,%edx
   124da:	b8 00 00 00 00       	mov    $0x0,%eax
   124df:	3b 55 e0             	cmp    -0x20(%ebp),%edx
   124e2:	1b 45 e4             	sbb    -0x1c(%ebp),%eax
   124e5:	73 24                	jae    1250b <km_init+0x11c>

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
   124e7:	ba 00 00 00 40       	mov    $0x40000000,%edx
   124ec:	b8 00 00 00 00       	mov    $0x0,%eax
   124f1:	3b 55 e8             	cmp    -0x18(%ebp),%edx
   124f4:	1b 45 ec             	sbb    -0x14(%ebp),%eax
   124f7:	0f 82 8c 00 00 00    	jb     12589 <km_init+0x19a>
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
   124fd:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
   12504:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {
   1250b:	ba ff ff 0f 00       	mov    $0xfffff,%edx
   12510:	b8 00 00 00 00       	mov    $0x0,%eax
   12515:	3b 55 e8             	cmp    -0x18(%ebp),%edx
   12518:	1b 45 ec             	sbb    -0x14(%ebp),%eax
   1251b:	73 12                	jae    1252f <km_init+0x140>
   1251d:	ba ff ff 0f 00       	mov    $0xfffff,%edx
   12522:	b8 00 00 00 00       	mov    $0x0,%eax
   12527:	3b 55 e0             	cmp    -0x20(%ebp),%edx
   1252a:	1b 45 e4             	sbb    -0x1c(%ebp),%eax
   1252d:	72 20                	jb     1254f <km_init+0x160>

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
   1252f:	ba ff ff 0f 00       	mov    $0xfffff,%edx
   12534:	b8 00 00 00 00       	mov    $0x0,%eax
   12539:	3b 55 e0             	cmp    -0x20(%ebp),%edx
   1253c:	1b 45 e4             	sbb    -0x1c(%ebp),%eax
   1253f:	73 4b                	jae    1258c <km_init+0x19d>
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
   12541:	c7 45 e8 00 00 10 00 	movl   $0x100000,-0x18(%ebp)
   12548:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		}

		// recalculate the length
		length = endpt - base;
   1254f:	8b 45 e0             	mov    -0x20(%ebp),%eax
   12552:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12555:	2b 45 e8             	sub    -0x18(%ebp),%eax
   12558:	1b 55 ec             	sbb    -0x14(%ebp),%edx
   1255b:	89 45 d0             	mov    %eax,-0x30(%ebp)
   1255e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
   12561:	8b 45 e8             	mov    -0x18(%ebp),%eax
   12564:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t l32 = length & ADDR_LOW_HALF;
   12567:	8b 45 d0             	mov    -0x30(%ebp),%eax
   1256a:	89 45 c8             	mov    %eax,-0x38(%ebp)

		add_block( b32, l32 );
   1256d:	83 ec 08             	sub    $0x8,%esp
   12570:	ff 75 c8             	push   -0x38(%ebp)
   12573:	ff 75 cc             	push   -0x34(%ebp)
   12576:	e8 6c fd ff ff       	call   122e7 <add_block>
   1257b:	83 c4 10             	add    $0x10,%esp
   1257e:	eb 0d                	jmp    1258d <km_init+0x19e>
			continue;
   12580:	90                   	nop
   12581:	eb 0a                	jmp    1258d <km_init+0x19e>
			continue;  // we'll ignore this, too
   12583:	90                   	nop
   12584:	eb 07                	jmp    1258d <km_init+0x19e>
			continue;  // we won't attempt to reclaim ACPI memory (yet)
   12586:	90                   	nop
   12587:	eb 04                	jmp    1258d <km_init+0x19e>
				continue;
   12589:	90                   	nop
   1258a:	eb 01                	jmp    1258d <km_init+0x19e>
				continue;
   1258c:	90                   	nop
	for( int i = 0; i < entries; ++i, ++region ) {
   1258d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12591:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
   12595:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12598:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   1259b:	0f 8c be fe ff ff    	jl     1245f <km_init+0x70>
	}

	// record the initialization
	km_initialized = 1;
   125a1:	c7 05 3c a6 01 00 01 	movl   $0x1,0x1a63c
   125a8:	00 00 00 
   125ab:	eb 01                	jmp    125ae <km_init+0x1bf>
		return;
   125ad:	90                   	nop
#if ANY_KMEM
	delay( DELAY_1_SEC );
#endif
}
   125ae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   125b1:	c9                   	leave  
   125b2:	c3                   	ret    

000125b3 <km_dump>:
/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
   125b3:	55                   	push   %ebp
   125b4:	89 e5                	mov    %esp,%ebp
   125b6:	53                   	push   %ebx
   125b7:	83 ec 14             	sub    $0x14,%esp
	blkinfo_t *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
   125ba:	8b 15 38 a6 01 00    	mov    0x1a638,%edx
   125c0:	a1 34 a6 01 00       	mov    0x1a634,%eax
   125c5:	bb 30 a6 01 00       	mov    $0x1a630,%ebx
   125ca:	b9 2c a6 01 00       	mov    $0x1a62c,%ecx
   125cf:	83 ec 0c             	sub    $0xc,%esp
   125d2:	52                   	push   %edx
   125d3:	50                   	push   %eax
   125d4:	53                   	push   %ebx
   125d5:	51                   	push   %ecx
   125d6:	68 d0 74 01 00       	push   $0x174d0
   125db:	e8 27 f1 ff ff       	call   11707 <cio_printf>
   125e0:	83 c4 20             	add    $0x20,%esp
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
   125e3:	a1 2c a6 01 00       	mov    0x1a62c,%eax
   125e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
   125eb:	eb 39                	jmp    12626 <km_dump+0x73>
		cio_printf(
   125ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
   125f0:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   125f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   125f6:	8b 00                	mov    (%eax),%eax
   125f8:	c1 e0 0c             	shl    $0xc,%eax
   125fb:	89 c1                	mov    %eax,%ecx
   125fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12600:	01 c1                	add    %eax,%ecx
   12602:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12605:	8b 00                	mov    (%eax),%eax
   12607:	83 ec 0c             	sub    $0xc,%esp
   1260a:	52                   	push   %edx
   1260b:	51                   	push   %ecx
   1260c:	50                   	push   %eax
   1260d:	ff 75 f4             	push   -0xc(%ebp)
   12610:	68 0c 75 01 00       	push   $0x1750c
   12615:	e8 ed f0 ff ff       	call   11707 <cio_printf>
   1261a:	83 c4 20             	add    $0x20,%esp
	for( block = free_pages; block != NULL; block = block->next ) {
   1261d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12620:	8b 40 04             	mov    0x4(%eax),%eax
   12623:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12626:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1262a:	75 c1                	jne    125ed <km_dump+0x3a>
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
   1262c:	a1 30 a6 01 00       	mov    0x1a630,%eax
   12631:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12634:	eb 39                	jmp    1266f <km_dump+0xbc>
		cio_printf(
   12636:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12639:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   1263c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1263f:	8b 00                	mov    (%eax),%eax
   12641:	c1 e0 0c             	shl    $0xc,%eax
   12644:	89 c1                	mov    %eax,%ecx
   12646:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12649:	01 c1                	add    %eax,%ecx
   1264b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1264e:	8b 00                	mov    (%eax),%eax
   12650:	83 ec 0c             	sub    $0xc,%esp
   12653:	52                   	push   %edx
   12654:	51                   	push   %ecx
   12655:	50                   	push   %eax
   12656:	ff 75 f4             	push   -0xc(%ebp)
   12659:	68 48 75 01 00       	push   $0x17548
   1265e:	e8 a4 f0 ff ff       	call   11707 <cio_printf>
   12663:	83 c4 20             	add    $0x20,%esp
	for( block = free_slices; block != NULL; block = block->next ) {
   12666:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12669:	8b 40 04             	mov    0x4(%eax),%eax
   1266c:	89 45 f4             	mov    %eax,-0xc(%ebp)
   1266f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12673:	75 c1                	jne    12636 <km_dump+0x83>
				block->next );
	}

}
   12675:	90                   	nop
   12676:	90                   	nop
   12677:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   1267a:	c9                   	leave  
   1267b:	c3                   	ret    

0001267c <km_page_alloc>:
** @param[in] count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {
   1267c:	55                   	push   %ebp
   1267d:	89 e5                	mov    %esp,%ebp
   1267f:	83 ec 28             	sub    $0x28,%esp

	assert( km_initialized != 0 );
   12682:	a1 3c a6 01 00       	mov    0x1a63c,%eax
   12687:	85 c0                	test   %eax,%eax
   12689:	75 39                	jne    126c4 <km_page_alloc+0x48>
   1268b:	83 ec 08             	sub    $0x8,%esp
   1268e:	68 85 75 01 00       	push   $0x17585
   12693:	68 ed 01 00 00       	push   $0x1ed
   12698:	68 99 74 01 00       	push   $0x17499
   1269d:	68 c8 75 01 00       	push   $0x175c8
   126a2:	68 a8 74 01 00       	push   $0x174a8
   126a7:	68 20 a4 01 00       	push   $0x1a420
   126ac:	e8 49 41 00 00       	call   167fa <sprint>
   126b1:	83 c4 20             	add    $0x20,%esp
   126b4:	83 ec 0c             	sub    $0xc,%esp
   126b7:	68 20 a4 01 00       	push   $0x1a420
   126bc:	e8 00 3c 00 00       	call   162c1 <kpanic>
   126c1:	83 c4 10             	add    $0x10,%esp
#if TRACING_KMEM_LIST
	cio_printf( "+++ km_p_alloc(%u)", count );
#endif

	// make sure we actually need to do something!
	if( count < 1 ) {
   126c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   126c8:	75 0a                	jne    126d4 <km_page_alloc+0x58>
#if TRACING_KMEM_LIST
	cio_putchar( '\n' );
#endif
		return( NULL );
   126ca:	b8 00 00 00 00       	mov    $0x0,%eax
   126cf:	e9 a9 00 00 00       	jmp    1277d <km_page_alloc+0x101>
	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	blkinfo_t *block = free_pages;
   126d4:	a1 2c a6 01 00       	mov    0x1a62c,%eax
   126d9:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// pointer to where the pointer to the current block is
	blkinfo_t **pointer = &free_pages;
   126dc:	c7 45 f0 2c a6 01 00 	movl   $0x1a62c,-0x10(%ebp)

	while( block != NULL && block->pages < count ){
   126e3:	eb 11                	jmp    126f6 <km_page_alloc+0x7a>
		pointer = &block->next;
   126e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126e8:	83 c0 04             	add    $0x4,%eax
   126eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
		block = *pointer;
   126ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
   126f1:	8b 00                	mov    (%eax),%eax
   126f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( block != NULL && block->pages < count ){
   126f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   126fa:	74 0a                	je     12706 <km_page_alloc+0x8a>
   126fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126ff:	8b 00                	mov    (%eax),%eax
   12701:	39 45 08             	cmp    %eax,0x8(%ebp)
   12704:	77 df                	ja     126e5 <km_page_alloc+0x69>
	}

	// did we find a big enough block?
	if( block == NULL ){
   12706:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1270a:	75 07                	jne    12713 <km_page_alloc+0x97>
		// nope!
		return( NULL );
   1270c:	b8 00 00 00 00       	mov    $0x0,%eax
   12711:	eb 6a                	jmp    1277d <km_page_alloc+0x101>
	}

	// found one!  check the length

	if( block->pages == count ) {
   12713:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12716:	8b 00                	mov    (%eax),%eax
   12718:	39 45 08             	cmp    %eax,0x8(%ebp)
   1271b:	75 0d                	jne    1272a <km_page_alloc+0xae>

		// exactly the right size - unlink it from the list

		*pointer = block->next;
   1271d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12720:	8b 50 04             	mov    0x4(%eax),%edx
   12723:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12726:	89 10                	mov    %edx,(%eax)
   12728:	eb 43                	jmp    1276d <km_page_alloc+0xf1>

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		blkinfo_t *chunk = block;
   1272a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1272d:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// how much space will be left over?
		int excess = block->pages - count;
   12730:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12733:	8b 00                	mov    (%eax),%eax
   12735:	2b 45 08             	sub    0x8(%ebp),%eax
   12738:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// find the start of the new fragment
		blkinfo_t *fragment = (blkinfo_t *) ( (uint8_t *) block + P2B(count) );
   1273b:	8b 45 08             	mov    0x8(%ebp),%eax
   1273e:	c1 e0 0c             	shl    $0xc,%eax
   12741:	89 c2                	mov    %eax,%edx
   12743:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12746:	01 d0                	add    %edx,%eax
   12748:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// set the length and link for the new fragment
		fragment->pages = excess;
   1274b:	8b 55 e8             	mov    -0x18(%ebp),%edx
   1274e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12751:	89 10                	mov    %edx,(%eax)
		fragment->next  = block->next;
   12753:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12756:	8b 50 04             	mov    0x4(%eax),%edx
   12759:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1275c:	89 50 04             	mov    %edx,0x4(%eax)

		// replace this chunk with the fragment
		*pointer = fragment;
   1275f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12762:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12765:	89 10                	mov    %edx,(%eax)

		// return this chunk
		block = chunk;
   12767:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1276a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// fix the count of available pages
	n_pages -= count;;
   1276d:	a1 34 a6 01 00       	mov    0x1a634,%eax
   12772:	2b 45 08             	sub    0x8(%ebp),%eax
   12775:	a3 34 a6 01 00       	mov    %eax,0x1a634

#if TRACING_KMEM_LIST
	cio_printf( " -> %08x, N = %u\n", (uint32_t) block, n_pages );
#endif

	return( block );
   1277a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1277d:	c9                   	leave  
   1277e:	c3                   	ret    

0001277f <km_page_free>:
** CRITICAL NOTE:  multi-page blocks must either be freed one page
** at a time (if this function is used), OR freed using km_page_free_multi()!
**
** @param[in,out] block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {
   1277f:	55                   	push   %ebp
   12780:	89 e5                	mov    %esp,%ebp
   12782:	83 ec 08             	sub    $0x8,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12785:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12789:	74 12                	je     1279d <km_page_free+0x1e>
		return;
	}

	km_page_free_multi( block, 1 );
   1278b:	83 ec 08             	sub    $0x8,%esp
   1278e:	6a 01                	push   $0x1
   12790:	ff 75 08             	push   0x8(%ebp)
   12793:	e8 08 00 00 00       	call   127a0 <km_page_free_multi>
   12798:	83 c4 10             	add    $0x10,%esp
   1279b:	eb 01                	jmp    1279e <km_page_free+0x1f>
		return;
   1279d:	90                   	nop
}
   1279e:	c9                   	leave  
   1279f:	c3                   	ret    

000127a0 <km_page_free_multi>:
** accepts a pointer to a multi-page block of memory.
**
** @param[in,out] block   Pointer to the block to be returned to the free list
** @param[in]     count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
   127a0:	55                   	push   %ebp
   127a1:	89 e5                	mov    %esp,%ebp
   127a3:	83 ec 18             	sub    $0x18,%esp
	blkinfo_t *used;
	blkinfo_t *prev;
	blkinfo_t *curr;

	assert( km_initialized );
   127a6:	a1 3c a6 01 00       	mov    0x1a63c,%eax
   127ab:	85 c0                	test   %eax,%eax
   127ad:	75 39                	jne    127e8 <km_page_free_multi+0x48>
   127af:	83 ec 08             	sub    $0x8,%esp
   127b2:	68 99 75 01 00       	push   $0x17599
   127b7:	68 61 02 00 00       	push   $0x261
   127bc:	68 99 74 01 00       	push   $0x17499
   127c1:	68 d8 75 01 00       	push   $0x175d8
   127c6:	68 a8 74 01 00       	push   $0x174a8
   127cb:	68 20 a4 01 00       	push   $0x1a420
   127d0:	e8 25 40 00 00       	call   167fa <sprint>
   127d5:	83 c4 20             	add    $0x20,%esp
   127d8:	83 ec 0c             	sub    $0xc,%esp
   127db:	68 20 a4 01 00       	push   $0x1a420
   127e0:	e8 dc 3a 00 00       	call   162c1 <kpanic>
   127e5:	83 c4 10             	add    $0x10,%esp
#endif

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   127e8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   127ec:	0f 84 e3 00 00 00    	je     128d5 <km_page_free_multi+0x135>
		cio_putchar( '\n' );
#endif
		return;
	}

	used = (blkinfo_t *) block;
   127f2:	8b 45 08             	mov    0x8(%ebp),%eax
   127f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	used->pages = count;
   127f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127fb:	8b 55 0c             	mov    0xc(%ebp),%edx
   127fe:	89 10                	mov    %edx,(%eax)

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
   12800:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	curr = free_pages;
   12807:	a1 2c a6 01 00       	mov    0x1a62c,%eax
   1280c:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while( curr != NULL && curr < used ){
   1280f:	eb 0f                	jmp    12820 <km_page_free_multi+0x80>
		prev = curr;
   12811:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12814:	89 45 f0             	mov    %eax,-0x10(%ebp)
		curr = curr->next;
   12817:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1281a:	8b 40 04             	mov    0x4(%eax),%eax
   1281d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while( curr != NULL && curr < used ){
   12820:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12824:	74 08                	je     1282e <km_page_free_multi+0x8e>
   12826:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12829:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1282c:	72 e3                	jb     12811 <km_page_free_multi+0x71>

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){
   1282e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12832:	74 44                	je     12878 <km_page_free_multi+0xd8>

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){
   12834:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12837:	8b 00                	mov    (%eax),%eax
   12839:	c1 e0 0c             	shl    $0xc,%eax
   1283c:	89 c2                	mov    %eax,%edx
   1283e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12841:	01 d0                	add    %edx,%eax
   12843:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   12846:	75 19                	jne    12861 <km_page_free_multi+0xc1>

			// yes - merge them
			prev->pages += used->pages;
   12848:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1284b:	8b 10                	mov    (%eax),%edx
   1284d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12850:	8b 00                	mov    (%eax),%eax
   12852:	01 c2                	add    %eax,%edx
   12854:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12857:	89 10                	mov    %edx,(%eax)

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;
   12859:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1285c:	89 45 f4             	mov    %eax,-0xc(%ebp)
   1285f:	eb 2b                	jmp    1288c <km_page_free_multi+0xec>

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
   12861:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12864:	8b 50 04             	mov    0x4(%eax),%edx
   12867:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1286a:	89 50 04             	mov    %edx,0x4(%eax)
			prev->next = used;
   1286d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12870:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12873:	89 50 04             	mov    %edx,0x4(%eax)
   12876:	eb 14                	jmp    1288c <km_page_free_multi+0xec>
		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
   12878:	8b 15 2c a6 01 00    	mov    0x1a62c,%edx
   1287e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12881:	89 50 04             	mov    %edx,0x4(%eax)
		free_pages = used;
   12884:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12887:	a3 2c a6 01 00       	mov    %eax,0x1a62c

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){
   1288c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12890:	74 31                	je     128c3 <km_page_free_multi+0x123>

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){
   12892:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12895:	8b 00                	mov    (%eax),%eax
   12897:	c1 e0 0c             	shl    $0xc,%eax
   1289a:	89 c2                	mov    %eax,%edx
   1289c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1289f:	01 d0                	add    %edx,%eax
   128a1:	39 45 ec             	cmp    %eax,-0x14(%ebp)
   128a4:	75 1d                	jne    128c3 <km_page_free_multi+0x123>

			// Yes, combine them.
			used->next = curr->next;
   128a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   128a9:	8b 50 04             	mov    0x4(%eax),%edx
   128ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128af:	89 50 04             	mov    %edx,0x4(%eax)
			used->pages += curr->pages;
   128b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128b5:	8b 10                	mov    (%eax),%edx
   128b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   128ba:	8b 00                	mov    (%eax),%eax
   128bc:	01 c2                	add    %eax,%edx
   128be:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128c1:	89 10                	mov    %edx,(%eax)

		}
	}

	// more in the pool
	n_pages += count;
   128c3:	8b 15 34 a6 01 00    	mov    0x1a634,%edx
   128c9:	8b 45 0c             	mov    0xc(%ebp),%eax
   128cc:	01 d0                	add    %edx,%eax
   128ce:	a3 34 a6 01 00       	mov    %eax,0x1a634
   128d3:	eb 01                	jmp    128d6 <km_page_free_multi+0x136>
		return;
   128d5:	90                   	nop

#if TRACING_KMEM_LIST
	cio_printf( " N = %u\n", n_pages );
#endif
}
   128d6:	c9                   	leave  
   128d7:	c3                   	ret    

000128d8 <carve_slices>:
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
   128d8:	55                   	push   %ebp
   128d9:	89 e5                	mov    %esp,%ebp
   128db:	83 ec 18             	sub    $0x18,%esp
#if TRACING_KMEM_LIST
	cio_puts( " carving:" );
#endif

	// get a page
	page = km_page_alloc( 1 );
   128de:	83 ec 0c             	sub    $0xc,%esp
   128e1:	6a 01                	push   $0x1
   128e3:	e8 94 fd ff ff       	call   1267c <km_page_alloc>
   128e8:	83 c4 10             	add    $0x10,%esp
   128eb:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// allocation failure is a show-stopping problem
	assert( page );
   128ee:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   128f2:	75 39                	jne    1292d <carve_slices+0x55>
   128f4:	83 ec 08             	sub    $0x8,%esp
   128f7:	68 a8 75 01 00       	push   $0x175a8
   128fc:	68 e1 02 00 00       	push   $0x2e1
   12901:	68 99 74 01 00       	push   $0x17499
   12906:	68 ec 75 01 00       	push   $0x175ec
   1290b:	68 a8 74 01 00       	push   $0x174a8
   12910:	68 20 a4 01 00       	push   $0x1a420
   12915:	e8 e0 3e 00 00       	call   167fa <sprint>
   1291a:	83 c4 20             	add    $0x20,%esp
   1291d:	83 ec 0c             	sub    $0xc,%esp
   12920:	68 20 a4 01 00       	push   $0x1a420
   12925:	e8 97 39 00 00       	call   162c1 <kpanic>
   1292a:	83 c4 10             	add    $0x10,%esp

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
   1292d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12930:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for( int i = 0; i < 4; ++i ) {
   12933:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   1293a:	eb 26                	jmp    12962 <carve_slices+0x8a>
		km_slice_free( (void *) ptr );
   1293c:	83 ec 0c             	sub    $0xc,%esp
   1293f:	ff 75 f4             	push   -0xc(%ebp)
   12942:	e8 f2 00 00 00       	call   12a39 <km_slice_free>
   12947:	83 c4 10             	add    $0x10,%esp
		ptr += SZ_SLICE;
   1294a:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
		++n_slices;
   12951:	a1 38 a6 01 00       	mov    0x1a638,%eax
   12956:	83 c0 01             	add    $0x1,%eax
   12959:	a3 38 a6 01 00       	mov    %eax,0x1a638
	for( int i = 0; i < 4; ++i ) {
   1295e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12962:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
   12966:	7e d4                	jle    1293c <carve_slices+0x64>
	}
}
   12968:	90                   	nop
   12969:	90                   	nop
   1296a:	c9                   	leave  
   1296b:	c3                   	ret    

0001296c <km_slice_alloc>:
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
   1296c:	55                   	push   %ebp
   1296d:	89 e5                	mov    %esp,%ebp
   1296f:	83 ec 18             	sub    $0x18,%esp
	blkinfo_t *slice;

	assert( km_initialized );
   12972:	a1 3c a6 01 00       	mov    0x1a63c,%eax
   12977:	85 c0                	test   %eax,%eax
   12979:	75 39                	jne    129b4 <km_slice_alloc+0x48>
   1297b:	83 ec 08             	sub    $0x8,%esp
   1297e:	68 99 75 01 00       	push   $0x17599
   12983:	68 f7 02 00 00       	push   $0x2f7
   12988:	68 99 74 01 00       	push   $0x17499
   1298d:	68 fc 75 01 00       	push   $0x175fc
   12992:	68 a8 74 01 00       	push   $0x174a8
   12997:	68 20 a4 01 00       	push   $0x1a420
   1299c:	e8 59 3e 00 00       	call   167fa <sprint>
   129a1:	83 c4 20             	add    $0x20,%esp
   129a4:	83 ec 0c             	sub    $0xc,%esp
   129a7:	68 20 a4 01 00       	push   $0x1a420
   129ac:	e8 10 39 00 00       	call   162c1 <kpanic>
   129b1:	83 c4 10             	add    $0x10,%esp
#if TRACING_KMEM_LIST
	cio_puts( "+++ km_slice_alloc:" );
#endif

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
   129b4:	a1 30 a6 01 00       	mov    0x1a630,%eax
   129b9:	85 c0                	test   %eax,%eax
   129bb:	75 05                	jne    129c2 <km_slice_alloc+0x56>
		carve_slices();
   129bd:	e8 16 ff ff ff       	call   128d8 <carve_slices>
	}

	// take the first one from the free list
	slice = free_slices;
   129c2:	a1 30 a6 01 00       	mov    0x1a630,%eax
   129c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert( slice != NULL );
   129ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   129ce:	75 39                	jne    12a09 <km_slice_alloc+0x9d>
   129d0:	83 ec 08             	sub    $0x8,%esp
   129d3:	68 ad 75 01 00       	push   $0x175ad
   129d8:	68 04 03 00 00       	push   $0x304
   129dd:	68 99 74 01 00       	push   $0x17499
   129e2:	68 fc 75 01 00       	push   $0x175fc
   129e7:	68 a8 74 01 00       	push   $0x174a8
   129ec:	68 20 a4 01 00       	push   $0x1a420
   129f1:	e8 04 3e 00 00       	call   167fa <sprint>
   129f6:	83 c4 20             	add    $0x20,%esp
   129f9:	83 ec 0c             	sub    $0xc,%esp
   129fc:	68 20 a4 01 00       	push   $0x1a420
   12a01:	e8 bb 38 00 00       	call   162c1 <kpanic>
   12a06:	83 c4 10             	add    $0x10,%esp
	--n_slices;
   12a09:	a1 38 a6 01 00       	mov    0x1a638,%eax
   12a0e:	83 e8 01             	sub    $0x1,%eax
   12a11:	a3 38 a6 01 00       	mov    %eax,0x1a638

	// unlink it
	free_slices = slice->next;
   12a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12a19:	8b 40 04             	mov    0x4(%eax),%eax
   12a1c:	a3 30 a6 01 00       	mov    %eax,0x1a630

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );
   12a21:	83 ec 08             	sub    $0x8,%esp
   12a24:	68 00 04 00 00       	push   $0x400
   12a29:	ff 75 f4             	push   -0xc(%ebp)
   12a2c:	e8 fd 3c 00 00       	call   1672e <memclr>
   12a31:	83 c4 10             	add    $0x10,%esp
#if TRACING_KMEM_LIST
	cio_printf( " -> @ %08x, *free %08x, N = %d\n",
			(uint32_t) slice, (uint32_t) free_slices, n_slices );
#endif

	return( slice );
   12a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12a37:	c9                   	leave  
   12a38:	c3                   	ret    

00012a39 <km_slice_free>:
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param[in,out] block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
   12a39:	55                   	push   %ebp
   12a3a:	89 e5                	mov    %esp,%ebp
   12a3c:	83 ec 18             	sub    $0x18,%esp
	blkinfo_t *slice = (blkinfo_t *) block;
   12a3f:	8b 45 08             	mov    0x8(%ebp),%eax
   12a42:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( km_initialized );
   12a45:	a1 3c a6 01 00       	mov    0x1a63c,%eax
   12a4a:	85 c0                	test   %eax,%eax
   12a4c:	75 39                	jne    12a87 <km_slice_free+0x4e>
   12a4e:	83 ec 08             	sub    $0x8,%esp
   12a51:	68 99 75 01 00       	push   $0x17599
   12a56:	68 22 03 00 00       	push   $0x322
   12a5b:	68 99 74 01 00       	push   $0x17499
   12a60:	68 0c 76 01 00       	push   $0x1760c
   12a65:	68 a8 74 01 00       	push   $0x174a8
   12a6a:	68 20 a4 01 00       	push   $0x1a420
   12a6f:	e8 86 3d 00 00       	call   167fa <sprint>
   12a74:	83 c4 20             	add    $0x20,%esp
   12a77:	83 ec 0c             	sub    $0xc,%esp
   12a7a:	68 20 a4 01 00       	push   $0x1a420
   12a7f:	e8 3d 38 00 00       	call   162c1 <kpanic>
   12a84:	83 c4 10             	add    $0x10,%esp
#if TRACING_KMEM_LIST
	cio_printf( "+++ km_slice_free(%08x)", (uint32_t) block );
#endif

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
   12a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12a8a:	c7 00 00 04 00 00    	movl   $0x400,(%eax)
	slice->next = free_slices;
   12a90:	8b 15 30 a6 01 00    	mov    0x1a630,%edx
   12a96:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12a99:	89 50 04             	mov    %edx,0x4(%eax)
	free_slices = slice;
   12a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12a9f:	a3 30 a6 01 00       	mov    %eax,0x1a630
	++n_slices;
   12aa4:	a1 38 a6 01 00       	mov    0x1a638,%eax
   12aa9:	83 c0 01             	add    $0x1,%eax
   12aac:	a3 38 a6 01 00       	mov    %eax,0x1a638
#if TRACING_KMEM_LIST
	cio_printf( " -> N = %d, *free %08x, f->next %08x\n",
			n_slices, (uint32_t) free_slices,
			(uint32_t) (free_slices->next) );
#endif
}
   12ab1:	90                   	nop
   12ab2:	c9                   	leave  
   12ab3:	c3                   	ret    

00012ab4 <list_add>:
** Add the supplied data to the beginning of the specified list.
**
** @param[in,out] list  The address of a list_t variable
** @param[in]     data      The data to prepend to the list
*/
void list_add( list_t *list, void *data ) {
   12ab4:	55                   	push   %ebp
   12ab5:	89 e5                	mov    %esp,%ebp
   12ab7:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( list != NULL );
   12aba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12abe:	75 36                	jne    12af6 <list_add+0x42>
   12ac0:	83 ec 08             	sub    $0x8,%esp
   12ac3:	68 1c 76 01 00       	push   $0x1761c
   12ac8:	6a 23                	push   $0x23
   12aca:	68 29 76 01 00       	push   $0x17629
   12acf:	68 68 76 01 00       	push   $0x17668
   12ad4:	68 38 76 01 00       	push   $0x17638
   12ad9:	68 20 a4 01 00       	push   $0x1a420
   12ade:	e8 17 3d 00 00       	call   167fa <sprint>
   12ae3:	83 c4 20             	add    $0x20,%esp
   12ae6:	83 ec 0c             	sub    $0xc,%esp
   12ae9:	68 20 a4 01 00       	push   $0x1a420
   12aee:	e8 ce 37 00 00       	call   162c1 <kpanic>
   12af3:	83 c4 10             	add    $0x10,%esp
	assert1( data != NULL );
   12af6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12afa:	75 36                	jne    12b32 <list_add+0x7e>
   12afc:	83 ec 08             	sub    $0x8,%esp
   12aff:	68 59 76 01 00       	push   $0x17659
   12b04:	6a 24                	push   $0x24
   12b06:	68 29 76 01 00       	push   $0x17629
   12b0b:	68 68 76 01 00       	push   $0x17668
   12b10:	68 38 76 01 00       	push   $0x17638
   12b15:	68 20 a4 01 00       	push   $0x1a420
   12b1a:	e8 db 3c 00 00       	call   167fa <sprint>
   12b1f:	83 c4 20             	add    $0x20,%esp
   12b22:	83 ec 0c             	sub    $0xc,%esp
   12b25:	68 20 a4 01 00       	push   $0x1a420
   12b2a:	e8 92 37 00 00       	call   162c1 <kpanic>
   12b2f:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *)data;
   12b32:	8b 45 0c             	mov    0xc(%ebp),%eax
   12b35:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tmp->next = list->next;
   12b38:	8b 45 08             	mov    0x8(%ebp),%eax
   12b3b:	8b 10                	mov    (%eax),%edx
   12b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12b40:	89 10                	mov    %edx,(%eax)
	list->next = tmp;
   12b42:	8b 45 08             	mov    0x8(%ebp),%eax
   12b45:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12b48:	89 10                	mov    %edx,(%eax)
}
   12b4a:	90                   	nop
   12b4b:	c9                   	leave  
   12b4c:	c3                   	ret    

00012b4d <list_remove>:
**
** @param[in,out] list  The address of a list_t variable
**
** @return a pointer to the removed data, or NULL if the list was empty
*/
void *list_remove( list_t *list ) {
   12b4d:	55                   	push   %ebp
   12b4e:	89 e5                	mov    %esp,%ebp
   12b50:	83 ec 18             	sub    $0x18,%esp

	assert1( list != NULL );
   12b53:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12b57:	75 36                	jne    12b8f <list_remove+0x42>
   12b59:	83 ec 08             	sub    $0x8,%esp
   12b5c:	68 1c 76 01 00       	push   $0x1761c
   12b61:	6a 36                	push   $0x36
   12b63:	68 29 76 01 00       	push   $0x17629
   12b68:	68 74 76 01 00       	push   $0x17674
   12b6d:	68 38 76 01 00       	push   $0x17638
   12b72:	68 20 a4 01 00       	push   $0x1a420
   12b77:	e8 7e 3c 00 00       	call   167fa <sprint>
   12b7c:	83 c4 20             	add    $0x20,%esp
   12b7f:	83 ec 0c             	sub    $0xc,%esp
   12b82:	68 20 a4 01 00       	push   $0x1a420
   12b87:	e8 35 37 00 00       	call   162c1 <kpanic>
   12b8c:	83 c4 10             	add    $0x10,%esp

	list_t *data = list->next;
   12b8f:	8b 45 08             	mov    0x8(%ebp),%eax
   12b92:	8b 00                	mov    (%eax),%eax
   12b94:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( data != NULL ) {
   12b97:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12b9b:	74 13                	je     12bb0 <list_remove+0x63>
		list->next = data->next;
   12b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ba0:	8b 10                	mov    (%eax),%edx
   12ba2:	8b 45 08             	mov    0x8(%ebp),%eax
   12ba5:	89 10                	mov    %edx,(%eax)
		data->next = NULL;
   12ba7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12baa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

	return (void *)data;
   12bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12bb3:	c9                   	leave  
   12bb4:	c3                   	ret    

00012bb5 <pcb_ix>:
**
** @param[in] p  The PCB to be checked
**
** @return The index (0..N_PROCS-1) if valid, else -1
*/
static int pcb_ix( pcb_t *p ) {
   12bb5:	55                   	push   %ebp
   12bb6:	89 e5                	mov    %esp,%ebp
   12bb8:	83 ec 10             	sub    $0x10,%esp

    int ix = p - &ptable[0];
   12bbb:	8b 45 08             	mov    0x8(%ebp),%eax
   12bbe:	2d 60 a6 01 00       	sub    $0x1a660,%eax
   12bc3:	c1 f8 05             	sar    $0x5,%eax
   12bc6:	89 45 fc             	mov    %eax,-0x4(%ebp)

    if( ix < 0 || ix >= N_PROCS ) {
   12bc9:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   12bcd:	78 06                	js     12bd5 <pcb_ix+0x20>
   12bcf:	83 7d fc 18          	cmpl   $0x18,-0x4(%ebp)
   12bd3:	7e 07                	jle    12bdc <pcb_ix+0x27>
        return -1;
   12bd5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   12bda:	eb 03                	jmp    12bdf <pcb_ix+0x2a>
    }

    return ix;
   12bdc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   12bdf:	c9                   	leave  
   12be0:	c3                   	ret    

00012be1 <comp_wakeup>:
** @return integer indicating the relationship between the wakeup times:
**   < 0 --> 'p1' < 'p2'
**   = 0 --> 'p1' = 'p2'
**   > 0 --> 'p1' > 'p2'
*/
static int comp_wakeup( const void *p1, const void *p2 ) {
   12be1:	55                   	push   %ebp
   12be2:	89 e5                	mov    %esp,%ebp
   12be4:	83 ec 10             	sub    $0x10,%esp
	time_t w1 = ((pcb_t *)p1)->wakeup;
   12be7:	8b 45 08             	mov    0x8(%ebp),%eax
   12bea:	8b 40 0c             	mov    0xc(%eax),%eax
   12bed:	89 45 fc             	mov    %eax,-0x4(%ebp)
	time_t w2 = ((pcb_t *)p2)->wakeup;
   12bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
   12bf3:	8b 40 0c             	mov    0xc(%eax),%eax
   12bf6:	89 45 f8             	mov    %eax,-0x8(%ebp)

	if( w1 < w2 )
   12bf9:	8b 45 fc             	mov    -0x4(%ebp),%eax
   12bfc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
   12bff:	73 07                	jae    12c08 <comp_wakeup+0x27>
		return -1;
   12c01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   12c06:	eb 14                	jmp    12c1c <comp_wakeup+0x3b>
	else if( w1 == w2 )
   12c08:	8b 45 fc             	mov    -0x4(%ebp),%eax
   12c0b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
   12c0e:	75 07                	jne    12c17 <comp_wakeup+0x36>
		return 0;
   12c10:	b8 00 00 00 00       	mov    $0x0,%eax
   12c15:	eb 05                	jmp    12c1c <comp_wakeup+0x3b>
	else
		return 1;
   12c17:	b8 01 00 00 00       	mov    $0x1,%eax
}
   12c1c:	c9                   	leave  
   12c1d:	c3                   	ret    

00012c1e <ctx_sanity_check>:
**
** Performs a "sanity check" on the user context
**
** @param ctx[in]   A pointer to the context to be checked
*/
void ctx_sanity_check( register context_t *c ) {
   12c1e:	55                   	push   %ebp
   12c1f:	89 e5                	mov    %esp,%ebp
   12c21:	57                   	push   %edi
   12c22:	56                   	push   %esi
   12c23:	53                   	push   %ebx
   12c24:	83 ec 2c             	sub    $0x2c,%esp
   12c27:	8b 5d 08             	mov    0x8(%ebp),%ebx
	bool_t any = false;
   12c2a:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)

	// check the segment registers
	if( c->cs != GDT_CODE || c->ss != GDT_STACK ||
   12c2e:	8b 43 40             	mov    0x40(%ebx),%eax
   12c31:	83 f8 10             	cmp    $0x10,%eax
   12c34:	75 27                	jne    12c5d <ctx_sanity_check+0x3f>
   12c36:	8b 03                	mov    (%ebx),%eax
   12c38:	83 f8 20             	cmp    $0x20,%eax
   12c3b:	75 20                	jne    12c5d <ctx_sanity_check+0x3f>
		c->gs != GDT_DATA || c->fs != GDT_DATA ||
   12c3d:	8b 43 04             	mov    0x4(%ebx),%eax
	if( c->cs != GDT_CODE || c->ss != GDT_STACK ||
   12c40:	83 f8 18             	cmp    $0x18,%eax
   12c43:	75 18                	jne    12c5d <ctx_sanity_check+0x3f>
		c->gs != GDT_DATA || c->fs != GDT_DATA ||
   12c45:	8b 43 08             	mov    0x8(%ebx),%eax
   12c48:	83 f8 18             	cmp    $0x18,%eax
   12c4b:	75 10                	jne    12c5d <ctx_sanity_check+0x3f>
		c->es != GDT_DATA || c->ds != GDT_DATA ) {
   12c4d:	8b 43 0c             	mov    0xc(%ebx),%eax
		c->gs != GDT_DATA || c->fs != GDT_DATA ||
   12c50:	83 f8 18             	cmp    $0x18,%eax
   12c53:	75 08                	jne    12c5d <ctx_sanity_check+0x3f>
		c->es != GDT_DATA || c->ds != GDT_DATA ) {
   12c55:	8b 43 10             	mov    0x10(%ebx),%eax
   12c58:	83 f8 18             	cmp    $0x18,%eax
   12c5b:	74 30                	je     12c8d <ctx_sanity_check+0x6f>
		any = true;
   12c5d:	c6 45 e7 01          	movb   $0x1,-0x19(%ebp)
		cio_printf( "CTXchk: cs %04x ss %04x ds %04x es %04x fs %04x gs %04x\n",
   12c61:	8b 43 04             	mov    0x4(%ebx),%eax
   12c64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
   12c67:	8b 7b 08             	mov    0x8(%ebx),%edi
   12c6a:	8b 73 0c             	mov    0xc(%ebx),%esi
   12c6d:	8b 4b 10             	mov    0x10(%ebx),%ecx
   12c70:	8b 13                	mov    (%ebx),%edx
   12c72:	8b 43 40             	mov    0x40(%ebx),%eax
   12c75:	83 ec 04             	sub    $0x4,%esp
   12c78:	ff 75 d4             	push   -0x2c(%ebp)
   12c7b:	57                   	push   %edi
   12c7c:	56                   	push   %esi
   12c7d:	51                   	push   %ecx
   12c7e:	52                   	push   %edx
   12c7f:	50                   	push   %eax
   12c80:	68 b0 76 01 00       	push   $0x176b0
   12c85:	e8 7d ea ff ff       	call   11707 <cio_printf>
   12c8a:	83 c4 20             	add    $0x20,%esp

	// ESP and EBP should be in the range 0x100000..0x200000 if non-zero
	// because the stacks are allocated starting in the second MB of memory
	// EIP should be in the range 0x10000..0x40000 because that's where
	// all the code is
	if( (c->esp != 0 && (c->esp < 0x100000 || c->esp > 0x200000)) ||
   12c8d:	8b 43 20             	mov    0x20(%ebx),%eax
   12c90:	85 c0                	test   %eax,%eax
   12c92:	74 14                	je     12ca8 <ctx_sanity_check+0x8a>
   12c94:	8b 43 20             	mov    0x20(%ebx),%eax
   12c97:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
   12c9c:	76 39                	jbe    12cd7 <ctx_sanity_check+0xb9>
   12c9e:	8b 43 20             	mov    0x20(%ebx),%eax
   12ca1:	3d 00 00 20 00       	cmp    $0x200000,%eax
   12ca6:	77 2f                	ja     12cd7 <ctx_sanity_check+0xb9>
		(c->ebp != 0 && (c->ebp < 0x100000 || c->ebp > 0x200000)) ||
   12ca8:	8b 43 1c             	mov    0x1c(%ebx),%eax
	if( (c->esp != 0 && (c->esp < 0x100000 || c->esp > 0x200000)) ||
   12cab:	85 c0                	test   %eax,%eax
   12cad:	74 14                	je     12cc3 <ctx_sanity_check+0xa5>
		(c->ebp != 0 && (c->ebp < 0x100000 || c->ebp > 0x200000)) ||
   12caf:	8b 43 1c             	mov    0x1c(%ebx),%eax
   12cb2:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
   12cb7:	76 1e                	jbe    12cd7 <ctx_sanity_check+0xb9>
   12cb9:	8b 43 1c             	mov    0x1c(%ebx),%eax
   12cbc:	3d 00 00 20 00       	cmp    $0x200000,%eax
   12cc1:	77 14                	ja     12cd7 <ctx_sanity_check+0xb9>
		c->eip < 0x10000 || c->eip > 0x40000 ) {
   12cc3:	8b 43 3c             	mov    0x3c(%ebx),%eax
		(c->ebp != 0 && (c->ebp < 0x100000 || c->ebp > 0x200000)) ||
   12cc6:	3d ff ff 00 00       	cmp    $0xffff,%eax
   12ccb:	76 0a                	jbe    12cd7 <ctx_sanity_check+0xb9>
		c->eip < 0x10000 || c->eip > 0x40000 ) {
   12ccd:	8b 43 3c             	mov    0x3c(%ebx),%eax
   12cd0:	3d 00 00 04 00       	cmp    $0x40000,%eax
   12cd5:	76 1d                	jbe    12cf4 <ctx_sanity_check+0xd6>
		any = true;
   12cd7:	c6 45 e7 01          	movb   $0x1,-0x19(%ebp)
		cio_printf( "        esp %08x ebp %08x eip %08x\n",
   12cdb:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   12cde:	8b 53 1c             	mov    0x1c(%ebx),%edx
   12ce1:	8b 43 20             	mov    0x20(%ebx),%eax
   12ce4:	51                   	push   %ecx
   12ce5:	52                   	push   %edx
   12ce6:	50                   	push   %eax
   12ce7:	68 ec 76 01 00       	push   $0x176ec
   12cec:	e8 16 ea ff ff       	call   11707 <cio_printf>
   12cf1:	83 c4 10             	add    $0x10,%esp
				c->esp, c->ebp, c->eip );
	}

	if( any ) {
   12cf4:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
   12cf8:	74 3e                	je     12d38 <ctx_sanity_check+0x11a>
		if( current != NULL ) {
   12cfa:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   12cff:	85 c0                	test   %eax,%eax
   12d01:	74 25                	je     12d28 <ctx_sanity_check+0x10a>
			pcb_dump( "current process", current, true );
   12d03:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   12d08:	83 ec 04             	sub    $0x4,%esp
   12d0b:	6a 01                	push   $0x1
   12d0d:	50                   	push   %eax
   12d0e:	68 10 77 01 00       	push   $0x17710
   12d13:	e8 92 01 00 00       	call   12eaa <pcb_dump>
   12d18:	83 c4 10             	add    $0x10,%esp
			cio_putchar( '\n' );
   12d1b:	83 ec 0c             	sub    $0xc,%esp
   12d1e:	6a 0a                	push   $0xa
   12d20:	e8 e7 e1 ff ff       	call   10f0c <cio_putchar>
   12d25:	83 c4 10             	add    $0x10,%esp
		}
		// delay, because we're probably in trouble
		delay( DELAY_10_SEC );
   12d28:	83 ec 0c             	sub    $0xc,%esp
   12d2b:	68 90 01 00 00       	push   $0x190
   12d30:	e8 60 35 00 00       	call   16295 <delay>
   12d35:	83 c4 10             	add    $0x10,%esp
	}

}
   12d38:	90                   	nop
   12d39:	8d 65 f4             	lea    -0xc(%ebp),%esp
   12d3c:	5b                   	pop    %ebx
   12d3d:	5e                   	pop    %esi
   12d3e:	5f                   	pop    %edi
   12d3f:	5d                   	pop    %ebp
   12d40:	c3                   	ret    

00012d41 <ctx_dump>:
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump( const char *msg, register context_t *c ) {
   12d41:	55                   	push   %ebp
   12d42:	89 e5                	mov    %esp,%ebp
   12d44:	57                   	push   %edi
   12d45:	56                   	push   %esi
   12d46:	53                   	push   %ebx
   12d47:	83 ec 1c             	sub    $0x1c,%esp
   12d4a:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// first, the message (if there is one)
	if( msg ) {
   12d4d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12d51:	74 0e                	je     12d61 <ctx_dump+0x20>
		cio_puts( msg );
   12d53:	83 ec 0c             	sub    $0xc,%esp
   12d56:	ff 75 08             	push   0x8(%ebp)
   12d59:	e8 31 e3 ff ff       	call   1108f <cio_puts>
   12d5e:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:\n", (uint32_t) c );
   12d61:	89 d8                	mov    %ebx,%eax
   12d63:	83 ec 08             	sub    $0x8,%esp
   12d66:	50                   	push   %eax
   12d67:	68 20 77 01 00       	push   $0x17720
   12d6c:	e8 96 e9 ff ff       	call   11707 <cio_printf>
   12d71:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( c == NULL ) {
   12d74:	85 db                	test   %ebx,%ebx
   12d76:	75 15                	jne    12d8d <ctx_dump+0x4c>
		cio_puts( " NULL???\n" );
   12d78:	83 ec 0c             	sub    $0xc,%esp
   12d7b:	68 2a 77 01 00       	push   $0x1772a
   12d80:	e8 0a e3 ff ff       	call   1108f <cio_puts>
   12d85:	83 c4 10             	add    $0x10,%esp
		return;
   12d88:	e9 9e 00 00 00       	jmp    12e2b <ctx_dump+0xea>
	}

	// now, the contents
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   12d8d:	8b 43 40             	mov    0x40(%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12d90:	0f b6 c0             	movzbl %al,%eax
   12d93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   12d96:	8b 43 10             	mov    0x10(%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12d99:	0f b6 f8             	movzbl %al,%edi
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   12d9c:	8b 43 0c             	mov    0xc(%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12d9f:	0f b6 f0             	movzbl %al,%esi
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   12da2:	8b 43 08             	mov    0x8(%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12da5:	0f b6 c8             	movzbl %al,%ecx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   12da8:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12dab:	0f b6 d0             	movzbl %al,%edx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   12dae:	8b 03                	mov    (%ebx),%eax
	cio_printf( "  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   12db0:	0f b6 c0             	movzbl %al,%eax
   12db3:	83 ec 04             	sub    $0x4,%esp
   12db6:	ff 75 e4             	push   -0x1c(%ebp)
   12db9:	57                   	push   %edi
   12dba:	56                   	push   %esi
   12dbb:	51                   	push   %ecx
   12dbc:	52                   	push   %edx
   12dbd:	50                   	push   %eax
   12dbe:	68 34 77 01 00       	push   $0x17734
   12dc3:	e8 3f e9 ff ff       	call   11707 <cio_printf>
   12dc8:	83 c4 20             	add    $0x20,%esp
	cio_printf( "  edi %08x esi %08x ebp %08x esp %08x\n",
   12dcb:	8b 73 20             	mov    0x20(%ebx),%esi
   12dce:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
   12dd1:	8b 53 18             	mov    0x18(%ebx),%edx
   12dd4:	8b 43 14             	mov    0x14(%ebx),%eax
   12dd7:	83 ec 0c             	sub    $0xc,%esp
   12dda:	56                   	push   %esi
   12ddb:	51                   	push   %ecx
   12ddc:	52                   	push   %edx
   12ddd:	50                   	push   %eax
   12dde:	68 68 77 01 00       	push   $0x17768
   12de3:	e8 1f e9 ff ff       	call   11707 <cio_printf>
   12de8:	83 c4 20             	add    $0x20,%esp
				  c->edi, c->esi, c->ebp, c->esp );
	cio_printf( "  ebx %08x edx %08x ecx %08x eax %08x\n",
   12deb:	8b 73 30             	mov    0x30(%ebx),%esi
   12dee:	8b 4b 2c             	mov    0x2c(%ebx),%ecx
   12df1:	8b 53 28             	mov    0x28(%ebx),%edx
   12df4:	8b 43 24             	mov    0x24(%ebx),%eax
   12df7:	83 ec 0c             	sub    $0xc,%esp
   12dfa:	56                   	push   %esi
   12dfb:	51                   	push   %ecx
   12dfc:	52                   	push   %edx
   12dfd:	50                   	push   %eax
   12dfe:	68 90 77 01 00       	push   $0x17790
   12e03:	e8 ff e8 ff ff       	call   11707 <cio_printf>
   12e08:	83 c4 20             	add    $0x20,%esp
				  c->ebx, c->edx, c->ecx, c->eax );
	cio_printf( "  vec %08x cod %08x eip %08x efl %08x\n",
   12e0b:	8b 73 44             	mov    0x44(%ebx),%esi
   12e0e:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   12e11:	8b 53 38             	mov    0x38(%ebx),%edx
   12e14:	8b 43 34             	mov    0x34(%ebx),%eax
   12e17:	83 ec 0c             	sub    $0xc,%esp
   12e1a:	56                   	push   %esi
   12e1b:	51                   	push   %ecx
   12e1c:	52                   	push   %edx
   12e1d:	50                   	push   %eax
   12e1e:	68 b8 77 01 00       	push   $0x177b8
   12e23:	e8 df e8 ff ff       	call   11707 <cio_printf>
   12e28:	83 c4 20             	add    $0x20,%esp
				  c->vector, c->code, c->eip, c->eflags );
}
   12e2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
   12e2e:	5b                   	pop    %ebx
   12e2f:	5e                   	pop    %esi
   12e30:	5f                   	pop    %edi
   12e31:	5d                   	pop    %ebp
   12e32:	c3                   	ret    

00012e33 <ctx_dump_all>:
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all( const char *msg ) {
   12e33:	55                   	push   %ebp
   12e34:	89 e5                	mov    %esp,%ebp
   12e36:	53                   	push   %ebx
   12e37:	83 ec 14             	sub    $0x14,%esp

	if( msg != NULL ) {
   12e3a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12e3e:	74 0e                	je     12e4e <ctx_dump_all+0x1b>
		cio_puts( msg );
   12e40:	83 ec 0c             	sub    $0xc,%esp
   12e43:	ff 75 08             	push   0x8(%ebp)
   12e46:	e8 44 e2 ff ff       	call   1108f <cio_puts>
   12e4b:	83 c4 10             	add    $0x10,%esp
	}

	int n = 0;
   12e4e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	register pcb_t *pcb = ptable;
   12e55:	bb 60 a6 01 00       	mov    $0x1a660,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   12e5a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   12e61:	eb 3a                	jmp    12e9d <ctx_dump_all+0x6a>
		if( pcb->state != STATE_UNUSED ) {
   12e63:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   12e67:	84 c0                	test   %al,%al
   12e69:	74 2b                	je     12e96 <ctx_dump_all+0x63>
			++n;
   12e6b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			cio_printf( "%2d(%d): ", n, pcb->pid );
   12e6f:	8b 43 14             	mov    0x14(%ebx),%eax
   12e72:	83 ec 04             	sub    $0x4,%esp
   12e75:	50                   	push   %eax
   12e76:	ff 75 f4             	push   -0xc(%ebp)
   12e79:	68 df 77 01 00       	push   $0x177df
   12e7e:	e8 84 e8 ff ff       	call   11707 <cio_printf>
   12e83:	83 c4 10             	add    $0x10,%esp
			ctx_dump( NULL, pcb->context );
   12e86:	8b 03                	mov    (%ebx),%eax
   12e88:	83 ec 08             	sub    $0x8,%esp
   12e8b:	50                   	push   %eax
   12e8c:	6a 00                	push   $0x0
   12e8e:	e8 ae fe ff ff       	call   12d41 <ctx_dump>
   12e93:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   12e96:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12e9a:	83 c3 20             	add    $0x20,%ebx
   12e9d:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   12ea1:	7e c0                	jle    12e63 <ctx_dump_all+0x30>
		}
	}
}
   12ea3:	90                   	nop
   12ea4:	90                   	nop
   12ea5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12ea8:	c9                   	leave  
   12ea9:	c3                   	ret    

00012eaa <pcb_dump>:
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump( const char *msg, register pcb_t *pcb, bool_t all ) {
   12eaa:	55                   	push   %ebp
   12eab:	89 e5                	mov    %esp,%ebp
   12ead:	53                   	push   %ebx
   12eae:	83 ec 24             	sub    $0x24,%esp
   12eb1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
   12eb4:	8b 45 10             	mov    0x10(%ebp),%eax
   12eb7:	88 45 e4             	mov    %al,-0x1c(%ebp)

	// first, the message (if there is one)
	if( msg ) {
   12eba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12ebe:	74 0e                	je     12ece <pcb_dump+0x24>
		cio_puts( msg );
   12ec0:	83 ec 0c             	sub    $0xc,%esp
   12ec3:	ff 75 08             	push   0x8(%ebp)
   12ec6:	e8 c4 e1 ff ff       	call   1108f <cio_puts>
   12ecb:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:", (uint32_t) pcb );
   12ece:	89 d8                	mov    %ebx,%eax
   12ed0:	83 ec 08             	sub    $0x8,%esp
   12ed3:	50                   	push   %eax
   12ed4:	68 e9 77 01 00       	push   $0x177e9
   12ed9:	e8 29 e8 ff ff       	call   11707 <cio_printf>
   12ede:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( pcb == NULL ) {
   12ee1:	85 db                	test   %ebx,%ebx
   12ee3:	75 15                	jne    12efa <pcb_dump+0x50>
		cio_puts( " NULL???\n" );
   12ee5:	83 ec 0c             	sub    $0xc,%esp
   12ee8:	68 2a 77 01 00       	push   $0x1772a
   12eed:	e8 9d e1 ff ff       	call   1108f <cio_puts>
   12ef2:	83 c4 10             	add    $0x10,%esp
		return;
   12ef5:	e9 30 01 00 00       	jmp    1302a <pcb_dump+0x180>
	}

	cio_printf( " %d %s", pcb->pid,
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   12efa:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   12efe:	3c 07                	cmp    $0x7,%al
   12f00:	77 12                	ja     12f14 <pcb_dump+0x6a>
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   12f02:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   12f06:	0f b6 c0             	movzbl %al,%eax
	cio_printf( " %d %s", pcb->pid,
   12f09:	c1 e0 02             	shl    $0x2,%eax
   12f0c:	8d 90 80 76 01 00    	lea    0x17680(%eax),%edx
   12f12:	eb 05                	jmp    12f19 <pcb_dump+0x6f>
   12f14:	ba f2 77 01 00       	mov    $0x177f2,%edx
   12f19:	8b 43 14             	mov    0x14(%ebx),%eax
   12f1c:	83 ec 04             	sub    $0x4,%esp
   12f1f:	52                   	push   %edx
   12f20:	50                   	push   %eax
   12f21:	68 f6 77 01 00       	push   $0x177f6
   12f26:	e8 dc e7 ff ff       	call   11707 <cio_printf>
   12f2b:	83 c4 10             	add    $0x10,%esp

	if( !all ) {
   12f2e:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   12f32:	0f 84 f1 00 00 00    	je     13029 <pcb_dump+0x17f>
		return;
	}

	// now, the rest of the contents
	cio_printf( " prio %s",
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   12f38:	0f b6 43 19          	movzbl 0x19(%ebx),%eax
	cio_printf( " prio %s",
   12f3c:	3c 02                	cmp    $0x2,%al
   12f3e:	77 15                	ja     12f55 <pcb_dump+0xab>
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   12f40:	0f b6 43 19          	movzbl 0x19(%ebx),%eax
   12f44:	0f b6 d0             	movzbl %al,%edx
	cio_printf( " prio %s",
   12f47:	89 d0                	mov    %edx,%eax
   12f49:	c1 e0 02             	shl    $0x2,%eax
   12f4c:	01 d0                	add    %edx,%eax
   12f4e:	05 a0 76 01 00       	add    $0x176a0,%eax
   12f53:	eb 05                	jmp    12f5a <pcb_dump+0xb0>
   12f55:	b8 f2 77 01 00       	mov    $0x177f2,%eax
   12f5a:	83 ec 08             	sub    $0x8,%esp
   12f5d:	50                   	push   %eax
   12f5e:	68 fd 77 01 00       	push   $0x177fd
   12f63:	e8 9f e7 ff ff       	call   11707 <cio_printf>
   12f68:	83 c4 10             	add    $0x10,%esp

	cio_printf( " xit %d wake %08x\n",
   12f6b:	8b 53 0c             	mov    0xc(%ebx),%edx
   12f6e:	8b 43 10             	mov    0x10(%ebx),%eax
   12f71:	83 ec 04             	sub    $0x4,%esp
   12f74:	52                   	push   %edx
   12f75:	50                   	push   %eax
   12f76:	68 06 78 01 00       	push   $0x17806
   12f7b:	e8 87 e7 ff ff       	call   11707 <cio_printf>
   12f80:	83 c4 10             	add    $0x10,%esp
				pcb->status, pcb->wakeup );

	cio_printf( " parent %08x", (uint32_t)pcb->parent );
   12f83:	8b 43 08             	mov    0x8(%ebx),%eax
   12f86:	83 ec 08             	sub    $0x8,%esp
   12f89:	50                   	push   %eax
   12f8a:	68 19 78 01 00       	push   $0x17819
   12f8f:	e8 73 e7 ff ff       	call   11707 <cio_printf>
   12f94:	83 c4 10             	add    $0x10,%esp
	if( pcb->parent != NULL ) {
   12f97:	8b 43 08             	mov    0x8(%ebx),%eax
   12f9a:	85 c0                	test   %eax,%eax
   12f9c:	74 17                	je     12fb5 <pcb_dump+0x10b>
		cio_printf( " (%u)", pcb->parent->pid );
   12f9e:	8b 43 08             	mov    0x8(%ebx),%eax
   12fa1:	8b 40 14             	mov    0x14(%eax),%eax
   12fa4:	83 ec 08             	sub    $0x8,%esp
   12fa7:	50                   	push   %eax
   12fa8:	68 26 78 01 00       	push   $0x17826
   12fad:	e8 55 e7 ff ff       	call   11707 <cio_printf>
   12fb2:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( " context %08x stk %08x",
			(uint32_t) pcb->context, (uint32_t) pcb->stack );
   12fb5:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( " context %08x stk %08x",
   12fb8:	89 c2                	mov    %eax,%edx
			(uint32_t) pcb->context, (uint32_t) pcb->stack );
   12fba:	8b 03                	mov    (%ebx),%eax
	cio_printf( " context %08x stk %08x",
   12fbc:	83 ec 04             	sub    $0x4,%esp
   12fbf:	52                   	push   %edx
   12fc0:	50                   	push   %eax
   12fc1:	68 2c 78 01 00       	push   $0x1782c
   12fc6:	e8 3c e7 ff ff       	call   11707 <cio_printf>
   12fcb:	83 c4 10             	add    $0x10,%esp

	cio_printf( " fill" );
   12fce:	83 ec 0c             	sub    $0xc,%esp
   12fd1:	68 43 78 01 00       	push   $0x17843
   12fd6:	e8 2c e7 ff ff       	call   11707 <cio_printf>
   12fdb:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < sizeof(pcb->filler); ++i ) {
   12fde:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   12fe5:	eb 2b                	jmp    13012 <pcb_dump+0x168>
		cio_putchar( ' ' );
   12fe7:	83 ec 0c             	sub    $0xc,%esp
   12fea:	6a 20                	push   $0x20
   12fec:	e8 1b df ff ff       	call   10f0c <cio_putchar>
   12ff1:	83 c4 10             	add    $0x10,%esp
		put_char_or_code( pcb->filler[i] );
   12ff4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ff7:	01 d8                	add    %ebx,%eax
   12ff9:	83 c0 1b             	add    $0x1b,%eax
   12ffc:	0f b6 00             	movzbl (%eax),%eax
   12fff:	0f b6 c0             	movzbl %al,%eax
   13002:	83 ec 0c             	sub    $0xc,%esp
   13005:	50                   	push   %eax
   13006:	e8 92 31 00 00       	call   1619d <put_char_or_code>
   1300b:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < sizeof(pcb->filler); ++i ) {
   1300e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   13012:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13015:	83 f8 04             	cmp    $0x4,%eax
   13018:	76 cd                	jbe    12fe7 <pcb_dump+0x13d>
	}

	cio_putchar( '\n' );
   1301a:	83 ec 0c             	sub    $0xc,%esp
   1301d:	6a 0a                	push   $0xa
   1301f:	e8 e8 de ff ff       	call   10f0c <cio_putchar>
   13024:	83 c4 10             	add    $0x10,%esp
   13027:	eb 01                	jmp    1302a <pcb_dump+0x180>
		return;
   13029:	90                   	nop
}
   1302a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   1302d:	c9                   	leave  
   1302e:	c3                   	ret    

0001302f <ptable_dump>:
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump( const char *msg, bool_t all ) {
   1302f:	55                   	push   %ebp
   13030:	89 e5                	mov    %esp,%ebp
   13032:	53                   	push   %ebx
   13033:	83 ec 24             	sub    $0x24,%esp
   13036:	8b 45 0c             	mov    0xc(%ebp),%eax
   13039:	88 45 e4             	mov    %al,-0x1c(%ebp)

	if( msg ) {
   1303c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13040:	74 0e                	je     13050 <ptable_dump+0x21>
		cio_puts( msg );
   13042:	83 ec 0c             	sub    $0xc,%esp
   13045:	ff 75 08             	push   0x8(%ebp)
   13048:	e8 42 e0 ff ff       	call   1108f <cio_puts>
   1304d:	83 c4 10             	add    $0x10,%esp
	}
	cio_putchar( ' ' );
   13050:	83 ec 0c             	sub    $0xc,%esp
   13053:	6a 20                	push   $0x20
   13055:	e8 b2 de ff ff       	call   10f0c <cio_putchar>
   1305a:	83 c4 10             	add    $0x10,%esp

	int used = 0;
   1305d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int empty = 0;
   13064:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	register pcb_t *pcb = ptable;
   1306b:	bb 60 a6 01 00       	mov    $0x1a660,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   13070:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   13077:	eb 58                	jmp    130d1 <ptable_dump+0xa2>
		if( pcb->state == STATE_UNUSED ) {
   13079:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   1307d:	84 c0                	test   %al,%al
   1307f:	75 06                	jne    13087 <ptable_dump+0x58>

			// an empty slot
			++empty;
   13081:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13085:	eb 43                	jmp    130ca <ptable_dump+0x9b>

		} else {

			// a non-empty slot
			++used;
   13087:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			// if not dumping everything, add commas if needed
			if( !all && used ) {
   1308b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1308f:	75 13                	jne    130a4 <ptable_dump+0x75>
   13091:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13095:	74 0d                	je     130a4 <ptable_dump+0x75>
				cio_putchar( ',' );
   13097:	83 ec 0c             	sub    $0xc,%esp
   1309a:	6a 2c                	push   $0x2c
   1309c:	e8 6b de ff ff       	call   10f0c <cio_putchar>
   130a1:	83 c4 10             	add    $0x10,%esp
			}

			// report the table slot #
			cio_printf( " #%d:", i );
   130a4:	83 ec 08             	sub    $0x8,%esp
   130a7:	ff 75 ec             	push   -0x14(%ebp)
   130aa:	68 49 78 01 00       	push   $0x17849
   130af:	e8 53 e6 ff ff       	call   11707 <cio_printf>
   130b4:	83 c4 10             	add    $0x10,%esp

			// and dump the contents
			pcb_dump( NULL, pcb, all );
   130b7:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
   130bb:	83 ec 04             	sub    $0x4,%esp
   130be:	50                   	push   %eax
   130bf:	53                   	push   %ebx
   130c0:	6a 00                	push   $0x0
   130c2:	e8 e3 fd ff ff       	call   12eaa <pcb_dump>
   130c7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   130ca:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   130ce:	83 c3 20             	add    $0x20,%ebx
   130d1:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   130d5:	7e a2                	jle    13079 <ptable_dump+0x4a>
		}
	}

	// only need this if we're doing one-line output
	if( !all ) {
   130d7:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   130db:	75 0d                	jne    130ea <ptable_dump+0xbb>
		cio_putchar( '\n' );
   130dd:	83 ec 0c             	sub    $0xc,%esp
   130e0:	6a 0a                	push   $0xa
   130e2:	e8 25 de ff ff       	call   10f0c <cio_putchar>
   130e7:	83 c4 10             	add    $0x10,%esp
	}

	// sanity check - make sure we saw the correct number of table slots
	if( (used + empty) != N_PROCS ) {
   130ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
   130ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
   130f0:	01 d0                	add    %edx,%eax
   130f2:	83 f8 19             	cmp    $0x19,%eax
   130f5:	74 21                	je     13118 <ptable_dump+0xe9>
		cio_printf( "Table size %d, used %d + empty %d = %d???\n",
   130f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   130fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
   130fd:	01 d0                	add    %edx,%eax
   130ff:	83 ec 0c             	sub    $0xc,%esp
   13102:	50                   	push   %eax
   13103:	ff 75 f0             	push   -0x10(%ebp)
   13106:	ff 75 f4             	push   -0xc(%ebp)
   13109:	6a 19                	push   $0x19
   1310b:	68 50 78 01 00       	push   $0x17850
   13110:	e8 f2 e5 ff ff       	call   11707 <cio_printf>
   13115:	83 c4 20             	add    $0x20,%esp
					  N_PROCS, used, empty, used + empty );
	}
}
   13118:	90                   	nop
   13119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   1311c:	c9                   	leave  
   1311d:	c3                   	ret    

0001311e <ptable_dump_stats>:
**
** @param tbl  Table to use, or NULL
**
** @return The number of process table entries in an "unknown" state.
*/
uint32_t ptable_dump_stats( uint32_t *tbl ) {
   1311e:	55                   	push   %ebp
   1311f:	89 e5                	mov    %esp,%ebp
   13121:	83 ec 38             	sub    $0x38,%esp
	uint32_t nstate[N_STATES] = { 0 };
   13124:	b9 00 00 00 00       	mov    $0x0,%ecx
   13129:	b8 20 00 00 00       	mov    $0x20,%eax
   1312e:	83 e0 fc             	and    $0xfffffffc,%eax
   13131:	89 c2                	mov    %eax,%edx
   13133:	b8 00 00 00 00       	mov    $0x0,%eax
   13138:	89 4c 05 cc          	mov    %ecx,-0x34(%ebp,%eax,1)
   1313c:	83 c0 04             	add    $0x4,%eax
   1313f:	39 d0                	cmp    %edx,%eax
   13141:	72 f5                	jb     13138 <ptable_dump_stats+0x1a>
	uint32_t unknown = 0;
   13143:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int n = 0;
   1314a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	pcb_t *ptr = ptable;
   13151:	c7 45 ec 60 a6 01 00 	movl   $0x1a660,-0x14(%ebp)
	while( n < N_PROCS ) {
   13158:	eb 2e                	jmp    13188 <ptable_dump_stats+0x6a>
		if( ptr->state < 0 || ptr->state >= N_STATES ) {
   1315a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1315d:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   13161:	3c 07                	cmp    $0x7,%al
   13163:	76 06                	jbe    1316b <ptable_dump_stats+0x4d>
			++unknown;
   13165:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   13169:	eb 15                	jmp    13180 <ptable_dump_stats+0x62>
		} else {
			++nstate[ptr->state];
   1316b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1316e:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   13172:	0f b6 c0             	movzbl %al,%eax
   13175:	8b 54 85 cc          	mov    -0x34(%ebp,%eax,4),%edx
   13179:	83 c2 01             	add    $0x1,%edx
   1317c:	89 54 85 cc          	mov    %edx,-0x34(%ebp,%eax,4)
		}
		++n;
   13180:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
		++ptr;
   13184:	83 45 ec 20          	addl   $0x20,-0x14(%ebp)
	while( n < N_PROCS ) {
   13188:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   1318c:	7e cc                	jle    1315a <ptable_dump_stats+0x3c>
	}

	// if tbl is not NULL, we just want the data
	if( tbl != NULL ) {
   1318e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13192:	74 19                	je     131ad <ptable_dump_stats+0x8f>
		memcpy( tbl, nstate, sizeof(nstate) );
   13194:	83 ec 04             	sub    $0x4,%esp
   13197:	6a 20                	push   $0x20
   13199:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1319c:	50                   	push   %eax
   1319d:	ff 75 08             	push   0x8(%ebp)
   131a0:	e8 ad 35 00 00       	call   16752 <memcpy>
   131a5:	83 c4 10             	add    $0x10,%esp
		return unknown;
   131a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   131ab:	eb 66                	jmp    13213 <ptable_dump_stats+0xf5>
	}

	// report the data
	cio_printf( "Ptable: %u ???", unknown );
   131ad:	83 ec 08             	sub    $0x8,%esp
   131b0:	ff 75 f4             	push   -0xc(%ebp)
   131b3:	68 7b 78 01 00       	push   $0x1787b
   131b8:	e8 4a e5 ff ff       	call   11707 <cio_printf>
   131bd:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   131c0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   131c7:	eb 34                	jmp    131fd <ptable_dump_stats+0xdf>
		if( nstate[n] ) {
   131c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   131cc:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
   131d0:	85 c0                	test   %eax,%eax
   131d2:	74 25                	je     131f9 <ptable_dump_stats+0xdb>
			cio_printf( " %u %s", nstate[n], state_str[n] );
   131d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   131d7:	c1 e0 02             	shl    $0x2,%eax
   131da:	8d 90 80 76 01 00    	lea    0x17680(%eax),%edx
   131e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   131e3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
   131e7:	83 ec 04             	sub    $0x4,%esp
   131ea:	52                   	push   %edx
   131eb:	50                   	push   %eax
   131ec:	68 8a 78 01 00       	push   $0x1788a
   131f1:	e8 11 e5 ff ff       	call   11707 <cio_printf>
   131f6:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   131f9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   131fd:	83 7d f0 07          	cmpl   $0x7,-0x10(%ebp)
   13201:	7e c6                	jle    131c9 <ptable_dump_stats+0xab>
		}
	}
	cio_putchar( '\n' );
   13203:	83 ec 0c             	sub    $0xc,%esp
   13206:	6a 0a                	push   $0xa
   13208:	e8 ff dc ff ff       	call   10f0c <cio_putchar>
   1320d:	83 c4 10             	add    $0x10,%esp

	return unknown;
   13210:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13213:	c9                   	leave  
   13214:	c3                   	ret    

00013215 <pcb_init>:
**
** Initialize the process module.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
*/
void pcb_init( void ) {
   13215:	55                   	push   %ebp
   13216:	89 e5                	mov    %esp,%ebp
   13218:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " PCB" );
   1321b:	83 ec 0c             	sub    $0xc,%esp
   1321e:	68 91 78 01 00       	push   $0x17891
   13223:	e8 67 de ff ff       	call   1108f <cio_puts>
   13228:	83 c4 10             	add    $0x10,%esp
#endif

	// start with the process table
	memclr( ptable, sizeof(ptable) );
   1322b:	83 ec 08             	sub    $0x8,%esp
   1322e:	68 20 03 00 00       	push   $0x320
   13233:	68 60 a6 01 00       	push   $0x1a660
   13238:	e8 f1 34 00 00       	call   1672e <memclr>
   1323d:	83 c4 10             	add    $0x10,%esp

	// next, set up the queues
	assert( (ready[PRIO_HIGH] = que_alloc(NULL)) != NULL );
   13240:	83 ec 0c             	sub    $0xc,%esp
   13243:	6a 00                	push   $0x0
   13245:	e8 26 09 00 00       	call   13b70 <que_alloc>
   1324a:	83 c4 10             	add    $0x10,%esp
   1324d:	a3 40 a6 01 00       	mov    %eax,0x1a640
   13252:	a1 40 a6 01 00       	mov    0x1a640,%eax
   13257:	85 c0                	test   %eax,%eax
   13259:	75 39                	jne    13294 <pcb_init+0x7f>
   1325b:	83 ec 08             	sub    $0x8,%esp
   1325e:	68 98 78 01 00       	push   $0x17898
   13263:	68 aa 01 00 00       	push   $0x1aa
   13268:	68 c5 78 01 00       	push   $0x178c5
   1326d:	68 04 7b 01 00       	push   $0x17b04
   13272:	68 d4 78 01 00       	push   $0x178d4
   13277:	68 20 a4 01 00       	push   $0x1a420
   1327c:	e8 79 35 00 00       	call   167fa <sprint>
   13281:	83 c4 20             	add    $0x20,%esp
   13284:	83 ec 0c             	sub    $0xc,%esp
   13287:	68 20 a4 01 00       	push   $0x1a420
   1328c:	e8 30 30 00 00       	call   162c1 <kpanic>
   13291:	83 c4 10             	add    $0x10,%esp
	assert( (ready[PRIO_STD]  = que_alloc(NULL)) != NULL );
   13294:	83 ec 0c             	sub    $0xc,%esp
   13297:	6a 00                	push   $0x0
   13299:	e8 d2 08 00 00       	call   13b70 <que_alloc>
   1329e:	83 c4 10             	add    $0x10,%esp
   132a1:	a3 44 a6 01 00       	mov    %eax,0x1a644
   132a6:	a1 44 a6 01 00       	mov    0x1a644,%eax
   132ab:	85 c0                	test   %eax,%eax
   132ad:	75 39                	jne    132e8 <pcb_init+0xd3>
   132af:	83 ec 08             	sub    $0x8,%esp
   132b2:	68 f8 78 01 00       	push   $0x178f8
   132b7:	68 ab 01 00 00       	push   $0x1ab
   132bc:	68 c5 78 01 00       	push   $0x178c5
   132c1:	68 04 7b 01 00       	push   $0x17b04
   132c6:	68 d4 78 01 00       	push   $0x178d4
   132cb:	68 20 a4 01 00       	push   $0x1a420
   132d0:	e8 25 35 00 00       	call   167fa <sprint>
   132d5:	83 c4 20             	add    $0x20,%esp
   132d8:	83 ec 0c             	sub    $0xc,%esp
   132db:	68 20 a4 01 00       	push   $0x1a420
   132e0:	e8 dc 2f 00 00       	call   162c1 <kpanic>
   132e5:	83 c4 10             	add    $0x10,%esp
	assert( (ready[PRIO_LOW]  = que_alloc(NULL)) != NULL );
   132e8:	83 ec 0c             	sub    $0xc,%esp
   132eb:	6a 00                	push   $0x0
   132ed:	e8 7e 08 00 00       	call   13b70 <que_alloc>
   132f2:	83 c4 10             	add    $0x10,%esp
   132f5:	a3 48 a6 01 00       	mov    %eax,0x1a648
   132fa:	a1 48 a6 01 00       	mov    0x1a648,%eax
   132ff:	85 c0                	test   %eax,%eax
   13301:	75 39                	jne    1333c <pcb_init+0x127>
   13303:	83 ec 08             	sub    $0x8,%esp
   13306:	68 24 79 01 00       	push   $0x17924
   1330b:	68 ac 01 00 00       	push   $0x1ac
   13310:	68 c5 78 01 00       	push   $0x178c5
   13315:	68 04 7b 01 00       	push   $0x17b04
   1331a:	68 d4 78 01 00       	push   $0x178d4
   1331f:	68 20 a4 01 00       	push   $0x1a420
   13324:	e8 d1 34 00 00       	call   167fa <sprint>
   13329:	83 c4 20             	add    $0x20,%esp
   1332c:	83 ec 0c             	sub    $0xc,%esp
   1332f:	68 20 a4 01 00       	push   $0x1a420
   13334:	e8 88 2f 00 00       	call   162c1 <kpanic>
   13339:	83 c4 10             	add    $0x10,%esp
	assert( (sleeping = que_alloc( comp_wakeup )) != NULL );
   1333c:	83 ec 0c             	sub    $0xc,%esp
   1333f:	68 e1 2b 01 00       	push   $0x12be1
   13344:	e8 27 08 00 00       	call   13b70 <que_alloc>
   13349:	83 c4 10             	add    $0x10,%esp
   1334c:	a3 4c a6 01 00       	mov    %eax,0x1a64c
   13351:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   13356:	85 c0                	test   %eax,%eax
   13358:	75 39                	jne    13393 <pcb_init+0x17e>
   1335a:	83 ec 08             	sub    $0x8,%esp
   1335d:	68 50 79 01 00       	push   $0x17950
   13362:	68 ad 01 00 00       	push   $0x1ad
   13367:	68 c5 78 01 00       	push   $0x178c5
   1336c:	68 04 7b 01 00       	push   $0x17b04
   13371:	68 d4 78 01 00       	push   $0x178d4
   13376:	68 20 a4 01 00       	push   $0x1a420
   1337b:	e8 7a 34 00 00       	call   167fa <sprint>
   13380:	83 c4 20             	add    $0x20,%esp
   13383:	83 ec 0c             	sub    $0xc,%esp
   13386:	68 20 a4 01 00       	push   $0x1a420
   1338b:	e8 31 2f 00 00       	call   162c1 <kpanic>
   13390:	83 c4 10             	add    $0x10,%esp
	assert( (zombie   = que_alloc(NULL)) != NULL );
   13393:	83 ec 0c             	sub    $0xc,%esp
   13396:	6a 00                	push   $0x0
   13398:	e8 d3 07 00 00       	call   13b70 <que_alloc>
   1339d:	83 c4 10             	add    $0x10,%esp
   133a0:	a3 50 a6 01 00       	mov    %eax,0x1a650
   133a5:	a1 50 a6 01 00       	mov    0x1a650,%eax
   133aa:	85 c0                	test   %eax,%eax
   133ac:	75 39                	jne    133e7 <pcb_init+0x1d2>
   133ae:	83 ec 08             	sub    $0x8,%esp
   133b1:	68 80 79 01 00       	push   $0x17980
   133b6:	68 ae 01 00 00       	push   $0x1ae
   133bb:	68 c5 78 01 00       	push   $0x178c5
   133c0:	68 04 7b 01 00       	push   $0x17b04
   133c5:	68 d4 78 01 00       	push   $0x178d4
   133ca:	68 20 a4 01 00       	push   $0x1a420
   133cf:	e8 26 34 00 00       	call   167fa <sprint>
   133d4:	83 c4 20             	add    $0x20,%esp
   133d7:	83 ec 0c             	sub    $0xc,%esp
   133da:	68 20 a4 01 00       	push   $0x1a420
   133df:	e8 dd 2e 00 00       	call   162c1 <kpanic>
   133e4:	83 c4 10             	add    $0x10,%esp
	assert( (blocked  = que_alloc(NULL)) != NULL );
   133e7:	83 ec 0c             	sub    $0xc,%esp
   133ea:	6a 00                	push   $0x0
   133ec:	e8 7f 07 00 00       	call   13b70 <que_alloc>
   133f1:	83 c4 10             	add    $0x10,%esp
   133f4:	a3 54 a6 01 00       	mov    %eax,0x1a654
   133f9:	a1 54 a6 01 00       	mov    0x1a654,%eax
   133fe:	85 c0                	test   %eax,%eax
   13400:	75 39                	jne    1343b <pcb_init+0x226>
   13402:	83 ec 08             	sub    $0x8,%esp
   13405:	68 a4 79 01 00       	push   $0x179a4
   1340a:	68 af 01 00 00       	push   $0x1af
   1340f:	68 c5 78 01 00       	push   $0x178c5
   13414:	68 04 7b 01 00       	push   $0x17b04
   13419:	68 d4 78 01 00       	push   $0x178d4
   1341e:	68 20 a4 01 00       	push   $0x1a420
   13423:	e8 d2 33 00 00       	call   167fa <sprint>
   13428:	83 c4 20             	add    $0x20,%esp
   1342b:	83 ec 0c             	sub    $0xc,%esp
   1342e:	68 20 a4 01 00       	push   $0x1a420
   13433:	e8 89 2e 00 00       	call   162c1 <kpanic>
   13438:	83 c4 10             	add    $0x10,%esp
	assert( (sioread  = que_alloc(NULL)) != NULL );
   1343b:	83 ec 0c             	sub    $0xc,%esp
   1343e:	6a 00                	push   $0x0
   13440:	e8 2b 07 00 00       	call   13b70 <que_alloc>
   13445:	83 c4 10             	add    $0x10,%esp
   13448:	a3 58 a6 01 00       	mov    %eax,0x1a658
   1344d:	a1 58 a6 01 00       	mov    0x1a658,%eax
   13452:	85 c0                	test   %eax,%eax
   13454:	75 39                	jne    1348f <pcb_init+0x27a>
   13456:	83 ec 08             	sub    $0x8,%esp
   13459:	68 c8 79 01 00       	push   $0x179c8
   1345e:	68 b0 01 00 00       	push   $0x1b0
   13463:	68 c5 78 01 00       	push   $0x178c5
   13468:	68 04 7b 01 00       	push   $0x17b04
   1346d:	68 d4 78 01 00       	push   $0x178d4
   13472:	68 20 a4 01 00       	push   $0x1a420
   13477:	e8 7e 33 00 00       	call   167fa <sprint>
   1347c:	83 c4 20             	add    $0x20,%esp
   1347f:	83 ec 0c             	sub    $0xc,%esp
   13482:	68 20 a4 01 00       	push   $0x1a420
   13487:	e8 35 2e 00 00       	call   162c1 <kpanic>
   1348c:	83 c4 10             	add    $0x10,%esp

	// prep all the other variables
	current = NULL;
   1348f:	c7 05 5c a6 01 00 00 	movl   $0x0,0x1a65c
   13496:	00 00 00 
	init_pcb = NULL;
   13499:	c7 05 84 a9 01 00 00 	movl   $0x0,0x1a984
   134a0:	00 00 00 
	next_pid = FIRST_USER_PID;
   134a3:	c7 05 80 a9 01 00 02 	movl   $0x2,0x1a980
   134aa:	00 00 00 

}
   134ad:	90                   	nop
   134ae:	c9                   	leave  
   134af:	c3                   	ret    

000134b0 <pcb_alloc>:
**
** @param[out] pcb   Pointer to a pcb_t * where the pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc( pcb_t **pcb ) {
   134b0:	55                   	push   %ebp
   134b1:	89 e5                	mov    %esp,%ebp
   134b3:	53                   	push   %ebx
   134b4:	83 ec 04             	sub    $0x4,%esp

	// sanity check!
	assert1( pcb != NULL );
   134b7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   134bb:	75 39                	jne    134f6 <pcb_alloc+0x46>
   134bd:	83 ec 08             	sub    $0x8,%esp
   134c0:	68 ec 79 01 00       	push   $0x179ec
   134c5:	68 c7 01 00 00       	push   $0x1c7
   134ca:	68 c5 78 01 00       	push   $0x178c5
   134cf:	68 10 7b 01 00       	push   $0x17b10
   134d4:	68 f8 79 01 00       	push   $0x179f8
   134d9:	68 20 a4 01 00       	push   $0x1a420
   134de:	e8 17 33 00 00       	call   167fa <sprint>
   134e3:	83 c4 20             	add    $0x20,%esp
   134e6:	83 ec 0c             	sub    $0xc,%esp
   134e9:	68 20 a4 01 00       	push   $0x1a420
   134ee:	e8 ce 2d 00 00       	call   162c1 <kpanic>
   134f3:	83 c4 10             	add    $0x10,%esp

	// locate the first unused PCB in the table
	register pcb_t *p;
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   134f6:	bb 60 a6 01 00       	mov    $0x1a660,%ebx
   134fb:	eb 17                	jmp    13514 <pcb_alloc+0x64>
		// did we find one?
		if( p->state == STATE_UNUSED ) {
   134fd:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   13501:	84 c0                	test   %al,%al
   13503:	75 0c                	jne    13511 <pcb_alloc+0x61>
			// yes!
			*pcb = p;
   13505:	8b 45 08             	mov    0x8(%ebp),%eax
   13508:	89 18                	mov    %ebx,(%eax)
			return E_SUCCESS;
   1350a:	b8 00 00 00 00       	mov    $0x0,%eax
   1350f:	eb 10                	jmp    13521 <pcb_alloc+0x71>
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   13511:	83 c3 20             	add    $0x20,%ebx
   13514:	81 fb 80 a9 01 00    	cmp    $0x1a980,%ebx
   1351a:	72 e1                	jb     134fd <pcb_alloc+0x4d>
		}
	}

	// sorry, nothing's free
	return E_NO_PCBS;
   1351c:	b8 07 00 00 00       	mov    $0x7,%eax
}
   13521:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   13524:	c9                   	leave  
   13525:	c3                   	ret    

00013526 <pcb_free>:
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[out] pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free( pcb_t *pcb ) {
   13526:	55                   	push   %ebp
   13527:	89 e5                	mov    %esp,%ebp
   13529:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( pcb != NULL );
   1352c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13530:	75 39                	jne    1356b <pcb_free+0x45>
   13532:	83 ec 08             	sub    $0x8,%esp
   13535:	68 ec 79 01 00       	push   $0x179ec
   1353a:	68 e4 01 00 00       	push   $0x1e4
   1353f:	68 c5 78 01 00       	push   $0x178c5
   13544:	68 1c 7b 01 00       	push   $0x17b1c
   13549:	68 f8 79 01 00       	push   $0x179f8
   1354e:	68 20 a4 01 00       	push   $0x1a420
   13553:	e8 a2 32 00 00       	call   167fa <sprint>
   13558:	83 c4 20             	add    $0x20,%esp
   1355b:	83 ec 0c             	sub    $0xc,%esp
   1355e:	68 20 a4 01 00       	push   $0x1a420
   13563:	e8 59 2d 00 00       	call   162c1 <kpanic>
   13568:	83 c4 10             	add    $0x10,%esp

	// mark the PCB as available
	pcb->state = STATE_UNUSED;
   1356b:	8b 45 08             	mov    0x8(%ebp),%eax
   1356e:	c6 40 18 00          	movb   $0x0,0x18(%eax)
}
   13572:	90                   	nop
   13573:	c9                   	leave  
   13574:	c3                   	ret    

00013575 <pcb_find_pid>:
**
** @param[in] pid   The PID to be located
**
** @return Pointer to the PCB, or NULL if not found
*/
pcb_t *pcb_find_pid( pid_t pid ) {
   13575:	55                   	push   %ebp
   13576:	89 e5                	mov    %esp,%ebp
   13578:	53                   	push   %ebx
   13579:	83 ec 04             	sub    $0x4,%esp

	// must be a valid PID
	assert1( pid >= FIRST_USER_PID );
   1357c:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   13580:	7f 39                	jg     135bb <pcb_find_pid+0x46>
   13582:	83 ec 08             	sub    $0x8,%esp
   13585:	68 19 7a 01 00       	push   $0x17a19
   1358a:	68 f8 01 00 00       	push   $0x1f8
   1358f:	68 c5 78 01 00       	push   $0x178c5
   13594:	68 28 7b 01 00       	push   $0x17b28
   13599:	68 f8 79 01 00       	push   $0x179f8
   1359e:	68 20 a4 01 00       	push   $0x1a420
   135a3:	e8 52 32 00 00       	call   167fa <sprint>
   135a8:	83 c4 20             	add    $0x20,%esp
   135ab:	83 ec 0c             	sub    $0xc,%esp
   135ae:	68 20 a4 01 00       	push   $0x1a420
   135b3:	e8 09 2d 00 00       	call   162c1 <kpanic>
   135b8:	83 c4 10             	add    $0x10,%esp
	// scan the process table
	register pcb_t *p = ptable;

	// find an entry whose PID matches our parameter
	// AND which isn't an "unused" PCB
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   135bb:	bb 60 a6 01 00       	mov    $0x1a660,%ebx
   135c0:	eb 17                	jmp    135d9 <pcb_find_pid+0x64>
		// see if the pids match and this PCB is in use
		if( p->pid == pid && p->state != STATE_UNUSED ) {
   135c2:	8b 43 14             	mov    0x14(%ebx),%eax
   135c5:	39 45 08             	cmp    %eax,0x8(%ebp)
   135c8:	75 0c                	jne    135d6 <pcb_find_pid+0x61>
   135ca:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   135ce:	84 c0                	test   %al,%al
   135d0:	74 04                	je     135d6 <pcb_find_pid+0x61>
			return p;
   135d2:	89 d8                	mov    %ebx,%eax
   135d4:	eb 10                	jmp    135e6 <pcb_find_pid+0x71>
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   135d6:	83 c3 20             	add    $0x20,%ebx
   135d9:	81 fb 80 a9 01 00    	cmp    $0x1a980,%ebx
   135df:	72 e1                	jb     135c2 <pcb_find_pid+0x4d>
		}
	}

	// didn't find it!
	return NULL;
   135e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
   135e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   135e9:	c9                   	leave  
   135ea:	c3                   	ret    

000135eb <pcb_find_child_of>:
**
** @param[in] parent   Pointer to the parent's PCB
**
** @return Pointer to the child's PCB, or NULL
*/
pcb_t *pcb_find_child_of( register pcb_t *parent ) {
   135eb:	55                   	push   %ebp
   135ec:	89 e5                	mov    %esp,%ebp
   135ee:	56                   	push   %esi
   135ef:	53                   	push   %ebx
   135f0:	8b 75 08             	mov    0x8(%ebp),%esi

	// must be a valid PCB pointer
	assert1( parent >= ptable && parent < &ptable[N_PROCS] );
   135f3:	81 fe 60 a6 01 00    	cmp    $0x1a660,%esi
   135f9:	72 08                	jb     13603 <pcb_find_child_of+0x18>
   135fb:	81 fe 80 a9 01 00    	cmp    $0x1a980,%esi
   13601:	72 39                	jb     1363c <pcb_find_child_of+0x51>
   13603:	83 ec 08             	sub    $0x8,%esp
   13606:	68 30 7a 01 00       	push   $0x17a30
   1360b:	68 18 02 00 00       	push   $0x218
   13610:	68 c5 78 01 00       	push   $0x178c5
   13615:	68 38 7b 01 00       	push   $0x17b38
   1361a:	68 f8 79 01 00       	push   $0x179f8
   1361f:	68 20 a4 01 00       	push   $0x1a420
   13624:	e8 d1 31 00 00       	call   167fa <sprint>
   13629:	83 c4 20             	add    $0x20,%esp
   1362c:	83 ec 0c             	sub    $0xc,%esp
   1362f:	68 20 a4 01 00       	push   $0x1a420
   13634:	e8 88 2c 00 00       	call   162c1 <kpanic>
   13639:	83 c4 10             	add    $0x10,%esp
	// scan the process table
	register pcb_t *p = ptable;

	// find an entry whose parent pointer matches our parameter
	// AND which isn't an "unused" PCB
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   1363c:	bb 60 a6 01 00       	mov    $0x1a660,%ebx
   13641:	eb 1a                	jmp    1365d <pcb_find_child_of+0x72>
		if( p != parent && p->parent == parent && p->state != STATE_UNUSED ) {
   13643:	39 f3                	cmp    %esi,%ebx
   13645:	74 13                	je     1365a <pcb_find_child_of+0x6f>
   13647:	8b 43 08             	mov    0x8(%ebx),%eax
   1364a:	39 c6                	cmp    %eax,%esi
   1364c:	75 0c                	jne    1365a <pcb_find_child_of+0x6f>
   1364e:	0f b6 43 18          	movzbl 0x18(%ebx),%eax
   13652:	84 c0                	test   %al,%al
   13654:	74 04                	je     1365a <pcb_find_child_of+0x6f>
			return p;
   13656:	89 d8                	mov    %ebx,%eax
   13658:	eb 10                	jmp    1366a <pcb_find_child_of+0x7f>
	for( p = ptable; p < &ptable[N_PROCS]; ++p ) {
   1365a:	83 c3 20             	add    $0x20,%ebx
   1365d:	81 fb 80 a9 01 00    	cmp    $0x1a980,%ebx
   13663:	72 de                	jb     13643 <pcb_find_child_of+0x58>
		}
	}

	// didn't find it!
	return NULL;
   13665:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1366a:	8d 65 f8             	lea    -0x8(%ebp),%esp
   1366d:	5b                   	pop    %ebx
   1366e:	5e                   	pop    %esi
   1366f:	5d                   	pop    %ebp
   13670:	c3                   	ret    

00013671 <pcb_zombify>:
** wanted to implement another syscall that could zombify a
** process (e.g., kill() or something similar).
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify( register pcb_t *pcb ) {
   13671:	55                   	push   %ebp
   13672:	89 e5                	mov    %esp,%ebp
   13674:	83 ec 08             	sub    $0x8,%esp
   13677:	8b 45 08             	mov    0x8(%ebp),%eax
#if TRACING_PCB
	cio_printf( "** pcb_zombify(0x%08x)\n", (uint32_t) pcb );
#endif

	// should this be an error?
	if( pcb == NULL ) {
   1367a:	85 c0                	test   %eax,%eax
   1367c:	74 56                	je     136d4 <pcb_zombify+0x63>
		return;
	}

	// mark this process as a zombie
	pcb->state = STATE_ZOMBIE;
   1367e:	c6 40 18 07          	movb   $0x7,0x18(%eax)

	// queue it up
	assert( que_insert(zombie,pcb) == E_SUCCESS );
   13682:	8b 15 50 a6 01 00    	mov    0x1a650,%edx
   13688:	83 ec 08             	sub    $0x8,%esp
   1368b:	50                   	push   %eax
   1368c:	52                   	push   %edx
   1368d:	e8 2d 06 00 00       	call   13cbf <que_insert>
   13692:	83 c4 10             	add    $0x10,%esp
   13695:	85 c0                	test   %eax,%eax
   13697:	74 3c                	je     136d5 <pcb_zombify+0x64>
   13699:	83 ec 08             	sub    $0x8,%esp
   1369c:	68 60 7a 01 00       	push   $0x17a60
   136a1:	68 44 02 00 00       	push   $0x244
   136a6:	68 c5 78 01 00       	push   $0x178c5
   136ab:	68 4c 7b 01 00       	push   $0x17b4c
   136b0:	68 d4 78 01 00       	push   $0x178d4
   136b5:	68 20 a4 01 00       	push   $0x1a420
   136ba:	e8 3b 31 00 00       	call   167fa <sprint>
   136bf:	83 c4 20             	add    $0x20,%esp
   136c2:	83 ec 0c             	sub    $0xc,%esp
   136c5:	68 20 a4 01 00       	push   $0x1a420
   136ca:	e8 f2 2b 00 00       	call   162c1 <kpanic>
   136cf:	83 c4 10             	add    $0x10,%esp
   136d2:	eb 01                	jmp    136d5 <pcb_zombify+0x64>
		return;
   136d4:	90                   	nop
	/*
	** Note: we don't call _dispatch() here - we leave that for
	** the calling routine, as it's possible we don't need to
	** choose a new current process.
	*/
}
   136d5:	c9                   	leave  
   136d6:	c3                   	ret    

000136d7 <pcb_cleanup>:
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup( pcb_t *pcb ) {
   136d7:	55                   	push   %ebp
   136d8:	89 e5                	mov    %esp,%ebp
   136da:	83 ec 08             	sub    $0x8,%esp
#if TRACING_PCB
	cio_printf( "** pcb_cleanup(0x%08x)\n", (uint32_t) pcb );
#endif

	// avoid deallocating a NULL pointer
	if( pcb == NULL ) {
   136dd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   136e1:	74 36                	je     13719 <pcb_cleanup+0x42>
		// should this be an error?
		return;
	}

	// release the stack if we need to
	if( pcb->stack != NULL ) {
   136e3:	8b 45 08             	mov    0x8(%ebp),%eax
   136e6:	8b 40 04             	mov    0x4(%eax),%eax
   136e9:	85 c0                	test   %eax,%eax
   136eb:	74 1c                	je     13709 <pcb_cleanup+0x32>
		stk_free( pcb->stack );
   136ed:	8b 45 08             	mov    0x8(%ebp),%eax
   136f0:	8b 40 04             	mov    0x4(%eax),%eax
   136f3:	83 ec 0c             	sub    $0xc,%esp
   136f6:	50                   	push   %eax
   136f7:	e8 df 15 00 00       	call   14cdb <stk_free>
   136fc:	83 c4 10             	add    $0x10,%esp
		// just to be safe
		pcb->stack = NULL;
   136ff:	8b 45 08             	mov    0x8(%ebp),%eax
   13702:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}

	// release the PCB itself
	pcb_free( pcb );
   13709:	83 ec 0c             	sub    $0xc,%esp
   1370c:	ff 75 08             	push   0x8(%ebp)
   1370f:	e8 12 fe ff ff       	call   13526 <pcb_free>
   13714:	83 c4 10             	add    $0x10,%esp
   13717:	eb 01                	jmp    1371a <pcb_cleanup+0x43>
		return;
   13719:	90                   	nop
}
   1371a:	c9                   	leave  
   1371b:	c3                   	ret    

0001371c <schedule>:
**
** Schedule the supplied process
**
** @param pcb[in,out]   Pointer to the PCB of the process to be scheduled
*/
void schedule( pcb_t *p ) {
   1371c:	55                   	push   %ebp
   1371d:	89 e5                	mov    %esp,%ebp
   1371f:	83 ec 08             	sub    $0x8,%esp
#if TRACING_SCHED
	cio_printf( "schedule(%08x)\n", (uint32_t) p );
#endif

	// sanity check - bad pointer
	assert1( pcb_ix(p) >= 0 );
   13722:	ff 75 08             	push   0x8(%ebp)
   13725:	e8 8b f4 ff ff       	call   12bb5 <pcb_ix>
   1372a:	83 c4 04             	add    $0x4,%esp
   1372d:	85 c0                	test   %eax,%eax
   1372f:	79 39                	jns    1376a <schedule+0x4e>
   13731:	83 ec 08             	sub    $0x8,%esp
   13734:	68 84 7a 01 00       	push   $0x17a84
   13739:	68 7d 02 00 00       	push   $0x27d
   1373e:	68 c5 78 01 00       	push   $0x178c5
   13743:	68 58 7b 01 00       	push   $0x17b58
   13748:	68 f8 79 01 00       	push   $0x179f8
   1374d:	68 20 a4 01 00       	push   $0x1a420
   13752:	e8 a3 30 00 00       	call   167fa <sprint>
   13757:	83 c4 20             	add    $0x20,%esp
   1375a:	83 ec 0c             	sub    $0xc,%esp
   1375d:	68 20 a4 01 00       	push   $0x1a420
   13762:	e8 5a 2b 00 00       	call   162c1 <kpanic>
   13767:	83 c4 10             	add    $0x10,%esp

	// verify the priority value is good
	assert1( p->priority >= PRIO_FIRST && p->priority <= PRIO_LAST );
   1376a:	8b 45 08             	mov    0x8(%ebp),%eax
   1376d:	0f b6 40 19          	movzbl 0x19(%eax),%eax
   13771:	3c 02                	cmp    $0x2,%al
   13773:	76 39                	jbe    137ae <schedule+0x92>
   13775:	83 ec 08             	sub    $0x8,%esp
   13778:	68 94 7a 01 00       	push   $0x17a94
   1377d:	68 80 02 00 00       	push   $0x280
   13782:	68 c5 78 01 00       	push   $0x178c5
   13787:	68 58 7b 01 00       	push   $0x17b58
   1378c:	68 f8 79 01 00       	push   $0x179f8
   13791:	68 20 a4 01 00       	push   $0x1a420
   13796:	e8 5f 30 00 00       	call   167fa <sprint>
   1379b:	83 c4 20             	add    $0x20,%esp
   1379e:	83 ec 0c             	sub    $0xc,%esp
   137a1:	68 20 a4 01 00       	push   $0x1a420
   137a6:	e8 16 2b 00 00       	call   162c1 <kpanic>
   137ab:	83 c4 10             	add    $0x10,%esp

	// add it to the ready queue
	if( que_insert(ready[p->priority],p) != E_SUCCESS ) {
   137ae:	8b 45 08             	mov    0x8(%ebp),%eax
   137b1:	0f b6 40 19          	movzbl 0x19(%eax),%eax
   137b5:	0f b6 c0             	movzbl %al,%eax
   137b8:	8b 04 85 40 a6 01 00 	mov    0x1a640(,%eax,4),%eax
   137bf:	83 ec 08             	sub    $0x8,%esp
   137c2:	ff 75 08             	push   0x8(%ebp)
   137c5:	50                   	push   %eax
   137c6:	e8 f4 04 00 00       	call   13cbf <que_insert>
   137cb:	83 c4 10             	add    $0x10,%esp
   137ce:	85 c0                	test   %eax,%eax
   137d0:	74 3b                	je     1380d <schedule+0xf1>
		PANIC( 0, "schedule, que insert fail" );
   137d2:	83 ec 04             	sub    $0x4,%esp
   137d5:	68 ca 7a 01 00       	push   $0x17aca
   137da:	6a 00                	push   $0x0
   137dc:	68 84 02 00 00       	push   $0x284
   137e1:	68 c5 78 01 00       	push   $0x178c5
   137e6:	68 58 7b 01 00       	push   $0x17b58
   137eb:	68 e4 7a 01 00       	push   $0x17ae4
   137f0:	68 20 a4 01 00       	push   $0x1a420
   137f5:	e8 00 30 00 00       	call   167fa <sprint>
   137fa:	83 c4 20             	add    $0x20,%esp
   137fd:	83 ec 0c             	sub    $0xc,%esp
   13800:	68 20 a4 01 00       	push   $0x1a420
   13805:	e8 b7 2a 00 00       	call   162c1 <kpanic>
   1380a:	83 c4 10             	add    $0x10,%esp
	}

	// mark it as ready
	p->state = STATE_READY;
   1380d:	8b 45 08             	mov    0x8(%ebp),%eax
   13810:	c6 40 18 02          	movb   $0x2,0x18(%eax)
}
   13814:	90                   	nop
   13815:	c9                   	leave  
   13816:	c3                   	ret    

00013817 <dispatch>:
/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch( void ) {
   13817:	55                   	push   %ebp
   13818:	89 e5                	mov    %esp,%ebp
   1381a:	83 ec 18             	sub    $0x18,%esp
	pcb_t *p = NULL;
   1381d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
#if TRACING_DISPATCH
	cio_puts( "dispatch(), checking" );
#endif

	// grab whoever is at the head of the highest queue
	for( int i = PRIO_FIRST; i <= PRIO_LAST; ++i ) {
   13824:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1382b:	eb 22                	jmp    1384f <dispatch+0x38>
#if TRACING_DISPATCH
		cio_printf( " %d", i );
#endif
		if( que_remove(ready[i],(void **)&p) == E_SUCCESS ) {
   1382d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13830:	8b 04 85 40 a6 01 00 	mov    0x1a640(,%eax,4),%eax
   13837:	83 ec 08             	sub    $0x8,%esp
   1383a:	8d 55 f0             	lea    -0x10(%ebp),%edx
   1383d:	52                   	push   %edx
   1383e:	50                   	push   %eax
   1383f:	e8 1d 07 00 00       	call   13f61 <que_remove>
   13844:	83 c4 10             	add    $0x10,%esp
   13847:	85 c0                	test   %eax,%eax
   13849:	74 0c                	je     13857 <dispatch+0x40>
	for( int i = PRIO_FIRST; i <= PRIO_LAST; ++i ) {
   1384b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   1384f:	83 7d f4 02          	cmpl   $0x2,-0xc(%ebp)
   13853:	7e d8                	jle    1382d <dispatch+0x16>
   13855:	eb 01                	jmp    13858 <dispatch+0x41>
#if TRACING_DISPATCH
		cio_puts( " HIT" );
#endif
			break;
   13857:	90                   	nop
		}
	}

	assert( p != NULL );
   13858:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1385b:	85 c0                	test   %eax,%eax
   1385d:	75 39                	jne    13898 <dispatch+0x81>
   1385f:	83 ec 08             	sub    $0x8,%esp
   13862:	68 fa 7a 01 00       	push   $0x17afa
   13867:	68 a4 02 00 00       	push   $0x2a4
   1386c:	68 c5 78 01 00       	push   $0x178c5
   13871:	68 64 7b 01 00       	push   $0x17b64
   13876:	68 d4 78 01 00       	push   $0x178d4
   1387b:	68 20 a4 01 00       	push   $0x1a420
   13880:	e8 75 2f 00 00       	call   167fa <sprint>
   13885:	83 c4 20             	add    $0x20,%esp
   13888:	83 ec 0c             	sub    $0xc,%esp
   1388b:	68 20 a4 01 00       	push   $0x1a420
   13890:	e8 2c 2a 00 00       	call   162c1 <kpanic>
   13895:	83 c4 10             	add    $0x10,%esp
#if TRACING_DISPATCH
	pcb_dump( "dispatching pcb", p, true );
#endif

	// set the process up for success
	current = p;
   13898:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1389b:	a3 5c a6 01 00       	mov    %eax,0x1a65c
	current->state = STATE_RUNNING;
   138a0:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   138a5:	c6 40 18 03          	movb   $0x3,0x18(%eax)
	current->quantum = Q_STD;
   138a9:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   138ae:	c6 40 1a 03          	movb   $0x3,0x1a(%eax)
}
   138b2:	90                   	nop
   138b3:	c9                   	leave  
   138b4:	c3                   	ret    

000138b5 <que_ix>:
**
** @param[in] q  The queue to be checked
**
** @return The index (0..N_QUEUES-1) if valid, else -1
*/
static int que_ix( queue_t q ) {
   138b5:	55                   	push   %ebp
   138b6:	89 e5                	mov    %esp,%ebp
   138b8:	83 ec 10             	sub    $0x10,%esp

	int ix = q - &queues[0];
   138bb:	8b 45 08             	mov    0x8(%ebp),%eax
   138be:	2d c0 a9 01 00       	sub    $0x1a9c0,%eax
   138c3:	c1 f8 04             	sar    $0x4,%eax
   138c6:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( ix < 0 || ix >= N_QUEUES ) {
   138c9:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   138cd:	78 06                	js     138d5 <que_ix+0x20>
   138cf:	83 7d fc 07          	cmpl   $0x7,-0x4(%ebp)
   138d3:	7e 07                	jle    138dc <que_ix+0x27>
		return -1;
   138d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   138da:	eb 03                	jmp    138df <que_ix+0x2a>
	}

	return ix;
   138dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   138df:	c9                   	leave  
   138e0:	c3                   	ret    

000138e1 <qnode_free>:
**
** Deallocates the supplied qnode
**
** @param[in] qn   The qnode to be put on the free list
*/
static void qnode_free( qnode_t *qn ) {
   138e1:	55                   	push   %ebp
   138e2:	89 e5                	mov    %esp,%ebp
   138e4:	83 ec 08             	sub    $0x8,%esp
	// sanity check!
	assert1( qn != NULL );
   138e7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   138eb:	75 36                	jne    13923 <qnode_free+0x42>
   138ed:	83 ec 08             	sub    $0x8,%esp
   138f0:	68 70 7b 01 00       	push   $0x17b70
   138f5:	6a 6f                	push   $0x6f
   138f7:	68 7b 7b 01 00       	push   $0x17b7b
   138fc:	68 14 7d 01 00       	push   $0x17d14
   13901:	68 8c 7b 01 00       	push   $0x17b8c
   13906:	68 20 a4 01 00       	push   $0x1a420
   1390b:	e8 ea 2e 00 00       	call   167fa <sprint>
   13910:	83 c4 20             	add    $0x20,%esp
   13913:	83 ec 0c             	sub    $0xc,%esp
   13916:	68 20 a4 01 00       	push   $0x1a420
   1391b:	e8 a1 29 00 00       	call   162c1 <kpanic>
   13920:	83 c4 10             	add    $0x10,%esp
	
	qn->next = free_qnodes;
   13923:	8b 15 a0 a9 01 00    	mov    0x1a9a0,%edx
   13929:	8b 45 08             	mov    0x8(%ebp),%eax
   1392c:	89 50 04             	mov    %edx,0x4(%eax)
	free_qnodes = qn;
   1392f:	8b 45 08             	mov    0x8(%ebp),%eax
   13932:	a3 a0 a9 01 00       	mov    %eax,0x1a9a0
}
   13937:	90                   	nop
   13938:	c9                   	leave  
   13939:	c3                   	ret    

0001393a <qnode_add_page>:
** qnode_add_page()
**
** Extend the set of available qnodes by allocating a page
** of memory and carving it into qnode structures.
*/
static void qnode_add_page( void ) {
   1393a:	55                   	push   %ebp
   1393b:	89 e5                	mov    %esp,%ebp
   1393d:	83 ec 18             	sub    $0x18,%esp
	qnode_t *block;

	// allocate a page of memory
	block = (qnode_t *) km_page_alloc( 1 );
   13940:	83 ec 0c             	sub    $0xc,%esp
   13943:	6a 01                	push   $0x1
   13945:	e8 32 ed ff ff       	call   1267c <km_page_alloc>
   1394a:	83 c4 10             	add    $0x10,%esp
   1394d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( block != NULL );
   13950:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13954:	75 39                	jne    1398f <qnode_add_page+0x55>
   13956:	83 ec 08             	sub    $0x8,%esp
   13959:	68 ad 7b 01 00       	push   $0x17bad
   1395e:	68 81 00 00 00       	push   $0x81
   13963:	68 7b 7b 01 00       	push   $0x17b7b
   13968:	68 20 7d 01 00       	push   $0x17d20
   1396d:	68 bc 7b 01 00       	push   $0x17bbc
   13972:	68 20 a4 01 00       	push   $0x1a420
   13977:	e8 7e 2e 00 00       	call   167fa <sprint>
   1397c:	83 c4 20             	add    $0x20,%esp
   1397f:	83 ec 0c             	sub    $0xc,%esp
   13982:	68 20 a4 01 00       	push   $0x1a420
   13987:	e8 35 29 00 00       	call   162c1 <kpanic>
   1398c:	83 c4 10             	add    $0x10,%esp

	// iterate through it, deallocating each qnode
	for( int i = 0; i < QNODES_PER_PAGE; ++i, ++block ) {
   1398f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13996:	eb 16                	jmp    139ae <qnode_add_page+0x74>
		qnode_free( block );
   13998:	83 ec 0c             	sub    $0xc,%esp
   1399b:	ff 75 f4             	push   -0xc(%ebp)
   1399e:	e8 3e ff ff ff       	call   138e1 <qnode_free>
   139a3:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < QNODES_PER_PAGE; ++i, ++block ) {
   139a6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   139aa:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
   139ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
   139b1:	3d ff 01 00 00       	cmp    $0x1ff,%eax
   139b6:	76 e0                	jbe    13998 <qnode_add_page+0x5e>
	}
}
   139b8:	90                   	nop
   139b9:	90                   	nop
   139ba:	c9                   	leave  
   139bb:	c3                   	ret    

000139bc <qnode_alloc>:
**
** Allocate a qnode
**
** @return A pointer to the allocated node, or NULL
*/
static qnode_t *qnode_alloc( void ) {
   139bc:	55                   	push   %ebp
   139bd:	89 e5                	mov    %esp,%ebp
   139bf:	83 ec 18             	sub    $0x18,%esp
	qnode_t *tmp;
	
	// if the list is empty, grab another slice and repopulate it
	if( free_qnodes == NULL ) {
   139c2:	a1 a0 a9 01 00       	mov    0x1a9a0,%eax
   139c7:	85 c0                	test   %eax,%eax
   139c9:	75 15                	jne    139e0 <qnode_alloc+0x24>
		qnode_add_page();
   139cb:	e8 6a ff ff ff       	call   1393a <qnode_add_page>
		// if it's still empty, we're done
		if( free_qnodes == NULL ) {
   139d0:	a1 a0 a9 01 00       	mov    0x1a9a0,%eax
   139d5:	85 c0                	test   %eax,%eax
   139d7:	75 07                	jne    139e0 <qnode_alloc+0x24>
			return NULL;
   139d9:	b8 00 00 00 00       	mov    $0x0,%eax
   139de:	eb 26                	jmp    13a06 <qnode_alloc+0x4a>
		}
	}
	
	// take the first node from the list
	tmp = free_qnodes;
   139e0:	a1 a0 a9 01 00       	mov    0x1a9a0,%eax
   139e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	free_qnodes = tmp->next;
   139e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   139eb:	8b 40 04             	mov    0x4(%eax),%eax
   139ee:	a3 a0 a9 01 00       	mov    %eax,0x1a9a0

	// make sure we clean it out
	memclr( tmp, sizeof(qnode_t) );
   139f3:	83 ec 08             	sub    $0x8,%esp
   139f6:	6a 08                	push   $0x8
   139f8:	ff 75 f4             	push   -0xc(%ebp)
   139fb:	e8 2e 2d 00 00       	call   1672e <memclr>
   13a00:	83 c4 10             	add    $0x10,%esp
	
	return tmp;
   13a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13a06:	c9                   	leave  
   13a07:	c3                   	ret    

00013a08 <que_dump>:
** dump the contents of the specified queue_t to the console
**
** @param[in] msg  Optional message to print
** @param[in] q    queue_t to dump
*/
void que_dump( const char *msg, queue_t q ) {
   13a08:	55                   	push   %ebp
   13a09:	89 e5                	mov    %esp,%ebp
   13a0b:	83 ec 18             	sub    $0x18,%esp

    // report on this queue
    cio_printf( "%s: ", msg ? msg : "???" );
   13a0e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13a12:	74 05                	je     13a19 <que_dump+0x11>
   13a14:	8b 45 08             	mov    0x8(%ebp),%eax
   13a17:	eb 05                	jmp    13a1e <que_dump+0x16>
   13a19:	b8 df 7b 01 00       	mov    $0x17bdf,%eax
   13a1e:	83 ec 08             	sub    $0x8,%esp
   13a21:	50                   	push   %eax
   13a22:	68 e3 7b 01 00       	push   $0x17be3
   13a27:	e8 db dc ff ff       	call   11707 <cio_printf>
   13a2c:	83 c4 10             	add    $0x10,%esp
    if( q == NULL ) {
   13a2f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13a33:	75 15                	jne    13a4a <que_dump+0x42>
        cio_puts( "NULL???\n" );
   13a35:	83 ec 0c             	sub    $0xc,%esp
   13a38:	68 e8 7b 01 00       	push   $0x17be8
   13a3d:	e8 4d d6 ff ff       	call   1108f <cio_puts>
   13a42:	83 c4 10             	add    $0x10,%esp
        return;
   13a45:	e9 d3 00 00 00       	jmp    13b1d <que_dump+0x115>
    }

    // first, the basic data
    cio_printf( "head %08x tail %08x len %d",
   13a4a:	8b 45 0c             	mov    0xc(%ebp),%eax
   13a4d:	8b 40 08             	mov    0x8(%eax),%eax
                  (uint32_t) q->head, (uint32_t) q->tail, q->count );
   13a50:	8b 55 0c             	mov    0xc(%ebp),%edx
   13a53:	8b 52 04             	mov    0x4(%edx),%edx
    cio_printf( "head %08x tail %08x len %d",
   13a56:	89 d1                	mov    %edx,%ecx
                  (uint32_t) q->head, (uint32_t) q->tail, q->count );
   13a58:	8b 55 0c             	mov    0xc(%ebp),%edx
   13a5b:	8b 12                	mov    (%edx),%edx
    cio_printf( "head %08x tail %08x len %d",
   13a5d:	50                   	push   %eax
   13a5e:	51                   	push   %ecx
   13a5f:	52                   	push   %edx
   13a60:	68 f1 7b 01 00       	push   $0x17bf1
   13a65:	e8 9d dc ff ff       	call   11707 <cio_printf>
   13a6a:	83 c4 10             	add    $0x10,%esp

    // next, how the queue is ordered
    if( q->compare ) {
   13a6d:	8b 45 0c             	mov    0xc(%ebp),%eax
   13a70:	8b 40 0c             	mov    0xc(%eax),%eax
   13a73:	85 c0                	test   %eax,%eax
   13a75:	74 19                	je     13a90 <que_dump+0x88>
        cio_printf( " compare %08x\n", (uint32_t) q->compare );
   13a77:	8b 45 0c             	mov    0xc(%ebp),%eax
   13a7a:	8b 40 0c             	mov    0xc(%eax),%eax
   13a7d:	83 ec 08             	sub    $0x8,%esp
   13a80:	50                   	push   %eax
   13a81:	68 0c 7c 01 00       	push   $0x17c0c
   13a86:	e8 7c dc ff ff       	call   11707 <cio_printf>
   13a8b:	83 c4 10             	add    $0x10,%esp
   13a8e:	eb 10                	jmp    13aa0 <que_dump+0x98>
    } else {
        cio_puts( " FIFO\n" );
   13a90:	83 ec 0c             	sub    $0xc,%esp
   13a93:	68 1b 7c 01 00       	push   $0x17c1b
   13a98:	e8 f2 d5 ff ff       	call   1108f <cio_puts>
   13a9d:	83 c4 10             	add    $0x10,%esp
    }

    // if there are members in the queue, dump the first nodes
    if( q->count > 0 ) {
   13aa0:	8b 45 0c             	mov    0xc(%ebp),%eax
   13aa3:	8b 40 08             	mov    0x8(%eax),%eax
   13aa6:	85 c0                	test   %eax,%eax
   13aa8:	74 73                	je     13b1d <que_dump+0x115>
        cio_puts( " data: " );
   13aaa:	83 ec 0c             	sub    $0xc,%esp
   13aad:	68 22 7c 01 00       	push   $0x17c22
   13ab2:	e8 d8 d5 ff ff       	call   1108f <cio_puts>
   13ab7:	83 c4 10             	add    $0x10,%esp
        qnode_t *tmp = q->head;
   13aba:	8b 45 0c             	mov    0xc(%ebp),%eax
   13abd:	8b 00                	mov    (%eax),%eax
   13abf:	89 45 f4             	mov    %eax,-0xc(%ebp)
        for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   13ac2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13ac9:	eb 23                	jmp    13aee <que_dump+0xe6>
            cio_printf( " [%08x]", (uint32_t) tmp->data );
   13acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13ace:	8b 00                	mov    (%eax),%eax
   13ad0:	83 ec 08             	sub    $0x8,%esp
   13ad3:	50                   	push   %eax
   13ad4:	68 2a 7c 01 00       	push   $0x17c2a
   13ad9:	e8 29 dc ff ff       	call   11707 <cio_printf>
   13ade:	83 c4 10             	add    $0x10,%esp
        for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   13ae1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13ae5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13ae8:	8b 40 04             	mov    0x4(%eax),%eax
   13aeb:	89 45 f4             	mov    %eax,-0xc(%ebp)
   13aee:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
   13af2:	7f 06                	jg     13afa <que_dump+0xf2>
   13af4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13af8:	75 d1                	jne    13acb <que_dump+0xc3>
        }

        if( tmp != NULL ) {
   13afa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13afe:	74 10                	je     13b10 <que_dump+0x108>
            cio_puts( " ..." );
   13b00:	83 ec 0c             	sub    $0xc,%esp
   13b03:	68 32 7c 01 00       	push   $0x17c32
   13b08:	e8 82 d5 ff ff       	call   1108f <cio_puts>
   13b0d:	83 c4 10             	add    $0x10,%esp
        }

        cio_putchar( '\n' );
   13b10:	83 ec 0c             	sub    $0xc,%esp
   13b13:	6a 0a                	push   $0xa
   13b15:	e8 f2 d3 ff ff       	call   10f0c <cio_putchar>
   13b1a:	83 c4 10             	add    $0x10,%esp
    }
}
   13b1d:	c9                   	leave  
   13b1e:	c3                   	ret    

00013b1f <que_init>:
/**
** que_init()
**
** Initialize the queue module.
*/
void que_init( void ) {
   13b1f:	55                   	push   %ebp
   13b20:	89 e5                	mov    %esp,%ebp
   13b22:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Que" );
   13b25:	83 ec 0c             	sub    $0xc,%esp
   13b28:	68 37 7c 01 00       	push   $0x17c37
   13b2d:	e8 5d d5 ff ff       	call   1108f <cio_puts>
   13b32:	83 c4 10             	add    $0x10,%esp
#endif

	// clear out the queue data structures
	memclr( queues, sizeof(queues) );
   13b35:	83 ec 08             	sub    $0x8,%esp
   13b38:	68 80 00 00 00       	push   $0x80
   13b3d:	68 c0 a9 01 00       	push   $0x1a9c0
   13b42:	e8 e7 2b 00 00       	call   1672e <memclr>
   13b47:	83 c4 10             	add    $0x10,%esp

	// set all the "free" flags
	memset( queue_free, sizeof(queue_free), QUE_FREE );
   13b4a:	83 ec 04             	sub    $0x4,%esp
   13b4d:	6a 01                	push   $0x1
   13b4f:	6a 08                	push   $0x8
   13b51:	68 40 aa 01 00       	push   $0x1aa40
   13b56:	e8 78 2c 00 00       	call   167d3 <memset>
   13b5b:	83 c4 10             	add    $0x10,%esp

	// reset the free list (just in case)
	free_qnodes = NULL;
   13b5e:	c7 05 a0 a9 01 00 00 	movl   $0x0,0x1a9a0
   13b65:	00 00 00 

	// create the first set of qnodes for use
	qnode_add_page();
   13b68:	e8 cd fd ff ff       	call   1393a <qnode_add_page>
}
   13b6d:	90                   	nop
   13b6e:	c9                   	leave  
   13b6f:	c3                   	ret    

00013b70 <que_alloc>:
**
** @param[in] compare  Pointer to the ordering function for the queue, or NULL
**
** @return A pointer to the allocated queue, or NULL on failure
*/
queue_t que_alloc( compare_t compare ) {
   13b70:	55                   	push   %ebp
   13b71:	89 e5                	mov    %esp,%ebp
   13b73:	83 ec 10             	sub    $0x10,%esp
#endif

	// locate a free queue
	int i;

	for( i = 0; i < N_QUEUES; ++i ) {
   13b76:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   13b7d:	eb 13                	jmp    13b92 <que_alloc+0x22>
		if( queue_free[i] ) {
   13b7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13b82:	05 40 aa 01 00       	add    $0x1aa40,%eax
   13b87:	0f b6 00             	movzbl (%eax),%eax
   13b8a:	84 c0                	test   %al,%al
   13b8c:	75 0c                	jne    13b9a <que_alloc+0x2a>
	for( i = 0; i < N_QUEUES; ++i ) {
   13b8e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   13b92:	83 7d fc 07          	cmpl   $0x7,-0x4(%ebp)
   13b96:	7e e7                	jle    13b7f <que_alloc+0xf>
   13b98:	eb 01                	jmp    13b9b <que_alloc+0x2b>
			break;
   13b9a:	90                   	nop
#if TRACING_QUEUE
	cio_printf( " search ix %d", i );
#endif

	// did we find one?
	if( i >= N_QUEUES ) {
   13b9b:	83 7d fc 07          	cmpl   $0x7,-0x4(%ebp)
   13b9f:	7e 07                	jle    13ba8 <que_alloc+0x38>
		// nope!
#if TRACING_QUEUE
	cio_puts( " NONE FREE?\n" );
#endif
		return NULL;
   13ba1:	b8 00 00 00 00       	mov    $0x0,%eax
   13ba6:	eb 44                	jmp    13bec <que_alloc+0x7c>
	}

	// found one - let's use it
	queue_t q = &queues[i];
   13ba8:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13bab:	c1 e0 04             	shl    $0x4,%eax
   13bae:	05 c0 a9 01 00       	add    $0x1a9c0,%eax
   13bb3:	89 45 f8             	mov    %eax,-0x8(%ebp)
	queue_free[i] = QUE_INUSE;
   13bb6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13bb9:	05 40 aa 01 00       	add    $0x1aa40,%eax
   13bbe:	c6 00 00             	movb   $0x0,(%eax)

	// make sure it's cleaned out
	q->head = q->tail = NULL;
   13bc1:	8b 45 f8             	mov    -0x8(%ebp),%eax
   13bc4:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13bcb:	8b 45 f8             	mov    -0x8(%ebp),%eax
   13bce:	8b 50 04             	mov    0x4(%eax),%edx
   13bd1:	8b 45 f8             	mov    -0x8(%ebp),%eax
   13bd4:	89 10                	mov    %edx,(%eax)
	q->count = 0;
   13bd6:	8b 45 f8             	mov    -0x8(%ebp),%eax
   13bd9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	q->compare = compare;
   13be0:	8b 45 f8             	mov    -0x8(%ebp),%eax
   13be3:	8b 55 08             	mov    0x8(%ebp),%edx
   13be6:	89 50 0c             	mov    %edx,0xc(%eax)
	cio_printf( " addr %08x\n", (uint32_t) q );
	que_dump( "new q", q );
#endif
	
	// send it on its way
	return q;
   13be9:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   13bec:	c9                   	leave  
   13bed:	c3                   	ret    

00013bee <que_free>:
**
** @param[in,out] q     The queue to be deallocated
**
** If the parameter is NULL or invalid, panics.
*/
void que_free( queue_t q ) {
   13bee:	55                   	push   %ebp
   13bef:	89 e5                	mov    %esp,%ebp
   13bf1:	83 ec 18             	sub    $0x18,%esp
#if TRACING_QUEUE
	cio_printf( "qfree(%08x)", (uint32_t) q );
#endif

	// which queue was it?
	int ix = que_ix( q );
   13bf4:	ff 75 08             	push   0x8(%ebp)
   13bf7:	e8 b9 fc ff ff       	call   138b5 <que_ix>
   13bfc:	83 c4 04             	add    $0x4,%esp
   13bff:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_QUEUE
	cio_printf( " ix %d, free[ix] %u", ix, queue_free[ix] );
#endif

	if( ix < 0 ) {
   13c02:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13c06:	79 10                	jns    13c18 <que_free+0x2a>
		kpanic( "que_free, bad queue pointer" );
   13c08:	83 ec 0c             	sub    $0xc,%esp
   13c0b:	68 3c 7c 01 00       	push   $0x17c3c
   13c10:	e8 ac 26 00 00       	call   162c1 <kpanic>
   13c15:	83 c4 10             	add    $0x10,%esp
	}

	// valid index - is it in use?
	if( queue_free[ix] ) {
   13c18:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13c1b:	05 40 aa 01 00       	add    $0x1aa40,%eax
   13c20:	0f b6 00             	movzbl (%eax),%eax
   13c23:	84 c0                	test   %al,%al
   13c25:	74 10                	je     13c37 <que_free+0x49>
		kpanic( "que_free of already-free queue" );
   13c27:	83 ec 0c             	sub    $0xc,%esp
   13c2a:	68 58 7c 01 00       	push   $0x17c58
   13c2f:	e8 8d 26 00 00       	call   162c1 <kpanic>
   13c34:	83 c4 10             	add    $0x10,%esp
	}

	// all is well - return the queue to the free list
	queue_free[ix] = QUE_FREE;
   13c37:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13c3a:	05 40 aa 01 00       	add    $0x1aa40,%eax
   13c3f:	c6 00 01             	movb   $0x1,(%eax)
	q->head = q->tail = NULL;
   13c42:	8b 45 08             	mov    0x8(%ebp),%eax
   13c45:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13c4c:	8b 45 08             	mov    0x8(%ebp),%eax
   13c4f:	8b 50 04             	mov    0x4(%eax),%edx
   13c52:	8b 45 08             	mov    0x8(%ebp),%eax
   13c55:	89 10                	mov    %edx,(%eax)
	q->compare = NULL;
   13c57:	8b 45 08             	mov    0x8(%ebp),%eax
   13c5a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	q->count = 0;
   13c61:	8b 45 08             	mov    0x8(%ebp),%eax
   13c64:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
   13c6b:	90                   	nop
   13c6c:	c9                   	leave  
   13c6d:	c3                   	ret    

00013c6e <que_length>:
**
** @return The occupancy count
**
** If the parameter is NULL or invalid, panics.
*/
int que_length( queue_t q ) {
   13c6e:	55                   	push   %ebp
   13c6f:	89 e5                	mov    %esp,%ebp
   13c71:	83 ec 18             	sub    $0x18,%esp

	// get the queue index
	int ix = que_ix( q );
   13c74:	ff 75 08             	push   0x8(%ebp)
   13c77:	e8 39 fc ff ff       	call   138b5 <que_ix>
   13c7c:	83 c4 04             	add    $0x4,%esp
   13c7f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( ix < 0 ) {
   13c82:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13c86:	79 10                	jns    13c98 <que_length+0x2a>
		kpanic( "que_length, bad que pointer" );
   13c88:	83 ec 0c             	sub    $0xc,%esp
   13c8b:	68 77 7c 01 00       	push   $0x17c77
   13c90:	e8 2c 26 00 00       	call   162c1 <kpanic>
   13c95:	83 c4 10             	add    $0x10,%esp
	}

	// is the queue in use?
	if( queue_free[ix] ) {
   13c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13c9b:	05 40 aa 01 00       	add    $0x1aa40,%eax
   13ca0:	0f b6 00             	movzbl (%eax),%eax
   13ca3:	84 c0                	test   %al,%al
   13ca5:	74 10                	je     13cb7 <que_length+0x49>
		kpanic( "que_length, unallocated queue" );
   13ca7:	83 ec 0c             	sub    $0xc,%esp
   13caa:	68 93 7c 01 00       	push   $0x17c93
   13caf:	e8 0d 26 00 00       	call   162c1 <kpanic>
   13cb4:	83 c4 10             	add    $0x10,%esp
	}

	// all is well - return the occupancy

	return q->count;
   13cb7:	8b 45 08             	mov    0x8(%ebp),%eax
   13cba:	8b 40 08             	mov    0x8(%eax),%eax
}
   13cbd:	c9                   	leave  
   13cbe:	c3                   	ret    

00013cbf <que_insert>:
** @param[in,out] q     The queue to be manipulated
** @param[in]     data  The value to add to the queue
**
** @return The insertion status
*/
int que_insert( queue_t q, void *data ) {
   13cbf:	55                   	push   %ebp
   13cc0:	89 e5                	mov    %esp,%ebp
   13cc2:	57                   	push   %edi
   13cc3:	56                   	push   %esi
   13cc4:	53                   	push   %ebx
   13cc5:	83 ec 1c             	sub    $0x1c,%esp

	// validate the queue parameter
	assert1( que_ix(q) >= 0 );
   13cc8:	ff 75 08             	push   0x8(%ebp)
   13ccb:	e8 e5 fb ff ff       	call   138b5 <que_ix>
   13cd0:	83 c4 04             	add    $0x4,%esp
   13cd3:	85 c0                	test   %eax,%eax
   13cd5:	79 39                	jns    13d10 <que_insert+0x51>
   13cd7:	83 ec 08             	sub    $0x8,%esp
   13cda:	68 b1 7c 01 00       	push   $0x17cb1
   13cdf:	68 7c 01 00 00       	push   $0x17c
   13ce4:	68 7b 7b 01 00       	push   $0x17b7b
   13ce9:	68 30 7d 01 00       	push   $0x17d30
   13cee:	68 8c 7b 01 00       	push   $0x17b8c
   13cf3:	68 20 a4 01 00       	push   $0x1a420
   13cf8:	e8 fd 2a 00 00       	call   167fa <sprint>
   13cfd:	83 c4 20             	add    $0x20,%esp
   13d00:	83 ec 0c             	sub    $0xc,%esp
   13d03:	68 20 a4 01 00       	push   $0x1a420
   13d08:	e8 b4 25 00 00       	call   162c1 <kpanic>
   13d0d:	83 c4 10             	add    $0x10,%esp
	
	// to insert, we'll need a qnode
	qnode_t *qn = qnode_alloc();
   13d10:	e8 a7 fc ff ff       	call   139bc <qnode_alloc>
   13d15:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if( qn == NULL ) {
   13d18:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   13d1c:	75 0a                	jne    13d28 <que_insert+0x69>
		return E_NO_QNODES;
   13d1e:	b8 08 00 00 00       	mov    $0x8,%eax
   13d23:	e9 6f 01 00 00       	jmp    13e97 <que_insert+0x1d8>
	}
	
	// value being inserted
	qn->data = data;
   13d28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13d2b:	8b 55 0c             	mov    0xc(%ebp),%edx
   13d2e:	89 10                	mov    %edx,(%eax)
	
	// if the queue is empty, we don't care about ordering
	if( q->count == 0 ) {
   13d30:	8b 45 08             	mov    0x8(%ebp),%eax
   13d33:	8b 40 08             	mov    0x8(%eax),%eax
   13d36:	85 c0                	test   %eax,%eax
   13d38:	75 74                	jne    13dae <que_insert+0xef>

		// sanity check of "empty" - pointers should both be NULL
		// if there's nothing in the queue
		assert1( q->head == NULL && q->tail == NULL );
   13d3a:	8b 45 08             	mov    0x8(%ebp),%eax
   13d3d:	8b 00                	mov    (%eax),%eax
   13d3f:	85 c0                	test   %eax,%eax
   13d41:	75 0a                	jne    13d4d <que_insert+0x8e>
   13d43:	8b 45 08             	mov    0x8(%ebp),%eax
   13d46:	8b 40 04             	mov    0x4(%eax),%eax
   13d49:	85 c0                	test   %eax,%eax
   13d4b:	74 39                	je     13d86 <que_insert+0xc7>
   13d4d:	83 ec 08             	sub    $0x8,%esp
   13d50:	68 c0 7c 01 00       	push   $0x17cc0
   13d55:	68 8c 01 00 00       	push   $0x18c
   13d5a:	68 7b 7b 01 00       	push   $0x17b7b
   13d5f:	68 30 7d 01 00       	push   $0x17d30
   13d64:	68 8c 7b 01 00       	push   $0x17b8c
   13d69:	68 20 a4 01 00       	push   $0x1a420
   13d6e:	e8 87 2a 00 00       	call   167fa <sprint>
   13d73:	83 c4 20             	add    $0x20,%esp
   13d76:	83 ec 0c             	sub    $0xc,%esp
   13d79:	68 20 a4 01 00       	push   $0x1a420
   13d7e:	e8 3e 25 00 00       	call   162c1 <kpanic>
   13d83:	83 c4 10             	add    $0x10,%esp

		// this is the new first and last node in the queue
		q->head = q->tail = qn;
   13d86:	8b 45 08             	mov    0x8(%ebp),%eax
   13d89:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   13d8c:	89 50 04             	mov    %edx,0x4(%eax)
   13d8f:	8b 45 08             	mov    0x8(%ebp),%eax
   13d92:	8b 50 04             	mov    0x4(%eax),%edx
   13d95:	8b 45 08             	mov    0x8(%ebp),%eax
   13d98:	89 10                	mov    %edx,(%eax)

		// this is the only thing in the queue
		q->count = 1;
   13d9a:	8b 45 08             	mov    0x8(%ebp),%eax
   13d9d:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)

		return E_SUCCESS;
   13da4:	b8 00 00 00 00       	mov    $0x0,%eax
   13da9:	e9 e9 00 00 00       	jmp    13e97 <que_insert+0x1d8>
	}
	
	// sanity check - pointers should not be NULL
	// if the queue isn't empty
	assert1( q->head != NULL && q->tail != NULL );
   13dae:	8b 45 08             	mov    0x8(%ebp),%eax
   13db1:	8b 00                	mov    (%eax),%eax
   13db3:	85 c0                	test   %eax,%eax
   13db5:	74 0a                	je     13dc1 <que_insert+0x102>
   13db7:	8b 45 08             	mov    0x8(%ebp),%eax
   13dba:	8b 40 04             	mov    0x4(%eax),%eax
   13dbd:	85 c0                	test   %eax,%eax
   13dbf:	75 39                	jne    13dfa <que_insert+0x13b>
   13dc1:	83 ec 08             	sub    $0x8,%esp
   13dc4:	68 e4 7c 01 00       	push   $0x17ce4
   13dc9:	68 99 01 00 00       	push   $0x199
   13dce:	68 7b 7b 01 00       	push   $0x17b7b
   13dd3:	68 30 7d 01 00       	push   $0x17d30
   13dd8:	68 8c 7b 01 00       	push   $0x17b8c
   13ddd:	68 20 a4 01 00       	push   $0x1a420
   13de2:	e8 13 2a 00 00       	call   167fa <sprint>
   13de7:	83 c4 20             	add    $0x20,%esp
   13dea:	83 ec 0c             	sub    $0xc,%esp
   13ded:	68 20 a4 01 00       	push   $0x1a420
   13df2:	e8 ca 24 00 00       	call   162c1 <kpanic>
   13df7:	83 c4 10             	add    $0x10,%esp
	** Queues can be ordered or FIFO. If there is no comparison
	** function for the queue, it's FIFO, so we just append the
	** new value.
	*/

	if( q->compare == NULL ) {
   13dfa:	8b 45 08             	mov    0x8(%ebp),%eax
   13dfd:	8b 40 0c             	mov    0xc(%eax),%eax
   13e00:	85 c0                	test   %eax,%eax
   13e02:	75 2b                	jne    13e2f <que_insert+0x170>

		// add after current "last" element
		q->tail->next = qn;
   13e04:	8b 45 08             	mov    0x8(%ebp),%eax
   13e07:	8b 40 04             	mov    0x4(%eax),%eax
   13e0a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   13e0d:	89 50 04             	mov    %edx,0x4(%eax)

		// this is now the tail end
		q->tail = qn;
   13e10:	8b 45 08             	mov    0x8(%ebp),%eax
   13e13:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   13e16:	89 50 04             	mov    %edx,0x4(%eax)

		// track occupancy
		q->count += 1;
   13e19:	8b 45 08             	mov    0x8(%ebp),%eax
   13e1c:	8b 40 08             	mov    0x8(%eax),%eax
   13e1f:	8d 50 01             	lea    0x1(%eax),%edx
   13e22:	8b 45 08             	mov    0x8(%ebp),%eax
   13e25:	89 50 08             	mov    %edx,0x8(%eax)

		return E_SUCCESS;
   13e28:	b8 00 00 00 00       	mov    $0x0,%eax
   13e2d:	eb 68                	jmp    13e97 <que_insert+0x1d8>
	** If we are here, this must be an ordered queue. We need to
	** traverse the queue looking for the first entry that must be
	** after the value we're inserting.
	*/

	register compare_t fcn = q->compare;
   13e2f:	8b 45 08             	mov    0x8(%ebp),%eax
   13e32:	8b 78 0c             	mov    0xc(%eax),%edi
	register qnode_t *prev, *curr;
	
	// begin at the front, and do a standard hand-over-hand traversal
	prev = NULL;
   13e35:	be 00 00 00 00       	mov    $0x0,%esi
	curr = q->head;
   13e3a:	8b 45 08             	mov    0x8(%ebp),%eax
   13e3d:	8b 18                	mov    (%eax),%ebx
	**     > 0 if p1 > p2
	**
	** What '<', '=', and '>' mean may vary; we treat it
	** as a simple ascending ordering.
	*/
	while( curr != NULL && fcn(data,curr->data) >= 0 ) {
   13e3f:	eb 05                	jmp    13e46 <que_insert+0x187>
		prev = curr;
   13e41:	89 de                	mov    %ebx,%esi
		curr = curr->next;
   13e43:	8b 5b 04             	mov    0x4(%ebx),%ebx
	while( curr != NULL && fcn(data,curr->data) >= 0 ) {
   13e46:	85 db                	test   %ebx,%ebx
   13e48:	74 12                	je     13e5c <que_insert+0x19d>
   13e4a:	8b 03                	mov    (%ebx),%eax
   13e4c:	83 ec 08             	sub    $0x8,%esp
   13e4f:	50                   	push   %eax
   13e50:	ff 75 0c             	push   0xc(%ebp)
   13e53:	ff d7                	call   *%edi
   13e55:	83 c4 10             	add    $0x10,%esp
   13e58:	85 c0                	test   %eax,%eax
   13e5a:	79 e5                	jns    13e41 <que_insert+0x182>
	**    !NULL  !NULL  inserting between 'prev' and 'curr'
	**    !NULL  NULL   appending after 'prev' (new 'tail')
	*/

	// always true, even if appending
	qn->next = curr;
   13e5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13e5f:	89 58 04             	mov    %ebx,0x4(%eax)

	if( prev == NULL ) {
   13e62:	85 f6                	test   %esi,%esi
   13e64:	75 0a                	jne    13e70 <que_insert+0x1b1>

		// inserting at beginning, so this is a new 'head' entry
		q->head = qn;
   13e66:	8b 45 08             	mov    0x8(%ebp),%eax
   13e69:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   13e6c:	89 10                	mov    %edx,(%eax)
   13e6e:	eb 13                	jmp    13e83 <que_insert+0x1c4>

	} else {

		// middle or end insertion, so predecessor points to new entry
		prev->next = qn;
   13e70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13e73:	89 46 04             	mov    %eax,0x4(%esi)

		// if there is no successor, this is the new 'tail' entry
		if( curr == NULL ) {
   13e76:	85 db                	test   %ebx,%ebx
   13e78:	75 09                	jne    13e83 <que_insert+0x1c4>
			q->tail = qn;
   13e7a:	8b 45 08             	mov    0x8(%ebp),%eax
   13e7d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   13e80:	89 50 04             	mov    %edx,0x4(%eax)
		}

	}

	// one more thing in the queue
	q->count += 1;
   13e83:	8b 45 08             	mov    0x8(%ebp),%eax
   13e86:	8b 40 08             	mov    0x8(%eax),%eax
   13e89:	8d 50 01             	lea    0x1(%eax),%edx
   13e8c:	8b 45 08             	mov    0x8(%ebp),%eax
   13e8f:	89 50 08             	mov    %edx,0x8(%eax)

	return E_SUCCESS;
   13e92:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13e97:	8d 65 f4             	lea    -0xc(%ebp),%esp
   13e9a:	5b                   	pop    %ebx
   13e9b:	5e                   	pop    %esi
   13e9c:	5f                   	pop    %edi
   13e9d:	5d                   	pop    %ebp
   13e9e:	c3                   	ret    

00013e9f <que_peek>:
** @param[in]  q     The queue to be examined
** @param,out] data  Where to save the value from the first queue node
**
** @return E_SUCCESS if there was an entry, else an error code
*/
int que_peek( queue_t q, void **data ) {
   13e9f:	55                   	push   %ebp
   13ea0:	89 e5                	mov    %esp,%ebp
   13ea2:	83 ec 08             	sub    $0x8,%esp

	// NULL q means real problems
	assert1( q != NULL );
   13ea5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13ea9:	75 39                	jne    13ee4 <que_peek+0x45>
   13eab:	83 ec 08             	sub    $0x8,%esp
   13eae:	68 07 7d 01 00       	push   $0x17d07
   13eb3:	68 fe 01 00 00       	push   $0x1fe
   13eb8:	68 7b 7b 01 00       	push   $0x17b7b
   13ebd:	68 3c 7d 01 00       	push   $0x17d3c
   13ec2:	68 8c 7b 01 00       	push   $0x17b8c
   13ec7:	68 20 a4 01 00       	push   $0x1a420
   13ecc:	e8 29 29 00 00       	call   167fa <sprint>
   13ed1:	83 c4 20             	add    $0x20,%esp
   13ed4:	83 ec 0c             	sub    $0xc,%esp
   13ed7:	68 20 a4 01 00       	push   $0x1a420
   13edc:	e8 e0 23 00 00       	call   162c1 <kpanic>
   13ee1:	83 c4 10             	add    $0x10,%esp

	// NULL data pointer might be recoverable
	if( data == NULL ) {
   13ee4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13ee8:	75 07                	jne    13ef1 <que_peek+0x52>
		return E_BAD_PARAM;
   13eea:	b8 03 00 00 00       	mov    $0x3,%eax
   13eef:	eb 6e                	jmp    13f5f <que_peek+0xc0>
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
   13ef1:	8b 45 08             	mov    0x8(%ebp),%eax
   13ef4:	8b 40 08             	mov    0x8(%eax),%eax
   13ef7:	85 c0                	test   %eax,%eax
   13ef9:	75 07                	jne    13f02 <que_peek+0x63>
		return E_EMPTY;
   13efb:	b8 04 00 00 00       	mov    $0x4,%eax
   13f00:	eb 5d                	jmp    13f5f <que_peek+0xc0>
	}
	
	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );
   13f02:	8b 45 08             	mov    0x8(%ebp),%eax
   13f05:	8b 00                	mov    (%eax),%eax
   13f07:	85 c0                	test   %eax,%eax
   13f09:	74 0a                	je     13f15 <que_peek+0x76>
   13f0b:	8b 45 08             	mov    0x8(%ebp),%eax
   13f0e:	8b 40 04             	mov    0x4(%eax),%eax
   13f11:	85 c0                	test   %eax,%eax
   13f13:	75 39                	jne    13f4e <que_peek+0xaf>
   13f15:	83 ec 08             	sub    $0x8,%esp
   13f18:	68 e4 7c 01 00       	push   $0x17ce4
   13f1d:	68 0b 02 00 00       	push   $0x20b
   13f22:	68 7b 7b 01 00       	push   $0x17b7b
   13f27:	68 3c 7d 01 00       	push   $0x17d3c
   13f2c:	68 8c 7b 01 00       	push   $0x17b8c
   13f31:	68 20 a4 01 00       	push   $0x1a420
   13f36:	e8 bf 28 00 00       	call   167fa <sprint>
   13f3b:	83 c4 20             	add    $0x20,%esp
   13f3e:	83 ec 0c             	sub    $0xc,%esp
   13f41:	68 20 a4 01 00       	push   $0x1a420
   13f46:	e8 76 23 00 00       	call   162c1 <kpanic>
   13f4b:	83 c4 10             	add    $0x10,%esp
	
	// all we need is the data field from the 'head' node
	*data = q->head->data;
   13f4e:	8b 45 08             	mov    0x8(%ebp),%eax
   13f51:	8b 00                	mov    (%eax),%eax
   13f53:	8b 10                	mov    (%eax),%edx
   13f55:	8b 45 0c             	mov    0xc(%ebp),%eax
   13f58:	89 10                	mov    %edx,(%eax)
	
	return E_SUCCESS;
   13f5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13f5f:	c9                   	leave  
   13f60:	c3                   	ret    

00013f61 <que_remove>:
** @param[in,out] q     The queue to be manipulated
** @param[out]    data  Where to save the removed data value
**
** @return The removal status
*/
int que_remove( queue_t q, void **data ) {
   13f61:	55                   	push   %ebp
   13f62:	89 e5                	mov    %esp,%ebp
   13f64:	83 ec 18             	sub    $0x18,%esp

	// NULL q means real problems
	assert1( q != NULL );
   13f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13f6b:	75 39                	jne    13fa6 <que_remove+0x45>
   13f6d:	83 ec 08             	sub    $0x8,%esp
   13f70:	68 07 7d 01 00       	push   $0x17d07
   13f75:	68 21 02 00 00       	push   $0x221
   13f7a:	68 7b 7b 01 00       	push   $0x17b7b
   13f7f:	68 48 7d 01 00       	push   $0x17d48
   13f84:	68 8c 7b 01 00       	push   $0x17b8c
   13f89:	68 20 a4 01 00       	push   $0x1a420
   13f8e:	e8 67 28 00 00       	call   167fa <sprint>
   13f93:	83 c4 20             	add    $0x20,%esp
   13f96:	83 ec 0c             	sub    $0xc,%esp
   13f99:	68 20 a4 01 00       	push   $0x1a420
   13f9e:	e8 1e 23 00 00       	call   162c1 <kpanic>
   13fa3:	83 c4 10             	add    $0x10,%esp

	// NULL data pointer might be recoverable
	if( data == NULL ) {
   13fa6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13faa:	75 0a                	jne    13fb6 <que_remove+0x55>
		return E_BAD_PARAM;
   13fac:	b8 03 00 00 00       	mov    $0x3,%eax
   13fb1:	e9 b2 00 00 00       	jmp    14068 <que_remove+0x107>
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
   13fb6:	8b 45 08             	mov    0x8(%ebp),%eax
   13fb9:	8b 40 08             	mov    0x8(%eax),%eax
   13fbc:	85 c0                	test   %eax,%eax
   13fbe:	75 0a                	jne    13fca <que_remove+0x69>
		return E_EMPTY;
   13fc0:	b8 04 00 00 00       	mov    $0x4,%eax
   13fc5:	e9 9e 00 00 00       	jmp    14068 <que_remove+0x107>
	}

	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );
   13fca:	8b 45 08             	mov    0x8(%ebp),%eax
   13fcd:	8b 00                	mov    (%eax),%eax
   13fcf:	85 c0                	test   %eax,%eax
   13fd1:	74 0a                	je     13fdd <que_remove+0x7c>
   13fd3:	8b 45 08             	mov    0x8(%ebp),%eax
   13fd6:	8b 40 04             	mov    0x4(%eax),%eax
   13fd9:	85 c0                	test   %eax,%eax
   13fdb:	75 39                	jne    14016 <que_remove+0xb5>
   13fdd:	83 ec 08             	sub    $0x8,%esp
   13fe0:	68 e4 7c 01 00       	push   $0x17ce4
   13fe5:	68 2e 02 00 00       	push   $0x22e
   13fea:	68 7b 7b 01 00       	push   $0x17b7b
   13fef:	68 48 7d 01 00       	push   $0x17d48
   13ff4:	68 8c 7b 01 00       	push   $0x17b8c
   13ff9:	68 20 a4 01 00       	push   $0x1a420
   13ffe:	e8 f7 27 00 00       	call   167fa <sprint>
   14003:	83 c4 20             	add    $0x20,%esp
   14006:	83 ec 0c             	sub    $0xc,%esp
   14009:	68 20 a4 01 00       	push   $0x1a420
   1400e:	e8 ae 22 00 00       	call   162c1 <kpanic>
   14013:	83 c4 10             	add    $0x10,%esp
	
	// get the first node and retrieve the data field from it
	qnode_t *qn = q->head;
   14016:	8b 45 08             	mov    0x8(%ebp),%eax
   14019:	8b 00                	mov    (%eax),%eax
   1401b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*data = qn->data;
   1401e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14021:	8b 10                	mov    (%eax),%edx
   14023:	8b 45 0c             	mov    0xc(%ebp),%eax
   14026:	89 10                	mov    %edx,(%eax)
	
	// second node is now the new 'head' of the queue
	q->head = qn->next;
   14028:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1402b:	8b 50 04             	mov    0x4(%eax),%edx
   1402e:	8b 45 08             	mov    0x8(%ebp),%eax
   14031:	89 10                	mov    %edx,(%eax)
	if( q->head == NULL ) {
   14033:	8b 45 08             	mov    0x8(%ebp),%eax
   14036:	8b 00                	mov    (%eax),%eax
   14038:	85 c0                	test   %eax,%eax
   1403a:	75 0a                	jne    14046 <que_remove+0xe5>
		// if there wasn't one, also reset the tail pointer
		q->tail = NULL;
   1403c:	8b 45 08             	mov    0x8(%ebp),%eax
   1403f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
	
	// one fewer entry
	q->count -= 1;
   14046:	8b 45 08             	mov    0x8(%ebp),%eax
   14049:	8b 40 08             	mov    0x8(%eax),%eax
   1404c:	8d 50 ff             	lea    -0x1(%eax),%edx
   1404f:	8b 45 08             	mov    0x8(%ebp),%eax
   14052:	89 50 08             	mov    %edx,0x8(%eax)
	
	// release the qnode
	qnode_free( qn );
   14055:	83 ec 0c             	sub    $0xc,%esp
   14058:	ff 75 f4             	push   -0xc(%ebp)
   1405b:	e8 81 f8 ff ff       	call   138e1 <qnode_free>
   14060:	83 c4 10             	add    $0x10,%esp
	
	return E_SUCCESS;
   14063:	b8 00 00 00 00       	mov    $0x0,%eax
}
   14068:	c9                   	leave  
   14069:	c3                   	ret    

0001406a <que_remove_by>:
** @param[in,out] q     The queue to be manipulated
** @param[in]     data  The entry to be located and removed
**
** @return The removal status
*/
int que_remove_by( queue_t q, void *data ) {
   1406a:	55                   	push   %ebp
   1406b:	89 e5                	mov    %esp,%ebp
   1406d:	56                   	push   %esi
   1406e:	53                   	push   %ebx

	// NULL q means real problems
	assert1( q != NULL );
   1406f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14073:	75 39                	jne    140ae <que_remove_by+0x44>
   14075:	83 ec 08             	sub    $0x8,%esp
   14078:	68 07 7d 01 00       	push   $0x17d07
   1407d:	68 59 02 00 00       	push   $0x259
   14082:	68 7b 7b 01 00       	push   $0x17b7b
   14087:	68 54 7d 01 00       	push   $0x17d54
   1408c:	68 8c 7b 01 00       	push   $0x17b8c
   14091:	68 20 a4 01 00       	push   $0x1a420
   14096:	e8 5f 27 00 00       	call   167fa <sprint>
   1409b:	83 c4 20             	add    $0x20,%esp
   1409e:	83 ec 0c             	sub    $0xc,%esp
   140a1:	68 20 a4 01 00       	push   $0x1a420
   140a6:	e8 16 22 00 00       	call   162c1 <kpanic>
   140ab:	83 c4 10             	add    $0x10,%esp

	// NULL data pointer might be recoverable
	if( data == NULL ) {
   140ae:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   140b2:	75 0a                	jne    140be <que_remove_by+0x54>
		return E_BAD_PARAM;
   140b4:	b8 03 00 00 00       	mov    $0x3,%eax
   140b9:	e9 c8 00 00 00       	jmp    14186 <que_remove_by+0x11c>
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
   140be:	8b 45 08             	mov    0x8(%ebp),%eax
   140c1:	8b 40 08             	mov    0x8(%eax),%eax
   140c4:	85 c0                	test   %eax,%eax
   140c6:	75 0a                	jne    140d2 <que_remove_by+0x68>
		return E_EMPTY;
   140c8:	b8 04 00 00 00       	mov    $0x4,%eax
   140cd:	e9 b4 00 00 00       	jmp    14186 <que_remove_by+0x11c>
	}

	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );
   140d2:	8b 45 08             	mov    0x8(%ebp),%eax
   140d5:	8b 00                	mov    (%eax),%eax
   140d7:	85 c0                	test   %eax,%eax
   140d9:	74 0a                	je     140e5 <que_remove_by+0x7b>
   140db:	8b 45 08             	mov    0x8(%ebp),%eax
   140de:	8b 40 04             	mov    0x4(%eax),%eax
   140e1:	85 c0                	test   %eax,%eax
   140e3:	75 39                	jne    1411e <que_remove_by+0xb4>
   140e5:	83 ec 08             	sub    $0x8,%esp
   140e8:	68 e4 7c 01 00       	push   $0x17ce4
   140ed:	68 66 02 00 00       	push   $0x266
   140f2:	68 7b 7b 01 00       	push   $0x17b7b
   140f7:	68 54 7d 01 00       	push   $0x17d54
   140fc:	68 8c 7b 01 00       	push   $0x17b8c
   14101:	68 20 a4 01 00       	push   $0x1a420
   14106:	e8 ef 26 00 00       	call   167fa <sprint>
   1410b:	83 c4 20             	add    $0x20,%esp
   1410e:	83 ec 0c             	sub    $0xc,%esp
   14111:	68 20 a4 01 00       	push   $0x1a420
   14116:	e8 a6 21 00 00       	call   162c1 <kpanic>
   1411b:	83 c4 10             	add    $0x10,%esp

	// standard hand-over-hand traversal
	register qnode_t *prev, *curr;
	
	prev = NULL;
   1411e:	be 00 00 00 00       	mov    $0x0,%esi
	curr = q->head;
   14123:	8b 45 08             	mov    0x8(%ebp),%eax
   14126:	8b 18                	mov    (%eax),%ebx
	
	/*
	** We walk the queue until either we run off the end, or
	** we find a node containing the desired data value.
	*/
	while( curr != NULL && data != curr->data ) {
   14128:	eb 05                	jmp    1412f <que_remove_by+0xc5>
		prev = curr;
   1412a:	89 de                	mov    %ebx,%esi
		curr = curr->next;
   1412c:	8b 5b 04             	mov    0x4(%ebx),%ebx
	while( curr != NULL && data != curr->data ) {
   1412f:	85 db                	test   %ebx,%ebx
   14131:	74 07                	je     1413a <que_remove_by+0xd0>
   14133:	8b 03                	mov    (%ebx),%eax
   14135:	39 45 0c             	cmp    %eax,0xc(%ebp)
   14138:	75 f0                	jne    1412a <que_remove_by+0xc0>
	}
	
	// did we find the entry?
	if( curr == NULL ) {
   1413a:	85 db                	test   %ebx,%ebx
   1413c:	75 07                	jne    14145 <que_remove_by+0xdb>
		return E_NOT_FOUND;
   1413e:	b8 05 00 00 00       	mov    $0x5,%eax
   14143:	eb 41                	jmp    14186 <que_remove_by+0x11c>
	}

	// found it - was it the first node?
	if( prev == NULL ) {
   14145:	85 f6                	test   %esi,%esi
   14147:	75 0a                	jne    14153 <que_remove_by+0xe9>
		// yes, so there's a new head node
		q->head = curr->next;
   14149:	8b 53 04             	mov    0x4(%ebx),%edx
   1414c:	8b 45 08             	mov    0x8(%ebp),%eax
   1414f:	89 10                	mov    %edx,(%eax)
   14151:	eb 06                	jmp    14159 <que_remove_by+0xef>
	} else {
		// no, so the predecessor must point to the successor
		prev->next = curr->next;
   14153:	8b 43 04             	mov    0x4(%ebx),%eax
   14156:	89 46 04             	mov    %eax,0x4(%esi)
	}
	
	// if there is no successor, we removed the last entry
	if( curr->next == NULL ) {
   14159:	8b 43 04             	mov    0x4(%ebx),%eax
   1415c:	85 c0                	test   %eax,%eax
   1415e:	75 06                	jne    14166 <que_remove_by+0xfc>
		q->tail = prev;
   14160:	8b 45 08             	mov    0x8(%ebp),%eax
   14163:	89 70 04             	mov    %esi,0x4(%eax)
	}

	// it's gone
	q->count -= 1;	
   14166:	8b 45 08             	mov    0x8(%ebp),%eax
   14169:	8b 40 08             	mov    0x8(%eax),%eax
   1416c:	8d 50 ff             	lea    -0x1(%eax),%edx
   1416f:	8b 45 08             	mov    0x8(%ebp),%eax
   14172:	89 50 08             	mov    %edx,0x8(%eax)
	
	// return the qnode to the free pool
	qnode_free( curr );
   14175:	83 ec 0c             	sub    $0xc,%esp
   14178:	53                   	push   %ebx
   14179:	e8 63 f7 ff ff       	call   138e1 <qnode_free>
   1417e:	83 c4 10             	add    $0x10,%esp
		
	return E_SUCCESS;
   14181:	b8 00 00 00 00       	mov    $0x0,%eax
}
   14186:	8d 65 f8             	lea    -0x8(%ebp),%esp
   14189:	5b                   	pop    %ebx
   1418a:	5e                   	pop    %esi
   1418b:	5d                   	pop    %ebp
   1418c:	c3                   	ret    

0001418d <sio_isr>:
** events (as described by the SIO controller).
**
** @param[in] vector   The interrupt vector number for this interrupt
** @param[in] ecode    The error code associated with this interrupt
*/
static void sio_isr( int vector, int ecode ) {
   1418d:	55                   	push   %ebp
   1418e:	89 e5                	mov    %esp,%ebp
   14190:	83 ec 58             	sub    $0x58,%esp
   14193:	c7 45 e4 fa 03 00 00 	movl   $0x3fa,-0x1c(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1419a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1419d:	89 c2                	mov    %eax,%edx
   1419f:	ec                   	in     (%dx),%al
   141a0:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
   141a3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
	//

	for(;;) {

		// get the "pending event" indicator
		int iir = inb( UA4_IIR ) & UA4_IIR_INT_PRI_MASK;
   141a7:	0f b6 c0             	movzbl %al,%eax
   141aa:	83 e0 0f             	and    $0xf,%eax
   141ad:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// process this event
		switch( iir ) {
   141b0:	83 7d f0 0c          	cmpl   $0xc,-0x10(%ebp)
   141b4:	0f 87 b8 02 00 00    	ja     14472 <sio_isr+0x2e5>
   141ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
   141bd:	c1 e0 02             	shl    $0x2,%eax
   141c0:	05 54 7e 01 00       	add    $0x17e54,%eax
   141c5:	8b 00                	mov    (%eax),%eax
   141c7:	ff e0                	jmp    *%eax
   141c9:	c7 45 dc fd 03 00 00 	movl   $0x3fd,-0x24(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   141d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
   141d3:	89 c2                	mov    %eax,%edx
   141d5:	ec                   	in     (%dx),%al
   141d6:	88 45 db             	mov    %al,-0x25(%ebp)
	return data;
   141d9:	0f b6 45 db          	movzbl -0x25(%ebp),%eax

		case UA4_IIR_LINE_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, LSR = %02x\n", inb(UA4_LSR) );
   141dd:	0f b6 c0             	movzbl %al,%eax
   141e0:	83 ec 08             	sub    $0x8,%esp
   141e3:	50                   	push   %eax
   141e4:	68 64 7d 01 00       	push   $0x17d64
   141e9:	e8 19 d5 ff ff       	call   11707 <cio_printf>
   141ee:	83 c4 10             	add    $0x10,%esp
			break;
   141f1:	e9 d9 02 00 00       	jmp    144cf <sio_isr+0x342>
   141f6:	c7 45 d4 f8 03 00 00 	movl   $0x3f8,-0x2c(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   141fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   14200:	89 c2                	mov    %eax,%edx
   14202:	ec                   	in     (%dx),%al
   14203:	88 45 d3             	mov    %al,-0x2d(%ebp)
	return data;
   14206:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
		case UA4_IIR_RX:
#if TRACING_SIO_ISR
	cio_puts( " RX" );
#endif
			// get the character
			ch = inb( UA4_RXD );
   1420a:	0f b6 c0             	movzbl %al,%eax
   1420d:	89 45 f4             	mov    %eax,-0xc(%ebp)
			if( ch == '\r' ) {    // map CR to LF
   14210:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
   14214:	75 07                	jne    1421d <sio_isr+0x90>
				ch = '\n';
   14216:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
			// If there is a waiting process, this must be
			// the first input character; give it to that
			// process and awaken the process.
			//

			if( !QEMPTY(QNAME) ) {
   1421d:	a1 58 a6 01 00       	mov    0x1a658,%eax
   14222:	83 ec 0c             	sub    $0xc,%esp
   14225:	50                   	push   %eax
   14226:	e8 43 fa ff ff       	call   13c6e <que_length>
   1422b:	83 c4 10             	add    $0x10,%esp
   1422e:	85 c0                	test   %eax,%eax
   14230:	0f 8e f1 00 00 00    	jle    14327 <sio_isr+0x19a>
				PCBTYPE *pcb = NULL;
   14236:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)

				QDEQUE( QNAME, pcb );
   1423d:	a1 58 a6 01 00       	mov    0x1a658,%eax
   14242:	83 ec 08             	sub    $0x8,%esp
   14245:	8d 55 ac             	lea    -0x54(%ebp),%edx
   14248:	52                   	push   %edx
   14249:	50                   	push   %eax
   1424a:	e8 12 fd ff ff       	call   13f61 <que_remove>
   1424f:	83 c4 10             	add    $0x10,%esp
   14252:	85 c0                	test   %eax,%eax
   14254:	74 39                	je     1428f <sio_isr+0x102>
   14256:	83 ec 08             	sub    $0x8,%esp
   14259:	68 7c 7d 01 00       	push   $0x17d7c
   1425e:	68 b0 00 00 00       	push   $0xb0
   14263:	68 b3 7d 01 00       	push   $0x17db3
   14268:	68 e4 7e 01 00       	push   $0x17ee4
   1426d:	68 c0 7d 01 00       	push   $0x17dc0
   14272:	68 20 a4 01 00       	push   $0x1a420
   14277:	e8 7e 25 00 00       	call   167fa <sprint>
   1427c:	83 c4 20             	add    $0x20,%esp
   1427f:	83 ec 0c             	sub    $0xc,%esp
   14282:	68 20 a4 01 00       	push   $0x1a420
   14287:	e8 35 20 00 00       	call   162c1 <kpanic>
   1428c:	83 c4 10             	add    $0x10,%esp
				// make sure we got a non-NULL result
				assert( pcb != NULL );
   1428f:	8b 45 ac             	mov    -0x54(%ebp),%eax
   14292:	85 c0                	test   %eax,%eax
   14294:	75 39                	jne    142cf <sio_isr+0x142>
   14296:	83 ec 08             	sub    $0x8,%esp
   14299:	68 e3 7d 01 00       	push   $0x17de3
   1429e:	68 b2 00 00 00       	push   $0xb2
   142a3:	68 b3 7d 01 00       	push   $0x17db3
   142a8:	68 e4 7e 01 00       	push   $0x17ee4
   142ad:	68 c0 7d 01 00       	push   $0x17dc0
   142b2:	68 20 a4 01 00       	push   $0x1a420
   142b7:	e8 3e 25 00 00       	call   167fa <sprint>
   142bc:	83 c4 20             	add    $0x20,%esp
   142bf:	83 ec 0c             	sub    $0xc,%esp
   142c2:	68 20 a4 01 00       	push   $0x1a420
   142c7:	e8 f5 1f 00 00       	call   162c1 <kpanic>
   142cc:	83 c4 10             	add    $0x10,%esp

				// return char via arg #2 and count in EAX
				char *buf = (char *) ARG(pcb,2);
   142cf:	8b 45 ac             	mov    -0x54(%ebp),%eax
   142d2:	8b 00                	mov    (%eax),%eax
   142d4:	83 c0 50             	add    $0x50,%eax
   142d7:	8b 00                	mov    (%eax),%eax
   142d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
				uint32_t len = (uint32_t) ARG(pcb,3);
   142dc:	8b 45 ac             	mov    -0x54(%ebp),%eax
   142df:	8b 00                	mov    (%eax),%eax
   142e1:	83 c0 54             	add    $0x54,%eax
   142e4:	8b 00                	mov    (%eax),%eax
   142e6:	89 45 e8             	mov    %eax,-0x18(%ebp)
				if( len > 0 ) {
   142e9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   142ed:	74 18                	je     14307 <sio_isr+0x17a>
					// save the character
					*buf = ch & 0xff;
   142ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
   142f2:	89 c2                	mov    %eax,%edx
   142f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
   142f7:	88 10                	mov    %dl,(%eax)
					RET(pcb) = 1;
   142f9:	8b 45 ac             	mov    -0x54(%ebp),%eax
   142fc:	8b 00                	mov    (%eax),%eax
   142fe:	c7 40 30 01 00 00 00 	movl   $0x1,0x30(%eax)
   14305:	eb 0c                	jmp    14313 <sio_isr+0x186>
				} else {
					// not enough room for one character???
					RET(pcb) = 0;
   14307:	8b 45 ac             	mov    -0x54(%ebp),%eax
   1430a:	8b 00                	mov    (%eax),%eax
   1430c:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
				}
				// either way, let this process proceed
				SCHED( pcb );
   14313:	8b 45 ac             	mov    -0x54(%ebp),%eax
   14316:	83 ec 0c             	sub    $0xc,%esp
   14319:	50                   	push   %eax
   1431a:	e8 fd f3 ff ff       	call   1371c <schedule>
   1431f:	83 c4 10             	add    $0x10,%esp
				}

#ifdef QNAME
			}
#endif /* QNAME */
			break;
   14322:	e9 a7 01 00 00       	jmp    144ce <sio_isr+0x341>
				if( incount < BUF_SIZE ) {
   14327:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   1432c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
   14331:	0f 87 97 01 00 00    	ja     144ce <sio_isr+0x341>
					*inlast++ = ch;
   14337:	a1 80 ae 01 00       	mov    0x1ae80,%eax
   1433c:	8d 50 01             	lea    0x1(%eax),%edx
   1433f:	89 15 80 ae 01 00    	mov    %edx,0x1ae80
   14345:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14348:	88 10                	mov    %dl,(%eax)
					++incount;
   1434a:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   1434f:	83 c0 01             	add    $0x1,%eax
   14352:	a3 88 ae 01 00       	mov    %eax,0x1ae88
			break;
   14357:	e9 72 01 00 00       	jmp    144ce <sio_isr+0x341>
   1435c:	c7 45 cc f8 03 00 00 	movl   $0x3f8,-0x34(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14363:	8b 45 cc             	mov    -0x34(%ebp),%eax
   14366:	89 c2                	mov    %eax,%edx
   14368:	ec                   	in     (%dx),%al
   14369:	88 45 cb             	mov    %al,-0x35(%ebp)
	return data;
   1436c:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax

		case UA5_IIR_RX_FIFO:
			// shouldn't happen, but just in case....
			ch = inb( UA4_RXD );
   14370:	0f b6 c0             	movzbl %al,%eax
   14373:	89 45 f4             	mov    %eax,-0xc(%ebp)
			cio_printf( "** SIO FIFO timeout, RXD = %02x\n", ch );
   14376:	83 ec 08             	sub    $0x8,%esp
   14379:	ff 75 f4             	push   -0xc(%ebp)
   1437c:	68 f0 7d 01 00       	push   $0x17df0
   14381:	e8 81 d3 ff ff       	call   11707 <cio_printf>
   14386:	83 c4 10             	add    $0x10,%esp
			break;
   14389:	e9 41 01 00 00       	jmp    144cf <sio_isr+0x342>
		case UA4_IIR_TX:
#if TRACING_SIO_ISR
	cio_puts( " TX" );
#endif
			// if there is another character, send it
			if( sending && outcount > 0 ) {
   1438e:	a1 ac b2 01 00       	mov    0x1b2ac,%eax
   14393:	85 c0                	test   %eax,%eax
   14395:	74 5e                	je     143f5 <sio_isr+0x268>
   14397:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   1439c:	85 c0                	test   %eax,%eax
   1439e:	74 55                	je     143f5 <sio_isr+0x268>
#if TRACING_SIO_ISR
	cio_printf( " ch %02x", *outnext );
#endif
				outb( UA4_TXD, *outnext );
   143a0:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   143a5:	0f b6 00             	movzbl (%eax),%eax
   143a8:	0f b6 c0             	movzbl %al,%eax
   143ab:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
   143b2:	88 45 c3             	mov    %al,-0x3d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   143b5:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   143b9:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   143bc:	ee                   	out    %al,(%dx)
}
   143bd:	90                   	nop
				++outnext;
   143be:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   143c3:	83 c0 01             	add    $0x1,%eax
   143c6:	a3 a4 b2 01 00       	mov    %eax,0x1b2a4
				// wrap around if necessary
				if( outnext >= (outbuffer + BUF_SIZE) ) {
   143cb:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   143d0:	ba a0 b2 01 00       	mov    $0x1b2a0,%edx
   143d5:	39 d0                	cmp    %edx,%eax
   143d7:	72 0a                	jb     143e3 <sio_isr+0x256>
					outnext = outbuffer;
   143d9:	c7 05 a4 b2 01 00 a0 	movl   $0x1aea0,0x1b2a4
   143e0:	ae 01 00 
				}
				--outcount;
   143e3:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   143e8:	83 e8 01             	sub    $0x1,%eax
   143eb:	a3 a8 b2 01 00       	mov    %eax,0x1b2a8
				outlast = outnext = outbuffer;
				sending = 0;
				// disable TX interrupts
				sio_disable( SIO_TX );
			}
			break;
   143f0:	e9 da 00 00 00       	jmp    144cf <sio_isr+0x342>
				outcount = 0;
   143f5:	c7 05 a8 b2 01 00 00 	movl   $0x0,0x1b2a8
   143fc:	00 00 00 
				outlast = outnext = outbuffer;
   143ff:	c7 05 a4 b2 01 00 a0 	movl   $0x1aea0,0x1b2a4
   14406:	ae 01 00 
   14409:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   1440e:	a3 a0 b2 01 00       	mov    %eax,0x1b2a0
				sending = 0;
   14413:	c7 05 ac b2 01 00 00 	movl   $0x0,0x1b2ac
   1441a:	00 00 00 
				sio_disable( SIO_TX );
   1441d:	83 ec 0c             	sub    $0xc,%esp
   14420:	6a 01                	push   $0x1
   14422:	e8 b0 02 00 00       	call   146d7 <sio_disable>
   14427:	83 c4 10             	add    $0x10,%esp
			break;
   1442a:	e9 a0 00 00 00       	jmp    144cf <sio_isr+0x342>
   1442f:	c7 45 bc 20 00 00 00 	movl   $0x20,-0x44(%ebp)
   14436:	c6 45 bb 20          	movb   $0x20,-0x45(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1443a:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   1443e:	8b 55 bc             	mov    -0x44(%ebp),%edx
   14441:	ee                   	out    %al,(%dx)
}
   14442:	90                   	nop
#if TRACING_SIO_ISR
	cio_puts( " EOI\n" );
#endif
			// nothing to do - tell the PIC we're done
			outb( PIC1_CMD, PIC_EOI );
			return;
   14443:	e9 8c 00 00 00       	jmp    144d4 <sio_isr+0x347>
   14448:	c7 45 b4 fe 03 00 00 	movl   $0x3fe,-0x4c(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1444f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   14452:	89 c2                	mov    %eax,%edx
   14454:	ec                   	in     (%dx),%al
   14455:	88 45 b3             	mov    %al,-0x4d(%ebp)
	return data;
   14458:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax

		case UA4_IIR_MODEM_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, MSR = %02x\n", inb(UA4_MSR) );
   1445c:	0f b6 c0             	movzbl %al,%eax
   1445f:	83 ec 08             	sub    $0x8,%esp
   14462:	50                   	push   %eax
   14463:	68 11 7e 01 00       	push   $0x17e11
   14468:	e8 9a d2 ff ff       	call   11707 <cio_printf>
   1446d:	83 c4 10             	add    $0x10,%esp
			break;
   14470:	eb 5d                	jmp    144cf <sio_isr+0x342>

		default:
			// uh-oh....
			sprint( b256, "sio isr: IIR %02x\n", ((uint32_t) iir) & 0xff );
   14472:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14475:	0f b6 c0             	movzbl %al,%eax
   14478:	83 ec 04             	sub    $0x4,%esp
   1447b:	50                   	push   %eax
   1447c:	68 29 7e 01 00       	push   $0x17e29
   14481:	68 20 a1 01 00       	push   $0x1a120
   14486:	e8 6f 23 00 00       	call   167fa <sprint>
   1448b:	83 c4 10             	add    $0x10,%esp
			PANIC( 0, b256 );
   1448e:	83 ec 04             	sub    $0x4,%esp
   14491:	68 20 a1 01 00       	push   $0x1a120
   14496:	6a 00                	push   $0x0
   14498:	68 0a 01 00 00       	push   $0x10a
   1449d:	68 b3 7d 01 00       	push   $0x17db3
   144a2:	68 e4 7e 01 00       	push   $0x17ee4
   144a7:	68 3c 7e 01 00       	push   $0x17e3c
   144ac:	68 20 a4 01 00       	push   $0x1a420
   144b1:	e8 44 23 00 00       	call   167fa <sprint>
   144b6:	83 c4 20             	add    $0x20,%esp
   144b9:	83 ec 0c             	sub    $0xc,%esp
   144bc:	68 20 a4 01 00       	push   $0x1a420
   144c1:	e8 fb 1d 00 00       	call   162c1 <kpanic>
   144c6:	83 c4 10             	add    $0x10,%esp
   144c9:	e9 c5 fc ff ff       	jmp    14193 <sio_isr+0x6>
			break;
   144ce:	90                   	nop
	for(;;) {
   144cf:	e9 bf fc ff ff       	jmp    14193 <sio_isr+0x6>
	
	}

	// should never reach this point!
	assert( false );
}
   144d4:	c9                   	leave  
   144d5:	c3                   	ret    

000144d6 <sio_init>:
/**
** sio_init()
**
** Initialize the UART chip.
*/
void sio_init( void ) {
   144d6:	55                   	push   %ebp
   144d7:	89 e5                	mov    %esp,%ebp
   144d9:	83 ec 68             	sub    $0x68,%esp

#if TRACING_INIT
	cio_puts( " Sio" );
   144dc:	83 ec 0c             	sub    $0xc,%esp
   144df:	68 88 7e 01 00       	push   $0x17e88
   144e4:	e8 a6 cb ff ff       	call   1108f <cio_puts>
   144e9:	83 c4 10             	add    $0x10,%esp

	/*
	** Initialize SIO variables.
	*/

	memclr( (void *) inbuffer, sizeof(inbuffer) );
   144ec:	83 ec 08             	sub    $0x8,%esp
   144ef:	68 00 04 00 00       	push   $0x400
   144f4:	68 80 aa 01 00       	push   $0x1aa80
   144f9:	e8 30 22 00 00       	call   1672e <memclr>
   144fe:	83 c4 10             	add    $0x10,%esp
	inlast = innext = inbuffer;
   14501:	c7 05 84 ae 01 00 80 	movl   $0x1aa80,0x1ae84
   14508:	aa 01 00 
   1450b:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   14510:	a3 80 ae 01 00       	mov    %eax,0x1ae80
	incount = 0;
   14515:	c7 05 88 ae 01 00 00 	movl   $0x0,0x1ae88
   1451c:	00 00 00 

	memclr( (void *) outbuffer, sizeof(outbuffer) );
   1451f:	83 ec 08             	sub    $0x8,%esp
   14522:	68 00 04 00 00       	push   $0x400
   14527:	68 a0 ae 01 00       	push   $0x1aea0
   1452c:	e8 fd 21 00 00       	call   1672e <memclr>
   14531:	83 c4 10             	add    $0x10,%esp
	outlast = outnext = outbuffer;
   14534:	c7 05 a4 b2 01 00 a0 	movl   $0x1aea0,0x1b2a4
   1453b:	ae 01 00 
   1453e:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   14543:	a3 a0 b2 01 00       	mov    %eax,0x1b2a0
	outcount = 0;
   14548:	c7 05 a8 b2 01 00 00 	movl   $0x0,0x1b2a8
   1454f:	00 00 00 
	sending = 0;
   14552:	c7 05 ac b2 01 00 00 	movl   $0x0,0x1b2ac
   14559:	00 00 00 
   1455c:	c7 45 a4 fa 03 00 00 	movl   $0x3fa,-0x5c(%ebp)
   14563:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14567:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
   1456b:	8b 55 a4             	mov    -0x5c(%ebp),%edx
   1456e:	ee                   	out    %al,(%dx)
}
   1456f:	90                   	nop
   14570:	c7 45 ac fa 03 00 00 	movl   $0x3fa,-0x54(%ebp)
   14577:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1457b:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
   1457f:	8b 55 ac             	mov    -0x54(%ebp),%edx
   14582:	ee                   	out    %al,(%dx)
}
   14583:	90                   	nop
   14584:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
   1458b:	c6 45 b3 01          	movb   $0x1,-0x4d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1458f:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   14593:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   14596:	ee                   	out    %al,(%dx)
}
   14597:	90                   	nop
   14598:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)
   1459f:	c6 45 bb 03          	movb   $0x3,-0x45(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   145a3:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   145a7:	8b 55 bc             	mov    -0x44(%ebp),%edx
   145aa:	ee                   	out    %al,(%dx)
}
   145ab:	90                   	nop
   145ac:	c7 45 c4 fa 03 00 00 	movl   $0x3fa,-0x3c(%ebp)
   145b3:	c6 45 c3 07          	movb   $0x7,-0x3d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   145b7:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   145bb:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   145be:	ee                   	out    %al,(%dx)
}
   145bf:	90                   	nop
   145c0:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
   145c7:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   145cb:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   145cf:	8b 55 cc             	mov    -0x34(%ebp),%edx
   145d2:	ee                   	out    %al,(%dx)
}
   145d3:	90                   	nop
	** we leave them disabled; sio_enable() must be
	** called to switch them back on
	*/

	outb( UA4_IER, 0 );
	ier = 0;
   145d4:	c6 05 b0 b2 01 00 00 	movb   $0x0,0x1b2b0
   145db:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
   145e2:	c6 45 d3 80          	movb   $0x80,-0x2d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   145e6:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   145ea:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   145ed:	ee                   	out    %al,(%dx)
}
   145ee:	90                   	nop
   145ef:	c7 45 dc f8 03 00 00 	movl   $0x3f8,-0x24(%ebp)
   145f6:	c6 45 db 0c          	movb   $0xc,-0x25(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   145fa:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   145fe:	8b 55 dc             	mov    -0x24(%ebp),%edx
   14601:	ee                   	out    %al,(%dx)
}
   14602:	90                   	nop
   14603:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
   1460a:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1460e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   14612:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14615:	ee                   	out    %al,(%dx)
}
   14616:	90                   	nop
   14617:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
   1461e:	c6 45 eb 03          	movb   $0x3,-0x15(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14622:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   14626:	8b 55 ec             	mov    -0x14(%ebp),%edx
   14629:	ee                   	out    %al,(%dx)
}
   1462a:	90                   	nop
   1462b:	c7 45 f4 fc 03 00 00 	movl   $0x3fc,-0xc(%ebp)
   14632:	c6 45 f3 0b          	movb   $0xb,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14636:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1463a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1463d:	ee                   	out    %al,(%dx)
}
   1463e:	90                   	nop

	/*
	** Install our ISR
	*/

	install_isr( VEC_COM1, sio_isr );
   1463f:	83 ec 08             	sub    $0x8,%esp
   14642:	68 8d 41 01 00       	push   $0x1418d
   14647:	6a 24                	push   $0x24
   14649:	e8 54 0e 00 00       	call   154a2 <install_isr>
   1464e:	83 c4 10             	add    $0x10,%esp

	/*
	** Indicate the SIO is usable
	*/

	sio_ready = 1;
   14651:	c7 05 60 aa 01 00 01 	movl   $0x1,0x1aa60
   14658:	00 00 00 
}
   1465b:	90                   	nop
   1465c:	c9                   	leave  
   1465d:	c3                   	ret    

0001465e <sio_enable>:
**
** @param[in] which   Bit mask indicating which interrupt(s) to enable
**
** @return the prior IER setting
*/
uint8_t sio_enable( uint8_t which ) {
   1465e:	55                   	push   %ebp
   1465f:	89 e5                	mov    %esp,%ebp
   14661:	83 ec 14             	sub    $0x14,%esp
   14664:	8b 45 08             	mov    0x8(%ebp),%eax
   14667:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   1466a:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14671:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to enable

	if( which & SIO_TX ) {
   14674:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14678:	83 e0 01             	and    $0x1,%eax
   1467b:	85 c0                	test   %eax,%eax
   1467d:	74 0f                	je     1468e <sio_enable+0x30>
		ier |= UA4_IER_TX_IE;
   1467f:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14686:	83 c8 02             	or     $0x2,%eax
   14689:	a2 b0 b2 01 00       	mov    %al,0x1b2b0
	}

	if( which & SIO_RX ) {
   1468e:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14692:	83 e0 02             	and    $0x2,%eax
   14695:	85 c0                	test   %eax,%eax
   14697:	74 0f                	je     146a8 <sio_enable+0x4a>
		ier |= UA4_IER_RX_IE;
   14699:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   146a0:	83 c8 01             	or     $0x1,%eax
   146a3:	a2 b0 b2 01 00       	mov    %al,0x1b2b0
	}

	// if there was a change, make it

	if( old != ier ) {
   146a8:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   146af:	38 45 ff             	cmp    %al,-0x1(%ebp)
   146b2:	74 1d                	je     146d1 <sio_enable+0x73>
		outb( UA4_IER, ier );
   146b4:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   146bb:	0f b6 c0             	movzbl %al,%eax
   146be:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   146c5:	88 45 f7             	mov    %al,-0x9(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   146c8:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   146cc:	8b 55 f8             	mov    -0x8(%ebp),%edx
   146cf:	ee                   	out    %al,(%dx)
}
   146d0:	90                   	nop
	}

	// return the prior settings

	return( old );
   146d1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   146d5:	c9                   	leave  
   146d6:	c3                   	ret    

000146d7 <sio_disable>:
**
** @param[in] which   Bit mask indicating which interrupt(s) to disable
**
** @return the prior IER setting
*/
uint8_t sio_disable( uint8_t which ) {
   146d7:	55                   	push   %ebp
   146d8:	89 e5                	mov    %esp,%ebp
   146da:	83 ec 14             	sub    $0x14,%esp
   146dd:	8b 45 08             	mov    0x8(%ebp),%eax
   146e0:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   146e3:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   146ea:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to disable

	if( which & SIO_TX ) {
   146ed:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   146f1:	83 e0 01             	and    $0x1,%eax
   146f4:	85 c0                	test   %eax,%eax
   146f6:	74 0f                	je     14707 <sio_disable+0x30>
		ier &= ~UA4_IER_TX_IE;
   146f8:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   146ff:	83 e0 fd             	and    $0xfffffffd,%eax
   14702:	a2 b0 b2 01 00       	mov    %al,0x1b2b0
	}

	if( which & SIO_RX ) {
   14707:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   1470b:	83 e0 02             	and    $0x2,%eax
   1470e:	85 c0                	test   %eax,%eax
   14710:	74 0f                	je     14721 <sio_disable+0x4a>
		ier &= ~UA4_IER_RX_IE;
   14712:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14719:	83 e0 fe             	and    $0xfffffffe,%eax
   1471c:	a2 b0 b2 01 00       	mov    %al,0x1b2b0
	}

	// if there was a change, make it

	if( old != ier ) {
   14721:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14728:	38 45 ff             	cmp    %al,-0x1(%ebp)
   1472b:	74 1d                	je     1474a <sio_disable+0x73>
		outb( UA4_IER, ier );
   1472d:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14734:	0f b6 c0             	movzbl %al,%eax
   14737:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   1473e:	88 45 f7             	mov    %al,-0x9(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14741:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   14745:	8b 55 f8             	mov    -0x8(%ebp),%edx
   14748:	ee                   	out    %al,(%dx)
}
   14749:	90                   	nop
	}

	// return the prior settings

	return( old );
   1474a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   1474e:	c9                   	leave  
   1474f:	c3                   	ret    

00014750 <sio_flush>:
**
** Flush the SIO input and/or output.
**
** @param[in] which  Bit mask indicating which queue(s) to flush.
*/
void sio_flush( uint8_t which ) {
   14750:	55                   	push   %ebp
   14751:	89 e5                	mov    %esp,%ebp
   14753:	83 ec 24             	sub    $0x24,%esp
   14756:	8b 45 08             	mov    0x8(%ebp),%eax
   14759:	88 45 dc             	mov    %al,-0x24(%ebp)

	if( (which & SIO_RX) != 0 ) {
   1475c:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   14760:	83 e0 02             	and    $0x2,%eax
   14763:	85 c0                	test   %eax,%eax
   14765:	74 69                	je     147d0 <sio_flush+0x80>
		// empty the queue
		incount = 0;
   14767:	c7 05 88 ae 01 00 00 	movl   $0x0,0x1ae88
   1476e:	00 00 00 
		inlast = innext = inbuffer;
   14771:	c7 05 84 ae 01 00 80 	movl   $0x1aa80,0x1ae84
   14778:	aa 01 00 
   1477b:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   14780:	a3 80 ae 01 00       	mov    %eax,0x1ae80
   14785:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1478c:	8b 45 f8             	mov    -0x8(%ebp),%eax
   1478f:	89 c2                	mov    %eax,%edx
   14791:	ec                   	in     (%dx),%al
   14792:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
   14795:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax

		// discard any characters in the receiver FIFO
		uint8_t lsr = inb( UA4_LSR );
   14799:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   1479c:	eb 27                	jmp    147c5 <sio_flush+0x75>
   1479e:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   147a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   147a8:	89 c2                	mov    %eax,%edx
   147aa:	ec                   	in     (%dx),%al
   147ab:	88 45 e7             	mov    %al,-0x19(%ebp)
   147ae:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
   147b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   147b8:	89 c2                	mov    %eax,%edx
   147ba:	ec                   	in     (%dx),%al
   147bb:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
   147be:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
			(void) inb( UA4_RXD );
			lsr = inb( UA4_LSR );
   147c2:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   147c5:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
   147c9:	83 e0 01             	and    $0x1,%eax
   147cc:	85 c0                	test   %eax,%eax
   147ce:	75 ce                	jne    1479e <sio_flush+0x4e>
		}
	}

	if( (which & SIO_TX) != 0 ) {
   147d0:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   147d4:	83 e0 01             	and    $0x1,%eax
   147d7:	85 c0                	test   %eax,%eax
   147d9:	74 28                	je     14803 <sio_flush+0xb3>
		// empty the queue
		outcount = 0;
   147db:	c7 05 a8 b2 01 00 00 	movl   $0x0,0x1b2a8
   147e2:	00 00 00 
		outlast = outnext = outbuffer;
   147e5:	c7 05 a4 b2 01 00 a0 	movl   $0x1aea0,0x1b2a4
   147ec:	ae 01 00 
   147ef:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   147f4:	a3 a0 b2 01 00       	mov    %eax,0x1b2a0

		// terminate any in-progress send operation
		sending = 0;
   147f9:	c7 05 ac b2 01 00 00 	movl   $0x0,0x1b2ac
   14800:	00 00 00 
	}
}
   14803:	90                   	nop
   14804:	c9                   	leave  
   14805:	c3                   	ret    

00014806 <sio_inq_length>:
**
** usage:    int num = sio_inq_length()
**
** @return the count of characters still in the input queue
*/
int sio_inq_length( void ) {
   14806:	55                   	push   %ebp
   14807:	89 e5                	mov    %esp,%ebp
	return( incount );
   14809:	a1 88 ae 01 00       	mov    0x1ae88,%eax
}
   1480e:	5d                   	pop    %ebp
   1480f:	c3                   	ret    

00014810 <sio_readc>:
**
** usage:    int ch = sio_readc()
**
** @return the next character, or -1 if no character is available
*/
int sio_readc( void ) {
   14810:	55                   	push   %ebp
   14811:	89 e5                	mov    %esp,%ebp
   14813:	83 ec 10             	sub    $0x10,%esp
	int ch;

	// assume there is no character available
	ch = -1;
   14816:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	// 
	// If there is a character, return it
	//

	if( incount > 0 ) {
   1481d:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14822:	85 c0                	test   %eax,%eax
   14824:	74 46                	je     1486c <sio_readc+0x5c>

		// take it out of the input buffer
		ch = ((int)(*innext++)) & 0xff;
   14826:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   1482b:	8d 50 01             	lea    0x1(%eax),%edx
   1482e:	89 15 84 ae 01 00    	mov    %edx,0x1ae84
   14834:	0f b6 00             	movzbl (%eax),%eax
   14837:	0f be c0             	movsbl %al,%eax
   1483a:	25 ff 00 00 00       	and    $0xff,%eax
   1483f:	89 45 fc             	mov    %eax,-0x4(%ebp)
		--incount;
   14842:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14847:	83 e8 01             	sub    $0x1,%eax
   1484a:	a3 88 ae 01 00       	mov    %eax,0x1ae88

		// reset the buffer variables if this was the last one
		if( incount < 1 ) {
   1484f:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14854:	85 c0                	test   %eax,%eax
   14856:	75 14                	jne    1486c <sio_readc+0x5c>
			inlast = innext = inbuffer;
   14858:	c7 05 84 ae 01 00 80 	movl   $0x1aa80,0x1ae84
   1485f:	aa 01 00 
   14862:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   14867:	a3 80 ae 01 00       	mov    %eax,0x1ae80
		}

	}

	return( ch );
   1486c:	8b 45 fc             	mov    -0x4(%ebp),%eax

}
   1486f:	c9                   	leave  
   14870:	c3                   	ret    

00014871 <sio_read>:
** @param[in]  length  Length of the buffer
**
** @return the number of bytes copied, or 0 if no characters were available
*/

int sio_read( char *buf, int length ) {
   14871:	55                   	push   %ebp
   14872:	89 e5                	mov    %esp,%ebp
   14874:	83 ec 10             	sub    $0x10,%esp
	char *ptr = buf;
   14877:	8b 45 08             	mov    0x8(%ebp),%eax
   1487a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	int copied = 0;
   1487d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// if there are no characters, just return 0

	if( incount < 1 ) {
   14884:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14889:	85 c0                	test   %eax,%eax
   1488b:	75 4c                	jne    148d9 <sio_read+0x68>
		return( 0 );
   1488d:	b8 00 00 00 00       	mov    $0x0,%eax
   14892:	eb 76                	jmp    1490a <sio_read+0x99>
	// We have characters.  Copy as many of them into the user
	// buffer as will fit.
	//

	while( incount > 0 && copied < length ) {
		*ptr++ = *innext++ & 0xff;
   14894:	8b 15 84 ae 01 00    	mov    0x1ae84,%edx
   1489a:	8d 42 01             	lea    0x1(%edx),%eax
   1489d:	a3 84 ae 01 00       	mov    %eax,0x1ae84
   148a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
   148a5:	8d 48 01             	lea    0x1(%eax),%ecx
   148a8:	89 4d fc             	mov    %ecx,-0x4(%ebp)
   148ab:	0f b6 12             	movzbl (%edx),%edx
   148ae:	88 10                	mov    %dl,(%eax)
		if( innext > (inbuffer + BUF_SIZE) ) {
   148b0:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   148b5:	ba 80 ae 01 00       	mov    $0x1ae80,%edx
   148ba:	39 d0                	cmp    %edx,%eax
   148bc:	76 0a                	jbe    148c8 <sio_read+0x57>
			innext = inbuffer;
   148be:	c7 05 84 ae 01 00 80 	movl   $0x1aa80,0x1ae84
   148c5:	aa 01 00 
		}
		--incount;
   148c8:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   148cd:	83 e8 01             	sub    $0x1,%eax
   148d0:	a3 88 ae 01 00       	mov    %eax,0x1ae88
		++copied;
   148d5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
	while( incount > 0 && copied < length ) {
   148d9:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   148de:	85 c0                	test   %eax,%eax
   148e0:	74 08                	je     148ea <sio_read+0x79>
   148e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
   148e5:	3b 45 0c             	cmp    0xc(%ebp),%eax
   148e8:	7c aa                	jl     14894 <sio_read+0x23>
	}

	// reset the input buffer if necessary

	if( incount < 1 ) {
   148ea:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   148ef:	85 c0                	test   %eax,%eax
   148f1:	75 14                	jne    14907 <sio_read+0x96>
		inlast = innext = inbuffer;
   148f3:	c7 05 84 ae 01 00 80 	movl   $0x1aa80,0x1ae84
   148fa:	aa 01 00 
   148fd:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   14902:	a3 80 ae 01 00       	mov    %eax,0x1ae80
	}

	// return the copy count

	return( copied );
   14907:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   1490a:	c9                   	leave  
   1490b:	c3                   	ret    

0001490c <sio_writec>:
**
** usage:    sio_writec( int ch )
**
** @param[in] ch   Character to be written (in the low-order 8 bits)
*/
void sio_writec( int ch ){
   1490c:	55                   	push   %ebp
   1490d:	89 e5                	mov    %esp,%ebp
   1490f:	83 ec 18             	sub    $0x18,%esp

	//
	// Must do LF -> CRLF mapping
	//

	if( ch == '\n' ) {
   14912:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
   14916:	75 0d                	jne    14925 <sio_writec+0x19>
		sio_writec( '\r' );
   14918:	83 ec 0c             	sub    $0xc,%esp
   1491b:	6a 0d                	push   $0xd
   1491d:	e8 ea ff ff ff       	call   1490c <sio_writec>
   14922:	83 c4 10             	add    $0x10,%esp

	//
	// If we're currently transmitting, just add this to the buffer
	//

	if( sending ) {
   14925:	a1 ac b2 01 00       	mov    0x1b2ac,%eax
   1492a:	85 c0                	test   %eax,%eax
   1492c:	74 22                	je     14950 <sio_writec+0x44>
		*outlast++ = ch;
   1492e:	a1 a0 b2 01 00       	mov    0x1b2a0,%eax
   14933:	8d 50 01             	lea    0x1(%eax),%edx
   14936:	89 15 a0 b2 01 00    	mov    %edx,0x1b2a0
   1493c:	8b 55 08             	mov    0x8(%ebp),%edx
   1493f:	88 10                	mov    %dl,(%eax)
		++outcount;
   14941:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   14946:	83 c0 01             	add    $0x1,%eax
   14949:	a3 a8 b2 01 00       	mov    %eax,0x1b2a8
		return;
   1494e:	eb 30                	jmp    14980 <sio_writec+0x74>

	//
	// Not sending - must prime the pump
	//

	sending = 1;
   14950:	c7 05 ac b2 01 00 01 	movl   $0x1,0x1b2ac
   14957:	00 00 00 
	outb( UA4_TXD, ch );
   1495a:	8b 45 08             	mov    0x8(%ebp),%eax
   1495d:	0f b6 c0             	movzbl %al,%eax
   14960:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
   14967:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1496a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1496e:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14971:	ee                   	out    %al,(%dx)
}
   14972:	90                   	nop

	// Also must enable transmitter interrupts

	sio_enable( SIO_TX );
   14973:	83 ec 0c             	sub    $0xc,%esp
   14976:	6a 01                	push   $0x1
   14978:	e8 e1 fc ff ff       	call   1465e <sio_enable>
   1497d:	83 c4 10             	add    $0x10,%esp

}
   14980:	c9                   	leave  
   14981:	c3                   	ret    

00014982 <sio_write>:
** @param[out] buffer   Buffer containing characters to write
** @param[in]  length   Number of characters to write
**
** @return the number of characters copied into the SIO output buffer
*/
int sio_write( const char *buffer, int length ) {
   14982:	55                   	push   %ebp
   14983:	89 e5                	mov    %esp,%ebp
   14985:	83 ec 18             	sub    $0x18,%esp
	int first = *buffer;
   14988:	8b 45 08             	mov    0x8(%ebp),%eax
   1498b:	0f b6 00             	movzbl (%eax),%eax
   1498e:	0f be c0             	movsbl %al,%eax
   14991:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *ptr = buffer;
   14994:	8b 45 08             	mov    0x8(%ebp),%eax
   14997:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int copied = 0;
   1499a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	// the characters to the output buffer; else, we want
	// to append all but the first character, and then use
	// sio_writec() to send the first one out.
	//

	if( !sending ) {
   149a1:	a1 ac b2 01 00       	mov    0x1b2ac,%eax
   149a6:	85 c0                	test   %eax,%eax
   149a8:	75 4f                	jne    149f9 <sio_write+0x77>
		ptr += 1;
   149aa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		copied++;
   149ae:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	}

	while( copied < length && outcount < BUF_SIZE ) {
   149b2:	eb 45                	jmp    149f9 <sio_write+0x77>
		*outlast++ = *ptr++;
   149b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149b7:	8d 42 01             	lea    0x1(%edx),%eax
   149ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
   149bd:	a1 a0 b2 01 00       	mov    0x1b2a0,%eax
   149c2:	8d 48 01             	lea    0x1(%eax),%ecx
   149c5:	89 0d a0 b2 01 00    	mov    %ecx,0x1b2a0
   149cb:	0f b6 12             	movzbl (%edx),%edx
   149ce:	88 10                	mov    %dl,(%eax)
		// wrap around if necessary
		if( outlast >= (outbuffer + BUF_SIZE) ) {
   149d0:	a1 a0 b2 01 00       	mov    0x1b2a0,%eax
   149d5:	ba a0 b2 01 00       	mov    $0x1b2a0,%edx
   149da:	39 d0                	cmp    %edx,%eax
   149dc:	72 0a                	jb     149e8 <sio_write+0x66>
			outlast = outbuffer;
   149de:	c7 05 a0 b2 01 00 a0 	movl   $0x1aea0,0x1b2a0
   149e5:	ae 01 00 
		}
		++outcount;
   149e8:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   149ed:	83 c0 01             	add    $0x1,%eax
   149f0:	a3 a8 b2 01 00       	mov    %eax,0x1b2a8
		++copied;
   149f5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	while( copied < length && outcount < BUF_SIZE ) {
   149f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149fc:	3b 45 0c             	cmp    0xc(%ebp),%eax
   149ff:	7d 0c                	jge    14a0d <sio_write+0x8b>
   14a01:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   14a06:	3d ff 03 00 00       	cmp    $0x3ff,%eax
   14a0b:	76 a7                	jbe    149b4 <sio_write+0x32>
	// We use sio_writec() to send out the first character,
	// as it will correctly set all the other necessary
	// variables for us.
	//

	if( !sending ) {
   14a0d:	a1 ac b2 01 00       	mov    0x1b2ac,%eax
   14a12:	85 c0                	test   %eax,%eax
   14a14:	75 0e                	jne    14a24 <sio_write+0xa2>
		sio_writec( first );
   14a16:	83 ec 0c             	sub    $0xc,%esp
   14a19:	ff 75 ec             	push   -0x14(%ebp)
   14a1c:	e8 eb fe ff ff       	call   1490c <sio_writec>
   14a21:	83 c4 10             	add    $0x10,%esp
	}

	// Return the transfer count


	return( copied );
   14a24:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
   14a27:	c9                   	leave  
   14a28:	c3                   	ret    

00014a29 <sio_puts>:
**
** @param[in] buffer  The buffer containing a NUL-terminated string
**
** @return the count of bytes transferred
*/
int sio_puts( const char *buffer ) {
   14a29:	55                   	push   %ebp
   14a2a:	89 e5                	mov    %esp,%ebp
   14a2c:	83 ec 18             	sub    $0x18,%esp
	int n;  // must be outside the loop so we can return it

	n = SLENGTH( buffer );
   14a2f:	83 ec 0c             	sub    $0xc,%esp
   14a32:	ff 75 08             	push   0x8(%ebp)
   14a35:	e8 6b 20 00 00       	call   16aa5 <strlen>
   14a3a:	83 c4 10             	add    $0x10,%esp
   14a3d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	sio_write( buffer, n );
   14a40:	83 ec 08             	sub    $0x8,%esp
   14a43:	ff 75 f4             	push   -0xc(%ebp)
   14a46:	ff 75 08             	push   0x8(%ebp)
   14a49:	e8 34 ff ff ff       	call   14982 <sio_write>
   14a4e:	83 c4 10             	add    $0x10,%esp

	return( n );
   14a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   14a54:	c9                   	leave  
   14a55:	c3                   	ret    

00014a56 <sio_putchar>:
**
** Operates by calling sio_write() with a length of 1
**
** @param ch  The character to print
*/
void sio_putchar( unsigned int ch ) {
   14a56:	55                   	push   %ebp
   14a57:	89 e5                	mov    %esp,%ebp
   14a59:	83 ec 18             	sub    $0x18,%esp
	char buf[2] = "x";
   14a5c:	66 c7 45 f6 78 00    	movw   $0x78,-0xa(%ebp)
	buf[0] = ch;
   14a62:	8b 45 08             	mov    0x8(%ebp),%eax
   14a65:	88 45 f6             	mov    %al,-0xa(%ebp)
	sio_write( buf, 1 );
   14a68:	83 ec 08             	sub    $0x8,%esp
   14a6b:	6a 01                	push   $0x1
   14a6d:	8d 45 f6             	lea    -0xa(%ebp),%eax
   14a70:	50                   	push   %eax
   14a71:	e8 0c ff ff ff       	call   14982 <sio_write>
   14a76:	83 c4 10             	add    $0x10,%esp
}
   14a79:	90                   	nop
   14a7a:	c9                   	leave  
   14a7b:	c3                   	ret    

00014a7c <sio_dump>:
** @param[in] full   Boolean indicating whether or not a "full" dump
**                   is being requested (which includes the contents
**                   of the queues)
*/

void sio_dump( bool_t full ) {
   14a7c:	55                   	push   %ebp
   14a7d:	89 e5                	mov    %esp,%ebp
   14a7f:	57                   	push   %edi
   14a80:	56                   	push   %esi
   14a81:	53                   	push   %ebx
   14a82:	83 ec 2c             	sub    $0x2c,%esp
   14a85:	8b 45 08             	mov    0x8(%ebp),%eax
   14a88:	88 45 d4             	mov    %al,-0x2c(%ebp)
	int n;
	char *ptr;

	// dump basic info into the status region

	cio_printf_at( 48, 0,
   14a8b:	8b 0d a8 b2 01 00    	mov    0x1b2a8,%ecx
   14a91:	8b 15 88 ae 01 00    	mov    0x1ae88,%edx
		"SIO: IER %02x (%c%c%c) in %d ot %d",
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
			(ier & UA4_IER_RX_IE) ? 'R' : 'r',
   14a97:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14a9e:	0f b6 c0             	movzbl %al,%eax
   14aa1:	83 e0 01             	and    $0x1,%eax
	cio_printf_at( 48, 0,
   14aa4:	85 c0                	test   %eax,%eax
   14aa6:	74 07                	je     14aaf <sio_dump+0x33>
   14aa8:	bf 52 00 00 00       	mov    $0x52,%edi
   14aad:	eb 05                	jmp    14ab4 <sio_dump+0x38>
   14aaf:	bf 72 00 00 00       	mov    $0x72,%edi
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
   14ab4:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14abb:	0f b6 c0             	movzbl %al,%eax
   14abe:	83 e0 02             	and    $0x2,%eax
	cio_printf_at( 48, 0,
   14ac1:	85 c0                	test   %eax,%eax
   14ac3:	74 07                	je     14acc <sio_dump+0x50>
   14ac5:	be 54 00 00 00       	mov    $0x54,%esi
   14aca:	eb 05                	jmp    14ad1 <sio_dump+0x55>
   14acc:	be 74 00 00 00       	mov    $0x74,%esi
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
   14ad1:	a1 ac b2 01 00       	mov    0x1b2ac,%eax
	cio_printf_at( 48, 0,
   14ad6:	85 c0                	test   %eax,%eax
   14ad8:	74 07                	je     14ae1 <sio_dump+0x65>
   14ada:	bb 2a 00 00 00       	mov    $0x2a,%ebx
   14adf:	eb 05                	jmp    14ae6 <sio_dump+0x6a>
   14ae1:	bb 2e 00 00 00       	mov    $0x2e,%ebx
   14ae6:	0f b6 05 b0 b2 01 00 	movzbl 0x1b2b0,%eax
   14aed:	0f b6 c0             	movzbl %al,%eax
   14af0:	83 ec 0c             	sub    $0xc,%esp
   14af3:	51                   	push   %ecx
   14af4:	52                   	push   %edx
   14af5:	57                   	push   %edi
   14af6:	56                   	push   %esi
   14af7:	53                   	push   %ebx
   14af8:	50                   	push   %eax
   14af9:	68 90 7e 01 00       	push   $0x17e90
   14afe:	6a 00                	push   $0x0
   14b00:	6a 30                	push   $0x30
   14b02:	e8 e0 cb ff ff       	call   116e7 <cio_printf_at>
   14b07:	83 c4 30             	add    $0x30,%esp
			incount, outcount );

	// if we're not doing a full dump, stop now

	if( !full ) {
   14b0a:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
   14b0e:	0f 84 dc 00 00 00    	je     14bf0 <sio_dump+0x174>
	}

	// also want the queue contents, but we'll
	// dump them into the scrolling region

	if( incount ) {
   14b14:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14b19:	85 c0                	test   %eax,%eax
   14b1b:	74 5c                	je     14b79 <sio_dump+0xfd>
		cio_puts( "SIO input queue: \"" );
   14b1d:	83 ec 0c             	sub    $0xc,%esp
   14b20:	68 b3 7e 01 00       	push   $0x17eb3
   14b25:	e8 65 c5 ff ff       	call   1108f <cio_puts>
   14b2a:	83 c4 10             	add    $0x10,%esp
		ptr = innext; 
   14b2d:	a1 84 ae 01 00       	mov    0x1ae84,%eax
   14b32:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < incount; ++n ) {
   14b35:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   14b3c:	eb 1f                	jmp    14b5d <sio_dump+0xe1>
			put_char_or_code( *ptr++ );
   14b3e:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14b41:	8d 50 01             	lea    0x1(%eax),%edx
   14b44:	89 55 e0             	mov    %edx,-0x20(%ebp)
   14b47:	0f b6 00             	movzbl (%eax),%eax
   14b4a:	0f be c0             	movsbl %al,%eax
   14b4d:	83 ec 0c             	sub    $0xc,%esp
   14b50:	50                   	push   %eax
   14b51:	e8 47 16 00 00       	call   1619d <put_char_or_code>
   14b56:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < incount; ++n ) {
   14b59:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   14b5d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14b60:	a1 88 ae 01 00       	mov    0x1ae88,%eax
   14b65:	39 c2                	cmp    %eax,%edx
   14b67:	72 d5                	jb     14b3e <sio_dump+0xc2>
		}
		cio_puts( "\"\n" );
   14b69:	83 ec 0c             	sub    $0xc,%esp
   14b6c:	68 c6 7e 01 00       	push   $0x17ec6
   14b71:	e8 19 c5 ff ff       	call   1108f <cio_puts>
   14b76:	83 c4 10             	add    $0x10,%esp
	}

	if( outcount ) {
   14b79:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   14b7e:	85 c0                	test   %eax,%eax
   14b80:	74 6f                	je     14bf1 <sio_dump+0x175>
		cio_puts( "SIO output queue: \"" );
   14b82:	83 ec 0c             	sub    $0xc,%esp
   14b85:	68 c9 7e 01 00       	push   $0x17ec9
   14b8a:	e8 00 c5 ff ff       	call   1108f <cio_puts>
   14b8f:	83 c4 10             	add    $0x10,%esp
		cio_puts( " ot: \"" );
   14b92:	83 ec 0c             	sub    $0xc,%esp
   14b95:	68 dd 7e 01 00       	push   $0x17edd
   14b9a:	e8 f0 c4 ff ff       	call   1108f <cio_puts>
   14b9f:	83 c4 10             	add    $0x10,%esp
		ptr = outnext; 
   14ba2:	a1 a4 b2 01 00       	mov    0x1b2a4,%eax
   14ba7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < outcount; ++n )  {
   14baa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   14bb1:	eb 1f                	jmp    14bd2 <sio_dump+0x156>
			put_char_or_code( *ptr++ );
   14bb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14bb6:	8d 50 01             	lea    0x1(%eax),%edx
   14bb9:	89 55 e0             	mov    %edx,-0x20(%ebp)
   14bbc:	0f b6 00             	movzbl (%eax),%eax
   14bbf:	0f be c0             	movsbl %al,%eax
   14bc2:	83 ec 0c             	sub    $0xc,%esp
   14bc5:	50                   	push   %eax
   14bc6:	e8 d2 15 00 00       	call   1619d <put_char_or_code>
   14bcb:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < outcount; ++n )  {
   14bce:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   14bd2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14bd5:	a1 a8 b2 01 00       	mov    0x1b2a8,%eax
   14bda:	39 c2                	cmp    %eax,%edx
   14bdc:	72 d5                	jb     14bb3 <sio_dump+0x137>
		}
		cio_puts( "\"\n" );
   14bde:	83 ec 0c             	sub    $0xc,%esp
   14be1:	68 c6 7e 01 00       	push   $0x17ec6
   14be6:	e8 a4 c4 ff ff       	call   1108f <cio_puts>
   14beb:	83 c4 10             	add    $0x10,%esp
   14bee:	eb 01                	jmp    14bf1 <sio_dump+0x175>
		return;
   14bf0:	90                   	nop
	}
}
   14bf1:	8d 65 f4             	lea    -0xc(%ebp),%esp
   14bf4:	5b                   	pop    %ebx
   14bf5:	5e                   	pop    %esi
   14bf6:	5f                   	pop    %edi
   14bf7:	5d                   	pop    %ebp
   14bf8:	c3                   	ret    

00014bf9 <stk_init>:
** Dependencies:
**    Cannot be called before kmem is initialized (if using dynamic alloc)
**    Must be called before interrupt handling has begun
**    Must be called before any process creation can be done
*/
void stk_init( void ) {
   14bf9:	55                   	push   %ebp
   14bfa:	89 e5                	mov    %esp,%ebp
   14bfc:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Stk" );
   14bff:	83 ec 0c             	sub    $0xc,%esp
   14c02:	68 ec 7e 01 00       	push   $0x17eec
   14c07:	e8 83 c4 ff ff       	call   1108f <cio_puts>
   14c0c:	83 c4 10             	add    $0x10,%esp
#endif

	// reset the "free stacks" pool
	free_stacks = NULL;
   14c0f:	c7 05 bc b2 01 00 00 	movl   $0x0,0x1b2bc
   14c16:	00 00 00 
		stk_dealloc( &stackset[i] );
	}
#endif

	// allocate the kernel stack
	assert( stk_alloc(&kstack) == E_SUCCESS );
   14c19:	83 ec 0c             	sub    $0xc,%esp
   14c1c:	68 b4 b2 01 00       	push   $0x1b2b4
   14c21:	e8 4f 00 00 00       	call   14c75 <stk_alloc>
   14c26:	83 c4 10             	add    $0x10,%esp
   14c29:	85 c0                	test   %eax,%eax
   14c2b:	74 36                	je     14c63 <stk_init+0x6a>
   14c2d:	83 ec 08             	sub    $0x8,%esp
   14c30:	68 f4 7e 01 00       	push   $0x17ef4
   14c35:	6a 75                	push   $0x75
   14c37:	68 14 7f 01 00       	push   $0x17f14
   14c3c:	68 98 7f 01 00       	push   $0x17f98
   14c41:	68 24 7f 01 00       	push   $0x17f24
   14c46:	68 20 a4 01 00       	push   $0x1a420
   14c4b:	e8 aa 1b 00 00       	call   167fa <sprint>
   14c50:	83 c4 20             	add    $0x20,%esp
   14c53:	83 ec 0c             	sub    $0xc,%esp
   14c56:	68 20 a4 01 00       	push   $0x1a420
   14c5b:	e8 61 16 00 00       	call   162c1 <kpanic>
   14c60:	83 c4 10             	add    $0x10,%esp

	// initial kernel stack pointer points to last word of stack
	kesp = kstack + STACK_WDS - 1;
   14c63:	a1 b4 b2 01 00       	mov    0x1b2b4,%eax
   14c68:	05 fc 1f 00 00       	add    $0x1ffc,%eax
   14c6d:	a3 b8 b2 01 00       	mov    %eax,0x1b2b8
}
   14c72:	90                   	nop
   14c73:	c9                   	leave  
   14c74:	c3                   	ret    

00014c75 <stk_alloc>:
**
** @param stk   A pointer to where the address of the stack is returned
**
** @return The status of the allocation attempt
*/
int stk_alloc( uint32_t **stk ) {
   14c75:	55                   	push   %ebp
   14c76:	89 e5                	mov    %esp,%ebp
   14c78:	83 ec 18             	sub    $0x18,%esp

#if TRACING_STACK
	cio_puts( "stk_alloc()\n" );
#endif

	if( free_stacks == NULL ) {
   14c7b:	a1 bc b2 01 00       	mov    0x1b2bc,%eax
   14c80:	85 c0                	test   %eax,%eax
   14c82:	75 12                	jne    14c96 <stk_alloc+0x21>
		// this is a serious problem if we're not using
		// dynamic allocation of stack space!
		kpanic( "stk_alloc: no more static stacks!!!" );
#else
		// must allocate a new stack
		new = (uint32_t *) km_page_alloc( STACK_PAGES );
   14c84:	83 ec 0c             	sub    $0xc,%esp
   14c87:	6a 02                	push   $0x2
   14c89:	e8 ee d9 ff ff       	call   1267c <km_page_alloc>
   14c8e:	83 c4 10             	add    $0x10,%esp
   14c91:	89 45 f4             	mov    %eax,-0xc(%ebp)
   14c94:	eb 18                	jmp    14cae <stk_alloc+0x39>
#endif

	} else {

		// can re-use an existing stack
		list_t *tmp = free_stacks;
   14c96:	a1 bc b2 01 00       	mov    0x1b2bc,%eax
   14c9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
		free_stacks = tmp->next;
   14c9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14ca1:	8b 00                	mov    (%eax),%eax
   14ca3:	a3 bc b2 01 00       	mov    %eax,0x1b2bc
		new = (uint32_t *) tmp;
   14ca8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14cab:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// if we succeeded, clean up the space for the caller
	if( new != NULL ) {
   14cae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14cb2:	74 1b                	je     14ccf <stk_alloc+0x5a>
		memclr( new, SZ_STACK );
   14cb4:	83 ec 08             	sub    $0x8,%esp
   14cb7:	68 00 20 00 00       	push   $0x2000
   14cbc:	ff 75 f4             	push   -0xc(%ebp)
   14cbf:	e8 6a 1a 00 00       	call   1672e <memclr>
   14cc4:	83 c4 10             	add    $0x10,%esp
		*stk = new;
   14cc7:	8b 45 08             	mov    0x8(%ebp),%eax
   14cca:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14ccd:	89 10                	mov    %edx,(%eax)
	}

	// return the proper stack

	return new != NULL ? E_SUCCESS : E_FAILURE;
   14ccf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14cd3:	0f 94 c0             	sete   %al
   14cd6:	0f b6 c0             	movzbl %al,%eax
}
   14cd9:	c9                   	leave  
   14cda:	c3                   	ret    

00014cdb <stk_free>:
**
** Note: this works regardless of whether or not we're dynamically
** allocating our stack space.
*/
void stk_free( uint32_t *stk )
{
   14cdb:	55                   	push   %ebp
   14cdc:	89 e5                	mov    %esp,%ebp
   14cde:	83 ec 18             	sub    $0x18,%esp
	// TODO
	cio_printf( "stk_free(%08x)\n", (uint32_t) stk );
#endif

	// sanity check
	assert1( stk != NULL );
   14ce1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14ce5:	75 39                	jne    14d20 <stk_free+0x45>
   14ce7:	83 ec 08             	sub    $0x8,%esp
   14cea:	68 47 7f 01 00       	push   $0x17f47
   14cef:	68 be 00 00 00       	push   $0xbe
   14cf4:	68 14 7f 01 00       	push   $0x17f14
   14cf9:	68 a4 7f 01 00       	push   $0x17fa4
   14cfe:	68 54 7f 01 00       	push   $0x17f54
   14d03:	68 20 a4 01 00       	push   $0x1a420
   14d08:	e8 ed 1a 00 00       	call   167fa <sprint>
   14d0d:	83 c4 20             	add    $0x20,%esp
   14d10:	83 ec 0c             	sub    $0xc,%esp
   14d13:	68 20 a4 01 00       	push   $0x1a420
   14d18:	e8 a4 15 00 00       	call   162c1 <kpanic>
   14d1d:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *) stk;
   14d20:	8b 45 08             	mov    0x8(%ebp),%eax
   14d23:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// link it into the free list
	tmp->next = free_stacks;
   14d26:	8b 15 bc b2 01 00    	mov    0x1b2bc,%edx
   14d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14d2f:	89 10                	mov    %edx,(%eax)
	free_stacks = tmp;
   14d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14d34:	a3 bc b2 01 00       	mov    %eax,0x1b2bc
}
   14d39:	90                   	nop
   14d3a:	c9                   	leave  
   14d3b:	c3                   	ret    

00014d3c <stk_setup>:
** @param entry  - Entry point for the new process
** @param args   - Argument vector to be put in place
**
** @return A pointer to the context_t on the stack, or NULL
*/
context_t *stk_setup( uint32_t *stk, uint32_t entry, const char *args ) {
   14d3c:	55                   	push   %ebp
   14d3d:	89 e5                	mov    %esp,%ebp
   14d3f:	83 ec 28             	sub    $0x28,%esp
	/*
	** First, calculate the space we'll need for all this stuff.
	*/

	// total number of words we need - start with a 0 at the end
	uint32_t totwords = 1;
   14d42:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)

	// number of bytes in the arg string
	uint32_t argbytes = (uint32_t) strlen( args ) + 1;
   14d49:	83 ec 0c             	sub    $0xc,%esp
   14d4c:	ff 75 10             	push   0x10(%ebp)
   14d4f:	e8 51 1d 00 00       	call   16aa5 <strlen>
   14d54:	83 c4 10             	add    $0x10,%esp
   14d57:	83 c0 01             	add    $0x1,%eax
   14d5a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
   14d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d60:	83 c0 03             	add    $0x3,%eax
   14d63:	83 e0 fc             	and    $0xfffffffc,%eax
   14d66:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32_t argwords = DIV4(argbytes);
   14d69:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d6c:	c1 e8 02             	shr    $0x2,%eax
   14d6f:	89 45 ec             	mov    %eax,-0x14(%ebp)

	totwords += argwords;
   14d72:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14d75:	01 45 f4             	add    %eax,-0xc(%ebp)

	// also need one word for the arg pointer
	totwords += 1;
   14d78:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	** following it is page-aligned. We need to back up from there
	** to figure out where the arg pointer will go, and then adjust
	** that address so that it's at a multiple of 16.
	*/

	uint32_t *stackend = stk + STACK_WDS; // pointer arithmetic roolz!
   14d7c:	8b 45 08             	mov    0x8(%ebp),%eax
   14d7f:	05 00 20 00 00       	add    $0x2000,%eax
   14d84:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// back up
	uint32_t *avptr = stackend - totwords;
   14d87:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14d8a:	c1 e0 02             	shl    $0x2,%eax
   14d8d:	f7 d8                	neg    %eax
   14d8f:	89 c2                	mov    %eax,%edx
   14d91:	8b 45 e8             	mov    -0x18(%ebp),%eax
   14d94:	01 d0                	add    %edx,%eax
   14d96:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// back up to multiple-of-16 address
	avptr = (uint32_t *) ( (uint32_t) avptr & MOD16_MASK);
   14d99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14d9c:	83 e0 f0             	and    $0xfffffff0,%eax
   14d9f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	** SURE THAT ASSUMPTION STILL HOLDS TRUE.
    ********************************************************************
	*/

	// assign the arg pointer
	*avptr = (uint32_t) (avptr + 1);
   14da2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14da5:	83 c0 04             	add    $0x4,%eax
   14da8:	89 c2                	mov    %eax,%edx
   14daa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14dad:	89 10                	mov    %edx,(%eax)

	// copy the arg string
	memmove( (void *)(avptr+1), args, argbytes );
   14daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14db2:	83 c0 04             	add    $0x4,%eax
   14db5:	83 ec 04             	sub    $0x4,%esp
   14db8:	ff 75 f0             	push   -0x10(%ebp)
   14dbb:	ff 75 10             	push   0x10(%ebp)
   14dbe:	50                   	push   %eax
   14dbf:	e8 bc 19 00 00       	call   16780 <memmove>
   14dc4:	83 c4 10             	add    $0x10,%esp

	// add the return address
	--avptr;
   14dc7:	83 6d e4 04          	subl   $0x4,-0x1c(%ebp)
	*avptr = user_locs[ULOC_FAKE];
   14dcb:	a1 20 a6 01 00       	mov    0x1a620,%eax
   14dd0:	8b 50 04             	mov    0x4(%eax),%edx
   14dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14dd6:	89 10                	mov    %edx,(%eax)
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *ctx = ((context_t *) avptr ) - 1;
   14dd8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14ddb:	83 e8 48             	sub    $0x48,%eax
   14dde:	89 45 e0             	mov    %eax,-0x20(%ebp)
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves ESP
	** where it winds up naturally
	*/

	ctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
   14de1:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14de4:	c7 40 44 02 02 00 00 	movl   $0x202,0x44(%eax)
	ctx->eip = entry;                // initial EIP
   14deb:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14dee:	8b 55 0c             	mov    0xc(%ebp),%edx
   14df1:	89 50 3c             	mov    %edx,0x3c(%eax)
	ctx->cs = GDT_CODE;              // segment registers
   14df4:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14df7:	c7 40 40 10 00 00 00 	movl   $0x10,0x40(%eax)
	ctx->ss = GDT_STACK;
   14dfe:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e01:	c7 00 20 00 00 00    	movl   $0x20,(%eax)
	ctx->ds = ctx->es = ctx->fs = ctx->gs = GDT_DATA;
   14e07:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e0a:	c7 40 04 18 00 00 00 	movl   $0x18,0x4(%eax)
   14e11:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e14:	8b 50 04             	mov    0x4(%eax),%edx
   14e17:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e1a:	89 50 08             	mov    %edx,0x8(%eax)
   14e1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e20:	8b 50 08             	mov    0x8(%eax),%edx
   14e23:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e26:	89 50 0c             	mov    %edx,0xc(%eax)
   14e29:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e2c:	8b 50 0c             	mov    0xc(%eax),%edx
   14e2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14e32:	89 50 10             	mov    %edx,0x10(%eax)

	/*
	** Return the new context pointer to the caller
	*/
	
	return ctx;
   14e35:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
   14e38:	c9                   	leave  
   14e39:	c3                   	ret    

00014e3a <stk_dump>:
// buffer sizes (rounded up a bit)
#define HBUFSZ      48
#define CBUFSZ      24

void stk_dump( const char *msg, uint32_t *stk, uint32_t limit )
{
   14e3a:	55                   	push   %ebp
   14e3b:	89 e5                	mov    %esp,%ebp
   14e3d:	57                   	push   %edi
   14e3e:	56                   	push   %esi
   14e3f:	53                   	push   %ebx
   14e40:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	uint32_t words = STACK_WDS;
   14e46:	c7 45 e4 00 08 00 00 	movl   $0x800,-0x1c(%ebp)
	int eliding = 0;
   14e4d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	char oldbuf[HBUFSZ], buf[HBUFSZ], cbuf[CBUFSZ];
	uint32_t addr = (uint32_t ) stk;
   14e54:	8b 45 0c             	mov    0xc(%ebp),%eax
   14e57:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t *sp = (uint32_t *) stk;
   14e5a:	8b 45 0c             	mov    0xc(%ebp),%eax
   14e5d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	char hexdigits[] = "0123456789ABCDEF";
   14e60:	c7 85 37 ff ff ff 30 	movl   $0x33323130,-0xc9(%ebp)
   14e67:	31 32 33 
   14e6a:	c7 85 3b ff ff ff 34 	movl   $0x37363534,-0xc5(%ebp)
   14e71:	35 36 37 
   14e74:	c7 85 3f ff ff ff 38 	movl   $0x42413938,-0xc1(%ebp)
   14e7b:	39 41 42 
   14e7e:	c7 85 43 ff ff ff 43 	movl   $0x46454443,-0xbd(%ebp)
   14e85:	44 45 46 
   14e88:	c6 85 47 ff ff ff 00 	movb   $0x0,-0xb9(%ebp)

	// if a limit was specified, dump only that many words

	if( limit > 0 ) {
   14e8f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   14e93:	74 30                	je     14ec5 <stk_dump+0x8b>
		words = limit;
   14e95:	8b 45 10             	mov    0x10(%ebp),%eax
   14e98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( (words & 0x3) != 0 ) {
   14e9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14e9e:	83 e0 03             	and    $0x3,%eax
   14ea1:	85 c0                	test   %eax,%eax
   14ea3:	74 0c                	je     14eb1 <stk_dump+0x77>
			// round up to a multiple of four
			words = (words + 3) & MOD4_MASK;
   14ea5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   14ea8:	83 c0 03             	add    $0x3,%eax
   14eab:	83 e0 fc             	and    $0xfffffffc,%eax
   14eae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		// skip to the new starting point
		sp += (STACK_WDS - words);
   14eb1:	b8 00 08 00 00       	mov    $0x800,%eax
   14eb6:	2b 45 e4             	sub    -0x1c(%ebp),%eax
   14eb9:	c1 e0 02             	shl    $0x2,%eax
   14ebc:	01 45 d8             	add    %eax,-0x28(%ebp)
		addr = (uint32_t) sp;
   14ebf:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14ec2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}

	cio_puts( "*** stack" );
   14ec5:	83 ec 0c             	sub    $0xc,%esp
   14ec8:	68 75 7f 01 00       	push   $0x17f75
   14ecd:	e8 bd c1 ff ff       	call   1108f <cio_puts>
   14ed2:	83 c4 10             	add    $0x10,%esp
	if( msg != NULL ) {
   14ed5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14ed9:	74 15                	je     14ef0 <stk_dump+0xb6>
		cio_printf( " (%s):\n", msg );
   14edb:	83 ec 08             	sub    $0x8,%esp
   14ede:	ff 75 08             	push   0x8(%ebp)
   14ee1:	68 7f 7f 01 00       	push   $0x17f7f
   14ee6:	e8 1c c8 ff ff       	call   11707 <cio_printf>
   14eeb:	83 c4 10             	add    $0x10,%esp
   14eee:	eb 10                	jmp    14f00 <stk_dump+0xc6>
	} else {
		cio_puts( ":\n" );
   14ef0:	83 ec 0c             	sub    $0xc,%esp
   14ef3:	68 87 7f 01 00       	push   $0x17f87
   14ef8:	e8 92 c1 ff ff       	call   1108f <cio_puts>
   14efd:	83 c4 10             	add    $0x10,%esp
	** Output lines that are identical except for the address are elided;
	** the next non-identical output line will have a '*' after the 8-digit
	** address field (where the '*' is in the example above).
	*/

	oldbuf[0] = '\0';
   14f00:	c6 45 90 00          	movb   $0x0,-0x70(%ebp)

	while( words > 0 ) {
   14f04:	e9 5e 01 00 00       	jmp    15067 <stk_dump+0x22d>
		register char *bp = buf;   // start of hex field
   14f09:	8d 9d 60 ff ff ff    	lea    -0xa0(%ebp),%ebx
		register char *cp = cbuf;  // start of character field
   14f0f:	8d bd 48 ff ff ff    	lea    -0xb8(%ebp),%edi
		uint32_t start_addr = addr;
   14f15:	8b 45 dc             	mov    -0x24(%ebp),%eax
   14f18:	89 45 c8             	mov    %eax,-0x38(%ebp)

		// iterate through the words for this line

		for( int i = 0; i < 4; ++i ) {
   14f1b:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
   14f22:	e9 a5 00 00 00       	jmp    14fcc <stk_dump+0x192>
			register uint32_t curr = *sp++;
   14f27:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14f2a:	8d 50 04             	lea    0x4(%eax),%edx
   14f2d:	89 55 d8             	mov    %edx,-0x28(%ebp)
   14f30:	8b 00                	mov    (%eax),%eax
   14f32:	89 85 24 ff ff ff    	mov    %eax,-0xdc(%ebp)
			register uint32_t data = curr;
   14f38:	89 c6                	mov    %eax,%esi

			// convert the hex representation

			// two spaces before each entry
			*bp++ = ' ';
   14f3a:	89 d8                	mov    %ebx,%eax
   14f3c:	8d 58 01             	lea    0x1(%eax),%ebx
   14f3f:	c6 00 20             	movb   $0x20,(%eax)
			*bp++ = ' ';
   14f42:	89 d8                	mov    %ebx,%eax
   14f44:	8d 58 01             	lea    0x1(%eax),%ebx
   14f47:	c6 00 20             	movb   $0x20,(%eax)

			// we could speed this up by advancing bp by 8 and
			// working backwards, shifting right by 4 at the
			// end and decrementing bp.
			for( int j = 0; j < 8; ++j ) {
   14f4a:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
   14f51:	eb 24                	jmp    14f77 <stk_dump+0x13d>
				// print the leftmost nybble
				uint32_t value = (data >> 28) & 0xf;
   14f53:	89 f0                	mov    %esi,%eax
   14f55:	c1 e8 1c             	shr    $0x1c,%eax
   14f58:	89 45 c0             	mov    %eax,-0x40(%ebp)
				*bp++ = hexdigits[value];
   14f5b:	89 da                	mov    %ebx,%edx
   14f5d:	8d 5a 01             	lea    0x1(%edx),%ebx
   14f60:	8d 8d 37 ff ff ff    	lea    -0xc9(%ebp),%ecx
   14f66:	8b 45 c0             	mov    -0x40(%ebp),%eax
   14f69:	01 c8                	add    %ecx,%eax
   14f6b:	0f b6 00             	movzbl (%eax),%eax
   14f6e:	88 02                	mov    %al,(%edx)
				// move next nybble into the high-order bit positions
				data <<= 4;
   14f70:	c1 e6 04             	shl    $0x4,%esi
			for( int j = 0; j < 8; ++j ) {
   14f73:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
   14f77:	83 7d d0 07          	cmpl   $0x7,-0x30(%ebp)
   14f7b:	7e d6                	jle    14f53 <stk_dump+0x119>
			}

			// now, convert the character version
			data = curr;
   14f7d:	8b b5 24 ff ff ff    	mov    -0xdc(%ebp),%esi

			// one space before each entry
			*cp++ = ' ';
   14f83:	89 f8                	mov    %edi,%eax
   14f85:	8d 78 01             	lea    0x1(%eax),%edi
   14f88:	c6 00 20             	movb   $0x20,(%eax)

			// again, we could speed this up by working backwards
			for( int j = 0; j < 4; ++j ) {
   14f8b:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
   14f92:	eb 2e                	jmp    14fc2 <stk_dump+0x188>
				uint32_t value = (data >> 24) & 0xff;
   14f94:	89 f0                	mov    %esi,%eax
   14f96:	c1 e8 18             	shr    $0x18,%eax
   14f99:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				*cp++ = (value >= ' ' && value < 0x7f) ? (char) value : '.';
   14f9c:	83 7d c4 1f          	cmpl   $0x1f,-0x3c(%ebp)
   14fa0:	76 0d                	jbe    14faf <stk_dump+0x175>
   14fa2:	83 7d c4 7e          	cmpl   $0x7e,-0x3c(%ebp)
   14fa6:	77 07                	ja     14faf <stk_dump+0x175>
   14fa8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   14fab:	89 c2                	mov    %eax,%edx
   14fad:	eb 05                	jmp    14fb4 <stk_dump+0x17a>
   14faf:	ba 2e 00 00 00       	mov    $0x2e,%edx
   14fb4:	89 f8                	mov    %edi,%eax
   14fb6:	8d 78 01             	lea    0x1(%eax),%edi
   14fb9:	88 10                	mov    %dl,(%eax)
				data <<= 8;
   14fbb:	c1 e6 08             	shl    $0x8,%esi
			for( int j = 0; j < 4; ++j ) {
   14fbe:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
   14fc2:	83 7d cc 03          	cmpl   $0x3,-0x34(%ebp)
   14fc6:	7e cc                	jle    14f94 <stk_dump+0x15a>
		for( int i = 0; i < 4; ++i ) {
   14fc8:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
   14fcc:	83 7d d4 03          	cmpl   $0x3,-0x2c(%ebp)
   14fd0:	0f 8e 51 ff ff ff    	jle    14f27 <stk_dump+0xed>
			}
		}
		*bp = '\0';
   14fd6:	c6 03 00             	movb   $0x0,(%ebx)
		*cp = '\0';
   14fd9:	c6 07 00             	movb   $0x0,(%edi)
		words -= 4;
   14fdc:	83 6d e4 04          	subl   $0x4,-0x1c(%ebp)
		addr += 16;
   14fe0:	83 45 dc 10          	addl   $0x10,-0x24(%ebp)

		// if this line looks like the last one, skip it

		if( strcmp(oldbuf,buf) == 0 ) {
   14fe4:	83 ec 08             	sub    $0x8,%esp
   14fe7:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   14fed:	50                   	push   %eax
   14fee:	8d 45 90             	lea    -0x70(%ebp),%eax
   14ff1:	50                   	push   %eax
   14ff2:	e8 78 1a 00 00       	call   16a6f <strcmp>
   14ff7:	83 c4 10             	add    $0x10,%esp
   14ffa:	85 c0                	test   %eax,%eax
   14ffc:	75 06                	jne    15004 <stk_dump+0x1ca>
			++eliding;
   14ffe:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
			continue;
   15002:	eb 63                	jmp    15067 <stk_dump+0x22d>
		}

		// it's different, so print it

		// start with the address
		cio_printf( "%08x%c", start_addr, eliding ? '*' : ' ' );
   15004:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   15008:	74 07                	je     15011 <stk_dump+0x1d7>
   1500a:	b8 2a 00 00 00       	mov    $0x2a,%eax
   1500f:	eb 05                	jmp    15016 <stk_dump+0x1dc>
   15011:	b8 20 00 00 00       	mov    $0x20,%eax
   15016:	83 ec 04             	sub    $0x4,%esp
   15019:	50                   	push   %eax
   1501a:	ff 75 c8             	push   -0x38(%ebp)
   1501d:	68 8a 7f 01 00       	push   $0x17f8a
   15022:	e8 e0 c6 ff ff       	call   11707 <cio_printf>
   15027:	83 c4 10             	add    $0x10,%esp
		eliding = 0;
   1502a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// print the words
		cio_printf( "%s %s\n", buf, cbuf );
   15031:	83 ec 04             	sub    $0x4,%esp
   15034:	8d 85 48 ff ff ff    	lea    -0xb8(%ebp),%eax
   1503a:	50                   	push   %eax
   1503b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   15041:	50                   	push   %eax
   15042:	68 91 7f 01 00       	push   $0x17f91
   15047:	e8 bb c6 ff ff       	call   11707 <cio_printf>
   1504c:	83 c4 10             	add    $0x10,%esp

		// remember this line
		memcpy( (uint8_t *) oldbuf, (uint8_t *) buf, HBUFSZ );
   1504f:	83 ec 04             	sub    $0x4,%esp
   15052:	6a 30                	push   $0x30
   15054:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1505a:	50                   	push   %eax
   1505b:	8d 45 90             	lea    -0x70(%ebp),%eax
   1505e:	50                   	push   %eax
   1505f:	e8 ee 16 00 00       	call   16752 <memcpy>
   15064:	83 c4 10             	add    $0x10,%esp
	while( words > 0 ) {
   15067:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   1506b:	0f 85 98 fe ff ff    	jne    14f09 <stk_dump+0xcf>
	}
}
   15071:	90                   	nop
   15072:	90                   	nop
   15073:	8d 65 f4             	lea    -0xc(%ebp),%esp
   15076:	5b                   	pop    %ebx
   15077:	5e                   	pop    %esi
   15078:	5f                   	pop    %edi
   15079:	5d                   	pop    %ebp
   1507a:	c3                   	ret    

0001507b <unexpected_handler>:
** Does not return.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void unexpected_handler( int vector, int code ){
   1507b:	55                   	push   %ebp
   1507c:	89 e5                	mov    %esp,%ebp
   1507e:	83 ec 08             	sub    $0x8,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector 0x%02x, code=%d\n",
   15081:	8b 45 08             	mov    0x8(%ebp),%eax
   15084:	83 ec 04             	sub    $0x4,%esp
   15087:	ff 75 0c             	push   0xc(%ebp)
   1508a:	50                   	push   %eax
   1508b:	68 b0 7f 01 00       	push   $0x17fb0
   15090:	e8 72 c6 ff ff       	call   11707 <cio_printf>
   15095:	83 c4 10             	add    $0x10,%esp
		  (unsigned int) vector, code );
#endif
	panic( "Unexpected interrupt" );
   15098:	83 ec 0c             	sub    $0xc,%esp
   1509b:	68 d7 7f 01 00       	push   $0x17fd7
   150a0:	e8 ce 03 00 00       	call   15473 <panic>
   150a5:	83 c4 10             	add    $0x10,%esp
}
   150a8:	90                   	nop
   150a9:	c9                   	leave  
   150aa:	c3                   	ret    

000150ab <illop_fault>:

#ifdef CATCH_OP_FAULTS
static void illop_fault( int vector, int code ){
   150ab:	55                   	push   %ebp
   150ac:	89 e5                	mov    %esp,%ebp
   150ae:	83 ec 08             	sub    $0x8,%esp

	cio_printf( "\nILL OP FAULT vec %02x code %d\n",
   150b1:	8b 45 08             	mov    0x8(%ebp),%eax
   150b4:	83 ec 04             	sub    $0x4,%esp
   150b7:	ff 75 0c             	push   0xc(%ebp)
   150ba:	50                   	push   %eax
   150bb:	68 ec 7f 01 00       	push   $0x17fec
   150c0:	e8 42 c6 ff ff       	call   11707 <cio_printf>
   150c5:	83 c4 10             	add    $0x10,%esp
			(uint32_t) vector, code );

	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
			current->context->cs, current->context->eip );
   150c8:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   150cd:	8b 00                	mov    (%eax),%eax
	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
   150cf:	8b 50 3c             	mov    0x3c(%eax),%edx
			current->context->cs, current->context->eip );
   150d2:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   150d7:	8b 00                	mov    (%eax),%eax
	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
   150d9:	8b 40 40             	mov    0x40(%eax),%eax
   150dc:	83 ec 04             	sub    $0x4,%esp
   150df:	52                   	push   %edx
   150e0:	50                   	push   %eax
   150e1:	68 0c 80 01 00       	push   $0x1800c
   150e6:	e8 1c c6 ff ff       	call   11707 <cio_printf>
   150eb:	83 c4 10             	add    $0x10,%esp

	pcb_dump( "Current", current, true );
   150ee:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   150f3:	83 ec 04             	sub    $0x4,%esp
   150f6:	6a 01                	push   $0x1
   150f8:	50                   	push   %eax
   150f9:	68 27 80 01 00       	push   $0x18027
   150fe:	e8 a7 dd ff ff       	call   12eaa <pcb_dump>
   15103:	83 c4 10             	add    $0x10,%esp

	ctx_dump( "current", current->context );
   15106:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   1510b:	8b 00                	mov    (%eax),%eax
   1510d:	83 ec 08             	sub    $0x8,%esp
   15110:	50                   	push   %eax
   15111:	68 2f 80 01 00       	push   $0x1802f
   15116:	e8 26 dc ff ff       	call   12d41 <ctx_dump>
   1511b:	83 c4 10             	add    $0x10,%esp

	panic( "Illegal Opcode fault" );
   1511e:	83 ec 0c             	sub    $0xc,%esp
   15121:	68 37 80 01 00       	push   $0x18037
   15126:	e8 48 03 00 00       	call   15473 <panic>
   1512b:	83 c4 10             	add    $0x10,%esp
}
   1512e:	90                   	nop
   1512f:	c9                   	leave  
   15130:	c3                   	ret    

00015131 <gp_fault>:
#endif

#ifdef CATCH_GP_FAULTS
static void gp_fault( int vector, int code ){
   15131:	55                   	push   %ebp
   15132:	89 e5                	mov    %esp,%ebp
   15134:	83 ec 08             	sub    $0x8,%esp

	cio_printf( "\nGP FAULT vec %02x code %d",
   15137:	8b 45 08             	mov    0x8(%ebp),%eax
   1513a:	83 ec 04             	sub    $0x4,%esp
   1513d:	ff 75 0c             	push   0xc(%ebp)
   15140:	50                   	push   %eax
   15141:	68 4c 80 01 00       	push   $0x1804c
   15146:	e8 bc c5 ff ff       	call   11707 <cio_printf>
   1514b:	83 c4 10             	add    $0x10,%esp
			(uint32_t) vector, code );

	if( code != 0 ) {
   1514e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   15152:	74 16                	je     1516a <gp_fault+0x39>
		cio_printf( " -> sel/idt number: %08x\n", (uint32_t) code );
   15154:	8b 45 0c             	mov    0xc(%ebp),%eax
   15157:	83 ec 08             	sub    $0x8,%esp
   1515a:	50                   	push   %eax
   1515b:	68 67 80 01 00       	push   $0x18067
   15160:	e8 a2 c5 ff ff       	call   11707 <cio_printf>
   15165:	83 c4 10             	add    $0x10,%esp
   15168:	eb 0d                	jmp    15177 <gp_fault+0x46>
	} else {
		cio_putchar( '\n' );
   1516a:	83 ec 0c             	sub    $0xc,%esp
   1516d:	6a 0a                	push   $0xa
   1516f:	e8 98 bd ff ff       	call   10f0c <cio_putchar>
   15174:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
			current->context->cs, current->context->eip );
   15177:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   1517c:	8b 00                	mov    (%eax),%eax
	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
   1517e:	8b 50 3c             	mov    0x3c(%eax),%edx
			current->context->cs, current->context->eip );
   15181:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   15186:	8b 00                	mov    (%eax),%eax
	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
   15188:	8b 40 40             	mov    0x40(%eax),%eax
   1518b:	83 ec 04             	sub    $0x4,%esp
   1518e:	52                   	push   %edx
   1518f:	50                   	push   %eax
   15190:	68 0c 80 01 00       	push   $0x1800c
   15195:	e8 6d c5 ff ff       	call   11707 <cio_printf>
   1519a:	83 c4 10             	add    $0x10,%esp

	pcb_dump( "Current", current, true );
   1519d:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   151a2:	83 ec 04             	sub    $0x4,%esp
   151a5:	6a 01                	push   $0x1
   151a7:	50                   	push   %eax
   151a8:	68 27 80 01 00       	push   $0x18027
   151ad:	e8 f8 dc ff ff       	call   12eaa <pcb_dump>
   151b2:	83 c4 10             	add    $0x10,%esp

	ctx_dump( "current", current->context );
   151b5:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   151ba:	8b 00                	mov    (%eax),%eax
   151bc:	83 ec 08             	sub    $0x8,%esp
   151bf:	50                   	push   %eax
   151c0:	68 2f 80 01 00       	push   $0x1802f
   151c5:	e8 77 db ff ff       	call   12d41 <ctx_dump>
   151ca:	83 c4 10             	add    $0x10,%esp

	panic( "General Protection fault" );
   151cd:	83 ec 0c             	sub    $0xc,%esp
   151d0:	68 81 80 01 00       	push   $0x18081
   151d5:	e8 99 02 00 00       	call   15473 <panic>
   151da:	83 c4 10             	add    $0x10,%esp
}
   151dd:	90                   	nop
   151de:	c9                   	leave  
   151df:	c3                   	ret    

000151e0 <default_handler>:
** handler doesn't return - instead, it panics.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void default_handler( int vector, int code ){
   151e0:	55                   	push   %ebp
   151e1:	89 e5                	mov    %esp,%ebp
   151e3:	83 ec 18             	sub    $0x18,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** DEFAULT vector 0x%02x, code=%d\n",
   151e6:	8b 45 08             	mov    0x8(%ebp),%eax
   151e9:	83 ec 04             	sub    $0x4,%esp
   151ec:	ff 75 0c             	push   0xc(%ebp)
   151ef:	50                   	push   %eax
   151f0:	68 9c 80 01 00       	push   $0x1809c
   151f5:	e8 0d c5 ff ff       	call   11707 <cio_printf>
   151fa:	83 c4 10             	add    $0x10,%esp
		  (unsigned int) vector, code );
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
   151fd:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   15201:	7e 36                	jle    15239 <default_handler+0x59>
   15203:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   15207:	7f 30                	jg     15239 <default_handler+0x59>
		if( vector > 0x27 ){
   15209:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   1520d:	7e 14                	jle    15223 <default_handler+0x43>
   1520f:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   15216:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
** @return The data read from the specified port
*/
OPSINLINED static inline void
outb( int port, uint8_t data )
{
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1521a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1521e:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15221:	ee                   	out    %al,(%dx)
}
   15222:	90                   	nop
   15223:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   1522a:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1522e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   15232:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15235:	ee                   	out    %al,(%dx)
}
   15236:	90                   	nop
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
   15237:	eb 11                	jmp    1524a <default_handler+0x6a>
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
   15239:	83 ec 0c             	sub    $0xc,%esp
   1523c:	68 c0 80 01 00       	push   $0x180c0
   15241:	e8 2d 02 00 00       	call   15473 <panic>
   15246:	83 c4 10             	add    $0x10,%esp
	}
}
   15249:	90                   	nop
   1524a:	90                   	nop
   1524b:	c9                   	leave  
   1524c:	c3                   	ret    

0001524d <mystery_handler>:
** non-PIC interrupt comes in.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ){
   1524d:	55                   	push   %ebp
   1524e:	89 e5                	mov    %esp,%ebp
   15250:	83 ec 28             	sub    $0x28,%esp
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\n** MYSTERY vector 0x%02x, code=%d\n",
   15253:	8b 45 08             	mov    0x8(%ebp),%eax
   15256:	83 ec 04             	sub    $0x4,%esp
   15259:	ff 75 0c             	push   0xc(%ebp)
   1525c:	50                   	push   %eax
   1525d:	68 e4 80 01 00       	push   $0x180e4
   15262:	e8 a0 c4 ff ff       	call   11707 <cio_printf>
   15267:	83 c4 10             	add    $0x10,%esp
		  (unsigned int) vector, code );
#endif
	// This is most probably from vector 0x27, but we check it
	// anyway just to be sure. 
	if( vector >= 0x20 && vector < 0x30 ) {
   1526a:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1526e:	7e 36                	jle    152a6 <mystery_handler+0x59>
   15270:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   15274:	7f 30                	jg     152a6 <mystery_handler+0x59>
		if( vector > 0x27 ){
   15276:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   1527a:	7e 14                	jle    15290 <mystery_handler+0x43>
   1527c:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   15283:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15287:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1528b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1528e:	ee                   	out    %al,(%dx)
}
   1528f:	90                   	nop
   15290:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   15297:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1529b:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1529f:	8b 55 ec             	mov    -0x14(%ebp),%edx
   152a2:	ee                   	out    %al,(%dx)
}
   152a3:	90                   	nop
			// Hmmm. Odd.
			outb( PIC2_CMD, PIC_EOI );
		}
		// This is what we expect.
		outb( PIC1_CMD, PIC_EOI );
   152a4:	eb 14                	jmp    152ba <mystery_handler+0x6d>
   152a6:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
   152ad:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   152b1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   152b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   152b8:	ee                   	out    %al,(%dx)
}
   152b9:	90                   	nop
	} else {
		// This is very strange. We'll ACK it anyway.
		outb( PIC1_CMD, PIC_EOI );
	}
}
   152ba:	90                   	nop
   152bb:	c9                   	leave  
   152bc:	c3                   	ret    

000152bd <init_pic>:
/**
** init_pic()
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ){
   152bd:	55                   	push   %ebp
   152be:	89 e5                	mov    %esp,%ebp
   152c0:	83 ec 50             	sub    $0x50,%esp
   152c3:	c7 45 b4 20 00 00 00 	movl   $0x20,-0x4c(%ebp)
   152ca:	c6 45 b3 11          	movb   $0x11,-0x4d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   152ce:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   152d2:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   152d5:	ee                   	out    %al,(%dx)
}
   152d6:	90                   	nop
   152d7:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
   152de:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   152e2:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   152e6:	8b 55 bc             	mov    -0x44(%ebp),%edx
   152e9:	ee                   	out    %al,(%dx)
}
   152ea:	90                   	nop
   152eb:	c7 45 c4 21 00 00 00 	movl   $0x21,-0x3c(%ebp)
   152f2:	c6 45 c3 20          	movb   $0x20,-0x3d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   152f6:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   152fa:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   152fd:	ee                   	out    %al,(%dx)
}
   152fe:	90                   	nop
   152ff:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
   15306:	c6 45 cb 28          	movb   $0x28,-0x35(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1530a:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   1530e:	8b 55 cc             	mov    -0x34(%ebp),%edx
   15311:	ee                   	out    %al,(%dx)
}
   15312:	90                   	nop
   15313:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
   1531a:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1531e:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   15322:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   15325:	ee                   	out    %al,(%dx)
}
   15326:	90                   	nop
   15327:	c7 45 dc a1 00 00 00 	movl   $0xa1,-0x24(%ebp)
   1532e:	c6 45 db 02          	movb   $0x2,-0x25(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15332:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   15336:	8b 55 dc             	mov    -0x24(%ebp),%edx
   15339:	ee                   	out    %al,(%dx)
}
   1533a:	90                   	nop
   1533b:	c7 45 e4 21 00 00 00 	movl   $0x21,-0x1c(%ebp)
   15342:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15346:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   1534a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   1534d:	ee                   	out    %al,(%dx)
}
   1534e:	90                   	nop
   1534f:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
   15356:	c6 45 eb 01          	movb   $0x1,-0x15(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1535a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1535e:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15361:	ee                   	out    %al,(%dx)
}
   15362:	90                   	nop
   15363:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
   1536a:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   1536e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15372:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15375:	ee                   	out    %al,(%dx)
}
   15376:	90                   	nop
   15377:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
   1537e:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15382:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   15386:	8b 55 fc             	mov    -0x4(%ebp),%edx
   15389:	ee                   	out    %al,(%dx)
}
   1538a:	90                   	nop
	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}
   1538b:	90                   	nop
   1538c:	c9                   	leave  
   1538d:	c3                   	ret    

0001538e <set_idt_entry>:
** @param[in] handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ){
   1538e:	55                   	push   %ebp
   1538f:	89 e5                	mov    %esp,%ebp
   15391:	83 ec 10             	sub    $0x10,%esp
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;
   15394:	8b 45 08             	mov    0x8(%ebp),%eax
   15397:	c1 e0 03             	shl    $0x3,%eax
   1539a:	05 00 25 00 00       	add    $0x2500,%eax
   1539f:	89 45 fc             	mov    %eax,-0x4(%ebp)

	g->offset_15_0 = (int)handler & 0xffff;
   153a2:	8b 45 0c             	mov    0xc(%ebp),%eax
   153a5:	89 c2                	mov    %eax,%edx
   153a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
   153aa:	66 89 10             	mov    %dx,(%eax)
	g->segment_selector = 0x0010;
   153ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
   153b0:	66 c7 40 02 10 00    	movw   $0x10,0x2(%eax)
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
   153b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   153b9:	66 c7 40 04 00 8e    	movw   $0x8e00,0x4(%eax)
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
   153bf:	8b 45 0c             	mov    0xc(%ebp),%eax
   153c2:	c1 e8 10             	shr    $0x10,%eax
   153c5:	89 c2                	mov    %eax,%edx
   153c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
   153ca:	66 89 50 06          	mov    %dx,0x6(%eax)
}
   153ce:	90                   	nop
   153cf:	c9                   	leave  
   153d0:	c3                   	ret    

000153d1 <init_idt>:
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ){
   153d1:	55                   	push   %ebp
   153d2:	89 e5                	mov    %esp,%ebp
   153d4:	83 ec 18             	sub    $0x18,%esp

	/*
	** Make each IDT entry point to the stub for that vector.  Also make
	** each entry in the ISR table point to the "unexpected" handler.
	*/
	for ( i=0; i < 256; i++ ){
   153d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   153de:	eb 2d                	jmp    1540d <init_idt+0x3c>
		set_idt_entry( i, isr_stub_table[ i ] );
   153e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   153e3:	8b 04 85 00 90 01 00 	mov    0x19000(,%eax,4),%eax
   153ea:	50                   	push   %eax
   153eb:	ff 75 f4             	push   -0xc(%ebp)
   153ee:	e8 9b ff ff ff       	call   1538e <set_idt_entry>
   153f3:	83 c4 08             	add    $0x8,%esp
		install_isr( i, unexpected_handler );
   153f6:	83 ec 08             	sub    $0x8,%esp
   153f9:	68 7b 50 01 00       	push   $0x1507b
   153fe:	ff 75 f4             	push   -0xc(%ebp)
   15401:	e8 9c 00 00 00       	call   154a2 <install_isr>
   15406:	83 c4 10             	add    $0x10,%esp
	for ( i=0; i < 256; i++ ){
   15409:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   1540d:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   15414:	7e ca                	jle    153e0 <init_idt+0xf>
	}

	// Replace the handlers for interrupts that (will) have a custom handler.
	install_isr( VEC_KBD, default_handler );
   15416:	83 ec 08             	sub    $0x8,%esp
   15419:	68 e0 51 01 00       	push   $0x151e0
   1541e:	6a 21                	push   $0x21
   15420:	e8 7d 00 00 00       	call   154a2 <install_isr>
   15425:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_TIMER, default_handler );
   15428:	83 ec 08             	sub    $0x8,%esp
   1542b:	68 e0 51 01 00       	push   $0x151e0
   15430:	6a 20                	push   $0x20
   15432:	e8 6b 00 00 00       	call   154a2 <install_isr>
   15437:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_MYSTERY, mystery_handler );
   1543a:	83 ec 08             	sub    $0x8,%esp
   1543d:	68 4d 52 01 00       	push   $0x1524d
   15442:	6a 27                	push   $0x27
   15444:	e8 59 00 00 00       	call   154a2 <install_isr>
   15449:	83 c4 10             	add    $0x10,%esp

#ifdef CATCH_OP_FAULTS
	install_isr( VEC_INVALID_OPCODE, illop_fault );
   1544c:	83 ec 08             	sub    $0x8,%esp
   1544f:	68 ab 50 01 00       	push   $0x150ab
   15454:	6a 06                	push   $0x6
   15456:	e8 47 00 00 00       	call   154a2 <install_isr>
   1545b:	83 c4 10             	add    $0x10,%esp
#endif
#ifdef CATCH_GP_FAULTS
	install_isr( VEC_GENERAL_PROTECTION, gp_fault );
   1545e:	83 ec 08             	sub    $0x8,%esp
   15461:	68 31 51 01 00       	push   $0x15131
   15466:	6a 0d                	push   $0xd
   15468:	e8 35 00 00 00       	call   154a2 <install_isr>
   1546d:	83 c4 10             	add    $0x10,%esp
#endif
}
   15470:	90                   	nop
   15471:	c9                   	leave  
   15472:	c3                   	ret    

00015473 <panic>:
**
** Called when we find an unrecoverable error. Does not return.
**
** @param[in] reason  An explanation of why we're halting
*/
void panic( char *reason ){
   15473:	55                   	push   %ebp
   15474:	89 e5                	mov    %esp,%ebp
   15476:	83 ec 08             	sub    $0x8,%esp
	__asm__( "cli" );
   15479:	fa                   	cli    
	cio_printf( "\nPANIC: %s\nHalting...", reason );
   1547a:	83 ec 08             	sub    $0x8,%esp
   1547d:	ff 75 08             	push   0x8(%ebp)
   15480:	68 08 81 01 00       	push   $0x18108
   15485:	e8 7d c2 ff ff       	call   11707 <cio_printf>
   1548a:	83 c4 10             	add    $0x10,%esp
	for(;;)
   1548d:	eb fe                	jmp    1548d <panic+0x1a>

0001548f <init_interrupts>:
/*
** init_interrupts()
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ){
   1548f:	55                   	push   %ebp
   15490:	89 e5                	mov    %esp,%ebp
   15492:	83 ec 08             	sub    $0x8,%esp
	init_idt();
   15495:	e8 37 ff ff ff       	call   153d1 <init_idt>
	init_pic();
   1549a:	e8 1e fe ff ff       	call   152bd <init_pic>
}
   1549f:	90                   	nop
   154a0:	c9                   	leave  
   154a1:	c3                   	ret    

000154a2 <install_isr>:
** @param[in] handler  Pointer to the handler to be installed
**
** @return Pointer to the previously-installed handler
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ){
   154a2:	55                   	push   %ebp
   154a3:	89 e5                	mov    %esp,%ebp
   154a5:	83 ec 10             	sub    $0x10,%esp

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
   154a8:	8b 45 08             	mov    0x8(%ebp),%eax
   154ab:	8b 04 85 c0 b2 01 00 	mov    0x1b2c0(,%eax,4),%eax
   154b2:	89 45 fc             	mov    %eax,-0x4(%ebp)
	isr_table[ vector ] = handler;
   154b5:	8b 45 08             	mov    0x8(%ebp),%eax
   154b8:	8b 55 0c             	mov    0xc(%ebp),%edx
   154bb:	89 14 85 c0 b2 01 00 	mov    %edx,0x1b2c0(,%eax,4)
	return old_handler;
   154c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   154c5:	c9                   	leave  
   154c6:	c3                   	ret    

000154c7 <status_return>:
** wants to do more work with it before cleaning it up.
**
** @param parent   The parent receiving the information
** @param child    The exiting child
*/
static void status_return( pcb_t *parent, pcb_t *child ) {
   154c7:	55                   	push   %ebp
   154c8:	89 e5                	mov    %esp,%ebp
   154ca:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( parent != NULL );
   154cd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   154d1:	75 36                	jne    15509 <status_return+0x42>
   154d3:	83 ec 08             	sub    $0x8,%esp
   154d6:	68 20 81 01 00       	push   $0x18120
   154db:	6a 59                	push   $0x59
   154dd:	68 2f 81 01 00       	push   $0x1812f
   154e2:	68 fc 82 01 00       	push   $0x182fc
   154e7:	68 44 81 01 00       	push   $0x18144
   154ec:	68 20 a4 01 00       	push   $0x1a420
   154f1:	e8 04 13 00 00       	call   167fa <sprint>
   154f6:	83 c4 20             	add    $0x20,%esp
   154f9:	83 ec 0c             	sub    $0xc,%esp
   154fc:	68 20 a4 01 00       	push   $0x1a420
   15501:	e8 bb 0d 00 00       	call   162c1 <kpanic>
   15506:	83 c4 10             	add    $0x10,%esp
	assert1( child != NULL );
   15509:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1550d:	75 36                	jne    15545 <status_return+0x7e>
   1550f:	83 ec 08             	sub    $0x8,%esp
   15512:	68 65 81 01 00       	push   $0x18165
   15517:	6a 5a                	push   $0x5a
   15519:	68 2f 81 01 00       	push   $0x1812f
   1551e:	68 fc 82 01 00       	push   $0x182fc
   15523:	68 44 81 01 00       	push   $0x18144
   15528:	68 20 a4 01 00       	push   $0x1a420
   1552d:	e8 c8 12 00 00       	call   167fa <sprint>
   15532:	83 c4 20             	add    $0x20,%esp
   15535:	83 ec 0c             	sub    $0xc,%esp
   15538:	68 20 a4 01 00       	push   $0x1a420
   1553d:	e8 7f 0d 00 00       	call   162c1 <kpanic>
   15542:	83 c4 10             	add    $0x10,%esp

	// intrinsic return value is the PID
	RET(parent) = child->pid;
   15545:	8b 45 0c             	mov    0xc(%ebp),%eax
   15548:	8b 50 14             	mov    0x14(%eax),%edx
   1554b:	8b 45 08             	mov    0x8(%ebp),%eax
   1554e:	8b 00                	mov    (%eax),%eax
   15550:	89 50 30             	mov    %edx,0x30(%eax)

	// may also want to return the exit status
	int32_t *ptr = (int32_t *) ARG(parent,1);
   15553:	8b 45 08             	mov    0x8(%ebp),%eax
   15556:	8b 00                	mov    (%eax),%eax
   15558:	83 c0 4c             	add    $0x4c,%eax
   1555b:	8b 00                	mov    (%eax),%eax
   1555d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	** any type of memory protection.  If address space
	** separation is implemented, this code will very likely
	** STOP WORKING, and will need to be fixed.
	********************************************************
	*/
	if( ptr != NULL ) {
   15560:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15564:	74 0b                	je     15571 <status_return+0xaa>
		*ptr = child->status;
   15566:	8b 45 0c             	mov    0xc(%ebp),%eax
   15569:	8b 50 10             	mov    0x10(%eax),%edx
   1556c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1556f:	89 10                	mov    %edx,(%eax)
	}
}
   15571:	90                   	nop
   15572:	c9                   	leave  
   15573:	c3                   	ret    

00015574 <sys_exit>:
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {
   15574:	55                   	push   %ebp
   15575:	89 e5                	mov    %esp,%ebp
   15577:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert( pcb != NULL );
   1557a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1557e:	75 39                	jne    155b9 <sys_exit+0x45>
   15580:	83 ec 08             	sub    $0x8,%esp
   15583:	68 73 81 01 00       	push   $0x18173
   15588:	68 8a 00 00 00       	push   $0x8a
   1558d:	68 2f 81 01 00       	push   $0x1812f
   15592:	68 0c 83 01 00       	push   $0x1830c
   15597:	68 80 81 01 00       	push   $0x18180
   1559c:	68 20 a4 01 00       	push   $0x1a420
   155a1:	e8 54 12 00 00       	call   167fa <sprint>
   155a6:	83 c4 20             	add    $0x20,%esp
   155a9:	83 ec 0c             	sub    $0xc,%esp
   155ac:	68 20 a4 01 00       	push   $0x1a420
   155b1:	e8 0b 0d 00 00       	call   162c1 <kpanic>
   155b6:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER(pcb->pid);

	// we'll need to notify the parent that this process has exited
	pcb_t *parent = pcb->parent;
   155b9:	8b 45 08             	mov    0x8(%ebp),%eax
   155bc:	8b 40 08             	mov    0x8(%eax),%eax
   155bf:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// make sure the parent actually exists and is a
	// different process than the one that is exiting
	assert1( parent != NULL );
   155c2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   155c6:	75 39                	jne    15601 <sys_exit+0x8d>
   155c8:	83 ec 08             	sub    $0x8,%esp
   155cb:	68 20 81 01 00       	push   $0x18120
   155d0:	68 93 00 00 00       	push   $0x93
   155d5:	68 2f 81 01 00       	push   $0x1812f
   155da:	68 0c 83 01 00       	push   $0x1830c
   155df:	68 44 81 01 00       	push   $0x18144
   155e4:	68 20 a4 01 00       	push   $0x1a420
   155e9:	e8 0c 12 00 00       	call   167fa <sprint>
   155ee:	83 c4 20             	add    $0x20,%esp
   155f1:	83 ec 0c             	sub    $0xc,%esp
   155f4:	68 20 a4 01 00       	push   $0x1a420
   155f9:	e8 c3 0c 00 00       	call   162c1 <kpanic>
   155fe:	83 c4 10             	add    $0x10,%esp
	assert1( parent->state != STATE_UNUSED );
   15601:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15604:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   15608:	84 c0                	test   %al,%al
   1560a:	75 39                	jne    15645 <sys_exit+0xd1>
   1560c:	83 ec 08             	sub    $0x8,%esp
   1560f:	68 a3 81 01 00       	push   $0x181a3
   15614:	68 94 00 00 00       	push   $0x94
   15619:	68 2f 81 01 00       	push   $0x1812f
   1561e:	68 0c 83 01 00       	push   $0x1830c
   15623:	68 44 81 01 00       	push   $0x18144
   15628:	68 20 a4 01 00       	push   $0x1a420
   1562d:	e8 c8 11 00 00       	call   167fa <sprint>
   15632:	83 c4 20             	add    $0x20,%esp
   15635:	83 ec 0c             	sub    $0xc,%esp
   15638:	68 20 a4 01 00       	push   $0x1a420
   1563d:	e8 7f 0c 00 00       	call   162c1 <kpanic>
   15642:	83 c4 10             	add    $0x10,%esp
	assert1( parent != pcb );
   15645:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15648:	3b 45 08             	cmp    0x8(%ebp),%eax
   1564b:	75 39                	jne    15686 <sys_exit+0x112>
   1564d:	83 ec 08             	sub    $0x8,%esp
   15650:	68 c1 81 01 00       	push   $0x181c1
   15655:	68 95 00 00 00       	push   $0x95
   1565a:	68 2f 81 01 00       	push   $0x1812f
   1565f:	68 0c 83 01 00       	push   $0x1830c
   15664:	68 44 81 01 00       	push   $0x18144
   15669:	68 20 a4 01 00       	push   $0x1a420
   1566e:	e8 87 11 00 00       	call   167fa <sprint>
   15673:	83 c4 20             	add    $0x20,%esp
   15676:	83 ec 0c             	sub    $0xc,%esp
   15679:	68 20 a4 01 00       	push   $0x1a420
   1567e:	e8 3e 0c 00 00       	call   162c1 <kpanic>
   15683:	83 c4 10             	add    $0x10,%esp
	
	// grab the termination status
	pcb->status = ARG(pcb,1);
   15686:	8b 45 08             	mov    0x8(%ebp),%eax
   15689:	8b 00                	mov    (%eax),%eax
   1568b:	83 c0 4c             	add    $0x4c,%eax
   1568e:	8b 00                	mov    (%eax),%eax
   15690:	89 c2                	mov    %eax,%edx
   15692:	8b 45 08             	mov    0x8(%ebp),%eax
   15695:	89 50 10             	mov    %edx,0x10(%eax)

	// find all children of this process and reparent them
	pcb_t *for_init = NULL;
   15698:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	do {
		pcb_t *next = pcb_find_child_of( pcb );
   1569f:	83 ec 0c             	sub    $0xc,%esp
   156a2:	ff 75 08             	push   0x8(%ebp)
   156a5:	e8 41 df ff ff       	call   135eb <pcb_find_child_of>
   156aa:	83 c4 10             	add    $0x10,%esp
   156ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( next == NULL ) {
   156b0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   156b4:	74 63                	je     15719 <sys_exit+0x1a5>
			// none found
			break;
		}

		// probably not necessary, but for now...
		assert1( next->parent == pcb );
   156b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   156b9:	8b 40 08             	mov    0x8(%eax),%eax
   156bc:	39 45 08             	cmp    %eax,0x8(%ebp)
   156bf:	74 39                	je     156fa <sys_exit+0x186>
   156c1:	83 ec 08             	sub    $0x8,%esp
   156c4:	68 cf 81 01 00       	push   $0x181cf
   156c9:	68 a4 00 00 00       	push   $0xa4
   156ce:	68 2f 81 01 00       	push   $0x1812f
   156d3:	68 0c 83 01 00       	push   $0x1830c
   156d8:	68 44 81 01 00       	push   $0x18144
   156dd:	68 20 a4 01 00       	push   $0x1a420
   156e2:	e8 13 11 00 00       	call   167fa <sprint>
   156e7:	83 c4 20             	add    $0x20,%esp
   156ea:	83 ec 0c             	sub    $0xc,%esp
   156ed:	68 20 a4 01 00       	push   $0x1a420
   156f2:	e8 ca 0b 00 00       	call   162c1 <kpanic>
   156f7:	83 c4 10             	add    $0x10,%esp

		// found a child
		next->parent = init_pcb;
   156fa:	8b 15 84 a9 01 00    	mov    0x1a984,%edx
   15700:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15703:	89 50 08             	mov    %edx,0x8(%eax)

		// if it has exited, we'll need to wake up init; if there
		// are two or more exited children, we'll remember the
		// last one here, which doesn't matter because 'init' will
		// clean it up, loop, and collect the others
		if( next->state == STATE_ZOMBIE ) {
   15706:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15709:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   1570d:	3c 07                	cmp    $0x7,%al
   1570f:	75 8e                	jne    1569f <sys_exit+0x12b>
			for_init = next;
   15711:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15714:	89 45 f4             	mov    %eax,-0xc(%ebp)
	do {
   15717:	eb 86                	jmp    1569f <sys_exit+0x12b>
			break;
   15719:	90                   	nop
	** existing process itself is cleaned up by init. This will work,
	** because after init cleans up the zombie, it will loop and
	** call wait() again, by which time this exiting process will
	** be marked as a zombie.
	*/
	if( for_init != NULL && init_pcb->state == STATE_WAITING ) {
   1571a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1571e:	0f 84 95 00 00 00    	je     157b9 <sys_exit+0x245>
   15724:	a1 84 a9 01 00       	mov    0x1a984,%eax
   15729:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   1572d:	3c 06                	cmp    $0x6,%al
   1572f:	0f 85 84 00 00 00    	jne    157b9 <sys_exit+0x245>

		// dequeue the zombie
		assert( que_remove_by(zombie,for_init) == E_SUCCESS );
   15735:	a1 50 a6 01 00       	mov    0x1a650,%eax
   1573a:	83 ec 08             	sub    $0x8,%esp
   1573d:	ff 75 f4             	push   -0xc(%ebp)
   15740:	50                   	push   %eax
   15741:	e8 24 e9 ff ff       	call   1406a <que_remove_by>
   15746:	83 c4 10             	add    $0x10,%esp
   15749:	85 c0                	test   %eax,%eax
   1574b:	74 39                	je     15786 <sys_exit+0x212>
   1574d:	83 ec 08             	sub    $0x8,%esp
   15750:	68 e4 81 01 00       	push   $0x181e4
   15755:	68 c5 00 00 00       	push   $0xc5
   1575a:	68 2f 81 01 00       	push   $0x1812f
   1575f:	68 0c 83 01 00       	push   $0x1830c
   15764:	68 80 81 01 00       	push   $0x18180
   15769:	68 20 a4 01 00       	push   $0x1a420
   1576e:	e8 87 10 00 00       	call   167fa <sprint>
   15773:	83 c4 20             	add    $0x20,%esp
   15776:	83 ec 0c             	sub    $0xc,%esp
   15779:	68 20 a4 01 00       	push   $0x1a420
   1577e:	e8 3e 0b 00 00       	call   162c1 <kpanic>
   15783:	83 c4 10             	add    $0x10,%esp

		// there is no "wait" queue - procs are just marked as waiting

		// send back the child's status and schedule init
		status_return( init_pcb, for_init );
   15786:	a1 84 a9 01 00       	mov    0x1a984,%eax
   1578b:	83 ec 08             	sub    $0x8,%esp
   1578e:	ff 75 f4             	push   -0xc(%ebp)
   15791:	50                   	push   %eax
   15792:	e8 30 fd ff ff       	call   154c7 <status_return>
   15797:	83 c4 10             	add    $0x10,%esp

		// make sure 'init' wakes up
		schedule( init_pcb );
   1579a:	a1 84 a9 01 00       	mov    0x1a984,%eax
   1579f:	83 ec 0c             	sub    $0xc,%esp
   157a2:	50                   	push   %eax
   157a3:	e8 74 df ff ff       	call   1371c <schedule>
   157a8:	83 c4 10             	add    $0x10,%esp

		// we're all done with the child, so get rid of it
		pcb_cleanup( for_init );
   157ab:	83 ec 0c             	sub    $0xc,%esp
   157ae:	ff 75 f4             	push   -0xc(%ebp)
   157b1:	e8 21 df ff ff       	call   136d7 <pcb_cleanup>
   157b6:	83 c4 10             	add    $0x10,%esp
	**    sleeping - zombify this process
	**    blocked - zombify this process
	**    ready - zombify this process
	*/

	if( parent->state == STATE_WAITING ) {
   157b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   157bc:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   157c0:	3c 06                	cmp    $0x6,%al
   157c2:	75 2f                	jne    157f3 <sys_exit+0x27f>

		// send back the status
		status_return( parent, pcb );
   157c4:	83 ec 08             	sub    $0x8,%esp
   157c7:	ff 75 08             	push   0x8(%ebp)
   157ca:	ff 75 f0             	push   -0x10(%ebp)
   157cd:	e8 f5 fc ff ff       	call   154c7 <status_return>
   157d2:	83 c4 10             	add    $0x10,%esp

		// wake up the parent
		schedule( parent );
   157d5:	83 ec 0c             	sub    $0xc,%esp
   157d8:	ff 75 f0             	push   -0x10(%ebp)
   157db:	e8 3c df ff ff       	call   1371c <schedule>
   157e0:	83 c4 10             	add    $0x10,%esp

		// all done with this process
		pcb_cleanup( pcb );
   157e3:	83 ec 0c             	sub    $0xc,%esp
   157e6:	ff 75 08             	push   0x8(%ebp)
   157e9:	e8 e9 de ff ff       	call   136d7 <pcb_cleanup>
   157ee:	83 c4 10             	add    $0x10,%esp
   157f1:	eb 0e                	jmp    15801 <sys_exit+0x28d>

	} else {

		// just want to zombify this process
		pcb_zombify( pcb );
   157f3:	83 ec 0c             	sub    $0xc,%esp
   157f6:	ff 75 08             	push   0x8(%ebp)
   157f9:	e8 73 de ff ff       	call   13671 <pcb_zombify>
   157fe:	83 c4 10             	add    $0x10,%esp
	}

	// either way, we need a new current process
	dispatch();
   15801:	e8 11 e0 ff ff       	call   13817 <dispatch>

	SYSCALL_EXIT(0);
}
   15806:	90                   	nop
   15807:	c9                   	leave  
   15808:	c3                   	ret    

00015809 <sys_wait>:
** Blocks the calling process until a child of the caller terminates.
** Intrinsic return is the PID of the child that terminated, or an error
** code; on success, returns the child's termination status via 'status'
** if that pointer is non-NULL.
*/
SYSIMPL(wait) {
   15809:	55                   	push   %ebp
   1580a:	89 e5                	mov    %esp,%ebp
   1580c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1580f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15813:	75 39                	jne    1584e <sys_wait+0x45>
   15815:	83 ec 08             	sub    $0x8,%esp
   15818:	68 73 81 01 00       	push   $0x18173
   1581d:	68 03 01 00 00       	push   $0x103
   15822:	68 2f 81 01 00       	push   $0x1812f
   15827:	68 18 83 01 00       	push   $0x18318
   1582c:	68 80 81 01 00       	push   $0x18180
   15831:	68 20 a4 01 00       	push   $0x1a420
   15836:	e8 bf 0f 00 00       	call   167fa <sprint>
   1583b:	83 c4 20             	add    $0x20,%esp
   1583e:	83 ec 0c             	sub    $0xc,%esp
   15841:	68 20 a4 01 00       	push   $0x1a420
   15846:	e8 76 0a 00 00       	call   162c1 <kpanic>
   1584b:	83 c4 10             	add    $0x10,%esp
	SYSCALL_ENTER(pcb->pid);

	// find a child of this process that has terminated, and
	// even if we don't find one, make sure we know if there were
	// any children at all
	int nkids = 0;
   1584e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *child = NULL;
   15855:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	** that won't work, because pcb_find_child_of() always
	** starts at the beginning of the table. grrr. instead,
	** we will scan the table ourselves.
	*/

	for( int i = 0; i < N_PROCS; ++i ) {
   1585c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   15863:	eb 47                	jmp    158ac <sys_wait+0xa3>

		// next process to check
		pcb_t *tmp = &ptable[i];
   15865:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15868:	c1 e0 05             	shl    $0x5,%eax
   1586b:	05 60 a6 01 00       	add    $0x1a660,%eax
   15870:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// a winning entry is one that:
		//    is not the process calling wait()
		//    is a child of the process calling wait()
		//    is a zombie

		if( tmp != pcb && tmp->parent == pcb && tmp->state != STATE_UNUSED ) {
   15873:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15876:	3b 45 08             	cmp    0x8(%ebp),%eax
   15879:	74 2d                	je     158a8 <sys_wait+0x9f>
   1587b:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1587e:	8b 40 08             	mov    0x8(%eax),%eax
   15881:	39 45 08             	cmp    %eax,0x8(%ebp)
   15884:	75 22                	jne    158a8 <sys_wait+0x9f>
   15886:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15889:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   1588d:	84 c0                	test   %al,%al
   1588f:	74 17                	je     158a8 <sys_wait+0x9f>
			// definitely a child of this parent
			++nkids;
   15891:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			// is it a zombie?
			if( tmp->state == STATE_ZOMBIE ) {
   15895:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15898:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   1589c:	3c 07                	cmp    $0x7,%al
   1589e:	75 08                	jne    158a8 <sys_wait+0x9f>
				// we have a winner!
				child = tmp;
   158a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   158a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
				break;
   158a6:	eb 0a                	jmp    158b2 <sys_wait+0xa9>
	for( int i = 0; i < N_PROCS; ++i ) {
   158a8:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   158ac:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   158b0:	7e b3                	jle    15865 <sys_wait+0x5c>
	}

	// if child is not NULL, we found an exited child, so we can just
	// return its information and clean it up
	
	if( child != NULL ) {
   158b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   158b6:	74 21                	je     158d9 <sys_wait+0xd0>
		// return the info
		status_return( pcb, child );
   158b8:	83 ec 08             	sub    $0x8,%esp
   158bb:	ff 75 f0             	push   -0x10(%ebp)
   158be:	ff 75 08             	push   0x8(%ebp)
   158c1:	e8 01 fc ff ff       	call   154c7 <status_return>
   158c6:	83 c4 10             	add    $0x10,%esp
		// clean things up
		pcb_cleanup( child );
   158c9:	83 ec 0c             	sub    $0xc,%esp
   158cc:	ff 75 f0             	push   -0x10(%ebp)
   158cf:	e8 03 de ff ff       	call   136d7 <pcb_cleanup>
   158d4:	83 c4 10             	add    $0x10,%esp
		// back into the calling process
		return;
   158d7:	eb 20                	jmp    158f9 <sys_wait+0xf0>
	}

	// no exited child was found; if we didn't find any at all,
	// return an error code
	
	if( nkids < 1 ) {
   158d9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   158dd:	7f 0e                	jg     158ed <sys_wait+0xe4>
		RET(pcb) = S_NO_CHILD;
   158df:	8b 45 08             	mov    0x8(%ebp),%eax
   158e2:	8b 00                	mov    (%eax),%eax
   158e4:	c7 40 30 fc ff ff ff 	movl   $0xfffffffc,0x30(%eax)
		return;
   158eb:	eb 0c                	jmp    158f9 <sys_wait+0xf0>
	}

	// there is at least one child, but it hasn't exited yet;
	// block this process and dispatch another one
	
	pcb->state = STATE_WAITING;
   158ed:	8b 45 08             	mov    0x8(%ebp),%eax
   158f0:	c6 40 18 06          	movb   $0x6,0x18(%eax)
	dispatch();
   158f4:	e8 1e df ff ff       	call   13817 <dispatch>

	SYSCALL_EXIT(0);
}
   158f9:	c9                   	leave  
   158fa:	c3                   	ret    

000158fb <sys_fork>:
** running at the specified process priority (or at the parent's priority
** if the special priority value PRIO_INHERIT is supplied).  On success,
** returns the child's PID to the parent and 0 to the child; else, returns
** an error code to the parent.
*/
SYSIMPL(fork) {
   158fb:	55                   	push   %ebp
   158fc:	89 e5                	mov    %esp,%ebp
   158fe:	83 ec 28             	sub    $0x28,%esp

	// sanity check
	assert( pcb != NULL );
   15901:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15905:	75 39                	jne    15940 <sys_fork+0x45>
   15907:	83 ec 08             	sub    $0x8,%esp
   1590a:	68 73 81 01 00       	push   $0x18173
   1590f:	68 67 01 00 00       	push   $0x167
   15914:	68 2f 81 01 00       	push   $0x1812f
   15919:	68 24 83 01 00       	push   $0x18324
   1591e:	68 80 81 01 00       	push   $0x18180
   15923:	68 20 a4 01 00       	push   $0x1a420
   15928:	e8 cd 0e 00 00       	call   167fa <sprint>
   1592d:	83 c4 20             	add    $0x20,%esp
   15930:	83 ec 0c             	sub    $0xc,%esp
   15933:	68 20 a4 01 00       	push   $0x1a420
   15938:	e8 84 09 00 00       	call   162c1 <kpanic>
   1593d:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER(pcb->pid);
	
	// allocate a PCB; if this fails, let the caller know
	pcb_t *new;
	int status = pcb_alloc( &new );
   15940:	83 ec 0c             	sub    $0xc,%esp
   15943:	8d 45 e4             	lea    -0x1c(%ebp),%eax
   15946:	50                   	push   %eax
   15947:	e8 64 db ff ff       	call   134b0 <pcb_alloc>
   1594c:	83 c4 10             	add    $0x10,%esp
   1594f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( status != E_SUCCESS ) {
   15952:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   15956:	74 11                	je     15969 <sys_fork+0x6e>
		RET(pcb) = S_ERROR;
   15958:	8b 45 08             	mov    0x8(%ebp),%eax
   1595b:	8b 00                	mov    (%eax),%eax
   1595d:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( S_ERROR );
		return;
   15964:	e9 8e 01 00 00       	jmp    15af7 <sys_fork+0x1fc>
	}

	// next, allocate a stack
	uint32_t *stk;
	status = stk_alloc( &stk );
   15969:	83 ec 0c             	sub    $0xc,%esp
   1596c:	8d 45 e0             	lea    -0x20(%ebp),%eax
   1596f:	50                   	push   %eax
   15970:	e8 00 f3 ff ff       	call   14c75 <stk_alloc>
   15975:	83 c4 10             	add    $0x10,%esp
   15978:	89 45 ec             	mov    %eax,-0x14(%ebp)

	if( status != E_SUCCESS ) {
   1597b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1597f:	74 20                	je     159a1 <sys_fork+0xa6>
		// must also free the PCB
		pcb_free( new );
   15981:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15984:	83 ec 0c             	sub    $0xc,%esp
   15987:	50                   	push   %eax
   15988:	e8 99 db ff ff       	call   13526 <pcb_free>
   1598d:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = S_ERROR;
   15990:	8b 45 08             	mov    0x8(%ebp),%eax
   15993:	8b 00                	mov    (%eax),%eax
   15995:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( S_ERROR );
		return;
   1599c:	e9 56 01 00 00       	jmp    15af7 <sys_fork+0x1fc>
	}

	// OK, we have all the pieces, start to fill things in;
	// begin by clearing the PCB
	memclr( new, sizeof(pcb_t) );
   159a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159a4:	83 ec 08             	sub    $0x8,%esp
   159a7:	6a 20                	push   $0x20
   159a9:	50                   	push   %eax
   159aa:	e8 7f 0d 00 00       	call   1672e <memclr>
   159af:	83 c4 10             	add    $0x10,%esp

	new->state = STATE_NEW;
   159b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159b5:	c6 40 18 01          	movb   $0x1,0x18(%eax)

	new->stack = stk;
   159b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159bc:	8b 55 e0             	mov    -0x20(%ebp),%edx
   159bf:	89 50 04             	mov    %edx,0x4(%eax)
	new->parent = pcb;
   159c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159c5:	8b 55 08             	mov    0x8(%ebp),%edx
   159c8:	89 50 08             	mov    %edx,0x8(%eax)
	new->pid = next_pid++;
   159cb:	a1 80 a9 01 00       	mov    0x1a980,%eax
   159d0:	8d 50 01             	lea    0x1(%eax),%edx
   159d3:	89 15 80 a9 01 00    	mov    %edx,0x1a980
   159d9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   159dc:	89 42 14             	mov    %eax,0x14(%edx)
	new->priority = ARG(pcb,1);
   159df:	8b 45 08             	mov    0x8(%ebp),%eax
   159e2:	8b 00                	mov    (%eax),%eax
   159e4:	83 c0 4c             	add    $0x4c,%eax
   159e7:	8b 10                	mov    (%eax),%edx
   159e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159ec:	88 50 19             	mov    %dl,0x19(%eax)

	// see if we're supposed to inherit the parent's priority
	if( new->priority == PRIO_INHERIT ) {
   159ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159f2:	0f b6 40 19          	movzbl 0x19(%eax),%eax
   159f6:	3c 80                	cmp    $0x80,%al
   159f8:	75 0d                	jne    15a07 <sys_fork+0x10c>
		new->priority = pcb->priority;
   159fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   159fd:	8b 55 08             	mov    0x8(%ebp),%edx
   15a00:	0f b6 52 19          	movzbl 0x19(%edx),%edx
   15a04:	88 50 19             	mov    %dl,0x19(%eax)
	}

	// duplicate the runtime stack
	blkmov( stk, pcb->stack, SZ_STACK );
   15a07:	8b 45 08             	mov    0x8(%ebp),%eax
   15a0a:	8b 50 04             	mov    0x4(%eax),%edx
   15a0d:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15a10:	83 ec 04             	sub    $0x4,%esp
   15a13:	68 00 20 00 00       	push   $0x2000
   15a18:	52                   	push   %edx
   15a19:	50                   	push   %eax
   15a1a:	e8 f8 09 00 00       	call   16417 <blkmov>
   15a1f:	83 c4 10             	add    $0x10,%esp
    ** them, as that's impractical. As a result, user code that relies on
    ** such pointers may behave strangely after a fork().
    */

    // Figure out the byte offset from one stack to the other.
    int32_t offset = (void *) stk - (void *) pcb->stack;
   15a22:	8b 55 e0             	mov    -0x20(%ebp),%edx
   15a25:	8b 45 08             	mov    0x8(%ebp),%eax
   15a28:	8b 48 04             	mov    0x4(%eax),%ecx
   15a2b:	89 d0                	mov    %edx,%eax
   15a2d:	29 c8                	sub    %ecx,%eax
   15a2f:	89 45 e8             	mov    %eax,-0x18(%ebp)

    // Add this to the child's context pointer.
    new->context = (context_t *) (((void *)pcb->context) + offset);
   15a32:	8b 45 08             	mov    0x8(%ebp),%eax
   15a35:	8b 08                	mov    (%eax),%ecx
   15a37:	8b 55 e8             	mov    -0x18(%ebp),%edx
   15a3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a3d:	01 ca                	add    %ecx,%edx
   15a3f:	89 10                	mov    %edx,(%eax)

    // Fix the child's ESP and EBP values IFF they're non-zero.
    if( REG(new,ebp) != 0 ) {
   15a41:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a44:	8b 00                	mov    (%eax),%eax
   15a46:	8b 40 1c             	mov    0x1c(%eax),%eax
   15a49:	85 c0                	test   %eax,%eax
   15a4b:	74 15                	je     15a62 <sys_fork+0x167>
        REG(new,ebp) += offset;
   15a4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a50:	8b 00                	mov    (%eax),%eax
   15a52:	8b 48 1c             	mov    0x1c(%eax),%ecx
   15a55:	8b 55 e8             	mov    -0x18(%ebp),%edx
   15a58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a5b:	8b 00                	mov    (%eax),%eax
   15a5d:	01 ca                	add    %ecx,%edx
   15a5f:	89 50 1c             	mov    %edx,0x1c(%eax)
    }

    if( REG(new,esp) != 0 ) {
   15a62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a65:	8b 00                	mov    (%eax),%eax
   15a67:	8b 40 20             	mov    0x20(%eax),%eax
   15a6a:	85 c0                	test   %eax,%eax
   15a6c:	74 15                	je     15a83 <sys_fork+0x188>
        REG(new,esp) += offset;
   15a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a71:	8b 00                	mov    (%eax),%eax
   15a73:	8b 48 20             	mov    0x20(%eax),%ecx
   15a76:	8b 55 e8             	mov    -0x18(%ebp),%edx
   15a79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a7c:	8b 00                	mov    (%eax),%eax
   15a7e:	01 ca                	add    %ecx,%edx
   15a80:	89 50 20             	mov    %edx,0x20(%eax)
    }

    // Follow the EBP chain through the child's stack.
    uint32_t *bp = (uint32_t *) REG(new,ebp);
   15a83:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15a86:	8b 00                	mov    (%eax),%eax
   15a88:	8b 40 1c             	mov    0x1c(%eax),%eax
   15a8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t *lastbp = NULL;
   15a8e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    while( bp ) {
   15a95:	eb 1d                	jmp    15ab4 <sys_fork+0x1b9>
        *bp += offset;
   15a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15a9a:	8b 10                	mov    (%eax),%edx
   15a9c:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15a9f:	01 c2                	add    %eax,%edx
   15aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15aa4:	89 10                	mov    %edx,(%eax)
		lastbp = bp;
   15aa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15aa9:	89 45 f0             	mov    %eax,-0x10(%ebp)
        bp = (uint32_t *) *bp;
   15aac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15aaf:	8b 00                	mov    (%eax),%eax
   15ab1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15ab4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15ab8:	75 dd                	jne    15a97 <sys_fork+0x19c>
	** lastbp now points to the EBP save area in the first stack
	** frame, which is the main() for the process. Immediately
	** below that is the return address, and immediately below
	** that is the arg string pointer. We need to fix that.
	*/
	lastbp += 2;
   15aba:	83 45 f0 08          	addl   $0x8,-0x10(%ebp)
	*lastbp += offset;
   15abe:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15ac1:	8b 10                	mov    (%eax),%edx
   15ac3:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15ac6:	01 c2                	add    %eax,%edx
   15ac8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15acb:	89 10                	mov    %edx,(%eax)

	// Set the return values for the two processes.
	RET(pcb) = new->pid;
   15acd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15ad0:	8b 50 14             	mov    0x14(%eax),%edx
   15ad3:	8b 45 08             	mov    0x8(%ebp),%eax
   15ad6:	8b 00                	mov    (%eax),%eax
   15ad8:	89 50 30             	mov    %edx,0x30(%eax)
	RET(new) = 0;
   15adb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15ade:	8b 00                	mov    (%eax),%eax
   15ae0:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

	// Schedule the child, and let the parent continue.
	schedule( new );
   15ae7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15aea:	83 ec 0c             	sub    $0xc,%esp
   15aed:	50                   	push   %eax
   15aee:	e8 29 dc ff ff       	call   1371c <schedule>
   15af3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( new->pid );
	return;
   15af6:	90                   	nop
}
   15af7:	c9                   	leave  
   15af8:	c3                   	ret    

00015af9 <sys_exec>:
** indicated program, using the specified command-line arguments.
**
** Returns only on failure.
*/
SYSIMPL(exec)
{
   15af9:	55                   	push   %ebp
   15afa:	89 e5                	mov    %esp,%ebp
   15afc:	83 ec 28             	sub    $0x28,%esp

	// sanity check
	assert( pcb != NULL );
   15aff:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15b03:	75 39                	jne    15b3e <sys_exec+0x45>
   15b05:	83 ec 08             	sub    $0x8,%esp
   15b08:	68 73 81 01 00       	push   $0x18173
   15b0d:	68 da 01 00 00       	push   $0x1da
   15b12:	68 2f 81 01 00       	push   $0x1812f
   15b17:	68 30 83 01 00       	push   $0x18330
   15b1c:	68 80 81 01 00       	push   $0x18180
   15b21:	68 20 a4 01 00       	push   $0x1a420
   15b26:	e8 cf 0c 00 00       	call   167fa <sprint>
   15b2b:	83 c4 20             	add    $0x20,%esp
   15b2e:	83 ec 0c             	sub    $0xc,%esp
   15b31:	68 20 a4 01 00       	push   $0x1a420
   15b36:	e8 86 07 00 00       	call   162c1 <kpanic>
   15b3b:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// grab the arguments
	uint32_t where = ARG(pcb,1);
   15b3e:	8b 45 08             	mov    0x8(%ebp),%eax
   15b41:	8b 00                	mov    (%eax),%eax
   15b43:	8b 40 4c             	mov    0x4c(%eax),%eax
   15b46:	89 45 f4             	mov    %eax,-0xc(%ebp)
	const char *args = (const char *) ARG(pcb,2);
   15b49:	8b 45 08             	mov    0x8(%ebp),%eax
   15b4c:	8b 00                	mov    (%eax),%eax
   15b4e:	83 c0 50             	add    $0x50,%eax
   15b51:	8b 00                	mov    (%eax),%eax
   15b53:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// we create a new stack for the process so we don't have to
	// worry about overwriting data in the old stack; however, we
	// need to keep the old one around until after we have copied
	// all the argument data from it.
	uint32_t *oldstack = pcb->stack;
   15b56:	8b 45 08             	mov    0x8(%ebp),%eax
   15b59:	8b 40 04             	mov    0x4(%eax),%eax
   15b5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t *stk;
	int status = stk_alloc( &stk );
   15b5f:	83 ec 0c             	sub    $0xc,%esp
   15b62:	8d 45 e4             	lea    -0x1c(%ebp),%eax
   15b65:	50                   	push   %eax
   15b66:	e8 0a f1 ff ff       	call   14c75 <stk_alloc>
   15b6b:	83 c4 10             	add    $0x10,%esp
   15b6e:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// if the alloc fails, we're done
	if( status != E_SUCCESS ) {
   15b71:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   15b75:	74 0e                	je     15b85 <sys_exec+0x8c>
		// process will probably never look at this
		RET(pcb) = S_ERROR;
   15b77:	8b 45 08             	mov    0x8(%ebp),%eax
   15b7a:	8b 00                	mov    (%eax),%eax
   15b7c:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
   15b83:	eb 6a                	jmp    15bef <sys_exec+0xf6>
		SYSCALL_EXIT( pcb->pid );
		return;
	}

	// set up the new stack using the old stack data
	pcb->context = stk_setup( stk, where, args );
   15b85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15b88:	83 ec 04             	sub    $0x4,%esp
   15b8b:	ff 75 f0             	push   -0x10(%ebp)
   15b8e:	ff 75 f4             	push   -0xc(%ebp)
   15b91:	50                   	push   %eax
   15b92:	e8 a5 f1 ff ff       	call   14d3c <stk_setup>
   15b97:	83 c4 10             	add    $0x10,%esp
   15b9a:	8b 55 08             	mov    0x8(%ebp),%edx
   15b9d:	89 02                	mov    %eax,(%edx)
	assert1( pcb->context != NULL );
   15b9f:	8b 45 08             	mov    0x8(%ebp),%eax
   15ba2:	8b 00                	mov    (%eax),%eax
   15ba4:	85 c0                	test   %eax,%eax
   15ba6:	75 39                	jne    15be1 <sys_exec+0xe8>
   15ba8:	83 ec 08             	sub    $0x8,%esp
   15bab:	68 10 82 01 00       	push   $0x18210
   15bb0:	68 f4 01 00 00       	push   $0x1f4
   15bb5:	68 2f 81 01 00       	push   $0x1812f
   15bba:	68 30 83 01 00       	push   $0x18330
   15bbf:	68 44 81 01 00       	push   $0x18144
   15bc4:	68 20 a4 01 00       	push   $0x1a420
   15bc9:	e8 2c 0c 00 00       	call   167fa <sprint>
   15bce:	83 c4 20             	add    $0x20,%esp
   15bd1:	83 ec 0c             	sub    $0xc,%esp
   15bd4:	68 20 a4 01 00       	push   $0x1a420
   15bd9:	e8 e3 06 00 00       	call   162c1 <kpanic>
   15bde:	83 c4 10             	add    $0x10,%esp

	// now we can safely free the old stack
	stk_free( oldstack );
   15be1:	83 ec 0c             	sub    $0xc,%esp
   15be4:	ff 75 ec             	push   -0x14(%ebp)
   15be7:	e8 ef f0 ff ff       	call   14cdb <stk_free>
   15bec:	83 c4 10             	add    $0x10,%esp
	 **
	 ** We choose option B.
	 */

	SYSCALL_EXIT( pcb->pid );
}
   15bef:	c9                   	leave  
   15bf0:	c3                   	ret    

00015bf1 <sys_read>:
**		int read( uint32_t chan, void *buffer, uint32_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {
   15bf1:	55                   	push   %ebp
   15bf2:	89 e5                	mov    %esp,%ebp
   15bf4:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15bf7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15bfb:	75 39                	jne    15c36 <sys_read+0x45>
   15bfd:	83 ec 08             	sub    $0x8,%esp
   15c00:	68 73 81 01 00       	push   $0x18173
   15c05:	68 11 02 00 00       	push   $0x211
   15c0a:	68 2f 81 01 00       	push   $0x1812f
   15c0f:	68 3c 83 01 00       	push   $0x1833c
   15c14:	68 80 81 01 00       	push   $0x18180
   15c19:	68 20 a4 01 00       	push   $0x1a420
   15c1e:	e8 d7 0b 00 00       	call   167fa <sprint>
   15c23:	83 c4 20             	add    $0x20,%esp
   15c26:	83 ec 0c             	sub    $0xc,%esp
   15c29:	68 20 a4 01 00       	push   $0x1a420
   15c2e:	e8 8e 06 00 00       	call   162c1 <kpanic>
   15c33:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
	
	// grab the arguments
	uint32_t chan = ARG(pcb,1);
   15c36:	8b 45 08             	mov    0x8(%ebp),%eax
   15c39:	8b 00                	mov    (%eax),%eax
   15c3b:	8b 40 4c             	mov    0x4c(%eax),%eax
   15c3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t len = ARG(pcb,3);
   15c41:	8b 45 08             	mov    0x8(%ebp),%eax
   15c44:	8b 00                	mov    (%eax),%eax
   15c46:	8b 40 54             	mov    0x54(%eax),%eax
   15c49:	89 45 f0             	mov    %eax,-0x10(%ebp)
	**
	** This line MUST CHANGE if VM is implemented, because the pointer
	** being retrieved is a pointer in user space, not kernel space.
	******************************************************************
	*/
	char *buf = (char *) ARG(pcb,2);
   15c4c:	8b 45 08             	mov    0x8(%ebp),%eax
   15c4f:	8b 00                	mov    (%eax),%eax
   15c51:	83 c0 50             	add    $0x50,%eax
   15c54:	8b 00                	mov    (%eax),%eax
   15c56:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// if the buffer is of length 0, we're done!
	if( len == 0 ) {
   15c59:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   15c5d:	75 11                	jne    15c70 <sys_read+0x7f>
		RET(pcb) = 0;
   15c5f:	8b 45 08             	mov    0x8(%ebp),%eax
   15c62:	8b 00                	mov    (%eax),%eax
   15c64:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		SYSCALL_EXIT( 0 );
		return;
   15c6b:	e9 e9 00 00 00       	jmp    15d59 <sys_read+0x168>
	}

	// try to get the next character(s)
	int n = 0;
   15c70:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	if( chan == CHAN_CIO ) {
   15c77:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15c7b:	75 3e                	jne    15cbb <sys_read+0xca>

		// console input is non-blocking
		if( cio_input_queue() < 1 ) {
   15c7d:	e8 28 bd ff ff       	call   119aa <cio_input_queue>
   15c82:	85 c0                	test   %eax,%eax
   15c84:	7f 11                	jg     15c97 <sys_read+0xa6>
			RET(pcb) = 0;
   15c86:	8b 45 08             	mov    0x8(%ebp),%eax
   15c89:	8b 00                	mov    (%eax),%eax
   15c8b:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
			SYSCALL_EXIT( 0 );
			return;
   15c92:	e9 c2 00 00 00       	jmp    15d59 <sys_read+0x168>
		}
		// at least one character
		n = cio_gets( buf, len );
   15c97:	83 ec 08             	sub    $0x8,%esp
   15c9a:	ff 75 f0             	push   -0x10(%ebp)
   15c9d:	ff 75 ec             	push   -0x14(%ebp)
   15ca0:	e8 b4 bc ff ff       	call   11959 <cio_gets>
   15ca5:	83 c4 10             	add    $0x10,%esp
   15ca8:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   15cab:	8b 45 08             	mov    0x8(%ebp),%eax
   15cae:	8b 00                	mov    (%eax),%eax
   15cb0:	8b 55 e8             	mov    -0x18(%ebp),%edx
   15cb3:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
		return;
   15cb6:	e9 9e 00 00 00       	jmp    15d59 <sys_read+0x168>

	} else if( chan == CHAN_SIO ) {
   15cbb:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
   15cbf:	0f 85 87 00 00 00    	jne    15d4c <sys_read+0x15b>

		// SIO input is blocking, so if there are no characters
		// available, we'll block this process
		n = sio_read( buf, len );
   15cc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15cc8:	83 ec 08             	sub    $0x8,%esp
   15ccb:	50                   	push   %eax
   15ccc:	ff 75 ec             	push   -0x14(%ebp)
   15ccf:	e8 9d eb ff ff       	call   14871 <sio_read>
   15cd4:	83 c4 10             	add    $0x10,%esp
   15cd7:	89 45 e8             	mov    %eax,-0x18(%ebp)

		if( n < 1 ) {
   15cda:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   15cde:	7f 5f                	jg     15d3f <sys_read+0x14e>
			// nothing available, so we'll block
			pcb->state = STATE_BLOCKED;
   15ce0:	8b 45 08             	mov    0x8(%ebp),%eax
   15ce3:	c6 40 18 05          	movb   $0x5,0x18(%eax)
			assert1( que_insert(sioread,(void *)pcb) != E_SUCCESS );
   15ce7:	a1 58 a6 01 00       	mov    0x1a658,%eax
   15cec:	83 ec 08             	sub    $0x8,%esp
   15cef:	ff 75 08             	push   0x8(%ebp)
   15cf2:	50                   	push   %eax
   15cf3:	e8 c7 df ff ff       	call   13cbf <que_insert>
   15cf8:	83 c4 10             	add    $0x10,%esp
   15cfb:	85 c0                	test   %eax,%eax
   15cfd:	75 39                	jne    15d38 <sys_read+0x147>
   15cff:	83 ec 08             	sub    $0x8,%esp
   15d02:	68 28 82 01 00       	push   $0x18228
   15d07:	68 44 02 00 00       	push   $0x244
   15d0c:	68 2f 81 01 00       	push   $0x1812f
   15d11:	68 3c 83 01 00       	push   $0x1833c
   15d16:	68 44 81 01 00       	push   $0x18144
   15d1b:	68 20 a4 01 00       	push   $0x1a420
   15d20:	e8 d5 0a 00 00       	call   167fa <sprint>
   15d25:	83 c4 20             	add    $0x20,%esp
   15d28:	83 ec 0c             	sub    $0xc,%esp
   15d2b:	68 20 a4 01 00       	push   $0x1a420
   15d30:	e8 8c 05 00 00       	call   162c1 <kpanic>
   15d35:	83 c4 10             	add    $0x10,%esp
			// dispatch a new process
			dispatch();
   15d38:	e8 da da ff ff       	call   13817 <dispatch>
			SYSCALL_EXIT(0);
			return;
   15d3d:	eb 1a                	jmp    15d59 <sys_read+0x168>
		}

		// got one or more characters; let the user know
		RET(pcb) = n;
   15d3f:	8b 45 08             	mov    0x8(%ebp),%eax
   15d42:	8b 00                	mov    (%eax),%eax
   15d44:	8b 55 e8             	mov    -0x18(%ebp),%edx
   15d47:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
		return;
   15d4a:	eb 0d                	jmp    15d59 <sys_read+0x168>

	}

	// bad channel code
	RET(pcb) = S_BAD_CHAN;
   15d4c:	8b 45 08             	mov    0x8(%ebp),%eax
   15d4f:	8b 00                	mov    (%eax),%eax
   15d51:	c7 40 30 fb ff ff ff 	movl   $0xfffffffb,0x30(%eax)
	SYSCALL_EXIT( S_BAD_CHAN );
	return;
   15d58:	90                   	nop
}
   15d59:	c9                   	leave  
   15d5a:	c3                   	ret    

00015d5b <sys_write>:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {
   15d5b:	55                   	push   %ebp
   15d5c:	89 e5                	mov    %esp,%ebp
   15d5e:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15d61:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15d65:	75 39                	jne    15da0 <sys_write+0x45>
   15d67:	83 ec 08             	sub    $0x8,%esp
   15d6a:	68 73 81 01 00       	push   $0x18173
   15d6f:	68 64 02 00 00       	push   $0x264
   15d74:	68 2f 81 01 00       	push   $0x1812f
   15d79:	68 48 83 01 00       	push   $0x18348
   15d7e:	68 80 81 01 00       	push   $0x18180
   15d83:	68 20 a4 01 00       	push   $0x1a420
   15d88:	e8 6d 0a 00 00       	call   167fa <sprint>
   15d8d:	83 c4 20             	add    $0x20,%esp
   15d90:	83 ec 0c             	sub    $0xc,%esp
   15d93:	68 20 a4 01 00       	push   $0x1a420
   15d98:	e8 24 05 00 00       	call   162c1 <kpanic>
   15d9d:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// grab the parameters
	uint_t chan = ARG(pcb,1);
   15da0:	8b 45 08             	mov    0x8(%ebp),%eax
   15da3:	8b 00                	mov    (%eax),%eax
   15da5:	8b 40 4c             	mov    0x4c(%eax),%eax
   15da8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint_t length = ARG(pcb,3);
   15dab:	8b 45 08             	mov    0x8(%ebp),%eax
   15dae:	8b 00                	mov    (%eax),%eax
   15db0:	8b 40 54             	mov    0x54(%eax),%eax
   15db3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	**
	** This line MUST CHANGE if VM is implemented, because the pointer
	** being retrieved is a pointer in user space, not kernel space.
	******************************************************************
	*/
	char *buf = (char *) ARG(pcb,2);
   15db6:	8b 45 08             	mov    0x8(%ebp),%eax
   15db9:	8b 00                	mov    (%eax),%eax
   15dbb:	83 c0 50             	add    $0x50,%eax
   15dbe:	8b 00                	mov    (%eax),%eax
   15dc0:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// this is almost insanely simple, but it does separate the
	// low-level device access fromm the higher-level syscall implementation

	// assume we write the indicated amount
	int rval = length;
   15dc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dc6:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// simplest case
	if( length >= 0 ) {

		if( chan == CHAN_CIO ) {
   15dc9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   15dcd:	75 14                	jne    15de3 <sys_write+0x88>

			cio_write( buf, length );
   15dcf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dd2:	83 ec 08             	sub    $0x8,%esp
   15dd5:	50                   	push   %eax
   15dd6:	ff 75 e8             	push   -0x18(%ebp)
   15dd9:	e8 e3 b2 ff ff       	call   110c1 <cio_write>
   15dde:	83 c4 10             	add    $0x10,%esp
   15de1:	eb 21                	jmp    15e04 <sys_write+0xa9>

		} else if( chan == CHAN_SIO ) {
   15de3:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   15de7:	75 14                	jne    15dfd <sys_write+0xa2>

			sio_write( buf, length );
   15de9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dec:	83 ec 08             	sub    $0x8,%esp
   15def:	50                   	push   %eax
   15df0:	ff 75 e8             	push   -0x18(%ebp)
   15df3:	e8 8a eb ff ff       	call   14982 <sio_write>
   15df8:	83 c4 10             	add    $0x10,%esp
   15dfb:	eb 07                	jmp    15e04 <sys_write+0xa9>

		} else {

			rval = S_BAD_CHAN;
   15dfd:	c7 45 f4 fb ff ff ff 	movl   $0xfffffffb,-0xc(%ebp)

		}

	}

	RET(pcb) = rval;
   15e04:	8b 45 08             	mov    0x8(%ebp),%eax
   15e07:	8b 00                	mov    (%eax),%eax
   15e09:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15e0c:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( rval );
	return;
   15e0f:	90                   	nop
}
   15e10:	c9                   	leave  
   15e11:	c3                   	ret    

00015e12 <sys_sleep>:
**		void  sleep( uint32_t n );
**
** Puts the calling process to sleep for 'n' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {
   15e12:	55                   	push   %ebp
   15e13:	89 e5                	mov    %esp,%ebp
   15e15:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15e18:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15e1c:	75 39                	jne    15e57 <sys_sleep+0x45>
   15e1e:	83 ec 08             	sub    $0x8,%esp
   15e21:	68 73 81 01 00       	push   $0x18173
   15e26:	68 a1 02 00 00       	push   $0x2a1
   15e2b:	68 2f 81 01 00       	push   $0x1812f
   15e30:	68 54 83 01 00       	push   $0x18354
   15e35:	68 80 81 01 00       	push   $0x18180
   15e3a:	68 20 a4 01 00       	push   $0x1a420
   15e3f:	e8 b6 09 00 00       	call   167fa <sprint>
   15e44:	83 c4 20             	add    $0x20,%esp
   15e47:	83 ec 0c             	sub    $0xc,%esp
   15e4a:	68 20 a4 01 00       	push   $0x1a420
   15e4f:	e8 6d 04 00 00       	call   162c1 <kpanic>
   15e54:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// get the desired duration
	uint32_t n = ARG( pcb, 1 );
   15e57:	8b 45 08             	mov    0x8(%ebp),%eax
   15e5a:	8b 00                	mov    (%eax),%eax
   15e5c:	8b 40 4c             	mov    0x4c(%eax),%eax
   15e5f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( n == 0 ) {
   15e62:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15e66:	75 15                	jne    15e7d <sys_sleep+0x6b>

		// back on the ready queue
		schedule( pcb );
   15e68:	83 ec 0c             	sub    $0xc,%esp
   15e6b:	ff 75 08             	push   0x8(%ebp)
   15e6e:	e8 a9 d8 ff ff       	call   1371c <schedule>
   15e73:	83 c4 10             	add    $0x10,%esp

		// pick a new process
		dispatch();
   15e76:	e8 9c d9 ff ff       	call   13817 <dispatch>
			dispatch();
		}
	}

	SYSCALL_EXIT( pcb->pid );
}
   15e7b:	eb 70                	jmp    15eed <sys_sleep+0xdb>
		pcb->state = STATE_SLEEPING;
   15e7d:	8b 45 08             	mov    0x8(%ebp),%eax
   15e80:	c6 40 18 04          	movb   $0x4,0x18(%eax)
		pcb->wakeup = system_time + n;
   15e84:	8b 15 0c a1 01 00    	mov    0x1a10c,%edx
   15e8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15e8d:	01 c2                	add    %eax,%edx
   15e8f:	8b 45 08             	mov    0x8(%ebp),%eax
   15e92:	89 50 0c             	mov    %edx,0xc(%eax)
		if( que_insert(sleeping,pcb) != E_SUCCESS ) {
   15e95:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   15e9a:	83 ec 08             	sub    $0x8,%esp
   15e9d:	ff 75 08             	push   0x8(%ebp)
   15ea0:	50                   	push   %eax
   15ea1:	e8 19 de ff ff       	call   13cbf <que_insert>
   15ea6:	83 c4 10             	add    $0x10,%esp
   15ea9:	85 c0                	test   %eax,%eax
   15eab:	74 3b                	je     15ee8 <sys_sleep+0xd6>
			WARNING( "sleep pcb insert failed" );
   15ead:	68 b8 02 00 00       	push   $0x2b8
   15eb2:	68 2f 81 01 00       	push   $0x1812f
   15eb7:	68 54 83 01 00       	push   $0x18354
   15ebc:	68 55 82 01 00       	push   $0x18255
   15ec1:	e8 41 b8 ff ff       	call   11707 <cio_printf>
   15ec6:	83 c4 10             	add    $0x10,%esp
   15ec9:	83 ec 0c             	sub    $0xc,%esp
   15ecc:	68 68 82 01 00       	push   $0x18268
   15ed1:	e8 b9 b1 ff ff       	call   1108f <cio_puts>
   15ed6:	83 c4 10             	add    $0x10,%esp
   15ed9:	83 ec 0c             	sub    $0xc,%esp
   15edc:	6a 0a                	push   $0xa
   15ede:	e8 29 b0 ff ff       	call   10f0c <cio_putchar>
   15ee3:	83 c4 10             	add    $0x10,%esp
}
   15ee6:	eb 05                	jmp    15eed <sys_sleep+0xdb>
			dispatch();
   15ee8:	e8 2a d9 ff ff       	call   13817 <dispatch>
}
   15eed:	90                   	nop
   15eee:	c9                   	leave  
   15eef:	c3                   	ret    

00015ef0 <sys_getpid>:
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {
   15ef0:	55                   	push   %ebp
   15ef1:	89 e5                	mov    %esp,%ebp
   15ef3:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   15ef6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15efa:	75 39                	jne    15f35 <sys_getpid+0x45>
   15efc:	83 ec 08             	sub    $0x8,%esp
   15eff:	68 73 81 01 00       	push   $0x18173
   15f04:	68 cb 02 00 00       	push   $0x2cb
   15f09:	68 2f 81 01 00       	push   $0x1812f
   15f0e:	68 60 83 01 00       	push   $0x18360
   15f13:	68 80 81 01 00       	push   $0x18180
   15f18:	68 20 a4 01 00       	push   $0x1a420
   15f1d:	e8 d8 08 00 00       	call   167fa <sprint>
   15f22:	83 c4 20             	add    $0x20,%esp
   15f25:	83 ec 0c             	sub    $0xc,%esp
   15f28:	68 20 a4 01 00       	push   $0x1a420
   15f2d:	e8 8f 03 00 00       	call   162c1 <kpanic>
   15f32:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// return the time
	RET(pcb) = pcb->pid;
   15f35:	8b 45 08             	mov    0x8(%ebp),%eax
   15f38:	8b 50 14             	mov    0x14(%eax),%edx
   15f3b:	8b 45 08             	mov    0x8(%ebp),%eax
   15f3e:	8b 00                	mov    (%eax),%eax
   15f40:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( pcb->pid );
}
   15f43:	90                   	nop
   15f44:	c9                   	leave  
   15f45:	c3                   	ret    

00015f46 <sys_gettime>:
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {
   15f46:	55                   	push   %ebp
   15f47:	89 e5                	mov    %esp,%ebp
   15f49:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   15f4c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15f50:	75 39                	jne    15f8b <sys_gettime+0x45>
   15f52:	83 ec 08             	sub    $0x8,%esp
   15f55:	68 73 81 01 00       	push   $0x18173
   15f5a:	68 de 02 00 00       	push   $0x2de
   15f5f:	68 2f 81 01 00       	push   $0x1812f
   15f64:	68 6c 83 01 00       	push   $0x1836c
   15f69:	68 80 81 01 00       	push   $0x18180
   15f6e:	68 20 a4 01 00       	push   $0x1a420
   15f73:	e8 82 08 00 00       	call   167fa <sprint>
   15f78:	83 c4 20             	add    $0x20,%esp
   15f7b:	83 ec 0c             	sub    $0xc,%esp
   15f7e:	68 20 a4 01 00       	push   $0x1a420
   15f83:	e8 39 03 00 00       	call   162c1 <kpanic>
   15f88:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// return the time
	RET(pcb) = system_time;
   15f8b:	8b 45 08             	mov    0x8(%ebp),%eax
   15f8e:	8b 00                	mov    (%eax),%eax
   15f90:	8b 15 0c a1 01 00    	mov    0x1a10c,%edx
   15f96:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( pcb->pid );
}
   15f99:	90                   	nop
   15f9a:	c9                   	leave  
   15f9b:	c3                   	ret    

00015f9c <sys_getprio>:
**		int getprio( pid_t pid );
**
** The special value 0 can be supplied as the PID; it is interpreted
** as an alias for the calling process' PID.
*/
SYSIMPL(getprio) {
   15f9c:	55                   	push   %ebp
   15f9d:	89 e5                	mov    %esp,%ebp
   15f9f:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert( pcb != NULL );
   15fa2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15fa6:	75 39                	jne    15fe1 <sys_getprio+0x45>
   15fa8:	83 ec 08             	sub    $0x8,%esp
   15fab:	68 73 81 01 00       	push   $0x18173
   15fb0:	68 f4 02 00 00       	push   $0x2f4
   15fb5:	68 2f 81 01 00       	push   $0x1812f
   15fba:	68 78 83 01 00       	push   $0x18378
   15fbf:	68 80 81 01 00       	push   $0x18180
   15fc4:	68 20 a4 01 00       	push   $0x1a420
   15fc9:	e8 2c 08 00 00       	call   167fa <sprint>
   15fce:	83 c4 20             	add    $0x20,%esp
   15fd1:	83 ec 0c             	sub    $0xc,%esp
   15fd4:	68 20 a4 01 00       	push   $0x1a420
   15fd9:	e8 e3 02 00 00       	call   162c1 <kpanic>
   15fde:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );

	// check the PID
	pid_t pid = ARG(pcb,1);
   15fe1:	8b 45 08             	mov    0x8(%ebp),%eax
   15fe4:	8b 00                	mov    (%eax),%eax
   15fe6:	83 c0 4c             	add    $0x4c,%eax
   15fe9:	8b 00                	mov    (%eax),%eax
   15feb:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// if it's this process, no search is required
	if( pid == 0 || pid == pcb->pid ) {
   15fee:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15ff2:	74 0b                	je     15fff <sys_getprio+0x63>
   15ff4:	8b 45 08             	mov    0x8(%ebp),%eax
   15ff7:	8b 40 14             	mov    0x14(%eax),%eax
   15ffa:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   15ffd:	75 14                	jne    16013 <sys_getprio+0x77>
		RET(pcb) = (uint32_t) (pcb->priority);
   15fff:	8b 45 08             	mov    0x8(%ebp),%eax
   16002:	0f b6 50 19          	movzbl 0x19(%eax),%edx
   16006:	8b 45 08             	mov    0x8(%ebp),%eax
   16009:	8b 00                	mov    (%eax),%eax
   1600b:	0f b6 d2             	movzbl %dl,%edx
   1600e:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( pcb->pid );
		return;
   16011:	eb 42                	jmp    16055 <sys_getprio+0xb9>
	}

	// not this process, so we need to search
	pcb_t *p = pcb_find_pid( pid );
   16013:	83 ec 0c             	sub    $0xc,%esp
   16016:	ff 75 f4             	push   -0xc(%ebp)
   16019:	e8 57 d5 ff ff       	call   13575 <pcb_find_pid>
   1601e:	83 c4 10             	add    $0x10,%esp
   16021:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if( pcb != NULL && pcb->state != STATE_UNUSED ) {
   16024:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16028:	74 1f                	je     16049 <sys_getprio+0xad>
   1602a:	8b 45 08             	mov    0x8(%ebp),%eax
   1602d:	0f b6 40 18          	movzbl 0x18(%eax),%eax
   16031:	84 c0                	test   %al,%al
   16033:	74 14                	je     16049 <sys_getprio+0xad>
		// found it!
		RET(pcb) = (uint32_t) (p->priority);
   16035:	8b 45 f0             	mov    -0x10(%ebp),%eax
   16038:	0f b6 50 19          	movzbl 0x19(%eax),%edx
   1603c:	8b 45 08             	mov    0x8(%ebp),%eax
   1603f:	8b 00                	mov    (%eax),%eax
   16041:	0f b6 d2             	movzbl %dl,%edx
   16044:	89 50 30             	mov    %edx,0x30(%eax)
   16047:	eb 0c                	jmp    16055 <sys_getprio+0xb9>
	} else {
		// no such process
		RET(pcb) = S_NOT_FOUND;
   16049:	8b 45 08             	mov    0x8(%ebp),%eax
   1604c:	8b 00                	mov    (%eax),%eax
   1604e:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
	}

	SYSCALL_EXIT( pcb->pid );
}
   16055:	c9                   	leave  
   16056:	c3                   	ret    

00016057 <sys_isr>:
** System call ISR
**
** @param[in] vector   Vector number for this interrupt
** @param[in] code     Error code (0 for this interrupt)
*/
static void sys_isr( int vector, int code ) {
   16057:	55                   	push   %ebp
   16058:	89 e5                	mov    %esp,%ebp
   1605a:	83 ec 18             	sub    $0x18,%esp
	// keep the compiler happy
	(void) vector;
	(void) code;

	// sanity checks!
	assert( current != NULL );
   1605d:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   16062:	85 c0                	test   %eax,%eax
   16064:	75 39                	jne    1609f <sys_isr+0x48>
   16066:	83 ec 08             	sub    $0x8,%esp
   16069:	68 a8 82 01 00       	push   $0x182a8
   1606e:	68 39 03 00 00       	push   $0x339
   16073:	68 2f 81 01 00       	push   $0x1812f
   16078:	68 84 83 01 00       	push   $0x18384
   1607d:	68 80 81 01 00       	push   $0x18180
   16082:	68 20 a4 01 00       	push   $0x1a420
   16087:	e8 6e 07 00 00       	call   167fa <sprint>
   1608c:	83 c4 20             	add    $0x20,%esp
   1608f:	83 ec 0c             	sub    $0xc,%esp
   16092:	68 20 a4 01 00       	push   $0x1a420
   16097:	e8 25 02 00 00       	call   162c1 <kpanic>
   1609c:	83 c4 10             	add    $0x10,%esp
	assert( current->context != NULL );
   1609f:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   160a4:	8b 00                	mov    (%eax),%eax
   160a6:	85 c0                	test   %eax,%eax
   160a8:	75 39                	jne    160e3 <sys_isr+0x8c>
   160aa:	83 ec 08             	sub    $0x8,%esp
   160ad:	68 b8 82 01 00       	push   $0x182b8
   160b2:	68 3a 03 00 00       	push   $0x33a
   160b7:	68 2f 81 01 00       	push   $0x1812f
   160bc:	68 84 83 01 00       	push   $0x18384
   160c1:	68 80 81 01 00       	push   $0x18180
   160c6:	68 20 a4 01 00       	push   $0x1a420
   160cb:	e8 2a 07 00 00       	call   167fa <sprint>
   160d0:	83 c4 20             	add    $0x20,%esp
   160d3:	83 ec 0c             	sub    $0xc,%esp
   160d6:	68 20 a4 01 00       	push   $0x1a420
   160db:	e8 e1 01 00 00       	call   162c1 <kpanic>
   160e0:	83 c4 10             	add    $0x10,%esp

	// retrieve the syscall code
	code = REG( current, eax );
   160e3:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   160e8:	8b 00                	mov    (%eax),%eax
   160ea:	8b 40 30             	mov    0x30(%eax),%eax
   160ed:	89 45 0c             	mov    %eax,0xc(%ebp)
#if TRACING_SYSCALLS || TRACING_SYSRETS
	cio_printf( "** --> SYS pid %u code %u\n", current->pid, code );
#endif

	// validate it
	if( code < 0 || code >= N_SYSCALLS ) {
   160f0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   160f4:	78 06                	js     160fc <sys_isr+0xa5>
   160f6:	83 7d 0c 09          	cmpl   $0x9,0xc(%ebp)
   160fa:	7e 33                	jle    1612f <sys_isr+0xd8>
		// bad syscall number
		// could kill it, but we'll just force it to exit
		cio_printf( "sys_isr: pid %d bad syscall (%d)\n", current->pid, code );
   160fc:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   16101:	8b 40 14             	mov    0x14(%eax),%eax
   16104:	83 ec 04             	sub    $0x4,%esp
   16107:	ff 75 0c             	push   0xc(%ebp)
   1610a:	50                   	push   %eax
   1610b:	68 d4 82 01 00       	push   $0x182d4
   16110:	e8 f2 b5 ff ff       	call   11707 <cio_printf>
   16115:	83 c4 10             	add    $0x10,%esp
		code = SYS_exit;
   16118:	c7 45 0c 00 00 00 00 	movl   $0x0,0xc(%ebp)
		ARG(current,1) = S_BAD_SYSCALL;
   1611f:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   16124:	8b 00                	mov    (%eax),%eax
   16126:	83 c0 4c             	add    $0x4c,%eax
   16129:	c7 00 fd ff ff ff    	movl   $0xfffffffd,(%eax)
	}

	// call the handler
	syscalls[code]( current );
   1612f:	8b 45 0c             	mov    0xc(%ebp),%eax
   16132:	8b 04 85 80 82 01 00 	mov    0x18280(,%eax,4),%eax
   16139:	8b 15 5c a6 01 00    	mov    0x1a65c,%edx
   1613f:	83 ec 0c             	sub    $0xc,%esp
   16142:	52                   	push   %edx
   16143:	ff d0                	call   *%eax
   16145:	83 c4 10             	add    $0x10,%esp
   16148:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
   1614f:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   16153:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   16157:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1615a:	ee                   	out    %al,(%dx)
}
   1615b:	90                   	nop
	cio_printf( "** <-- SYS pid %u ret %u\n", current->pid, RET(current) );
#endif

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   1615c:	90                   	nop
   1615d:	c9                   	leave  
   1615e:	c3                   	ret    

0001615f <sys_init>:
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init( void ) {
   1615f:	55                   	push   %ebp
   16160:	89 e5                	mov    %esp,%ebp
   16162:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Sys" );
   16165:	83 ec 0c             	sub    $0xc,%esp
   16168:	68 f6 82 01 00       	push   $0x182f6
   1616d:	e8 1d af ff ff       	call   1108f <cio_puts>
   16172:	83 c4 10             	add    $0x10,%esp
#endif

	// install the second-stage ISR
	install_isr( VEC_SYSCALL, sys_isr );
   16175:	83 ec 08             	sub    $0x8,%esp
   16178:	68 57 60 01 00       	push   $0x16057
   1617d:	68 80 00 00 00       	push   $0x80
   16182:	e8 1b f3 ff ff       	call   154a2 <install_isr>
   16187:	83 c4 10             	add    $0x10,%esp
}
   1618a:	90                   	nop
   1618b:	c9                   	leave  
   1618c:	c3                   	ret    

0001618d <r_ebp>:
{
   1618d:	55                   	push   %ebp
   1618e:	89 e5                	mov    %esp,%ebp
   16190:	83 ec 10             	sub    $0x10,%esp
	__asm__ __volatile__( "movl %%ebp,%0" : "=r" (val) );
   16193:	89 e8                	mov    %ebp,%eax
   16195:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return val;
   16198:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1619b:	c9                   	leave  
   1619c:	c3                   	ret    

0001619d <put_char_or_code>:
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {
   1619d:	55                   	push   %ebp
   1619e:	89 e5                	mov    %esp,%ebp
   161a0:	83 ec 08             	sub    $0x8,%esp

	if( ch >= ' ' && ch < 0x7f ) {
   161a3:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   161a7:	7e 17                	jle    161c0 <put_char_or_code+0x23>
   161a9:	83 7d 08 7e          	cmpl   $0x7e,0x8(%ebp)
   161ad:	7f 11                	jg     161c0 <put_char_or_code+0x23>
		cio_putchar( ch );
   161af:	8b 45 08             	mov    0x8(%ebp),%eax
   161b2:	83 ec 0c             	sub    $0xc,%esp
   161b5:	50                   	push   %eax
   161b6:	e8 51 ad ff ff       	call   10f0c <cio_putchar>
   161bb:	83 c4 10             	add    $0x10,%esp
   161be:	eb 14                	jmp    161d4 <put_char_or_code+0x37>
	} else {
		cio_printf( "\\x%02x", ch );
   161c0:	83 ec 08             	sub    $0x8,%esp
   161c3:	ff 75 08             	push   0x8(%ebp)
   161c6:	68 8c 83 01 00       	push   $0x1838c
   161cb:	e8 37 b5 ff ff       	call   11707 <cio_printf>
   161d0:	83 c4 10             	add    $0x10,%esp
	}
}
   161d3:	90                   	nop
   161d4:	90                   	nop
   161d5:	c9                   	leave  
   161d6:	c3                   	ret    

000161d7 <backtrace>:
** Perform a stack backtrace
**
** @param[in] ebp   Initial EBP to use
** @param[in] args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {
   161d7:	55                   	push   %ebp
   161d8:	89 e5                	mov    %esp,%ebp
   161da:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "Trace:  " );
   161dd:	83 ec 0c             	sub    $0xc,%esp
   161e0:	68 93 83 01 00       	push   $0x18393
   161e5:	e8 a5 ae ff ff       	call   1108f <cio_puts>
   161ea:	83 c4 10             	add    $0x10,%esp
	if( ebp == NULL ) {
   161ed:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   161f1:	75 15                	jne    16208 <backtrace+0x31>
		cio_puts( "NULL ebp, no trace possible\n" );
   161f3:	83 ec 0c             	sub    $0xc,%esp
   161f6:	68 9c 83 01 00       	push   $0x1839c
   161fb:	e8 8f ae ff ff       	call   1108f <cio_puts>
   16200:	83 c4 10             	add    $0x10,%esp
		return;
   16203:	e9 8b 00 00 00       	jmp    16293 <backtrace+0xbc>
	} else {
		cio_putchar( '\n' );
   16208:	83 ec 0c             	sub    $0xc,%esp
   1620b:	6a 0a                	push   $0xa
   1620d:	e8 fa ac ff ff       	call   10f0c <cio_putchar>
   16212:	83 c4 10             	add    $0x10,%esp
	}

	while( ebp != NULL ){
   16215:	eb 76                	jmp    1628d <backtrace+0xb6>

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
   16217:	8b 45 08             	mov    0x8(%ebp),%eax
   1621a:	8b 40 04             	mov    0x4(%eax),%eax
   1621d:	89 45 f0             	mov    %eax,-0x10(%ebp)
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );
   16220:	8b 45 08             	mov    0x8(%ebp),%eax
   16223:	83 ec 04             	sub    $0x4,%esp
   16226:	ff 75 f0             	push   -0x10(%ebp)
   16229:	50                   	push   %eax
   1622a:	68 b9 83 01 00       	push   $0x183b9
   1622f:	e8 d3 b4 ff ff       	call   11707 <cio_printf>
   16234:	83 c4 10             	add    $0x10,%esp

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
   16237:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1623e:	eb 30                	jmp    16270 <backtrace+0x99>
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
   16240:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16243:	83 c0 02             	add    $0x2,%eax
   16246:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1624d:	8b 45 08             	mov    0x8(%ebp),%eax
   16250:	01 d0                	add    %edx,%eax
   16252:	8b 00                	mov    (%eax),%eax
   16254:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16257:	83 c2 01             	add    $0x1,%edx
   1625a:	83 ec 04             	sub    $0x4,%esp
   1625d:	50                   	push   %eax
   1625e:	52                   	push   %edx
   1625f:	68 d1 83 01 00       	push   $0x183d1
   16264:	e8 9e b4 ff ff       	call   11707 <cio_printf>
   16269:	83 c4 10             	add    $0x10,%esp
		for( uint_t i = 0; i < args; ++i ) {
   1626c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16270:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16273:	3b 45 0c             	cmp    0xc(%ebp),%eax
   16276:	72 c8                	jb     16240 <backtrace+0x69>
		}
		cio_putchar( '\n' );
   16278:	83 ec 0c             	sub    $0xc,%esp
   1627b:	6a 0a                	push   $0xa
   1627d:	e8 8a ac ff ff       	call   10f0c <cio_putchar>
   16282:	83 c4 10             	add    $0x10,%esp

		// follow the chain
		ebp = (uint32_t *) *ebp;
   16285:	8b 45 08             	mov    0x8(%ebp),%eax
   16288:	8b 00                	mov    (%eax),%eax
   1628a:	89 45 08             	mov    %eax,0x8(%ebp)
	while( ebp != NULL ){
   1628d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16291:	75 84                	jne    16217 <backtrace+0x40>
	}
}
   16293:	c9                   	leave  
   16294:	c3                   	ret    

00016295 <delay>:
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
**
** @param[in] length   How long (sort of) to delay
*/
void delay( int length ) {
   16295:	55                   	push   %ebp
   16296:	89 e5                	mov    %esp,%ebp
   16298:	83 ec 10             	sub    $0x10,%esp

	while( --length >= 0 ) {
   1629b:	eb 16                	jmp    162b3 <delay+0x1e>
		for( int i = 0; i < 10000000; ++i )
   1629d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   162a4:	eb 04                	jmp    162aa <delay+0x15>
   162a6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   162aa:	81 7d fc 7f 96 98 00 	cmpl   $0x98967f,-0x4(%ebp)
   162b1:	7e f3                	jle    162a6 <delay+0x11>
	while( --length >= 0 ) {
   162b3:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
   162b7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   162bb:	79 e0                	jns    1629d <delay+0x8>
			;
	}
}
   162bd:	90                   	nop
   162be:	90                   	nop
   162bf:	c9                   	leave  
   162c0:	c3                   	ret    

000162c1 <kpanic>:
** Prefix routine for panic() - can be expanded to do other things
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {
   162c1:	55                   	push   %ebp
   162c2:	89 e5                	mov    %esp,%ebp
   162c4:	83 ec 08             	sub    $0x8,%esp

	cio_puts( "\n***** KERNEL PANIC *****\n" );
   162c7:	83 ec 0c             	sub    $0xc,%esp
   162ca:	68 dc 83 01 00       	push   $0x183dc
   162cf:	e8 bb ad ff ff       	call   1108f <cio_puts>
   162d4:	83 c4 10             	add    $0x10,%esp

	if( msg ) {
   162d7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   162db:	74 13                	je     162f0 <kpanic+0x2f>
		cio_printf( "%s\n", msg );
   162dd:	83 ec 08             	sub    $0x8,%esp
   162e0:	ff 75 08             	push   0x8(%ebp)
   162e3:	68 f7 83 01 00       	push   $0x183f7
   162e8:	e8 1a b4 ff ff       	call   11707 <cio_printf>
   162ed:	83 c4 10             	add    $0x10,%esp
	}

	delay( DELAY_5_SEC );   // approximately
   162f0:	83 ec 0c             	sub    $0xc,%esp
   162f3:	68 c8 00 00 00       	push   $0xc8
   162f8:	e8 98 ff ff ff       	call   16295 <delay>
   162fd:	83 c4 10             	add    $0x10,%esp

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );
   16300:	a1 5c a6 01 00       	mov    0x1a65c,%eax
   16305:	83 ec 04             	sub    $0x4,%esp
   16308:	6a 01                	push   $0x1
   1630a:	50                   	push   %eax
   1630b:	68 fb 83 01 00       	push   $0x183fb
   16310:	e8 95 cb ff ff       	call   12eaa <pcb_dump>
   16315:	83 c4 10             	add    $0x10,%esp

	// dump the basic info about what's in the process table
	ptable_dump_stats( NULL );
   16318:	83 ec 0c             	sub    $0xc,%esp
   1631b:	6a 00                	push   $0x0
   1631d:	e8 fc cd ff ff       	call   1311e <ptable_dump_stats>
   16322:	83 c4 10             	add    $0x10,%esp

	// dump information about the queues
	que_dump( "RH", ready[PRIO_HIGH] );
   16325:	a1 40 a6 01 00       	mov    0x1a640,%eax
   1632a:	83 ec 08             	sub    $0x8,%esp
   1632d:	50                   	push   %eax
   1632e:	68 03 84 01 00       	push   $0x18403
   16333:	e8 d0 d6 ff ff       	call   13a08 <que_dump>
   16338:	83 c4 10             	add    $0x10,%esp
	que_dump( "RS", ready[PRIO_STD] );
   1633b:	a1 44 a6 01 00       	mov    0x1a644,%eax
   16340:	83 ec 08             	sub    $0x8,%esp
   16343:	50                   	push   %eax
   16344:	68 06 84 01 00       	push   $0x18406
   16349:	e8 ba d6 ff ff       	call   13a08 <que_dump>
   1634e:	83 c4 10             	add    $0x10,%esp
	que_dump( "RL", ready[PRIO_LOW] );
   16351:	a1 48 a6 01 00       	mov    0x1a648,%eax
   16356:	83 ec 08             	sub    $0x8,%esp
   16359:	50                   	push   %eax
   1635a:	68 09 84 01 00       	push   $0x18409
   1635f:	e8 a4 d6 ff ff       	call   13a08 <que_dump>
   16364:	83 c4 10             	add    $0x10,%esp
	que_dump( "S", sleeping );
   16367:	a1 4c a6 01 00       	mov    0x1a64c,%eax
   1636c:	83 ec 08             	sub    $0x8,%esp
   1636f:	50                   	push   %eax
   16370:	68 0c 84 01 00       	push   $0x1840c
   16375:	e8 8e d6 ff ff       	call   13a08 <que_dump>
   1637a:	83 c4 10             	add    $0x10,%esp
	que_dump( "Z", zombie );
   1637d:	a1 50 a6 01 00       	mov    0x1a650,%eax
   16382:	83 ec 08             	sub    $0x8,%esp
   16385:	50                   	push   %eax
   16386:	68 0e 84 01 00       	push   $0x1840e
   1638b:	e8 78 d6 ff ff       	call   13a08 <que_dump>
   16390:	83 c4 10             	add    $0x10,%esp
	que_dump( "B", blocked );
   16393:	a1 54 a6 01 00       	mov    0x1a654,%eax
   16398:	83 ec 08             	sub    $0x8,%esp
   1639b:	50                   	push   %eax
   1639c:	68 10 84 01 00       	push   $0x18410
   163a1:	e8 62 d6 ff ff       	call   13a08 <que_dump>
   163a6:	83 c4 10             	add    $0x10,%esp
	que_dump( "I", sioread );
   163a9:	a1 58 a6 01 00       	mov    0x1a658,%eax
   163ae:	83 ec 08             	sub    $0x8,%esp
   163b1:	50                   	push   %eax
   163b2:	68 12 84 01 00       	push   $0x18412
   163b7:	e8 4c d6 ff ff       	call   13a08 <que_dump>
   163bc:	83 c4 10             	add    $0x10,%esp

	cio_puts( "\n\nPanic information:\n" );
   163bf:	83 ec 0c             	sub    $0xc,%esp
   163c2:	68 14 84 01 00       	push   $0x18414
   163c7:	e8 c3 ac ff ff       	call   1108f <cio_puts>
   163cc:	83 c4 10             	add    $0x10,%esp

	ptable_dump( "Full process table", true );
   163cf:	83 ec 08             	sub    $0x8,%esp
   163d2:	6a 01                	push   $0x1
   163d4:	68 2a 84 01 00       	push   $0x1842a
   163d9:	e8 51 cc ff ff       	call   1302f <ptable_dump>
   163de:	83 c4 10             	add    $0x10,%esp

	ctx_dump_all( "Full context dump" );
   163e1:	83 ec 0c             	sub    $0xc,%esp
   163e4:	68 3d 84 01 00       	push   $0x1843d
   163e9:	e8 45 ca ff ff       	call   12e33 <ctx_dump_all>
   163ee:	83 c4 10             	add    $0x10,%esp

	backtrace( (uint32_t *) r_ebp(), 3 );
   163f1:	e8 97 fd ff ff       	call   1618d <r_ebp>
   163f6:	83 ec 08             	sub    $0x8,%esp
   163f9:	6a 03                	push   $0x3
   163fb:	50                   	push   %eax
   163fc:	e8 d6 fd ff ff       	call   161d7 <backtrace>
   16401:	83 c4 10             	add    $0x10,%esp

	__asm__( "cli" );
   16404:	fa                   	cli    
	cio_printf( "*** HALTING" );
   16405:	83 ec 0c             	sub    $0xc,%esp
   16408:	68 4f 84 01 00       	push   $0x1844f
   1640d:	e8 f5 b2 ff ff       	call   11707 <cio_printf>
   16412:	83 c4 10             	add    $0x10,%esp
	for(;;) {
   16415:	eb fe                	jmp    16415 <kpanic+0x154>

00016417 <blkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {
   16417:	55                   	push   %ebp
   16418:	89 e5                	mov    %esp,%ebp
   1641a:	56                   	push   %esi
   1641b:	53                   	push   %ebx
   1641c:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   1641f:	8b 55 08             	mov    0x8(%ebp),%edx
   16422:	83 e2 03             	and    $0x3,%edx
   16425:	85 d2                	test   %edx,%edx
   16427:	75 13                	jne    1643c <blkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   16429:	8b 55 0c             	mov    0xc(%ebp),%edx
   1642c:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   1642f:	85 d2                	test   %edx,%edx
   16431:	75 09                	jne    1643c <blkmov+0x25>
		(len & 0x3) != 0 ) {
   16433:	89 c2                	mov    %eax,%edx
   16435:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   16438:	85 d2                	test   %edx,%edx
   1643a:	74 14                	je     16450 <blkmov+0x39>
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
   1643c:	83 ec 04             	sub    $0x4,%esp
   1643f:	50                   	push   %eax
   16440:	ff 75 0c             	push   0xc(%ebp)
   16443:	ff 75 08             	push   0x8(%ebp)
   16446:	e8 35 03 00 00       	call   16780 <memmove>
   1644b:	83 c4 10             	add    $0x10,%esp
		return;
   1644e:	eb 5a                	jmp    164aa <blkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   16450:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   16453:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   16456:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   16459:	39 de                	cmp    %ebx,%esi
   1645b:	73 44                	jae    164a1 <blkmov+0x8a>
   1645d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16464:	01 f2                	add    %esi,%edx
   16466:	39 d3                	cmp    %edx,%ebx
   16468:	73 37                	jae    164a1 <blkmov+0x8a>
		source += len;
   1646a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16471:	01 d6                	add    %edx,%esi
		dest += len;
   16473:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1647a:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   1647c:	eb 0a                	jmp    16488 <blkmov+0x71>
			*--dest = *--source;
   1647e:	83 ee 04             	sub    $0x4,%esi
   16481:	83 eb 04             	sub    $0x4,%ebx
   16484:	8b 16                	mov    (%esi),%edx
   16486:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   16488:	89 c2                	mov    %eax,%edx
   1648a:	8d 42 ff             	lea    -0x1(%edx),%eax
   1648d:	85 d2                	test   %edx,%edx
   1648f:	75 ed                	jne    1647e <blkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   16491:	eb 17                	jmp    164aa <blkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   16493:	89 f1                	mov    %esi,%ecx
   16495:	8d 71 04             	lea    0x4(%ecx),%esi
   16498:	89 da                	mov    %ebx,%edx
   1649a:	8d 5a 04             	lea    0x4(%edx),%ebx
   1649d:	8b 09                	mov    (%ecx),%ecx
   1649f:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   164a1:	89 c2                	mov    %eax,%edx
   164a3:	8d 42 ff             	lea    -0x1(%edx),%eax
   164a6:	85 d2                	test   %edx,%edx
   164a8:	75 e9                	jne    16493 <blkmov+0x7c>
		}
	}
}
   164aa:	8d 65 f8             	lea    -0x8(%ebp),%esp
   164ad:	5b                   	pop    %ebx
   164ae:	5e                   	pop    %esi
   164af:	5d                   	pop    %ebp
   164b0:	c3                   	ret    

000164b1 <bound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
   164b1:	55                   	push   %ebp
   164b2:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   164b4:	8b 45 0c             	mov    0xc(%ebp),%eax
   164b7:	3b 45 08             	cmp    0x8(%ebp),%eax
   164ba:	73 06                	jae    164c2 <bound+0x11>
		value = min;
   164bc:	8b 45 08             	mov    0x8(%ebp),%eax
   164bf:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   164c2:	8b 45 0c             	mov    0xc(%ebp),%eax
   164c5:	3b 45 10             	cmp    0x10(%ebp),%eax
   164c8:	76 06                	jbe    164d0 <bound+0x1f>
		value = max;
   164ca:	8b 45 10             	mov    0x10(%ebp),%eax
   164cd:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   164d0:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   164d3:	5d                   	pop    %ebp
   164d4:	c3                   	ret    

000164d5 <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   164d5:	55                   	push   %ebp
   164d6:	89 e5                	mov    %esp,%ebp
   164d8:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   164db:	8b 45 08             	mov    0x8(%ebp),%eax
   164de:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   164e1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   164e5:	79 0f                	jns    164f6 <cvtdec+0x21>
		*bp++ = '-';
   164e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   164ea:	8d 50 01             	lea    0x1(%eax),%edx
   164ed:	89 55 f4             	mov    %edx,-0xc(%ebp)
   164f0:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   164f3:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   164f6:	83 ec 08             	sub    $0x8,%esp
   164f9:	ff 75 0c             	push   0xc(%ebp)
   164fc:	ff 75 f4             	push   -0xc(%ebp)
   164ff:	e8 14 00 00 00       	call   16518 <cvtdec0>
   16504:	83 c4 10             	add    $0x10,%esp
   16507:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   1650a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1650d:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   16510:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16513:	2b 45 08             	sub    0x8(%ebp),%eax
}
   16516:	c9                   	leave  
   16517:	c3                   	ret    

00016518 <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   16518:	55                   	push   %ebp
   16519:	89 e5                	mov    %esp,%ebp
   1651b:	53                   	push   %ebx
   1651c:	83 ec 14             	sub    $0x14,%esp
	int quotient;

	quotient = value / 10;
   1651f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   16522:	ba 67 66 66 66       	mov    $0x66666667,%edx
   16527:	89 c8                	mov    %ecx,%eax
   16529:	f7 ea                	imul   %edx
   1652b:	89 d0                	mov    %edx,%eax
   1652d:	c1 f8 02             	sar    $0x2,%eax
   16530:	c1 f9 1f             	sar    $0x1f,%ecx
   16533:	89 ca                	mov    %ecx,%edx
   16535:	29 d0                	sub    %edx,%eax
   16537:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1653a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1653e:	79 0e                	jns    1654e <cvtdec0+0x36>
		quotient = 214748364;
   16540:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   16547:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   1654e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16552:	74 14                	je     16568 <cvtdec0+0x50>
		buf = cvtdec0( buf, quotient );
   16554:	83 ec 08             	sub    $0x8,%esp
   16557:	ff 75 f4             	push   -0xc(%ebp)
   1655a:	ff 75 08             	push   0x8(%ebp)
   1655d:	e8 b6 ff ff ff       	call   16518 <cvtdec0>
   16562:	83 c4 10             	add    $0x10,%esp
   16565:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   16568:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1656b:	ba 67 66 66 66       	mov    $0x66666667,%edx
   16570:	89 c8                	mov    %ecx,%eax
   16572:	f7 ea                	imul   %edx
   16574:	89 d0                	mov    %edx,%eax
   16576:	c1 f8 02             	sar    $0x2,%eax
   16579:	89 cb                	mov    %ecx,%ebx
   1657b:	c1 fb 1f             	sar    $0x1f,%ebx
   1657e:	29 d8                	sub    %ebx,%eax
   16580:	89 c2                	mov    %eax,%edx
   16582:	89 d0                	mov    %edx,%eax
   16584:	c1 e0 02             	shl    $0x2,%eax
   16587:	01 d0                	add    %edx,%eax
   16589:	01 c0                	add    %eax,%eax
   1658b:	29 c1                	sub    %eax,%ecx
   1658d:	89 ca                	mov    %ecx,%edx
   1658f:	89 d0                	mov    %edx,%eax
   16591:	8d 48 30             	lea    0x30(%eax),%ecx
   16594:	8b 45 08             	mov    0x8(%ebp),%eax
   16597:	8d 50 01             	lea    0x1(%eax),%edx
   1659a:	89 55 08             	mov    %edx,0x8(%ebp)
   1659d:	89 ca                	mov    %ecx,%edx
   1659f:	88 10                	mov    %dl,(%eax)
	return buf;
   165a1:	8b 45 08             	mov    0x8(%ebp),%eax
}
   165a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   165a7:	c9                   	leave  
   165a8:	c3                   	ret    

000165a9 <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   165a9:	55                   	push   %ebp
   165aa:	89 e5                	mov    %esp,%ebp
   165ac:	83 ec 10             	sub    $0x10,%esp
	int chars_stored = 0;
   165af:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   165b6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   165bd:	eb 44                	jmp    16603 <cvthex+0x5a>
		uint32_t val = value & 0xf0000000;
   165bf:	8b 45 0c             	mov    0xc(%ebp),%eax
   165c2:	25 00 00 00 f0       	and    $0xf0000000,%eax
   165c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   165ca:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   165ce:	75 0c                	jne    165dc <cvthex+0x33>
   165d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   165d4:	75 06                	jne    165dc <cvthex+0x33>
   165d6:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   165da:	75 1f                	jne    165fb <cvthex+0x52>
			++chars_stored;
   165dc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   165e0:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   165e4:	8b 45 08             	mov    0x8(%ebp),%eax
   165e7:	8d 50 01             	lea    0x1(%eax),%edx
   165ea:	89 55 08             	mov    %edx,0x8(%ebp)
   165ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
   165f0:	81 c2 5c 84 01 00    	add    $0x1845c,%edx
   165f6:	0f b6 12             	movzbl (%edx),%edx
   165f9:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   165fb:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   165ff:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   16603:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   16607:	7e b6                	jle    165bf <cvthex+0x16>
	}

	*buf = '\0';
   16609:	8b 45 08             	mov    0x8(%ebp),%eax
   1660c:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   1660f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   16612:	c9                   	leave  
   16613:	c3                   	ret    

00016614 <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   16614:	55                   	push   %ebp
   16615:	89 e5                	mov    %esp,%ebp
   16617:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1661a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   16621:	8b 45 08             	mov    0x8(%ebp),%eax
   16624:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   16627:	8b 45 0c             	mov    0xc(%ebp),%eax
   1662a:	25 00 00 00 c0       	and    $0xc0000000,%eax
   1662f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   16632:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   16636:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1663d:	eb 47                	jmp    16686 <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   1663f:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   16643:	74 0c                	je     16651 <cvtoct+0x3d>
   16645:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   16649:	75 06                	jne    16651 <cvtoct+0x3d>
   1664b:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   1664f:	74 1e                	je     1666f <cvtoct+0x5b>
			chars_stored = 1;
   16651:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   16658:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   1665c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1665f:	8d 48 30             	lea    0x30(%eax),%ecx
   16662:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16665:	8d 50 01             	lea    0x1(%eax),%edx
   16668:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1666b:	89 ca                	mov    %ecx,%edx
   1666d:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   1666f:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   16673:	8b 45 0c             	mov    0xc(%ebp),%eax
   16676:	25 00 00 00 e0       	and    $0xe0000000,%eax
   1667b:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   1667e:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   16682:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   16686:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1668a:	7e b3                	jle    1663f <cvtoct+0x2b>
	}
	*bp = '\0';
   1668c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1668f:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   16692:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16695:	2b 45 08             	sub    0x8(%ebp),%eax
}
   16698:	c9                   	leave  
   16699:	c3                   	ret    

0001669a <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   1669a:	55                   	push   %ebp
   1669b:	89 e5                	mov    %esp,%ebp
   1669d:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   166a0:	8b 45 08             	mov    0x8(%ebp),%eax
   166a3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   166a6:	83 ec 08             	sub    $0x8,%esp
   166a9:	ff 75 0c             	push   0xc(%ebp)
   166ac:	ff 75 f4             	push   -0xc(%ebp)
   166af:	e8 14 00 00 00       	call   166c8 <cvtuns0>
   166b4:	83 c4 10             	add    $0x10,%esp
   166b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   166ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
   166bd:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   166c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   166c3:	2b 45 08             	sub    0x8(%ebp),%eax
}
   166c6:	c9                   	leave  
   166c7:	c3                   	ret    

000166c8 <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   166c8:	55                   	push   %ebp
   166c9:	89 e5                	mov    %esp,%ebp
   166cb:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   166ce:	8b 45 0c             	mov    0xc(%ebp),%eax
   166d1:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   166d6:	f7 e2                	mul    %edx
   166d8:	89 d0                	mov    %edx,%eax
   166da:	c1 e8 03             	shr    $0x3,%eax
   166dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   166e0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   166e4:	74 15                	je     166fb <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   166e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   166e9:	83 ec 08             	sub    $0x8,%esp
   166ec:	50                   	push   %eax
   166ed:	ff 75 08             	push   0x8(%ebp)
   166f0:	e8 23 fe ff ff       	call   16518 <cvtdec0>
   166f5:	83 c4 10             	add    $0x10,%esp
   166f8:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   166fb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   166fe:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   16703:	89 c8                	mov    %ecx,%eax
   16705:	f7 e2                	mul    %edx
   16707:	c1 ea 03             	shr    $0x3,%edx
   1670a:	89 d0                	mov    %edx,%eax
   1670c:	c1 e0 02             	shl    $0x2,%eax
   1670f:	01 d0                	add    %edx,%eax
   16711:	01 c0                	add    %eax,%eax
   16713:	29 c1                	sub    %eax,%ecx
   16715:	89 ca                	mov    %ecx,%edx
   16717:	89 d0                	mov    %edx,%eax
   16719:	8d 48 30             	lea    0x30(%eax),%ecx
   1671c:	8b 45 08             	mov    0x8(%ebp),%eax
   1671f:	8d 50 01             	lea    0x1(%eax),%edx
   16722:	89 55 08             	mov    %edx,0x8(%ebp)
   16725:	89 ca                	mov    %ecx,%edx
   16727:	88 10                	mov    %dl,(%eax)
	return buf;
   16729:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1672c:	c9                   	leave  
   1672d:	c3                   	ret    

0001672e <memclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
   1672e:	55                   	push   %ebp
   1672f:	89 e5                	mov    %esp,%ebp
   16731:	53                   	push   %ebx
   16732:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   16735:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   16738:	eb 08                	jmp    16742 <memclr+0x14>
			*dest++ = 0;
   1673a:	89 d8                	mov    %ebx,%eax
   1673c:	8d 58 01             	lea    0x1(%eax),%ebx
   1673f:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   16742:	89 d0                	mov    %edx,%eax
   16744:	8d 50 ff             	lea    -0x1(%eax),%edx
   16747:	85 c0                	test   %eax,%eax
   16749:	75 ef                	jne    1673a <memclr+0xc>
	}
}
   1674b:	90                   	nop
   1674c:	90                   	nop
   1674d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   16750:	c9                   	leave  
   16751:	c3                   	ret    

00016752 <memcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
   16752:	55                   	push   %ebp
   16753:	89 e5                	mov    %esp,%ebp
   16755:	56                   	push   %esi
   16756:	53                   	push   %ebx
   16757:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   1675a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   1675d:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   16760:	eb 0f                	jmp    16771 <memcpy+0x1f>
		*dest++ = *source++;
   16762:	89 f2                	mov    %esi,%edx
   16764:	8d 72 01             	lea    0x1(%edx),%esi
   16767:	89 d8                	mov    %ebx,%eax
   16769:	8d 58 01             	lea    0x1(%eax),%ebx
   1676c:	0f b6 12             	movzbl (%edx),%edx
   1676f:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   16771:	89 c8                	mov    %ecx,%eax
   16773:	8d 48 ff             	lea    -0x1(%eax),%ecx
   16776:	85 c0                	test   %eax,%eax
   16778:	75 e8                	jne    16762 <memcpy+0x10>
	}
}
   1677a:	90                   	nop
   1677b:	90                   	nop
   1677c:	5b                   	pop    %ebx
   1677d:	5e                   	pop    %esi
   1677e:	5d                   	pop    %ebp
   1677f:	c3                   	ret    

00016780 <memmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
   16780:	55                   	push   %ebp
   16781:	89 e5                	mov    %esp,%ebp
   16783:	56                   	push   %esi
   16784:	53                   	push   %ebx
   16785:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   16788:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   1678b:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   1678e:	39 de                	cmp    %ebx,%esi
   16790:	73 32                	jae    167c4 <memmove+0x44>
   16792:	8d 14 06             	lea    (%esi,%eax,1),%edx
   16795:	39 d3                	cmp    %edx,%ebx
   16797:	73 2b                	jae    167c4 <memmove+0x44>
		source += len;
   16799:	01 c6                	add    %eax,%esi
		dest += len;
   1679b:	01 c3                	add    %eax,%ebx
		while( len-- > 0 ) {
   1679d:	eb 0b                	jmp    167aa <memmove+0x2a>
			*--dest = *--source;
   1679f:	83 ee 01             	sub    $0x1,%esi
   167a2:	83 eb 01             	sub    $0x1,%ebx
   167a5:	0f b6 16             	movzbl (%esi),%edx
   167a8:	88 13                	mov    %dl,(%ebx)
		while( len-- > 0 ) {
   167aa:	89 c2                	mov    %eax,%edx
   167ac:	8d 42 ff             	lea    -0x1(%edx),%eax
   167af:	85 d2                	test   %edx,%edx
   167b1:	75 ec                	jne    1679f <memmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   167b3:	eb 19                	jmp    167ce <memmove+0x4e>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   167b5:	89 f1                	mov    %esi,%ecx
   167b7:	8d 71 01             	lea    0x1(%ecx),%esi
   167ba:	89 da                	mov    %ebx,%edx
   167bc:	8d 5a 01             	lea    0x1(%edx),%ebx
   167bf:	0f b6 09             	movzbl (%ecx),%ecx
   167c2:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   167c4:	89 c2                	mov    %eax,%edx
   167c6:	8d 42 ff             	lea    -0x1(%edx),%eax
   167c9:	85 d2                	test   %edx,%edx
   167cb:	75 e8                	jne    167b5 <memmove+0x35>
		}
	}
}
   167cd:	90                   	nop
   167ce:	90                   	nop
   167cf:	5b                   	pop    %ebx
   167d0:	5e                   	pop    %esi
   167d1:	5d                   	pop    %ebp
   167d2:	c3                   	ret    

000167d3 <memset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
   167d3:	55                   	push   %ebp
   167d4:	89 e5                	mov    %esp,%ebp
   167d6:	53                   	push   %ebx
   167d7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   167da:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   167dd:	eb 0b                	jmp    167ea <memset+0x17>
		*bp++ = value;
   167df:	89 d8                	mov    %ebx,%eax
   167e1:	8d 58 01             	lea    0x1(%eax),%ebx
   167e4:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   167e8:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   167ea:	89 c8                	mov    %ecx,%eax
   167ec:	8d 48 ff             	lea    -0x1(%eax),%ecx
   167ef:	85 c0                	test   %eax,%eax
   167f1:	75 ec                	jne    167df <memset+0xc>
	}
}
   167f3:	90                   	nop
   167f4:	90                   	nop
   167f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   167f8:	c9                   	leave  
   167f9:	c3                   	ret    

000167fa <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   167fa:	55                   	push   %ebp
   167fb:	89 e5                	mov    %esp,%ebp
   167fd:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   16800:	8d 45 0c             	lea    0xc(%ebp),%eax
   16803:	83 c0 04             	add    $0x4,%eax
   16806:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   16809:	e9 3f 02 00 00       	jmp    16a4d <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   1680e:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   16812:	0f 85 26 02 00 00    	jne    16a3e <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   16818:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   1681f:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   16826:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   1682d:	8b 45 0c             	mov    0xc(%ebp),%eax
   16830:	8d 50 01             	lea    0x1(%eax),%edx
   16833:	89 55 0c             	mov    %edx,0xc(%ebp)
   16836:	0f b6 00             	movzbl (%eax),%eax
   16839:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   1683c:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   16840:	75 16                	jne    16858 <sprint+0x5e>
				leftadjust = 1;
   16842:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   16849:	8b 45 0c             	mov    0xc(%ebp),%eax
   1684c:	8d 50 01             	lea    0x1(%eax),%edx
   1684f:	89 55 0c             	mov    %edx,0xc(%ebp)
   16852:	0f b6 00             	movzbl (%eax),%eax
   16855:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   16858:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   1685c:	75 40                	jne    1689e <sprint+0xa4>
				padchar = '0';
   1685e:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   16865:	8b 45 0c             	mov    0xc(%ebp),%eax
   16868:	8d 50 01             	lea    0x1(%eax),%edx
   1686b:	89 55 0c             	mov    %edx,0xc(%ebp)
   1686e:	0f b6 00             	movzbl (%eax),%eax
   16871:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   16874:	eb 28                	jmp    1689e <sprint+0xa4>
				width *= 10;
   16876:	8b 55 e8             	mov    -0x18(%ebp),%edx
   16879:	89 d0                	mov    %edx,%eax
   1687b:	c1 e0 02             	shl    $0x2,%eax
   1687e:	01 d0                	add    %edx,%eax
   16880:	01 c0                	add    %eax,%eax
   16882:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   16885:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   16889:	83 e8 30             	sub    $0x30,%eax
   1688c:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   1688f:	8b 45 0c             	mov    0xc(%ebp),%eax
   16892:	8d 50 01             	lea    0x1(%eax),%edx
   16895:	89 55 0c             	mov    %edx,0xc(%ebp)
   16898:	0f b6 00             	movzbl (%eax),%eax
   1689b:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   1689e:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   168a2:	7e 06                	jle    168aa <sprint+0xb0>
   168a4:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   168a8:	7e cc                	jle    16876 <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   168aa:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   168ae:	83 e8 63             	sub    $0x63,%eax
   168b1:	83 f8 15             	cmp    $0x15,%eax
   168b4:	0f 87 93 01 00 00    	ja     16a4d <sprint+0x253>
   168ba:	8b 04 85 70 84 01 00 	mov    0x18470(,%eax,4),%eax
   168c1:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   168c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   168c6:	8d 50 04             	lea    0x4(%eax),%edx
   168c9:	89 55 f4             	mov    %edx,-0xc(%ebp)
   168cc:	8b 00                	mov    (%eax),%eax
   168ce:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   168d1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   168d5:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   168d8:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   168dc:	83 ec 08             	sub    $0x8,%esp
   168df:	ff 75 e4             	push   -0x1c(%ebp)
   168e2:	ff 75 ec             	push   -0x14(%ebp)
   168e5:	ff 75 e8             	push   -0x18(%ebp)
   168e8:	6a 01                	push   $0x1
   168ea:	8d 45 d0             	lea    -0x30(%ebp),%eax
   168ed:	50                   	push   %eax
   168ee:	ff 75 08             	push   0x8(%ebp)
   168f1:	e8 d3 01 00 00       	call   16ac9 <padstr>
   168f6:	83 c4 20             	add    $0x20,%esp
   168f9:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   168fc:	e9 4c 01 00 00       	jmp    16a4d <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   16901:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16904:	8d 50 04             	lea    0x4(%eax),%edx
   16907:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1690a:	8b 00                	mov    (%eax),%eax
   1690c:	83 ec 08             	sub    $0x8,%esp
   1690f:	50                   	push   %eax
   16910:	8d 45 d0             	lea    -0x30(%ebp),%eax
   16913:	50                   	push   %eax
   16914:	e8 bc fb ff ff       	call   164d5 <cvtdec>
   16919:	83 c4 10             	add    $0x10,%esp
   1691c:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   1691f:	83 ec 08             	sub    $0x8,%esp
   16922:	ff 75 e4             	push   -0x1c(%ebp)
   16925:	ff 75 ec             	push   -0x14(%ebp)
   16928:	ff 75 e8             	push   -0x18(%ebp)
   1692b:	ff 75 e0             	push   -0x20(%ebp)
   1692e:	8d 45 d0             	lea    -0x30(%ebp),%eax
   16931:	50                   	push   %eax
   16932:	ff 75 08             	push   0x8(%ebp)
   16935:	e8 8f 01 00 00       	call   16ac9 <padstr>
   1693a:	83 c4 20             	add    $0x20,%esp
   1693d:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   16940:	e9 08 01 00 00       	jmp    16a4d <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   16945:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16948:	8d 50 04             	lea    0x4(%eax),%edx
   1694b:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1694e:	8b 00                	mov    (%eax),%eax
   16950:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   16953:	83 ec 08             	sub    $0x8,%esp
   16956:	ff 75 e4             	push   -0x1c(%ebp)
   16959:	ff 75 ec             	push   -0x14(%ebp)
   1695c:	ff 75 e8             	push   -0x18(%ebp)
   1695f:	6a ff                	push   $0xffffffff
   16961:	ff 75 dc             	push   -0x24(%ebp)
   16964:	ff 75 08             	push   0x8(%ebp)
   16967:	e8 5d 01 00 00       	call   16ac9 <padstr>
   1696c:	83 c4 20             	add    $0x20,%esp
   1696f:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   16972:	e9 d6 00 00 00       	jmp    16a4d <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   16977:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1697a:	8d 50 04             	lea    0x4(%eax),%edx
   1697d:	89 55 f4             	mov    %edx,-0xc(%ebp)
   16980:	8b 00                	mov    (%eax),%eax
   16982:	83 ec 08             	sub    $0x8,%esp
   16985:	50                   	push   %eax
   16986:	8d 45 d0             	lea    -0x30(%ebp),%eax
   16989:	50                   	push   %eax
   1698a:	e8 1a fc ff ff       	call   165a9 <cvthex>
   1698f:	83 c4 10             	add    $0x10,%esp
   16992:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   16995:	83 ec 08             	sub    $0x8,%esp
   16998:	ff 75 e4             	push   -0x1c(%ebp)
   1699b:	ff 75 ec             	push   -0x14(%ebp)
   1699e:	ff 75 e8             	push   -0x18(%ebp)
   169a1:	ff 75 e0             	push   -0x20(%ebp)
   169a4:	8d 45 d0             	lea    -0x30(%ebp),%eax
   169a7:	50                   	push   %eax
   169a8:	ff 75 08             	push   0x8(%ebp)
   169ab:	e8 19 01 00 00       	call   16ac9 <padstr>
   169b0:	83 c4 20             	add    $0x20,%esp
   169b3:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   169b6:	e9 92 00 00 00       	jmp    16a4d <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   169bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   169be:	8d 50 04             	lea    0x4(%eax),%edx
   169c1:	89 55 f4             	mov    %edx,-0xc(%ebp)
   169c4:	8b 00                	mov    (%eax),%eax
   169c6:	83 ec 08             	sub    $0x8,%esp
   169c9:	50                   	push   %eax
   169ca:	8d 45 d0             	lea    -0x30(%ebp),%eax
   169cd:	50                   	push   %eax
   169ce:	e8 41 fc ff ff       	call   16614 <cvtoct>
   169d3:	83 c4 10             	add    $0x10,%esp
   169d6:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   169d9:	83 ec 08             	sub    $0x8,%esp
   169dc:	ff 75 e4             	push   -0x1c(%ebp)
   169df:	ff 75 ec             	push   -0x14(%ebp)
   169e2:	ff 75 e8             	push   -0x18(%ebp)
   169e5:	ff 75 e0             	push   -0x20(%ebp)
   169e8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   169eb:	50                   	push   %eax
   169ec:	ff 75 08             	push   0x8(%ebp)
   169ef:	e8 d5 00 00 00       	call   16ac9 <padstr>
   169f4:	83 c4 20             	add    $0x20,%esp
   169f7:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   169fa:	eb 51                	jmp    16a4d <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   169fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   169ff:	8d 50 04             	lea    0x4(%eax),%edx
   16a02:	89 55 f4             	mov    %edx,-0xc(%ebp)
   16a05:	8b 00                	mov    (%eax),%eax
   16a07:	83 ec 08             	sub    $0x8,%esp
   16a0a:	50                   	push   %eax
   16a0b:	8d 45 d0             	lea    -0x30(%ebp),%eax
   16a0e:	50                   	push   %eax
   16a0f:	e8 86 fc ff ff       	call   1669a <cvtuns>
   16a14:	83 c4 10             	add    $0x10,%esp
   16a17:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   16a1a:	83 ec 08             	sub    $0x8,%esp
   16a1d:	ff 75 e4             	push   -0x1c(%ebp)
   16a20:	ff 75 ec             	push   -0x14(%ebp)
   16a23:	ff 75 e8             	push   -0x18(%ebp)
   16a26:	ff 75 e0             	push   -0x20(%ebp)
   16a29:	8d 45 d0             	lea    -0x30(%ebp),%eax
   16a2c:	50                   	push   %eax
   16a2d:	ff 75 08             	push   0x8(%ebp)
   16a30:	e8 94 00 00 00       	call   16ac9 <padstr>
   16a35:	83 c4 20             	add    $0x20,%esp
   16a38:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   16a3b:	90                   	nop
   16a3c:	eb 0f                	jmp    16a4d <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   16a3e:	8b 45 08             	mov    0x8(%ebp),%eax
   16a41:	8d 50 01             	lea    0x1(%eax),%edx
   16a44:	89 55 08             	mov    %edx,0x8(%ebp)
   16a47:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   16a4b:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   16a4d:	8b 45 0c             	mov    0xc(%ebp),%eax
   16a50:	8d 50 01             	lea    0x1(%eax),%edx
   16a53:	89 55 0c             	mov    %edx,0xc(%ebp)
   16a56:	0f b6 00             	movzbl (%eax),%eax
   16a59:	88 45 f3             	mov    %al,-0xd(%ebp)
   16a5c:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   16a60:	0f 85 a8 fd ff ff    	jne    1680e <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   16a66:	8b 45 08             	mov    0x8(%ebp),%eax
   16a69:	c6 00 00             	movb   $0x0,(%eax)
}
   16a6c:	90                   	nop
   16a6d:	c9                   	leave  
   16a6e:	c3                   	ret    

00016a6f <strcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {
   16a6f:	55                   	push   %ebp
   16a70:	89 e5                	mov    %esp,%ebp
   16a72:	53                   	push   %ebx
   16a73:	8b 45 08             	mov    0x8(%ebp),%eax
   16a76:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   16a79:	eb 06                	jmp    16a81 <strcmp+0x12>
		++s1, ++s2;
   16a7b:	83 c0 01             	add    $0x1,%eax
   16a7e:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   16a81:	0f b6 08             	movzbl (%eax),%ecx
   16a84:	84 c9                	test   %cl,%cl
   16a86:	74 0a                	je     16a92 <strcmp+0x23>
   16a88:	0f b6 18             	movzbl (%eax),%ebx
   16a8b:	0f b6 0a             	movzbl (%edx),%ecx
   16a8e:	38 cb                	cmp    %cl,%bl
   16a90:	74 e9                	je     16a7b <strcmp+0xc>

	return( *s1 - *s2 );
   16a92:	0f b6 00             	movzbl (%eax),%eax
   16a95:	0f be c0             	movsbl %al,%eax
   16a98:	0f b6 12             	movzbl (%edx),%edx
   16a9b:	0f be d2             	movsbl %dl,%edx
   16a9e:	29 d0                	sub    %edx,%eax
}
   16aa0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   16aa3:	c9                   	leave  
   16aa4:	c3                   	ret    

00016aa5 <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   16aa5:	55                   	push   %ebp
   16aa6:	89 e5                	mov    %esp,%ebp
   16aa8:	53                   	push   %ebx
   16aa9:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   16aac:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   16ab1:	eb 03                	jmp    16ab6 <strlen+0x11>
		++len;
   16ab3:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   16ab6:	89 d0                	mov    %edx,%eax
   16ab8:	8d 50 01             	lea    0x1(%eax),%edx
   16abb:	0f b6 00             	movzbl (%eax),%eax
   16abe:	84 c0                	test   %al,%al
   16ac0:	75 f1                	jne    16ab3 <strlen+0xe>
	}

	return( len );
   16ac2:	89 d8                	mov    %ebx,%eax
}
   16ac4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   16ac7:	c9                   	leave  
   16ac8:	c3                   	ret    

00016ac9 <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   16ac9:	55                   	push   %ebp
   16aca:	89 e5                	mov    %esp,%ebp
   16acc:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   16acf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   16ad3:	79 11                	jns    16ae6 <padstr+0x1d>
		len = strlen( str );
   16ad5:	83 ec 0c             	sub    $0xc,%esp
   16ad8:	ff 75 0c             	push   0xc(%ebp)
   16adb:	e8 c5 ff ff ff       	call   16aa5 <strlen>
   16ae0:	83 c4 10             	add    $0x10,%esp
   16ae3:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   16ae6:	8b 45 14             	mov    0x14(%ebp),%eax
   16ae9:	2b 45 10             	sub    0x10(%ebp),%eax
   16aec:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   16aef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   16af3:	7e 1d                	jle    16b12 <padstr+0x49>
   16af5:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   16af9:	75 17                	jne    16b12 <padstr+0x49>
		dst = pad( dst, extra, padchar );
   16afb:	83 ec 04             	sub    $0x4,%esp
   16afe:	ff 75 1c             	push   0x1c(%ebp)
   16b01:	ff 75 f0             	push   -0x10(%ebp)
   16b04:	ff 75 08             	push   0x8(%ebp)
   16b07:	e8 5a 00 00 00       	call   16b66 <pad>
   16b0c:	83 c4 10             	add    $0x10,%esp
   16b0f:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   16b12:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16b19:	eb 1b                	jmp    16b36 <padstr+0x6d>
		*dst++ = str[i];
   16b1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16b1e:	8b 45 0c             	mov    0xc(%ebp),%eax
   16b21:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   16b24:	8b 45 08             	mov    0x8(%ebp),%eax
   16b27:	8d 50 01             	lea    0x1(%eax),%edx
   16b2a:	89 55 08             	mov    %edx,0x8(%ebp)
   16b2d:	0f b6 11             	movzbl (%ecx),%edx
   16b30:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   16b32:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16b39:	3b 45 10             	cmp    0x10(%ebp),%eax
   16b3c:	7c dd                	jl     16b1b <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   16b3e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   16b42:	7e 1d                	jle    16b61 <padstr+0x98>
   16b44:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   16b48:	74 17                	je     16b61 <padstr+0x98>
		dst = pad( dst, extra, padchar );
   16b4a:	83 ec 04             	sub    $0x4,%esp
   16b4d:	ff 75 1c             	push   0x1c(%ebp)
   16b50:	ff 75 f0             	push   -0x10(%ebp)
   16b53:	ff 75 08             	push   0x8(%ebp)
   16b56:	e8 0b 00 00 00       	call   16b66 <pad>
   16b5b:	83 c4 10             	add    $0x10,%esp
   16b5e:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   16b61:	8b 45 08             	mov    0x8(%ebp),%eax
}
   16b64:	c9                   	leave  
   16b65:	c3                   	ret    

00016b66 <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   16b66:	55                   	push   %ebp
   16b67:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   16b69:	eb 12                	jmp    16b7d <pad+0x17>
		*dst++ = (char) padchar;
   16b6b:	8b 45 08             	mov    0x8(%ebp),%eax
   16b6e:	8d 50 01             	lea    0x1(%eax),%edx
   16b71:	89 55 08             	mov    %edx,0x8(%ebp)
   16b74:	8b 55 10             	mov    0x10(%ebp),%edx
   16b77:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   16b79:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   16b7d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   16b81:	7f e8                	jg     16b6b <pad+0x5>
	}
	return dst;
   16b83:	8b 45 08             	mov    0x8(%ebp),%eax
}
   16b86:	5d                   	pop    %ebp
   16b87:	c3                   	ret    
