/**
** @file    memory.h
**
** @author  K. Reek
** @author  Warren R. Carithers, Garrett C. Smith
**
** @brief   Constants and addresses related to the boot program.
**
** Based on   SCCS ID:	@(#)bootstrap.h	2.4	1/22/25
*/

#ifndef MEMORY_H_
#define MEMORY_H_

/***************************
** Section 1:  THE BOOTSTRAP
***************************/

// boot device information
#define BDEV_FLOPPY     0x00
#define BDEV_USB        0x80         // hard drive

#define BDEV            BDEV_USB     // default

// bootstrap addresses, sizes, etc.
#define BOOT_SEG        0x07c0       // 07c0:0000
#define BOOT_DISP       0x0000
#define BOOT_ADDR       ((BOOT_SEG << 4) + BOOT_DISP)

#define PART2_DISP      0x0200       // 07c0:0200
#define PART2_ADDR      ((BOOT_SEG << 4) + PART2_DISP)

#define SECTOR_SIZE     0x200        // 512 bytes

// Note: this assumes the bootstrap is two sectors long!
#define BOOT_SIZE       (SECTOR_SIZE + SECTOR_SIZE)

#define OFFSET_LIMIT    (0x10000 - SECTOR_SIZE)

#define BOOT_SP_DISP    0x4000       // stack pointer 07c0:4000, or 0xbc00
#define BOOT_SP_ADDR    ((BOOT_SEG << 4) + BOOT_SP_DISP)

#define SECTOR1_END     (BOOT_ADDR + SECTOR_SIZE)
#define SECTOR2_END     (BOOT_ADDR + BOOT_SIZE)

/********************
** Section 2:  THE OS
********************/

// os addresses, etc.
#define SYSTEM_SEG      0x00001000   // 1000:0000
#define SYSTEM_ADDR     0x00010000   // and upward
#define SYSTEM_STACK    0x00010000   // and downward

/*
** The Global Descriptor Table (0000:0500 - 0000:2500)
*/
#define GDT_SEG         0x00000050
#define GDT_ADDR        0x00000500

	// segment register values
#define GDT_LINEAR      0x0008       // All of memory, R/W
#define GDT_CODE        0x0010       // All of memory, R/E
#define GDT_DATA        0x0018       // All of memory, R/W
#define GDT_STACK       0x0020       // All of memory, R/W

/*
** The Interrupt Descriptor Table (0000:2500 - 0000:2D00)
*/
#define IDT_SEG         0x00000250
#define IDT_ADDR        0x00002500

#ifdef ASM_SRC

/*
** Segment descriptor macros for use in assembly source files.
** Layout:
**     .word    lower 16 bits of limit
**     .word    lower 16 bits of base
**     .byte    middle 8 bits of base
**     .byte    type byte
**     .byte    granularity byte
**     .byte    upper 8 bits of base
** We use 4K units, so we ignore the lower 12 bits of the limit
*/
#define SEGNULL       \
	.word 0, 0, 0, 0

#define SEGMENT(base,limit,dpl,type) \
	.word (((limit) >> 12) & 0xffff); \
	.word ((base) & 0xffff) ; \
	.byte (((base) >> 16) & 0xff) ; \
	.byte (SEG_PRESENT | (dpl) | SEG_NON_SYSTEM | (type)) ; \
	.byte (SEG_GRAN_4KBYTE | SEG_DB_32BIT | (((limit) >> 28) & 0xf)) ; \
	.byte (((base) >> 24) & 0xff)

#endif  /* ASM_SRC */

/***************************
** Section 3:  THE USER BLOB
***************************/

// user blob addresses, etc
#define USER_SEG      0x00003000   // 3000:0000
#define USER_ADDR     0x00030000   // and upward

// location of the user blob data within the bootstrap
// (three halfwords of data)
#define USER_BLOB_DATA  (SECTOR2_END - 12)

#endif
