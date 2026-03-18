#ifndef PROGDE_INC_C_
#define PROGDE_INC_C_
#include <common.h>

/**
** User function main #2:  write
**
** Prints its ID, then loops N times delaying and printing, then returns
** without calling exit(). Verifies the return byte count from each call
** to write().
**
** Invoked as:  progX  x  n
**	 where X varies depending on which "user program" this is (D, E)
**	       x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
	int n;
	int count = 30;	  // default iteration count
	char ch = '2';	  // default character to print
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progDE" );
	switch( argc ) {
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
	n = swritech( ch );
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

	// all done! return status 60 or 61
	return( 60 + (ch - 'D') );
}
#endif
