/**
** @file	kextras.c
**
** @author	Numerous CSCI-452 classes
**
** @brief	Kernel-specific library functions
*/

#define KERNEL_SRC

#include <common.h>

#include <lib.h>
#include <procs.h>
#include <sio.h>

/**
** Name:    put_char_or_code( ch )
**
** Description: Prints a character on the console, unless it
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {

	if( ch >= ' ' && ch < 0x7f ) {
		cio_putchar( ch );
	} else {
		cio_printf( "\\x%02x", ch );
	}
}

/**
** Name:    backtrace
**
** Perform a stack backtrace
**
** @param[in] ebp   Initial EBP to use
** @param[in] args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {

	cio_puts( "Trace:  " );
	if( ebp == NULL ) {
		cio_puts( "NULL ebp, no trace possible\n" );
		return;
	} else {
		cio_putchar( '\n' );
	}

	while( ebp != NULL ){

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
		}
		cio_putchar( '\n' );

		// follow the chain
		ebp = (uint32_t *) *ebp;
	}
}

/*
** delay - pause for some length of time
**
** Notes:  The parameter to the delay() function is ambiguous; it
** purports to indicate a delay length, but that isn't really tied
** to any real-world time measurement.
**
** On the original systems we used (dual 500MHz Intel P3 CPUs), each
** "unit" was approximately one tenth of a second, so delay(10) would
** delay for about one second.
**
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
**
** @param[in] length   How long (sort of) to delay
*/
void delay( int length ) {

	while( --length >= 0 ) {
		for( int i = 0; i < 10000000; ++i )
			;
	}
}

/**
** kpanic - kernel-level panic routine
**
** usage:  kpanic( msg )
**
** Prefix routine for panic() - can be expanded to do other things
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {

	cio_puts( "\n***** KERNEL PANIC *****\n" );

	if( msg ) {
		cio_printf( "%s\n", msg );
	}

	delay( DELAY_5_SEC );   // approximately

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );

	// dump the basic info about what's in the process table
	ptable_dump_stats( NULL );

	// dump information about the queues
	que_dump( "RH", ready[PRIO_HIGH] );
	que_dump( "RS", ready[PRIO_STD] );
	que_dump( "RL", ready[PRIO_LOW] );
	que_dump( "S", sleeping );
	que_dump( "Z", zombie );
	que_dump( "B", blocked );
	que_dump( "I", sioread );

	cio_puts( "\n\nPanic information:\n" );

	ptable_dump( "Full process table", true );

	ctx_dump_all( "Full context dump" );

	backtrace( (uint32_t *) r_ebp(), 3 );

	__asm__( "cli" );
	cio_printf( "*** HALTING" );
	for(;;) {
		;
	}
}
