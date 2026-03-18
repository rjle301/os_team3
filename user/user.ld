/*
** Simple linker script for user-level programs.
*/

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* Link the user code at this address. Must match the */
	/* USER_ADDR defined in memory.h! */
	. = 0x00030000;

	.text : {
		KEEP(*(.text .stub .text.* .gnu.linkonce.t.*))
	}

	/* define some standard symbols */
	PROVIDE(_etext = .);

	/* Page-align the read-only data segment */
	. = ALIGN(0x1000);

	PROVIDE( _rodata = .);

	/* read-only data will go at the end of the text section */
	.rodata : {
		KEEP(*(.rodata .rodata.* .gnu.linkonce.r.*))
	}

	PROVIDE( _erodata = .);

	/* Page-align the data segment */
	. = ALIGN(0x1000);

	.data : {
		KEEP(*(.data))
	}

	PROVIDE(_edata = .);

	/* Page-align the BSS segment */
	. = ALIGN(0x1000);

	PROVIDE(__bss_start = .);

	.bss : {
		KEEP(*(.bss))
	}

	PROVIDE(_end = .);

	/DISCARD/ : {
		*(.stab .stab_info .stabstr .eh_frame .note.GNU-stack .note.gnu.property .comment)
	}
}
