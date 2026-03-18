/*
** Simple linker script for the 20255 kernel.
*/

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* Link the kernel at this address. Must match the */
        /* SYSTEM_ADDR defined in memory.h! */
	. = 0x00010000;

	.text : AT(0x10000) {
		*(.text .stub .text.* .gnu.linkonce.t.*)
	}

	/* standard symbols */
	PROVIDE(etext = .);
	PROVIDE(_etext = .);


	/* Align the read-only data segment at next page boundary? */
	. = ALIGN(0x1000);

	PROVIDE(_rodata = .);

	.rodata : {
		*(.rodata .rodata.* .gnu.linkonce.r.*)
	}

	PROVIDE(erodata = .);
	PROVIDE(_erodata = .);

	/* Align the data segment at the next page boundary */
	. = ALIGN(0x1000);

	PROVIDE(data = .);
	PROVIDE(_data = .);

	/* The data segment */
	.data : {
		*(.data .data.* .gnu.linkonce.d.*)
	}

	PROVIDE(edata = .);
	PROVIDE(_edata = .);

	/* page-align the BSS */
	. = ALIGN(0x1000);

	PROVIDE(__bss_start = .);

	.bss : {
		*(.bss .bss.* .gnu.linkonce.b.*)
		*(COMMON)
	}

	PROVIDE(end = .);
	PROVIDE(_end = .);

	/DISCARD/ : {
		*(.stab .stab.* .stabstr)
		*(.eh_frame .eh_frame_hdr)
		/* *(.note.GNU-stack .note.gnu-property .comment) */
		*(.note.* .comment)
	}
}
