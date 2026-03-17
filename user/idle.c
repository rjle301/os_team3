#ifndef IDLE_INC_C_
#define IDLE_INC_C_
#include <common.h>

/**
** Idle process:  write, getpid, gettime, exit
**
** Reports itself, then loops forever delaying and printing a character.
** MUST NOT SLEEP, as it must always be available in the ready queue 
** when there is no other process to dispatch.
**
** If compiled with VERBOSE_IDLE defined, reports itself by printing
** the character '.' periodically on the SIO.
**
** Invoked as:	idle
**
** Compile-time options - define in Make.mk
**
**    VERBOSE_IDLE   Causes 'idle' to print '.' characters periodically
*/

USERMAIN( idle ) {
#ifdef VERBOSE_IDLE
	// this is the character we will repeatedly print
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) args;

	// get some current information
	pid_t pid = getpid();
	time_t now = gettime();
	prio_t prio = getprio( 0 );

	char buf[128];
	sprint( buf, "idle [%d], started @ %u\n", pid, prio, now );
	cwrites( buf );
	
#ifdef VERBOSE_IDLE
	write( CHAN_SIO, &ch, 1 );
#endif

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
#ifdef VERBOSE_IDLE
		write( CHAN_SIO, &ch, 1 );
#endif
	}

	// we should never reach this point!
	now = gettime();
	sprint( buf, "idle [%d] EXITING @ %u!?!?!\n", pid, now );
	cwrites( buf );

	exit( 1 );

	return( 42 );
}
#endif
