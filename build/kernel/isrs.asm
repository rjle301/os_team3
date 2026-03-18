
build/kernel/isrs.o:     file format elf32-i386


Disassembly of section .text:

00000000 <isr_save>:
#           0, or error code    saved by the hardware, or the entry macro
#           saved EIP           saved by the hardware
#           saved CS            saved by the hardware
#           saved EFLAGS        saved by the hardware
#
	pusha			# save E*X, ESP, EBP, ESI, EDI
   0:	60                   	pusha  
	pushl	%ds		# save segment registers
   1:	1e                   	push   %ds
	pushl	%es
   2:	06                   	push   %es
	pushl	%fs
   3:	0f a0                	push   %fs
	pushl	%gs
   5:	0f a8                	push   %gs
	pushl	%ss
   7:	16                   	push   %ss
#
# Note that the saved ESP is the contents before the PUSHA.
#
# Set up parameters for the ISR call.
#
	movl	52(%esp), %eax   # get vector number and error code
   8:	8b 44 24 34          	mov    0x34(%esp),%eax
	movl	56(%esp), %ebx
   c:	8b 5c 24 38          	mov    0x38(%esp),%ebx

	.globl	current
	.globl	kesp

	# save the context pointer
	movl	current, %edx
  10:	8b 15 00 00 00 00    	mov    0x0,%edx
	movl	%esp, (%edx)    # assumes this is the first field
  16:	89 22                	mov    %esp,(%edx)
	# THIS CODE IS INHERENTLY NON-REENTRANT! If/when the OS
	# is converted from monolithic to something that supports
	# reentrant or interruptable ISRs, this code will need to
	# be changed to support that!

	movl	kesp, %esp
  18:	8b 25 00 00 00 00    	mov    0x0,%esp

############################################################################
# End of stack switch mod.
############################################################################

	subl	$8, %esp        # preserve stack alignment!
  1e:	83 ec 08             	sub    $0x8,%esp
	pushl	%ebx		# put them on the top of the stack ...
  21:	53                   	push   %ebx
	pushl	%eax		# ... as parameters for the ISR
  22:	50                   	push   %eax

#
# Call the ISR
#
	movl	isr_table(,%eax,4),%ebx
  23:	8b 1c 85 00 00 00 00 	mov    0x0(,%eax,4),%ebx
	call	*%ebx
  2a:	ff d3                	call   *%ebx
	addl	$16,%esp        # pop the parameters
  2c:	83 c4 10             	add    $0x10,%esp

0000002f <isr_restore>:
# We're running using the kernel stack, so we need to switch back to the
# stack for the current process.
############################################################################

        # get the context pointer
        movl    current, %ebx
  2f:	8b 1d 00 00 00 00    	mov    0x0,%ebx
	movl	(%ebx), %esp    # again, assumes this is the first field
  35:	8b 23                	mov    (%ebx),%esp
#ifdef CX_SANITY_CHK
	# perform a "sanity check" on the context before
	# we restore it, just in case....
	.globl	ctx_sanity_check
	
	movl	%esp, %eax      # context pointer
  37:	89 e0                	mov    %esp,%eax
	subl	$12, %esp
  39:	83 ec 0c             	sub    $0xc,%esp
	pushl	%eax
  3c:	50                   	push   %eax
	call	ctx_sanity_check
  3d:	e8 fc ff ff ff       	call   3e <isr_restore+0xf>
	addl	$16, %esp
  42:	83 c4 10             	add    $0x10,%esp
# By default, it prints out the CPU context being restored; it
# relies on the standard save sequence (see above).
#
	.globl	cio_printf_at

	pushl	$fmt
  45:	68 62 00 00 00       	push   $0x62
	pushl	$1
  4a:	6a 01                	push   $0x1
	pushl	$0
  4c:	6a 00                	push   $0x0
	call	cio_printf_at
  4e:	e8 fc ff ff ff       	call   4f <isr_restore+0x20>
	addl	$12,%esp
  53:	83 c4 0c             	add    $0xc,%esp
#endif

#
# Restore the context.
#
	popl	%ss		# restore the segment registers
  56:	17                   	pop    %ss
	popl	%gs
  57:	0f a9                	pop    %gs
	popl	%fs
  59:	0f a1                	pop    %fs
	popl	%es
  5b:	07                   	pop    %es
	popl	%ds
  5c:	1f                   	pop    %ds
	popa			# restore others
  5d:	61                   	popa   
	addl	$8, %esp	# discard the error code and vector
  5e:	83 c4 08             	add    $0x8,%esp
	iret			# and return
  61:	cf                   	iret   

00000062 <fmt>:
  62:	20 73 73             	and    %dh,0x73(%ebx)
  65:	3d 25 30 38 78       	cmp    $0x78383025,%eax
  6a:	20 20                	and    %ah,(%eax)
  6c:	67 73 3d             	addr16 jae ac <fmt+0x4a>
  6f:	25 30 38 78 20       	and    $0x20783830,%eax
  74:	20 66 73             	and    %ah,0x73(%esi)
  77:	3d 25 30 38 78       	cmp    $0x78383025,%eax
  7c:	20 20                	and    %ah,(%eax)
  7e:	65 73 3d             	gs jae be <fmt+0x5c>
  81:	25 30 38 78 20       	and    $0x20783830,%eax
  86:	20 64 73 3d          	and    %ah,0x3d(%ebx,%esi,2)
  8a:	25 30 38 78 0a       	and    $0xa783830,%eax
  8f:	65 64 69 3d 25 30 38 	gs imul $0x69736520,%fs:0x78383025,%edi
  96:	78 20 65 73 69 
  9b:	3d 25 30 38 78       	cmp    $0x78383025,%eax
  a0:	20 65 62             	and    %ah,0x62(%ebp)
  a3:	70 3d                	jo     e2 <fmt+0x80>
  a5:	25 30 38 78 20       	and    $0x20783830,%eax
  aa:	65 73 70             	gs jae 11d <isr_0x02+0x6>
  ad:	3d 25 30 38 78       	cmp    $0x78383025,%eax
  b2:	20 65 62             	and    %ah,0x62(%ebp)
  b5:	78 3d                	js     f4 <fmt+0x92>
  b7:	25 30 38 78 0a       	and    $0xa783830,%eax
  bc:	65 64 78 3d          	gs fs js fd <fmt+0x9b>
  c0:	25 30 38 78 20       	and    $0x20783830,%eax
  c5:	65 63 78 3d          	arpl   %di,%gs:0x3d(%eax)
  c9:	25 30 38 78 20       	and    $0x20783830,%eax
  ce:	65 61                	gs popa 
  d0:	78 3d                	js     10f <isr_0x01+0x1>
  d2:	25 30 38 78 20       	and    $0x20783830,%eax
  d7:	76 65                	jbe    13e <isr_0x06+0x3>
  d9:	63 3d 25 30 38 78    	arpl   %di,0x78383025
  df:	20 63 6f             	and    %ah,0x6f(%ebx)
  e2:	64 3d 25 30 38 78    	fs cmp $0x78383025,%eax
  e8:	0a 65 69             	or     0x69(%ebp),%ah
  eb:	70 3d                	jo     12a <isr_0x04+0x1>
  ed:	25 30 38 78 20       	and    $0x20783830,%eax
  f2:	20 63 73             	and    %ah,0x73(%ebx)
  f5:	3d 25 30 38 78       	cmp    $0x78383025,%eax
  fa:	20 65 66             	and    %ah,0x66(%ebp)
  fd:	6c                   	insb   (%dx),%es:(%edi)
  fe:	3d 25 30 38 78       	cmp    $0x78383025,%eax
 103:	0a 00                	or     (%eax),%al

00000105 <isr_0x00>:
#endif

#
# Here we generate the individual stubs for each interrupt.
#
ISR(0x00);	ISR(0x01);	ISR(0x02);	ISR(0x03);
 105:	6a 00                	push   $0x0
 107:	6a 00                	push   $0x0
 109:	e9 f2 fe ff ff       	jmp    0 <isr_save>

0000010e <isr_0x01>:
 10e:	6a 00                	push   $0x0
 110:	6a 01                	push   $0x1
 112:	e9 e9 fe ff ff       	jmp    0 <isr_save>

00000117 <isr_0x02>:
 117:	6a 00                	push   $0x0
 119:	6a 02                	push   $0x2
 11b:	e9 e0 fe ff ff       	jmp    0 <isr_save>

00000120 <isr_0x03>:
 120:	6a 00                	push   $0x0
 122:	6a 03                	push   $0x3
 124:	e9 d7 fe ff ff       	jmp    0 <isr_save>

00000129 <isr_0x04>:
ISR(0x04);	ISR(0x05);	ISR(0x06);	ISR(0x07);
 129:	6a 00                	push   $0x0
 12b:	6a 04                	push   $0x4
 12d:	e9 ce fe ff ff       	jmp    0 <isr_save>

00000132 <isr_0x05>:
 132:	6a 00                	push   $0x0
 134:	6a 05                	push   $0x5
 136:	e9 c5 fe ff ff       	jmp    0 <isr_save>

0000013b <isr_0x06>:
 13b:	6a 00                	push   $0x0
 13d:	6a 06                	push   $0x6
 13f:	e9 bc fe ff ff       	jmp    0 <isr_save>

00000144 <isr_0x07>:
 144:	6a 00                	push   $0x0
 146:	6a 07                	push   $0x7
 148:	e9 b3 fe ff ff       	jmp    0 <isr_save>

0000014d <isr_0x08>:
ERR_ISR(0x08);	ISR(0x09);	ERR_ISR(0x0a);	ERR_ISR(0x0b);
 14d:	6a 08                	push   $0x8
 14f:	e9 ac fe ff ff       	jmp    0 <isr_save>

00000154 <isr_0x09>:
 154:	6a 00                	push   $0x0
 156:	6a 09                	push   $0x9
 158:	e9 a3 fe ff ff       	jmp    0 <isr_save>

0000015d <isr_0x0a>:
 15d:	6a 0a                	push   $0xa
 15f:	e9 9c fe ff ff       	jmp    0 <isr_save>

00000164 <isr_0x0b>:
 164:	6a 0b                	push   $0xb
 166:	e9 95 fe ff ff       	jmp    0 <isr_save>

0000016b <isr_0x0c>:
ERR_ISR(0x0c);	ERR_ISR(0x0d);	ERR_ISR(0x0e);	ISR(0x0f);
 16b:	6a 0c                	push   $0xc
 16d:	e9 8e fe ff ff       	jmp    0 <isr_save>

00000172 <isr_0x0d>:
 172:	6a 0d                	push   $0xd
 174:	e9 87 fe ff ff       	jmp    0 <isr_save>

00000179 <isr_0x0e>:
 179:	6a 0e                	push   $0xe
 17b:	e9 80 fe ff ff       	jmp    0 <isr_save>

00000180 <isr_0x0f>:
 180:	6a 00                	push   $0x0
 182:	6a 0f                	push   $0xf
 184:	e9 77 fe ff ff       	jmp    0 <isr_save>

00000189 <isr_0x10>:
ISR(0x10);	ERR_ISR(0x11);	ISR(0x12);	ISR(0x13);
 189:	6a 00                	push   $0x0
 18b:	6a 10                	push   $0x10
 18d:	e9 6e fe ff ff       	jmp    0 <isr_save>

00000192 <isr_0x11>:
 192:	6a 11                	push   $0x11
 194:	e9 67 fe ff ff       	jmp    0 <isr_save>

00000199 <isr_0x12>:
 199:	6a 00                	push   $0x0
 19b:	6a 12                	push   $0x12
 19d:	e9 5e fe ff ff       	jmp    0 <isr_save>

000001a2 <isr_0x13>:
 1a2:	6a 00                	push   $0x0
 1a4:	6a 13                	push   $0x13
 1a6:	e9 55 fe ff ff       	jmp    0 <isr_save>

000001ab <isr_0x14>:
ISR(0x14);	ERR_ISR(0x15);	ISR(0x16);	ISR(0x17);
 1ab:	6a 00                	push   $0x0
 1ad:	6a 14                	push   $0x14
 1af:	e9 4c fe ff ff       	jmp    0 <isr_save>

000001b4 <isr_0x15>:
 1b4:	6a 15                	push   $0x15
 1b6:	e9 45 fe ff ff       	jmp    0 <isr_save>

000001bb <isr_0x16>:
 1bb:	6a 00                	push   $0x0
 1bd:	6a 16                	push   $0x16
 1bf:	e9 3c fe ff ff       	jmp    0 <isr_save>

000001c4 <isr_0x17>:
 1c4:	6a 00                	push   $0x0
 1c6:	6a 17                	push   $0x17
 1c8:	e9 33 fe ff ff       	jmp    0 <isr_save>

000001cd <isr_0x18>:
ISR(0x18);	ISR(0x19);	ISR(0x1a);	ISR(0x1b);
 1cd:	6a 00                	push   $0x0
 1cf:	6a 18                	push   $0x18
 1d1:	e9 2a fe ff ff       	jmp    0 <isr_save>

000001d6 <isr_0x19>:
 1d6:	6a 00                	push   $0x0
 1d8:	6a 19                	push   $0x19
 1da:	e9 21 fe ff ff       	jmp    0 <isr_save>

000001df <isr_0x1a>:
 1df:	6a 00                	push   $0x0
 1e1:	6a 1a                	push   $0x1a
 1e3:	e9 18 fe ff ff       	jmp    0 <isr_save>

000001e8 <isr_0x1b>:
 1e8:	6a 00                	push   $0x0
 1ea:	6a 1b                	push   $0x1b
 1ec:	e9 0f fe ff ff       	jmp    0 <isr_save>

000001f1 <isr_0x1c>:
ISR(0x1c);	ISR(0x1d);	ISR(0x1e);	ISR(0x1f);
 1f1:	6a 00                	push   $0x0
 1f3:	6a 1c                	push   $0x1c
 1f5:	e9 06 fe ff ff       	jmp    0 <isr_save>

000001fa <isr_0x1d>:
 1fa:	6a 00                	push   $0x0
 1fc:	6a 1d                	push   $0x1d
 1fe:	e9 fd fd ff ff       	jmp    0 <isr_save>

00000203 <isr_0x1e>:
 203:	6a 00                	push   $0x0
 205:	6a 1e                	push   $0x1e
 207:	e9 f4 fd ff ff       	jmp    0 <isr_save>

0000020c <isr_0x1f>:
 20c:	6a 00                	push   $0x0
 20e:	6a 1f                	push   $0x1f
 210:	e9 eb fd ff ff       	jmp    0 <isr_save>

00000215 <isr_0x20>:
ISR(0x20);	ISR(0x21);	ISR(0x22);	ISR(0x23);
 215:	6a 00                	push   $0x0
 217:	6a 20                	push   $0x20
 219:	e9 e2 fd ff ff       	jmp    0 <isr_save>

0000021e <isr_0x21>:
 21e:	6a 00                	push   $0x0
 220:	6a 21                	push   $0x21
 222:	e9 d9 fd ff ff       	jmp    0 <isr_save>

00000227 <isr_0x22>:
 227:	6a 00                	push   $0x0
 229:	6a 22                	push   $0x22
 22b:	e9 d0 fd ff ff       	jmp    0 <isr_save>

00000230 <isr_0x23>:
 230:	6a 00                	push   $0x0
 232:	6a 23                	push   $0x23
 234:	e9 c7 fd ff ff       	jmp    0 <isr_save>

00000239 <isr_0x24>:
ISR(0x24);	ISR(0x25);	ISR(0x26);	ISR(0x27);
 239:	6a 00                	push   $0x0
 23b:	6a 24                	push   $0x24
 23d:	e9 be fd ff ff       	jmp    0 <isr_save>

00000242 <isr_0x25>:
 242:	6a 00                	push   $0x0
 244:	6a 25                	push   $0x25
 246:	e9 b5 fd ff ff       	jmp    0 <isr_save>

0000024b <isr_0x26>:
 24b:	6a 00                	push   $0x0
 24d:	6a 26                	push   $0x26
 24f:	e9 ac fd ff ff       	jmp    0 <isr_save>

00000254 <isr_0x27>:
 254:	6a 00                	push   $0x0
 256:	6a 27                	push   $0x27
 258:	e9 a3 fd ff ff       	jmp    0 <isr_save>

0000025d <isr_0x28>:
ISR(0x28);	ISR(0x29);	ISR(0x2a);	ISR(0x2b);
 25d:	6a 00                	push   $0x0
 25f:	6a 28                	push   $0x28
 261:	e9 9a fd ff ff       	jmp    0 <isr_save>

00000266 <isr_0x29>:
 266:	6a 00                	push   $0x0
 268:	6a 29                	push   $0x29
 26a:	e9 91 fd ff ff       	jmp    0 <isr_save>

0000026f <isr_0x2a>:
 26f:	6a 00                	push   $0x0
 271:	6a 2a                	push   $0x2a
 273:	e9 88 fd ff ff       	jmp    0 <isr_save>

00000278 <isr_0x2b>:
 278:	6a 00                	push   $0x0
 27a:	6a 2b                	push   $0x2b
 27c:	e9 7f fd ff ff       	jmp    0 <isr_save>

00000281 <isr_0x2c>:
ISR(0x2c);	ISR(0x2d);	ISR(0x2e);	ISR(0x2f);
 281:	6a 00                	push   $0x0
 283:	6a 2c                	push   $0x2c
 285:	e9 76 fd ff ff       	jmp    0 <isr_save>

0000028a <isr_0x2d>:
 28a:	6a 00                	push   $0x0
 28c:	6a 2d                	push   $0x2d
 28e:	e9 6d fd ff ff       	jmp    0 <isr_save>

00000293 <isr_0x2e>:
 293:	6a 00                	push   $0x0
 295:	6a 2e                	push   $0x2e
 297:	e9 64 fd ff ff       	jmp    0 <isr_save>

0000029c <isr_0x2f>:
 29c:	6a 00                	push   $0x0
 29e:	6a 2f                	push   $0x2f
 2a0:	e9 5b fd ff ff       	jmp    0 <isr_save>

000002a5 <isr_0x30>:
ISR(0x30);	ISR(0x31);	ISR(0x32);	ISR(0x33);
 2a5:	6a 00                	push   $0x0
 2a7:	6a 30                	push   $0x30
 2a9:	e9 52 fd ff ff       	jmp    0 <isr_save>

000002ae <isr_0x31>:
 2ae:	6a 00                	push   $0x0
 2b0:	6a 31                	push   $0x31
 2b2:	e9 49 fd ff ff       	jmp    0 <isr_save>

000002b7 <isr_0x32>:
 2b7:	6a 00                	push   $0x0
 2b9:	6a 32                	push   $0x32
 2bb:	e9 40 fd ff ff       	jmp    0 <isr_save>

000002c0 <isr_0x33>:
 2c0:	6a 00                	push   $0x0
 2c2:	6a 33                	push   $0x33
 2c4:	e9 37 fd ff ff       	jmp    0 <isr_save>

000002c9 <isr_0x34>:
ISR(0x34);	ISR(0x35);	ISR(0x36);	ISR(0x37);
 2c9:	6a 00                	push   $0x0
 2cb:	6a 34                	push   $0x34
 2cd:	e9 2e fd ff ff       	jmp    0 <isr_save>

000002d2 <isr_0x35>:
 2d2:	6a 00                	push   $0x0
 2d4:	6a 35                	push   $0x35
 2d6:	e9 25 fd ff ff       	jmp    0 <isr_save>

000002db <isr_0x36>:
 2db:	6a 00                	push   $0x0
 2dd:	6a 36                	push   $0x36
 2df:	e9 1c fd ff ff       	jmp    0 <isr_save>

000002e4 <isr_0x37>:
 2e4:	6a 00                	push   $0x0
 2e6:	6a 37                	push   $0x37
 2e8:	e9 13 fd ff ff       	jmp    0 <isr_save>

000002ed <isr_0x38>:
ISR(0x38);	ISR(0x39);	ISR(0x3a);	ISR(0x3b);
 2ed:	6a 00                	push   $0x0
 2ef:	6a 38                	push   $0x38
 2f1:	e9 0a fd ff ff       	jmp    0 <isr_save>

000002f6 <isr_0x39>:
 2f6:	6a 00                	push   $0x0
 2f8:	6a 39                	push   $0x39
 2fa:	e9 01 fd ff ff       	jmp    0 <isr_save>

000002ff <isr_0x3a>:
 2ff:	6a 00                	push   $0x0
 301:	6a 3a                	push   $0x3a
 303:	e9 f8 fc ff ff       	jmp    0 <isr_save>

00000308 <isr_0x3b>:
 308:	6a 00                	push   $0x0
 30a:	6a 3b                	push   $0x3b
 30c:	e9 ef fc ff ff       	jmp    0 <isr_save>

00000311 <isr_0x3c>:
ISR(0x3c);	ISR(0x3d);	ISR(0x3e);	ISR(0x3f);
 311:	6a 00                	push   $0x0
 313:	6a 3c                	push   $0x3c
 315:	e9 e6 fc ff ff       	jmp    0 <isr_save>

0000031a <isr_0x3d>:
 31a:	6a 00                	push   $0x0
 31c:	6a 3d                	push   $0x3d
 31e:	e9 dd fc ff ff       	jmp    0 <isr_save>

00000323 <isr_0x3e>:
 323:	6a 00                	push   $0x0
 325:	6a 3e                	push   $0x3e
 327:	e9 d4 fc ff ff       	jmp    0 <isr_save>

0000032c <isr_0x3f>:
 32c:	6a 00                	push   $0x0
 32e:	6a 3f                	push   $0x3f
 330:	e9 cb fc ff ff       	jmp    0 <isr_save>

00000335 <isr_0x40>:
ISR(0x40);	ISR(0x41);	ISR(0x42);	ISR(0x43);
 335:	6a 00                	push   $0x0
 337:	6a 40                	push   $0x40
 339:	e9 c2 fc ff ff       	jmp    0 <isr_save>

0000033e <isr_0x41>:
 33e:	6a 00                	push   $0x0
 340:	6a 41                	push   $0x41
 342:	e9 b9 fc ff ff       	jmp    0 <isr_save>

00000347 <isr_0x42>:
 347:	6a 00                	push   $0x0
 349:	6a 42                	push   $0x42
 34b:	e9 b0 fc ff ff       	jmp    0 <isr_save>

00000350 <isr_0x43>:
 350:	6a 00                	push   $0x0
 352:	6a 43                	push   $0x43
 354:	e9 a7 fc ff ff       	jmp    0 <isr_save>

00000359 <isr_0x44>:
ISR(0x44);	ISR(0x45);	ISR(0x46);	ISR(0x47);
 359:	6a 00                	push   $0x0
 35b:	6a 44                	push   $0x44
 35d:	e9 9e fc ff ff       	jmp    0 <isr_save>

00000362 <isr_0x45>:
 362:	6a 00                	push   $0x0
 364:	6a 45                	push   $0x45
 366:	e9 95 fc ff ff       	jmp    0 <isr_save>

0000036b <isr_0x46>:
 36b:	6a 00                	push   $0x0
 36d:	6a 46                	push   $0x46
 36f:	e9 8c fc ff ff       	jmp    0 <isr_save>

00000374 <isr_0x47>:
 374:	6a 00                	push   $0x0
 376:	6a 47                	push   $0x47
 378:	e9 83 fc ff ff       	jmp    0 <isr_save>

0000037d <isr_0x48>:
ISR(0x48);	ISR(0x49);	ISR(0x4a);	ISR(0x4b);
 37d:	6a 00                	push   $0x0
 37f:	6a 48                	push   $0x48
 381:	e9 7a fc ff ff       	jmp    0 <isr_save>

00000386 <isr_0x49>:
 386:	6a 00                	push   $0x0
 388:	6a 49                	push   $0x49
 38a:	e9 71 fc ff ff       	jmp    0 <isr_save>

0000038f <isr_0x4a>:
 38f:	6a 00                	push   $0x0
 391:	6a 4a                	push   $0x4a
 393:	e9 68 fc ff ff       	jmp    0 <isr_save>

00000398 <isr_0x4b>:
 398:	6a 00                	push   $0x0
 39a:	6a 4b                	push   $0x4b
 39c:	e9 5f fc ff ff       	jmp    0 <isr_save>

000003a1 <isr_0x4c>:
ISR(0x4c);	ISR(0x4d);	ISR(0x4e);	ISR(0x4f);
 3a1:	6a 00                	push   $0x0
 3a3:	6a 4c                	push   $0x4c
 3a5:	e9 56 fc ff ff       	jmp    0 <isr_save>

000003aa <isr_0x4d>:
 3aa:	6a 00                	push   $0x0
 3ac:	6a 4d                	push   $0x4d
 3ae:	e9 4d fc ff ff       	jmp    0 <isr_save>

000003b3 <isr_0x4e>:
 3b3:	6a 00                	push   $0x0
 3b5:	6a 4e                	push   $0x4e
 3b7:	e9 44 fc ff ff       	jmp    0 <isr_save>

000003bc <isr_0x4f>:
 3bc:	6a 00                	push   $0x0
 3be:	6a 4f                	push   $0x4f
 3c0:	e9 3b fc ff ff       	jmp    0 <isr_save>

000003c5 <isr_0x50>:
ISR(0x50);	ISR(0x51);	ISR(0x52);	ISR(0x53);
 3c5:	6a 00                	push   $0x0
 3c7:	6a 50                	push   $0x50
 3c9:	e9 32 fc ff ff       	jmp    0 <isr_save>

000003ce <isr_0x51>:
 3ce:	6a 00                	push   $0x0
 3d0:	6a 51                	push   $0x51
 3d2:	e9 29 fc ff ff       	jmp    0 <isr_save>

000003d7 <isr_0x52>:
 3d7:	6a 00                	push   $0x0
 3d9:	6a 52                	push   $0x52
 3db:	e9 20 fc ff ff       	jmp    0 <isr_save>

000003e0 <isr_0x53>:
 3e0:	6a 00                	push   $0x0
 3e2:	6a 53                	push   $0x53
 3e4:	e9 17 fc ff ff       	jmp    0 <isr_save>

000003e9 <isr_0x54>:
ISR(0x54);	ISR(0x55);	ISR(0x56);	ISR(0x57);
 3e9:	6a 00                	push   $0x0
 3eb:	6a 54                	push   $0x54
 3ed:	e9 0e fc ff ff       	jmp    0 <isr_save>

000003f2 <isr_0x55>:
 3f2:	6a 00                	push   $0x0
 3f4:	6a 55                	push   $0x55
 3f6:	e9 05 fc ff ff       	jmp    0 <isr_save>

000003fb <isr_0x56>:
 3fb:	6a 00                	push   $0x0
 3fd:	6a 56                	push   $0x56
 3ff:	e9 fc fb ff ff       	jmp    0 <isr_save>

00000404 <isr_0x57>:
 404:	6a 00                	push   $0x0
 406:	6a 57                	push   $0x57
 408:	e9 f3 fb ff ff       	jmp    0 <isr_save>

0000040d <isr_0x58>:
ISR(0x58);	ISR(0x59);	ISR(0x5a);	ISR(0x5b);
 40d:	6a 00                	push   $0x0
 40f:	6a 58                	push   $0x58
 411:	e9 ea fb ff ff       	jmp    0 <isr_save>

00000416 <isr_0x59>:
 416:	6a 00                	push   $0x0
 418:	6a 59                	push   $0x59
 41a:	e9 e1 fb ff ff       	jmp    0 <isr_save>

0000041f <isr_0x5a>:
 41f:	6a 00                	push   $0x0
 421:	6a 5a                	push   $0x5a
 423:	e9 d8 fb ff ff       	jmp    0 <isr_save>

00000428 <isr_0x5b>:
 428:	6a 00                	push   $0x0
 42a:	6a 5b                	push   $0x5b
 42c:	e9 cf fb ff ff       	jmp    0 <isr_save>

00000431 <isr_0x5c>:
ISR(0x5c);	ISR(0x5d);	ISR(0x5e);	ISR(0x5f);
 431:	6a 00                	push   $0x0
 433:	6a 5c                	push   $0x5c
 435:	e9 c6 fb ff ff       	jmp    0 <isr_save>

0000043a <isr_0x5d>:
 43a:	6a 00                	push   $0x0
 43c:	6a 5d                	push   $0x5d
 43e:	e9 bd fb ff ff       	jmp    0 <isr_save>

00000443 <isr_0x5e>:
 443:	6a 00                	push   $0x0
 445:	6a 5e                	push   $0x5e
 447:	e9 b4 fb ff ff       	jmp    0 <isr_save>

0000044c <isr_0x5f>:
 44c:	6a 00                	push   $0x0
 44e:	6a 5f                	push   $0x5f
 450:	e9 ab fb ff ff       	jmp    0 <isr_save>

00000455 <isr_0x60>:
ISR(0x60);	ISR(0x61);	ISR(0x62);	ISR(0x63);
 455:	6a 00                	push   $0x0
 457:	6a 60                	push   $0x60
 459:	e9 a2 fb ff ff       	jmp    0 <isr_save>

0000045e <isr_0x61>:
 45e:	6a 00                	push   $0x0
 460:	6a 61                	push   $0x61
 462:	e9 99 fb ff ff       	jmp    0 <isr_save>

00000467 <isr_0x62>:
 467:	6a 00                	push   $0x0
 469:	6a 62                	push   $0x62
 46b:	e9 90 fb ff ff       	jmp    0 <isr_save>

00000470 <isr_0x63>:
 470:	6a 00                	push   $0x0
 472:	6a 63                	push   $0x63
 474:	e9 87 fb ff ff       	jmp    0 <isr_save>

00000479 <isr_0x64>:
ISR(0x64);	ISR(0x65);	ISR(0x66);	ISR(0x67);
 479:	6a 00                	push   $0x0
 47b:	6a 64                	push   $0x64
 47d:	e9 7e fb ff ff       	jmp    0 <isr_save>

00000482 <isr_0x65>:
 482:	6a 00                	push   $0x0
 484:	6a 65                	push   $0x65
 486:	e9 75 fb ff ff       	jmp    0 <isr_save>

0000048b <isr_0x66>:
 48b:	6a 00                	push   $0x0
 48d:	6a 66                	push   $0x66
 48f:	e9 6c fb ff ff       	jmp    0 <isr_save>

00000494 <isr_0x67>:
 494:	6a 00                	push   $0x0
 496:	6a 67                	push   $0x67
 498:	e9 63 fb ff ff       	jmp    0 <isr_save>

0000049d <isr_0x68>:
ISR(0x68);	ISR(0x69);	ISR(0x6a);	ISR(0x6b);
 49d:	6a 00                	push   $0x0
 49f:	6a 68                	push   $0x68
 4a1:	e9 5a fb ff ff       	jmp    0 <isr_save>

000004a6 <isr_0x69>:
 4a6:	6a 00                	push   $0x0
 4a8:	6a 69                	push   $0x69
 4aa:	e9 51 fb ff ff       	jmp    0 <isr_save>

000004af <isr_0x6a>:
 4af:	6a 00                	push   $0x0
 4b1:	6a 6a                	push   $0x6a
 4b3:	e9 48 fb ff ff       	jmp    0 <isr_save>

000004b8 <isr_0x6b>:
 4b8:	6a 00                	push   $0x0
 4ba:	6a 6b                	push   $0x6b
 4bc:	e9 3f fb ff ff       	jmp    0 <isr_save>

000004c1 <isr_0x6c>:
ISR(0x6c);	ISR(0x6d);	ISR(0x6e);	ISR(0x6f);
 4c1:	6a 00                	push   $0x0
 4c3:	6a 6c                	push   $0x6c
 4c5:	e9 36 fb ff ff       	jmp    0 <isr_save>

000004ca <isr_0x6d>:
 4ca:	6a 00                	push   $0x0
 4cc:	6a 6d                	push   $0x6d
 4ce:	e9 2d fb ff ff       	jmp    0 <isr_save>

000004d3 <isr_0x6e>:
 4d3:	6a 00                	push   $0x0
 4d5:	6a 6e                	push   $0x6e
 4d7:	e9 24 fb ff ff       	jmp    0 <isr_save>

000004dc <isr_0x6f>:
 4dc:	6a 00                	push   $0x0
 4de:	6a 6f                	push   $0x6f
 4e0:	e9 1b fb ff ff       	jmp    0 <isr_save>

000004e5 <isr_0x70>:
ISR(0x70);	ISR(0x71);	ISR(0x72);	ISR(0x73);
 4e5:	6a 00                	push   $0x0
 4e7:	6a 70                	push   $0x70
 4e9:	e9 12 fb ff ff       	jmp    0 <isr_save>

000004ee <isr_0x71>:
 4ee:	6a 00                	push   $0x0
 4f0:	6a 71                	push   $0x71
 4f2:	e9 09 fb ff ff       	jmp    0 <isr_save>

000004f7 <isr_0x72>:
 4f7:	6a 00                	push   $0x0
 4f9:	6a 72                	push   $0x72
 4fb:	e9 00 fb ff ff       	jmp    0 <isr_save>

00000500 <isr_0x73>:
 500:	6a 00                	push   $0x0
 502:	6a 73                	push   $0x73
 504:	e9 f7 fa ff ff       	jmp    0 <isr_save>

00000509 <isr_0x74>:
ISR(0x74);	ISR(0x75);	ISR(0x76);	ISR(0x77);
 509:	6a 00                	push   $0x0
 50b:	6a 74                	push   $0x74
 50d:	e9 ee fa ff ff       	jmp    0 <isr_save>

00000512 <isr_0x75>:
 512:	6a 00                	push   $0x0
 514:	6a 75                	push   $0x75
 516:	e9 e5 fa ff ff       	jmp    0 <isr_save>

0000051b <isr_0x76>:
 51b:	6a 00                	push   $0x0
 51d:	6a 76                	push   $0x76
 51f:	e9 dc fa ff ff       	jmp    0 <isr_save>

00000524 <isr_0x77>:
 524:	6a 00                	push   $0x0
 526:	6a 77                	push   $0x77
 528:	e9 d3 fa ff ff       	jmp    0 <isr_save>

0000052d <isr_0x78>:
ISR(0x78);	ISR(0x79);	ISR(0x7a);	ISR(0x7b);
 52d:	6a 00                	push   $0x0
 52f:	6a 78                	push   $0x78
 531:	e9 ca fa ff ff       	jmp    0 <isr_save>

00000536 <isr_0x79>:
 536:	6a 00                	push   $0x0
 538:	6a 79                	push   $0x79
 53a:	e9 c1 fa ff ff       	jmp    0 <isr_save>

0000053f <isr_0x7a>:
 53f:	6a 00                	push   $0x0
 541:	6a 7a                	push   $0x7a
 543:	e9 b8 fa ff ff       	jmp    0 <isr_save>

00000548 <isr_0x7b>:
 548:	6a 00                	push   $0x0
 54a:	6a 7b                	push   $0x7b
 54c:	e9 af fa ff ff       	jmp    0 <isr_save>

00000551 <isr_0x7c>:
ISR(0x7c);	ISR(0x7d);	ISR(0x7e);	ISR(0x7f);
 551:	6a 00                	push   $0x0
 553:	6a 7c                	push   $0x7c
 555:	e9 a6 fa ff ff       	jmp    0 <isr_save>

0000055a <isr_0x7d>:
 55a:	6a 00                	push   $0x0
 55c:	6a 7d                	push   $0x7d
 55e:	e9 9d fa ff ff       	jmp    0 <isr_save>

00000563 <isr_0x7e>:
 563:	6a 00                	push   $0x0
 565:	6a 7e                	push   $0x7e
 567:	e9 94 fa ff ff       	jmp    0 <isr_save>

0000056c <isr_0x7f>:
 56c:	6a 00                	push   $0x0
 56e:	6a 7f                	push   $0x7f
 570:	e9 8b fa ff ff       	jmp    0 <isr_save>

00000575 <isr_0x80>:
ISR(0x80);	ISR(0x81);	ISR(0x82);	ISR(0x83);
 575:	6a 00                	push   $0x0
 577:	68 80 00 00 00       	push   $0x80
 57c:	e9 7f fa ff ff       	jmp    0 <isr_save>

00000581 <isr_0x81>:
 581:	6a 00                	push   $0x0
 583:	68 81 00 00 00       	push   $0x81
 588:	e9 73 fa ff ff       	jmp    0 <isr_save>

0000058d <isr_0x82>:
 58d:	6a 00                	push   $0x0
 58f:	68 82 00 00 00       	push   $0x82
 594:	e9 67 fa ff ff       	jmp    0 <isr_save>

00000599 <isr_0x83>:
 599:	6a 00                	push   $0x0
 59b:	68 83 00 00 00       	push   $0x83
 5a0:	e9 5b fa ff ff       	jmp    0 <isr_save>

000005a5 <isr_0x84>:
ISR(0x84);	ISR(0x85);	ISR(0x86);	ISR(0x87);
 5a5:	6a 00                	push   $0x0
 5a7:	68 84 00 00 00       	push   $0x84
 5ac:	e9 4f fa ff ff       	jmp    0 <isr_save>

000005b1 <isr_0x85>:
 5b1:	6a 00                	push   $0x0
 5b3:	68 85 00 00 00       	push   $0x85
 5b8:	e9 43 fa ff ff       	jmp    0 <isr_save>

000005bd <isr_0x86>:
 5bd:	6a 00                	push   $0x0
 5bf:	68 86 00 00 00       	push   $0x86
 5c4:	e9 37 fa ff ff       	jmp    0 <isr_save>

000005c9 <isr_0x87>:
 5c9:	6a 00                	push   $0x0
 5cb:	68 87 00 00 00       	push   $0x87
 5d0:	e9 2b fa ff ff       	jmp    0 <isr_save>

000005d5 <isr_0x88>:
ISR(0x88);	ISR(0x89);	ISR(0x8a);	ISR(0x8b);
 5d5:	6a 00                	push   $0x0
 5d7:	68 88 00 00 00       	push   $0x88
 5dc:	e9 1f fa ff ff       	jmp    0 <isr_save>

000005e1 <isr_0x89>:
 5e1:	6a 00                	push   $0x0
 5e3:	68 89 00 00 00       	push   $0x89
 5e8:	e9 13 fa ff ff       	jmp    0 <isr_save>

000005ed <isr_0x8a>:
 5ed:	6a 00                	push   $0x0
 5ef:	68 8a 00 00 00       	push   $0x8a
 5f4:	e9 07 fa ff ff       	jmp    0 <isr_save>

000005f9 <isr_0x8b>:
 5f9:	6a 00                	push   $0x0
 5fb:	68 8b 00 00 00       	push   $0x8b
 600:	e9 fb f9 ff ff       	jmp    0 <isr_save>

00000605 <isr_0x8c>:
ISR(0x8c);	ISR(0x8d);	ISR(0x8e);	ISR(0x8f);
 605:	6a 00                	push   $0x0
 607:	68 8c 00 00 00       	push   $0x8c
 60c:	e9 ef f9 ff ff       	jmp    0 <isr_save>

00000611 <isr_0x8d>:
 611:	6a 00                	push   $0x0
 613:	68 8d 00 00 00       	push   $0x8d
 618:	e9 e3 f9 ff ff       	jmp    0 <isr_save>

0000061d <isr_0x8e>:
 61d:	6a 00                	push   $0x0
 61f:	68 8e 00 00 00       	push   $0x8e
 624:	e9 d7 f9 ff ff       	jmp    0 <isr_save>

00000629 <isr_0x8f>:
 629:	6a 00                	push   $0x0
 62b:	68 8f 00 00 00       	push   $0x8f
 630:	e9 cb f9 ff ff       	jmp    0 <isr_save>

00000635 <isr_0x90>:
ISR(0x90);	ISR(0x91);	ISR(0x92);	ISR(0x93);
 635:	6a 00                	push   $0x0
 637:	68 90 00 00 00       	push   $0x90
 63c:	e9 bf f9 ff ff       	jmp    0 <isr_save>

00000641 <isr_0x91>:
 641:	6a 00                	push   $0x0
 643:	68 91 00 00 00       	push   $0x91
 648:	e9 b3 f9 ff ff       	jmp    0 <isr_save>

0000064d <isr_0x92>:
 64d:	6a 00                	push   $0x0
 64f:	68 92 00 00 00       	push   $0x92
 654:	e9 a7 f9 ff ff       	jmp    0 <isr_save>

00000659 <isr_0x93>:
 659:	6a 00                	push   $0x0
 65b:	68 93 00 00 00       	push   $0x93
 660:	e9 9b f9 ff ff       	jmp    0 <isr_save>

00000665 <isr_0x94>:
ISR(0x94);	ISR(0x95);	ISR(0x96);	ISR(0x97);
 665:	6a 00                	push   $0x0
 667:	68 94 00 00 00       	push   $0x94
 66c:	e9 8f f9 ff ff       	jmp    0 <isr_save>

00000671 <isr_0x95>:
 671:	6a 00                	push   $0x0
 673:	68 95 00 00 00       	push   $0x95
 678:	e9 83 f9 ff ff       	jmp    0 <isr_save>

0000067d <isr_0x96>:
 67d:	6a 00                	push   $0x0
 67f:	68 96 00 00 00       	push   $0x96
 684:	e9 77 f9 ff ff       	jmp    0 <isr_save>

00000689 <isr_0x97>:
 689:	6a 00                	push   $0x0
 68b:	68 97 00 00 00       	push   $0x97
 690:	e9 6b f9 ff ff       	jmp    0 <isr_save>

00000695 <isr_0x98>:
ISR(0x98);	ISR(0x99);	ISR(0x9a);	ISR(0x9b);
 695:	6a 00                	push   $0x0
 697:	68 98 00 00 00       	push   $0x98
 69c:	e9 5f f9 ff ff       	jmp    0 <isr_save>

000006a1 <isr_0x99>:
 6a1:	6a 00                	push   $0x0
 6a3:	68 99 00 00 00       	push   $0x99
 6a8:	e9 53 f9 ff ff       	jmp    0 <isr_save>

000006ad <isr_0x9a>:
 6ad:	6a 00                	push   $0x0
 6af:	68 9a 00 00 00       	push   $0x9a
 6b4:	e9 47 f9 ff ff       	jmp    0 <isr_save>

000006b9 <isr_0x9b>:
 6b9:	6a 00                	push   $0x0
 6bb:	68 9b 00 00 00       	push   $0x9b
 6c0:	e9 3b f9 ff ff       	jmp    0 <isr_save>

000006c5 <isr_0x9c>:
ISR(0x9c);	ISR(0x9d);	ISR(0x9e);	ISR(0x9f);
 6c5:	6a 00                	push   $0x0
 6c7:	68 9c 00 00 00       	push   $0x9c
 6cc:	e9 2f f9 ff ff       	jmp    0 <isr_save>

000006d1 <isr_0x9d>:
 6d1:	6a 00                	push   $0x0
 6d3:	68 9d 00 00 00       	push   $0x9d
 6d8:	e9 23 f9 ff ff       	jmp    0 <isr_save>

000006dd <isr_0x9e>:
 6dd:	6a 00                	push   $0x0
 6df:	68 9e 00 00 00       	push   $0x9e
 6e4:	e9 17 f9 ff ff       	jmp    0 <isr_save>

000006e9 <isr_0x9f>:
 6e9:	6a 00                	push   $0x0
 6eb:	68 9f 00 00 00       	push   $0x9f
 6f0:	e9 0b f9 ff ff       	jmp    0 <isr_save>

000006f5 <isr_0xa0>:
ISR(0xa0);	ISR(0xa1);	ISR(0xa2);	ISR(0xa3);
 6f5:	6a 00                	push   $0x0
 6f7:	68 a0 00 00 00       	push   $0xa0
 6fc:	e9 ff f8 ff ff       	jmp    0 <isr_save>

00000701 <isr_0xa1>:
 701:	6a 00                	push   $0x0
 703:	68 a1 00 00 00       	push   $0xa1
 708:	e9 f3 f8 ff ff       	jmp    0 <isr_save>

0000070d <isr_0xa2>:
 70d:	6a 00                	push   $0x0
 70f:	68 a2 00 00 00       	push   $0xa2
 714:	e9 e7 f8 ff ff       	jmp    0 <isr_save>

00000719 <isr_0xa3>:
 719:	6a 00                	push   $0x0
 71b:	68 a3 00 00 00       	push   $0xa3
 720:	e9 db f8 ff ff       	jmp    0 <isr_save>

00000725 <isr_0xa4>:
ISR(0xa4);	ISR(0xa5);	ISR(0xa6);	ISR(0xa7);
 725:	6a 00                	push   $0x0
 727:	68 a4 00 00 00       	push   $0xa4
 72c:	e9 cf f8 ff ff       	jmp    0 <isr_save>

00000731 <isr_0xa5>:
 731:	6a 00                	push   $0x0
 733:	68 a5 00 00 00       	push   $0xa5
 738:	e9 c3 f8 ff ff       	jmp    0 <isr_save>

0000073d <isr_0xa6>:
 73d:	6a 00                	push   $0x0
 73f:	68 a6 00 00 00       	push   $0xa6
 744:	e9 b7 f8 ff ff       	jmp    0 <isr_save>

00000749 <isr_0xa7>:
 749:	6a 00                	push   $0x0
 74b:	68 a7 00 00 00       	push   $0xa7
 750:	e9 ab f8 ff ff       	jmp    0 <isr_save>

00000755 <isr_0xa8>:
ISR(0xa8);	ISR(0xa9);	ISR(0xaa);	ISR(0xab);
 755:	6a 00                	push   $0x0
 757:	68 a8 00 00 00       	push   $0xa8
 75c:	e9 9f f8 ff ff       	jmp    0 <isr_save>

00000761 <isr_0xa9>:
 761:	6a 00                	push   $0x0
 763:	68 a9 00 00 00       	push   $0xa9
 768:	e9 93 f8 ff ff       	jmp    0 <isr_save>

0000076d <isr_0xaa>:
 76d:	6a 00                	push   $0x0
 76f:	68 aa 00 00 00       	push   $0xaa
 774:	e9 87 f8 ff ff       	jmp    0 <isr_save>

00000779 <isr_0xab>:
 779:	6a 00                	push   $0x0
 77b:	68 ab 00 00 00       	push   $0xab
 780:	e9 7b f8 ff ff       	jmp    0 <isr_save>

00000785 <isr_0xac>:
ISR(0xac);	ISR(0xad);	ISR(0xae);	ISR(0xaf);
 785:	6a 00                	push   $0x0
 787:	68 ac 00 00 00       	push   $0xac
 78c:	e9 6f f8 ff ff       	jmp    0 <isr_save>

00000791 <isr_0xad>:
 791:	6a 00                	push   $0x0
 793:	68 ad 00 00 00       	push   $0xad
 798:	e9 63 f8 ff ff       	jmp    0 <isr_save>

0000079d <isr_0xae>:
 79d:	6a 00                	push   $0x0
 79f:	68 ae 00 00 00       	push   $0xae
 7a4:	e9 57 f8 ff ff       	jmp    0 <isr_save>

000007a9 <isr_0xaf>:
 7a9:	6a 00                	push   $0x0
 7ab:	68 af 00 00 00       	push   $0xaf
 7b0:	e9 4b f8 ff ff       	jmp    0 <isr_save>

000007b5 <isr_0xb0>:
ISR(0xb0);	ISR(0xb1);	ISR(0xb2);	ISR(0xb3);
 7b5:	6a 00                	push   $0x0
 7b7:	68 b0 00 00 00       	push   $0xb0
 7bc:	e9 3f f8 ff ff       	jmp    0 <isr_save>

000007c1 <isr_0xb1>:
 7c1:	6a 00                	push   $0x0
 7c3:	68 b1 00 00 00       	push   $0xb1
 7c8:	e9 33 f8 ff ff       	jmp    0 <isr_save>

000007cd <isr_0xb2>:
 7cd:	6a 00                	push   $0x0
 7cf:	68 b2 00 00 00       	push   $0xb2
 7d4:	e9 27 f8 ff ff       	jmp    0 <isr_save>

000007d9 <isr_0xb3>:
 7d9:	6a 00                	push   $0x0
 7db:	68 b3 00 00 00       	push   $0xb3
 7e0:	e9 1b f8 ff ff       	jmp    0 <isr_save>

000007e5 <isr_0xb4>:
ISR(0xb4);	ISR(0xb5);	ISR(0xb6);	ISR(0xb7);
 7e5:	6a 00                	push   $0x0
 7e7:	68 b4 00 00 00       	push   $0xb4
 7ec:	e9 0f f8 ff ff       	jmp    0 <isr_save>

000007f1 <isr_0xb5>:
 7f1:	6a 00                	push   $0x0
 7f3:	68 b5 00 00 00       	push   $0xb5
 7f8:	e9 03 f8 ff ff       	jmp    0 <isr_save>

000007fd <isr_0xb6>:
 7fd:	6a 00                	push   $0x0
 7ff:	68 b6 00 00 00       	push   $0xb6
 804:	e9 f7 f7 ff ff       	jmp    0 <isr_save>

00000809 <isr_0xb7>:
 809:	6a 00                	push   $0x0
 80b:	68 b7 00 00 00       	push   $0xb7
 810:	e9 eb f7 ff ff       	jmp    0 <isr_save>

00000815 <isr_0xb8>:
ISR(0xb8);	ISR(0xb9);	ISR(0xba);	ISR(0xbb);
 815:	6a 00                	push   $0x0
 817:	68 b8 00 00 00       	push   $0xb8
 81c:	e9 df f7 ff ff       	jmp    0 <isr_save>

00000821 <isr_0xb9>:
 821:	6a 00                	push   $0x0
 823:	68 b9 00 00 00       	push   $0xb9
 828:	e9 d3 f7 ff ff       	jmp    0 <isr_save>

0000082d <isr_0xba>:
 82d:	6a 00                	push   $0x0
 82f:	68 ba 00 00 00       	push   $0xba
 834:	e9 c7 f7 ff ff       	jmp    0 <isr_save>

00000839 <isr_0xbb>:
 839:	6a 00                	push   $0x0
 83b:	68 bb 00 00 00       	push   $0xbb
 840:	e9 bb f7 ff ff       	jmp    0 <isr_save>

00000845 <isr_0xbc>:
ISR(0xbc);	ISR(0xbd);	ISR(0xbe);	ISR(0xbf);
 845:	6a 00                	push   $0x0
 847:	68 bc 00 00 00       	push   $0xbc
 84c:	e9 af f7 ff ff       	jmp    0 <isr_save>

00000851 <isr_0xbd>:
 851:	6a 00                	push   $0x0
 853:	68 bd 00 00 00       	push   $0xbd
 858:	e9 a3 f7 ff ff       	jmp    0 <isr_save>

0000085d <isr_0xbe>:
 85d:	6a 00                	push   $0x0
 85f:	68 be 00 00 00       	push   $0xbe
 864:	e9 97 f7 ff ff       	jmp    0 <isr_save>

00000869 <isr_0xbf>:
 869:	6a 00                	push   $0x0
 86b:	68 bf 00 00 00       	push   $0xbf
 870:	e9 8b f7 ff ff       	jmp    0 <isr_save>

00000875 <isr_0xc0>:
ISR(0xc0);	ISR(0xc1);	ISR(0xc2);	ISR(0xc3);
 875:	6a 00                	push   $0x0
 877:	68 c0 00 00 00       	push   $0xc0
 87c:	e9 7f f7 ff ff       	jmp    0 <isr_save>

00000881 <isr_0xc1>:
 881:	6a 00                	push   $0x0
 883:	68 c1 00 00 00       	push   $0xc1
 888:	e9 73 f7 ff ff       	jmp    0 <isr_save>

0000088d <isr_0xc2>:
 88d:	6a 00                	push   $0x0
 88f:	68 c2 00 00 00       	push   $0xc2
 894:	e9 67 f7 ff ff       	jmp    0 <isr_save>

00000899 <isr_0xc3>:
 899:	6a 00                	push   $0x0
 89b:	68 c3 00 00 00       	push   $0xc3
 8a0:	e9 5b f7 ff ff       	jmp    0 <isr_save>

000008a5 <isr_0xc4>:
ISR(0xc4);	ISR(0xc5);	ISR(0xc6);	ISR(0xc7);
 8a5:	6a 00                	push   $0x0
 8a7:	68 c4 00 00 00       	push   $0xc4
 8ac:	e9 4f f7 ff ff       	jmp    0 <isr_save>

000008b1 <isr_0xc5>:
 8b1:	6a 00                	push   $0x0
 8b3:	68 c5 00 00 00       	push   $0xc5
 8b8:	e9 43 f7 ff ff       	jmp    0 <isr_save>

000008bd <isr_0xc6>:
 8bd:	6a 00                	push   $0x0
 8bf:	68 c6 00 00 00       	push   $0xc6
 8c4:	e9 37 f7 ff ff       	jmp    0 <isr_save>

000008c9 <isr_0xc7>:
 8c9:	6a 00                	push   $0x0
 8cb:	68 c7 00 00 00       	push   $0xc7
 8d0:	e9 2b f7 ff ff       	jmp    0 <isr_save>

000008d5 <isr_0xc8>:
ISR(0xc8);	ISR(0xc9);	ISR(0xca);	ISR(0xcb);
 8d5:	6a 00                	push   $0x0
 8d7:	68 c8 00 00 00       	push   $0xc8
 8dc:	e9 1f f7 ff ff       	jmp    0 <isr_save>

000008e1 <isr_0xc9>:
 8e1:	6a 00                	push   $0x0
 8e3:	68 c9 00 00 00       	push   $0xc9
 8e8:	e9 13 f7 ff ff       	jmp    0 <isr_save>

000008ed <isr_0xca>:
 8ed:	6a 00                	push   $0x0
 8ef:	68 ca 00 00 00       	push   $0xca
 8f4:	e9 07 f7 ff ff       	jmp    0 <isr_save>

000008f9 <isr_0xcb>:
 8f9:	6a 00                	push   $0x0
 8fb:	68 cb 00 00 00       	push   $0xcb
 900:	e9 fb f6 ff ff       	jmp    0 <isr_save>

00000905 <isr_0xcc>:
ISR(0xcc);	ISR(0xcd);	ISR(0xce);	ISR(0xcf);
 905:	6a 00                	push   $0x0
 907:	68 cc 00 00 00       	push   $0xcc
 90c:	e9 ef f6 ff ff       	jmp    0 <isr_save>

00000911 <isr_0xcd>:
 911:	6a 00                	push   $0x0
 913:	68 cd 00 00 00       	push   $0xcd
 918:	e9 e3 f6 ff ff       	jmp    0 <isr_save>

0000091d <isr_0xce>:
 91d:	6a 00                	push   $0x0
 91f:	68 ce 00 00 00       	push   $0xce
 924:	e9 d7 f6 ff ff       	jmp    0 <isr_save>

00000929 <isr_0xcf>:
 929:	6a 00                	push   $0x0
 92b:	68 cf 00 00 00       	push   $0xcf
 930:	e9 cb f6 ff ff       	jmp    0 <isr_save>

00000935 <isr_0xd0>:
ISR(0xd0);	ISR(0xd1);	ISR(0xd2);	ISR(0xd3);
 935:	6a 00                	push   $0x0
 937:	68 d0 00 00 00       	push   $0xd0
 93c:	e9 bf f6 ff ff       	jmp    0 <isr_save>

00000941 <isr_0xd1>:
 941:	6a 00                	push   $0x0
 943:	68 d1 00 00 00       	push   $0xd1
 948:	e9 b3 f6 ff ff       	jmp    0 <isr_save>

0000094d <isr_0xd2>:
 94d:	6a 00                	push   $0x0
 94f:	68 d2 00 00 00       	push   $0xd2
 954:	e9 a7 f6 ff ff       	jmp    0 <isr_save>

00000959 <isr_0xd3>:
 959:	6a 00                	push   $0x0
 95b:	68 d3 00 00 00       	push   $0xd3
 960:	e9 9b f6 ff ff       	jmp    0 <isr_save>

00000965 <isr_0xd4>:
ISR(0xd4);	ISR(0xd5);	ISR(0xd6);	ISR(0xd7);
 965:	6a 00                	push   $0x0
 967:	68 d4 00 00 00       	push   $0xd4
 96c:	e9 8f f6 ff ff       	jmp    0 <isr_save>

00000971 <isr_0xd5>:
 971:	6a 00                	push   $0x0
 973:	68 d5 00 00 00       	push   $0xd5
 978:	e9 83 f6 ff ff       	jmp    0 <isr_save>

0000097d <isr_0xd6>:
 97d:	6a 00                	push   $0x0
 97f:	68 d6 00 00 00       	push   $0xd6
 984:	e9 77 f6 ff ff       	jmp    0 <isr_save>

00000989 <isr_0xd7>:
 989:	6a 00                	push   $0x0
 98b:	68 d7 00 00 00       	push   $0xd7
 990:	e9 6b f6 ff ff       	jmp    0 <isr_save>

00000995 <isr_0xd8>:
ISR(0xd8);	ISR(0xd9);	ISR(0xda);	ISR(0xdb);
 995:	6a 00                	push   $0x0
 997:	68 d8 00 00 00       	push   $0xd8
 99c:	e9 5f f6 ff ff       	jmp    0 <isr_save>

000009a1 <isr_0xd9>:
 9a1:	6a 00                	push   $0x0
 9a3:	68 d9 00 00 00       	push   $0xd9
 9a8:	e9 53 f6 ff ff       	jmp    0 <isr_save>

000009ad <isr_0xda>:
 9ad:	6a 00                	push   $0x0
 9af:	68 da 00 00 00       	push   $0xda
 9b4:	e9 47 f6 ff ff       	jmp    0 <isr_save>

000009b9 <isr_0xdb>:
 9b9:	6a 00                	push   $0x0
 9bb:	68 db 00 00 00       	push   $0xdb
 9c0:	e9 3b f6 ff ff       	jmp    0 <isr_save>

000009c5 <isr_0xdc>:
ISR(0xdc);	ISR(0xdd);	ISR(0xde);	ISR(0xdf);
 9c5:	6a 00                	push   $0x0
 9c7:	68 dc 00 00 00       	push   $0xdc
 9cc:	e9 2f f6 ff ff       	jmp    0 <isr_save>

000009d1 <isr_0xdd>:
 9d1:	6a 00                	push   $0x0
 9d3:	68 dd 00 00 00       	push   $0xdd
 9d8:	e9 23 f6 ff ff       	jmp    0 <isr_save>

000009dd <isr_0xde>:
 9dd:	6a 00                	push   $0x0
 9df:	68 de 00 00 00       	push   $0xde
 9e4:	e9 17 f6 ff ff       	jmp    0 <isr_save>

000009e9 <isr_0xdf>:
 9e9:	6a 00                	push   $0x0
 9eb:	68 df 00 00 00       	push   $0xdf
 9f0:	e9 0b f6 ff ff       	jmp    0 <isr_save>

000009f5 <isr_0xe0>:
ISR(0xe0);	ISR(0xe1);	ISR(0xe2);	ISR(0xe3);
 9f5:	6a 00                	push   $0x0
 9f7:	68 e0 00 00 00       	push   $0xe0
 9fc:	e9 ff f5 ff ff       	jmp    0 <isr_save>

00000a01 <isr_0xe1>:
 a01:	6a 00                	push   $0x0
 a03:	68 e1 00 00 00       	push   $0xe1
 a08:	e9 f3 f5 ff ff       	jmp    0 <isr_save>

00000a0d <isr_0xe2>:
 a0d:	6a 00                	push   $0x0
 a0f:	68 e2 00 00 00       	push   $0xe2
 a14:	e9 e7 f5 ff ff       	jmp    0 <isr_save>

00000a19 <isr_0xe3>:
 a19:	6a 00                	push   $0x0
 a1b:	68 e3 00 00 00       	push   $0xe3
 a20:	e9 db f5 ff ff       	jmp    0 <isr_save>

00000a25 <isr_0xe4>:
ISR(0xe4);	ISR(0xe5);	ISR(0xe6);	ISR(0xe7);
 a25:	6a 00                	push   $0x0
 a27:	68 e4 00 00 00       	push   $0xe4
 a2c:	e9 cf f5 ff ff       	jmp    0 <isr_save>

00000a31 <isr_0xe5>:
 a31:	6a 00                	push   $0x0
 a33:	68 e5 00 00 00       	push   $0xe5
 a38:	e9 c3 f5 ff ff       	jmp    0 <isr_save>

00000a3d <isr_0xe6>:
 a3d:	6a 00                	push   $0x0
 a3f:	68 e6 00 00 00       	push   $0xe6
 a44:	e9 b7 f5 ff ff       	jmp    0 <isr_save>

00000a49 <isr_0xe7>:
 a49:	6a 00                	push   $0x0
 a4b:	68 e7 00 00 00       	push   $0xe7
 a50:	e9 ab f5 ff ff       	jmp    0 <isr_save>

00000a55 <isr_0xe8>:
ISR(0xe8);	ISR(0xe9);	ISR(0xea);	ISR(0xeb);
 a55:	6a 00                	push   $0x0
 a57:	68 e8 00 00 00       	push   $0xe8
 a5c:	e9 9f f5 ff ff       	jmp    0 <isr_save>

00000a61 <isr_0xe9>:
 a61:	6a 00                	push   $0x0
 a63:	68 e9 00 00 00       	push   $0xe9
 a68:	e9 93 f5 ff ff       	jmp    0 <isr_save>

00000a6d <isr_0xea>:
 a6d:	6a 00                	push   $0x0
 a6f:	68 ea 00 00 00       	push   $0xea
 a74:	e9 87 f5 ff ff       	jmp    0 <isr_save>

00000a79 <isr_0xeb>:
 a79:	6a 00                	push   $0x0
 a7b:	68 eb 00 00 00       	push   $0xeb
 a80:	e9 7b f5 ff ff       	jmp    0 <isr_save>

00000a85 <isr_0xec>:
ISR(0xec);	ISR(0xed);	ISR(0xee);	ISR(0xef);
 a85:	6a 00                	push   $0x0
 a87:	68 ec 00 00 00       	push   $0xec
 a8c:	e9 6f f5 ff ff       	jmp    0 <isr_save>

00000a91 <isr_0xed>:
 a91:	6a 00                	push   $0x0
 a93:	68 ed 00 00 00       	push   $0xed
 a98:	e9 63 f5 ff ff       	jmp    0 <isr_save>

00000a9d <isr_0xee>:
 a9d:	6a 00                	push   $0x0
 a9f:	68 ee 00 00 00       	push   $0xee
 aa4:	e9 57 f5 ff ff       	jmp    0 <isr_save>

00000aa9 <isr_0xef>:
 aa9:	6a 00                	push   $0x0
 aab:	68 ef 00 00 00       	push   $0xef
 ab0:	e9 4b f5 ff ff       	jmp    0 <isr_save>

00000ab5 <isr_0xf0>:
ISR(0xf0);	ISR(0xf1);	ISR(0xf2);	ISR(0xf3);
 ab5:	6a 00                	push   $0x0
 ab7:	68 f0 00 00 00       	push   $0xf0
 abc:	e9 3f f5 ff ff       	jmp    0 <isr_save>

00000ac1 <isr_0xf1>:
 ac1:	6a 00                	push   $0x0
 ac3:	68 f1 00 00 00       	push   $0xf1
 ac8:	e9 33 f5 ff ff       	jmp    0 <isr_save>

00000acd <isr_0xf2>:
 acd:	6a 00                	push   $0x0
 acf:	68 f2 00 00 00       	push   $0xf2
 ad4:	e9 27 f5 ff ff       	jmp    0 <isr_save>

00000ad9 <isr_0xf3>:
 ad9:	6a 00                	push   $0x0
 adb:	68 f3 00 00 00       	push   $0xf3
 ae0:	e9 1b f5 ff ff       	jmp    0 <isr_save>

00000ae5 <isr_0xf4>:
ISR(0xf4);	ISR(0xf5);	ISR(0xf6);	ISR(0xf7);
 ae5:	6a 00                	push   $0x0
 ae7:	68 f4 00 00 00       	push   $0xf4
 aec:	e9 0f f5 ff ff       	jmp    0 <isr_save>

00000af1 <isr_0xf5>:
 af1:	6a 00                	push   $0x0
 af3:	68 f5 00 00 00       	push   $0xf5
 af8:	e9 03 f5 ff ff       	jmp    0 <isr_save>

00000afd <isr_0xf6>:
 afd:	6a 00                	push   $0x0
 aff:	68 f6 00 00 00       	push   $0xf6
 b04:	e9 f7 f4 ff ff       	jmp    0 <isr_save>

00000b09 <isr_0xf7>:
 b09:	6a 00                	push   $0x0
 b0b:	68 f7 00 00 00       	push   $0xf7
 b10:	e9 eb f4 ff ff       	jmp    0 <isr_save>

00000b15 <isr_0xf8>:
ISR(0xf8);	ISR(0xf9);	ISR(0xfa);	ISR(0xfb);
 b15:	6a 00                	push   $0x0
 b17:	68 f8 00 00 00       	push   $0xf8
 b1c:	e9 df f4 ff ff       	jmp    0 <isr_save>

00000b21 <isr_0xf9>:
 b21:	6a 00                	push   $0x0
 b23:	68 f9 00 00 00       	push   $0xf9
 b28:	e9 d3 f4 ff ff       	jmp    0 <isr_save>

00000b2d <isr_0xfa>:
 b2d:	6a 00                	push   $0x0
 b2f:	68 fa 00 00 00       	push   $0xfa
 b34:	e9 c7 f4 ff ff       	jmp    0 <isr_save>

00000b39 <isr_0xfb>:
 b39:	6a 00                	push   $0x0
 b3b:	68 fb 00 00 00       	push   $0xfb
 b40:	e9 bb f4 ff ff       	jmp    0 <isr_save>

00000b45 <isr_0xfc>:
ISR(0xfc);	ISR(0xfd);	ISR(0xfe);	ISR(0xff);
 b45:	6a 00                	push   $0x0
 b47:	68 fc 00 00 00       	push   $0xfc
 b4c:	e9 af f4 ff ff       	jmp    0 <isr_save>

00000b51 <isr_0xfd>:
 b51:	6a 00                	push   $0x0
 b53:	68 fd 00 00 00       	push   $0xfd
 b58:	e9 a3 f4 ff ff       	jmp    0 <isr_save>

00000b5d <isr_0xfe>:
 b5d:	6a 00                	push   $0x0
 b5f:	68 fe 00 00 00       	push   $0xfe
 b64:	e9 97 f4 ff ff       	jmp    0 <isr_save>

00000b69 <isr_0xff>:
 b69:	6a 00                	push   $0x0
 b6b:	68 ff 00 00 00       	push   $0xff
 b70:	e9 8b f4 ff ff       	jmp    0 <isr_save>
