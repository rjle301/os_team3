#ifndef PROGI_INC_C_
#define PROGI_INC_C_
#include <common.h>

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

/**
** User function I:  exit, fork, exec, sleep, wait, write
**
** Reports, then loops spawing progW, sleeps, then
** loops checking the status of all its children
**
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
	int count = 5;	  // default child count
	char ch = 'i';	  // default character to print
	int nap = 5;	  // nap time
	char buf[128];
	char ch2[] = "*?*";
	pid_t children[MAX_CHILDREN];
	int nkids = 0;

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progI" );
	switch( argc ) {
	case 3:	count = str2int( argv[2], 10 );
			// FALL THROUGH
	case 2:	ch = argv[1][0];
			break;
	case 1:	// just use the defaults
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

	// secondary output (for indicating errors)
	ch2[1] = ch;

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	// set up the argument vector
	// we run:	progW 10 5

	char *argw = "progW\rW\r10\r5";

	for( int i = 0; i < count; ++i ) {
		pid_t whom = spawn( (uint32_t) progW, argw );
		if( whom < 0 ) {
			swrites( ch2 );
		} else {
			swritech( ch );
			children[nkids++] = whom;
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );

	// collect child information
	while( 1 ) {
		pid_t n = wait( NULL );
		if( n == S_NO_CHILD ) {
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
			if( children[i] == n ) {
				sprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
				cwrites( buf );
			}
		}
		sleep( SEC_TO_MS(nap) );
	};

	// let init() clean up after us!

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
