#ifndef PROGW_INC_C_
#define PROGW_INC_C_
#include <common.h>

/**
** User function W:   exit, sleep, write, getpid, gettime
**
** Reports its presence, then iterates 'n' times printing identifying
** information and sleeping, before exiting.
**
** Invoked as:  progW  x  [ n  [ s ] ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
	int count = 20;	  // default iteration count
	char ch = 'w';	  // default character to print
	int nap = 3;	  // nap length
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progW" );
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
	pid_t pid = getpid();
	time_t now = gettime();
	sprint( buf, " %c[%d,%u]", ch, pid, now );
	swrites( buf );

	write( CHAN_SIO, &ch, 1 );

	for( int i = 0; i < count ; ++i ) {
		now = gettime();
		sprint( buf, " %c[%d,%u] ", ch, pid, now );
		swrites( buf );
		sleep( SEC_TO_MS(nap) );
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
