/**
** @file	kernel.c
**
** @author	CSCI-452 class of 20255
**
** @brief	Kernel support routines
**
** Compile-time options - define in Makefile:
**
**    CONSOLE_STATS   Print various stats when console keys are pressed
**    SLOW_INIT       Add 2-second delays at various places in main()
*/

#define	KERNEL_SRC

#include <common.h>

#include <memory.h>
#include <cio.h>
#include <clock.h>
#include <kmem.h>
#include <procs.h>
#include <stacks.h>
#include <queues.h>
#include <sio.h>
#include <syscalls.h>

/*
** PRIVATE DEFINITIONS
*/

/*
** PRIVATE DATA TYPES
*/

/*
** PRIVATE GLOBAL VARIABLES
*/

/*
** PUBLIC GLOBAL VARIABLES
*/

// character buffers, usable throughout the OS; not guaranteed
// to retain their contents across an exception return
char b256[256];    // primarily used for message creation
char b512[512];    // ditto
char bpanic[512];  // used by PANIC macro

// address of the array in the userblob that contains addresses of user
// code we need to know about (see user/locations.S)
uint32_t *user_locs;

// "user blob" information from the bootstrap
uint16_t user_offset;
uint16_t user_segment;
uint16_t user_sectors;

// Section boundary markers
extern uint8_t _start[];
extern uint8_t _etext[];
extern uint8_t _rodata[];
extern uint8_t _erodata[];
extern uint8_t _data[];
extern uint8_t _edata[];
extern uint8_t __bss_start[];
extern uint8_t _end[];

/*
** PRIVATE FUNCTIONS
*/

/**
** kreport - report the system configuration
**
** Prints configuration information about the OS on the console monitor.
**
** @param dtrace  Decode the TRACE options
*/
static void kreport( bool_t dtrace ) {

	cio_puts( "\n-------------------------------\n" );
	cio_printf( "Config:  N_PROCS = %d", N_PROCS );
	cio_printf( " N_PRIOS = %d", N_PRIOS );
	cio_printf( " N_STATES = %d", N_STATES );
	cio_printf( " CLOCK = %dHz\n", CLOCK_FREQ );

	// This code is ugly, but it's the simplest way to
	// print out the values of compile-time options
	// without spending a lot of execution time at it.

	cio_puts( "Options: "
#ifdef RPT_INT_UNEXP
		" R-uint"
#endif
#ifdef RPT_INT_MYSTERY
		" R-mint"
#endif
#ifdef TRACE_CX
		" CX"
#endif
#ifdef CONSOLE_STATS
		" Cstats"
#endif
		); // end of cio_puts() call

#ifdef DBLV
	cio_printf( " DBLV = %d", DBLV );
#endif

#if TRACE > 0
	cio_printf( " TRACE = 0x%04x\n", TRACE );

	// decode the trace settings if that was requested
	if( TRACING_ANYTHING && dtrace ) {

		// this one is simpler - we rely on string literal
		// concatenation in the C compiler to create one
		// long string to print out

		cio_puts( "Tracing:"
#if TRACING_PCB
			" PCB"
#endif
#if TRACING_QUEUE
			 " QUE"
#endif
#if TRACING_SCHED
			 " SCHED"
#endif
#if TRACING_DISPATCH
			 " DISPATCH"
#endif
#if TRACING_SYSCALLS
			 " SCALL"
#endif
#if TRACING_SYSRETS
			 " SRET"
#endif
#if TRACING_EXIT
			 " EXIT"
#endif
#if TRACING_KMEM
			 " KM"
#endif
#if TRACING_INIT
			 " INIT"
#endif
#if TRACING_SIO_ST
			 " S_ST"
#endif
#if TRACING_SIO_RD
			 " S_RD"
#endif
#if TRACING_SIO_WR
			 " S_WR"
#endif
#if TRACING_STACK
			 " STK"
#endif
			 ); // end of cio_puts() call
	}
#endif  /* TRACE > 0 */

	cio_putchar( '\n' );
}

/*
** PUBLIC FUNCTIONS
*/

/**
** main - system initialization routine
**
** Called by the startup code immediately before returning into the
** first user process.
**
** Typing this as 'int' keeps the compiler happy.
*/
int main( void ) {

	/*
	** Get the location of the user blob; this is gross, but we
	** need to get this information somehow, and the linker is
	** making it difficult to get it any other way. We do this by
	** directly accessing the "user blob" information at the end
	** of the second bootstrap sector. This works ONLY because
	** nothing has touched that section of memory yet.
	*/
	uint16_t *blobdata = (uint16_t *) USER_BLOB_DATA;
	user_offset  = *blobdata++;
	user_segment = *blobdata++;
	user_sectors = *blobdata++;

	/*
	** Initialize interrupt stuff.
	*/

	init_interrupts();  // IDT and PIC initialization

	/*
	** Console I/O system.
	**
	** Does not depend on the other kernel modules, so we can
	** initialize it before we initialize the kernel memory
	** and queue modules.
	*/

	cio_init( NULL );	// no console callback routine

	// cio_clearscreen();  // moved into cio_init()

	// report on the segment boundaries
	cio_printf( "Text: %08x to %08x\n",
			(uint32_t) _start, (uint32_t) _etext );
	cio_printf( "Rdat: %08x to %08x\n",
			(uint32_t) _rodata, (uint32_t) _erodata );
	cio_printf( "Data: %08x to %08x\n",
			(uint32_t) _data, (uint32_t) _edata );
	cio_printf( "BSS:  %08x to %08x\n",
			(uint32_t) __bss_start, (uint32_t) _end );

	// the actual memory address of the user blob
	user_locs = (uint32_t *)
		((uint32_t)(user_segment << 4) + (uint32_t) user_offset);

	// report info on the user blob
	cio_printf( "User blob %u sectors @ %04x:%04x (%08x)\n",
			user_sectors, user_segment, user_offset,
			(uint32_t) user_locs );

	/*
	** Initialize various OS modules
	**
	** Other modules (clock, SIO, syscall, etc.) are expected to
	** install their own ISRs in their initialization routines.
	*/

	cio_puts( "System initialization starting.\n" );
	cio_puts( "-------------------------------\n" );

#if TRACING_INIT
	cio_puts( "Modules:" );
#endif

#ifdef SLOW_INIT
	delay( DELAY_2_SEC );
#endif

	// call the module initialization functions, being
	// careful to follow any module precedence requirements

	km_init();		// MUST BE FIRST
	que_init();     // MUST BE SECOND

	sio_init();     // serial i/o module

#ifdef SLOW_INIT
	delay( DELAY_2_SEC );
#endif

	// other module initialization calls here
	pcb_init();     // process (PCBs, scheduler)
	stk_init();     // stacks
	clk_init();     // clock
	sys_init();     // system call

	// once they're all set up, begin echoing CIO to SIO

	(void) cio_opt_set( CIO_OPT_DUP );

	cio_puts( "\nModule initialization complete.\n" );

	// report our configuration options
	kreport( true );
	cio_puts( "-------------------------------\n" );

#ifdef SLOW_INIT
	delay( DELAY_2_SEC );
#endif

	/*
	** Other tasks typically performed here:
	**
	**	Enabling any I/O devices (e.g., SIO xmit/rcv)
	*/

	/*
	** Create the initial user process
	** 
	** This code is largely stolen from the fork() and exec()
	** implementations in syscalls.c; if those change, this must
	** also change.
	*/

	cio_puts( "Creating initial user process..." );

	// if we can't get a PCB, there's no use continuing!
	assert( pcb_alloc(&init_pcb) == E_SUCCESS );

	// fill in the necessary details
	init_pcb->pid = PID_INIT;
	init_pcb->state = STATE_NEW;
	init_pcb->priority = PRIO_HIGH;

	// command-line for 'init': "init +"
	const char *args = "init\r+";

	// allocate a stack
	uint32_t *stk;
	assert( stk_alloc(&stk) == E_SUCCESS );

	init_pcb->stack = stk;

	// initialize the stack and the context to be restored
	//
	// user_locs is a pointer to the entry point location array
	// at the beginning of the code blob
	init_pcb->context = stk_setup( stk, user_locs[ULOC_INIT], args );
	assert( init_pcb->context != NULL );

	// "i'm my own grandpa...."
	init_pcb->parent = init_pcb;

	// send it on its merry way
	schedule( init_pcb );

	// and let it start to execute
	dispatch();

	cio_puts( " done.\n" );

#ifdef SLOW_INIT
	delay( DELAY_1_SEC );
#endif

#ifdef TRACE_CX

	// wipe out whatever is on the screen at the moment
	cio_clearscreen();

	// define a scrolling region in the top 7 lines of the screen
	cio_setscroll( 0, 7, 99, 99 );

	// clear it
	cio_clearscroll();

	// clear the top line
	cio_puts_at( 0, 0, "*                                                                               " );
	// separator
	cio_puts_at( 0, 6, "================================================================================" );
#endif

	/*
	** END OF TERM-SPECIFIC CODE
	*/

	sio_flush( SIO_RX | SIO_TX );
	sio_enable( SIO_RX );

	cio_puts( "System initialization complete.\n" );
	cio_puts( "-------------------------------\n" );

	return 0;
}
