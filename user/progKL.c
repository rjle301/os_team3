#ifndef PROGKL_INC_C_
#define PROGKL_INC_C_
#include <common.h>

/**
** User function main #4:  exit, fork, exec, sleep, write
**
** Loops, spawning N copies of progX and sleeping between spawns.
**
** Invoked as:  progX  x  n
**	 where X varies (K, L)
**	       x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
	int count = 5;			// default iteration count
	char ch = '4';			// default character to print
	int nap = 30;			// nap time
	char msg2[] = "*4*";	// "error" message to print
	char buf[32];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progKL" );
	switch( argc ) {
	case 3:	count = str2int( argv[2], 10 );
			// FALL THROUGH
	case 2:	ch = argv[1][0];
			break;
	default:
			sprint( buf, "%s: argc %d, args: ", "progKL", argc );
			cwrites( buf );
			for( int i = 0; i <= argc; ++i ) {
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
				cwrites( buf );
			}
			cwrites( "\n" );
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	for( int i = 0; i < count ; ++i ) {

		write( CHAN_SIO, &ch, 1 );

		// second argument to X is 100 plus the iteration number
		sprint( buf, "progX\rX\r%d", 100 + i );
		pid_t whom = spawn( (uint32_t) progX, buf );
		if( whom < 0 ) {
			swrites( msg2 );
		} else {
			write( CHAN_SIO, &ch, 1 );
		}

		sleep( SEC_TO_MS(nap) );
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
