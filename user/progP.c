#ifndef PROGP_INC_C_
#define PROGP_INC_C_
#include "common.h"

/**
** User function P:   exit, sleep, write, gettime
**
** Reports itself, then loops reporting itself
**
** Invoked as:  progP  x  [ n  [ t ] ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
	int count = 3;	  // default iteration count
	char ch = 'p';	  // default character to print
	int nap = 2;	  // nap time
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progP" );
	switch( argc ) {
	case 4:	nap = str2int( argv[3], 10 );
			// FALL THROUGH
	case 3:	count = str2int( argv[2], 10 );
			// FALL THROUGH
	case 2:	ch = argv[1][0];
			break;
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
			cwrites( buf );
			for( int i = 0; i <= argc; ++i ) {
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
				cwrites( buf );
			}
			cwrites( "\n" );
	}

	// announce our presence
	time_t now = gettime();
	sprint( buf, " P@%u", now );
	swrites( buf );

	for( int i = 0; i < count; ++i ) {
		sleep( SEC_TO_MS(nap) );
		write( CHAN_SIO, &ch, 1 );
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
