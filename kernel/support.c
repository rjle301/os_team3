/**
** @file    support.c
**
** @author  4003-506 class of 20003
** @author  K. Reek, Warren R. Carithers
**
** Based on   SCCS ID:	@(#)support.c	2.6	1/22/25
**
** Miscellaneous system initialization functions, interrupt
** support routines, and data structures.
**
** Compile-time options - define in Makefile:
**
**    RPT_INT_UNEXP     Report unexp/default/mystery interrupts
**    RPT_INT_MYSTERY   Report only mystery interrupts
**    CATCH_OP_FAULTS   Register a handler for Illegal Opcode faults (0x06)
**    CATCH_GP_FAULTS   Register a handler for GP faults (0x0d)
**
** "Mystery" interrupts are sometimes referred to as "spurious level 7"
** interrupts.
**
** "Unexpected" interrupts are those we don't expect to handle.
**
** "Default" interrupts are those we aren't currently handling, but
** which we most probably will install a custom handler for.
*/

#include <support.h>
#include <lib.h>
#include <cio.h>
#include <x86/arch.h>
#include <x86/ops.h>
#include <x86/pic.h>
#include <memory.h>

#if defined(CATCH_OP_FAULTS) || defined(CATCH_GP_FAULTS)
#include <procs.h>
#include <queues.h>
#endif

/*
** Global variables and local data types.
*/

/*
** This is the table that contains pointers to the C-language ISR for
** each interrupt.  These functions are called from the isr stub based
** on the interrupt number.
*/
void ( *isr_table[ 256 ] )( int vector, int code );

/*
** Format of an IDT entry.
*/
typedef struct  {
	short   offset_15_0;
	short   segment_selector;
	short   flags;
	short   offset_31_16;
} IDT_Gate;

/*
** LOCAL ROUTINES - not intended to be used outside this module.
*/

/**
** unexpected_handler()
**
** This routine catches interrupts that we do not expect to ever occur.
** It handles them by (optionally) reporting them and then calling panic().
**
** Does not return.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void unexpected_handler( int vector, int code ){
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector 0x%02x, code=%d\n",
		  (unsigned int) vector, code );
#endif
	panic( "Unexpected interrupt" );
}

#ifdef CATCH_OP_FAULTS
static void illop_fault( int vector, int code ){

	cio_printf( "\nILL OP FAULT vec %02x code %d\n",
			(uint32_t) vector, code );

	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
			current->context->cs, current->context->eip );

	pcb_dump( "Current", current, true );

	ctx_dump( "current", current->context );

	panic( "Illegal Opcode fault" );
}
#endif

#ifdef CATCH_GP_FAULTS
static void gp_fault( int vector, int code ){

	cio_printf( "\nGP FAULT vec %02x code %d",
			(uint32_t) vector, code );

	if( code != 0 ) {
		cio_printf( " -> sel/idt number: %08x\n", (uint32_t) code );
	} else {
		cio_putchar( '\n' );
	}

	cio_printf( "ADDRESS: CS %04x EIP %08x\n",
			current->context->cs, current->context->eip );

	pcb_dump( "Current", current, true );

	ctx_dump( "current", current->context );

	panic( "General Protection fault" );
}
#endif

/**
** default_handler()
**
** Default handler for interrupts we expect may occur but are not
** handling (yet).  We just reset the PIC and return.
**
** If an interrupt outside the PIC range (0x20-0x2f) comes in, this
** handler doesn't return - instead, it panics.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void default_handler( int vector, int code ){
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** DEFAULT vector 0x%02x, code=%d\n",
		  (unsigned int) vector, code );
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
		if( vector > 0x27 ){
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
	} else {
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
	}
}

/**
** mystery_handler()
**
** Default handler for the "mystery" interrupt that comes through vector
** 0x27.  This is a non-repeatable interrupt whose source has not been
** identified, but appears to be the (in)famous "spurious level 7 interrupt"
** source.
**
** This handler it like the default handler, but doesn't panic if a
** non-PIC interrupt comes in.
**
** @param[in] vector   vector number for the interrupt that occurred
** @param[in] code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ){
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\n** MYSTERY vector 0x%02x, code=%d\n",
		  (unsigned int) vector, code );
#endif
	// This is most probably from vector 0x27, but we check it
	// anyway just to be sure. 
	if( vector >= 0x20 && vector < 0x30 ) {
		if( vector > 0x27 ){
			// Hmmm. Odd.
			outb( PIC2_CMD, PIC_EOI );
		}
		// This is what we expect.
		outb( PIC1_CMD, PIC_EOI );
	} else {
		// This is very strange. We'll ACK it anyway.
		outb( PIC1_CMD, PIC_EOI );
	}
}

/**
** init_pic()
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ){
	/*
	** ICW1: start the init sequence, update ICW4
	*/
	outb( PIC1_CMD, PIC_CW1_INIT | PIC_CW1_NEED4 );
	outb( PIC2_CMD, PIC_CW1_INIT | PIC_CW1_NEED4 );

	/*
	** ICW2: primary offset of 0x20 in the IDT, secondary offset of 0x28
	*/
	outb( PIC1_DATA, PIC1_CW2_VECBASE );
	outb( PIC2_DATA, PIC2_CW2_VECBASE );

	/*
	** ICW3: secondary attached to line 2 of primary, bit mask is 00000100
	**   secondary id is 2
	*/
	outb( PIC1_DATA, PIC1_CW3_SEC_IRQ2 );
	outb( PIC2_DATA, PIC2_CW3_SEC_ID );

	/*
	** ICW4: want 8086 mode, not 8080/8085 mode
	*/
	outb( PIC1_DATA, PIC_CW4_PM86 );
	outb( PIC2_DATA, PIC_CW4_PM86 );

	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}

/**
** set_idt_entry()
**
** Construct an entry in the IDT
**
** @param[in] entry    the vector number of the interrupt
** @param[in] handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ){
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;

	g->offset_15_0 = (int)handler & 0xffff;
	g->segment_selector = 0x0010;
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
}

/**
** init_idt()
**
** Initialize the Interrupt Descriptor Table (IDT).  This makes each of
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ){
	int i;
	extern  void    ( *isr_stub_table[ 256 ] )( void );

	/*
	** Make each IDT entry point to the stub for that vector.  Also make
	** each entry in the ISR table point to the "unexpected" handler.
	*/
	for ( i=0; i < 256; i++ ){
		set_idt_entry( i, isr_stub_table[ i ] );
		install_isr( i, unexpected_handler );
	}

	// Replace the handlers for interrupts that (will) have a custom handler.
	install_isr( VEC_KBD, default_handler );
	install_isr( VEC_TIMER, default_handler );
	install_isr( VEC_MYSTERY, mystery_handler );

#ifdef CATCH_OP_FAULTS
	install_isr( VEC_INVALID_OPCODE, illop_fault );
#endif
#ifdef CATCH_GP_FAULTS
	install_isr( VEC_GENERAL_PROTECTION, gp_fault );
#endif
}

/*
** END OF LOCAL ROUTINES.
**
** Full documentation for globally-visible routines is in the corresponding
** header file.
*/

/*
** panic()
**
** Called when we find an unrecoverable error. Does not return.
**
** @param[in] reason  An explanation of why we're halting
*/
void panic( char *reason ){
	__asm__( "cli" );
	cio_printf( "\nPANIC: %s\nHalting...", reason );
	for(;;)
		;
}

/*
** init_interrupts()
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ){
	init_idt();
	init_pic();
}

/**
** install_isr()
**
** Installs a second-level handler for a specific interrupt.
**
** @param[in] vector   The IDT entry index
** @param[in] handler  Pointer to the handler to be installed
**
** @return Pointer to the previously-installed handler
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ){

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
	isr_table[ vector ] = handler;
	return old_handler;
}
