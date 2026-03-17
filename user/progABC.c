#ifndef PROGABC_INC_C_
#define PROGABC_INC_C_
#include <common.h>

/**
** User function main #1:  exit, write
**
** Prints its ID, then loops N times delaying and printing, then exits.
** Verifies the return byte count from each call to write().
**
** Invoked as:  progX  x  n
**	 where X varies depending on which "user program" this is (A, B, C)
**	       x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
	int count = 30; // default iteration count
	char ch = '1';	// default character to print
	char buf[128];	// local char buffer

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progABC" );

	switch( argc ) {
	case 3:	count = str2int( argv[2], 10 );
			// FALL THROUGH
	case 2:	ch = argv[1][0];
			break;
	default:
			sprint( buf, "%s: argc %d, args: ", argv[0], argc );
			cwrites( buf );
			for( int i = 1; i <= argc; ++i ) {
				sprint( buf, " %s", argv[i] ? argv[i] : "(null)" );
				cwrites( buf );
			}
			cwrites( "\n" );
	}

	// announce our presence
	int n = swritech( ch );
	if( n != 1 ) {
		sprint( buf, "== %c, write #1 returned %d\n", ch, n );
		cwrites( buf );
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
		DELAY(STD);
		n = swritech( ch );
		if( n != 1 ) {
			sprint( buf, "== %c, write #2 returned %d\n", ch, n );
			cwrites( buf );
		}
	}

	// all done - exit status is 50, 51, or 52
	exit( 50 + (ch - 'A') );

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
	msg[1] = ch;
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
	if( n != 3 ) {
		sprint( buf, "User %c, write #3 returned %d\n", ch, n );
		cwrites( buf );
	}

	// this should really get us out of here
	return( 99 );
}
#endif
