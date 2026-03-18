#ifndef PROGMN_INC_C_
#define PROGMN_INC_C_
#include <common.h>

/**
** User function main #5:  exit, fork, exec, write
**
** Iterates spawning copies of progW (and possibly progZ), reporting
** their PIDs as it goes.
**
** Invoked as:  progX  x  n  b
**	 where X varies (M, N)
**	       x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
	int count = 5;	// default iteration count
	char ch = '5';	// default character to print
	int alsoZ = 0;	// also do progZ?
	char msgw[] = "*5w*";
	char msgz[] = "*5z*";
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progMN" );
	switch( argc ) {
	case 4:	alsoZ = argv[3][0] == 't';
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

	// update the extra message strings
	msgw[1] = msgz[1] = ch;

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argw = "progW\rW\r15\r5";

	// Z:  15 iterations
	char *argz = "progZ\rZ\r15";

	for( int i = 0; i < count; ++i ) {
		write( CHAN_SIO, &ch, 1 );
		int whom = spawn( (uint32_t) progW, argw	);
		if( whom < 1 ) {
			swrites( msgw );
		}
		if( alsoZ ) {
			whom = spawn( (uint32_t) progZ, argz );
			if( whom < 1 ) {
				swrites( msgz );
			}
		}
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
