#ifndef PROGTUV_INC_C_
#define PROGTUV_INC_C_
#include <common.h>

/**
** User function main #6:  exit, fork, exec, wait, sleep, write
**
** Reports, then loops spawing progW, sleeps, then waits for
** all its children.
**
** Invoked as:  progX  x  c
**	 where X varies (T, U, V)
**	       x is the ID character
**		   c is the child count
*/

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
	int count = 3;			// default child count
	char ch = '6';			// default character to print
	int nap = 8;			// nap time
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
	char ch2[] = "*?*";

	// process the command-line arguments
	ARG_PROC( 3, args, 5, argc, "progTUV" );
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

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	// set up the argument vector
	char *argw = "progW\rW\r10\r5";

	for( int i = 0; i < count; ++i ) {
		int whom = spawn( (uint32_t) progW, argw );
		if( whom < 0 ) {
			swrites( ch2 );
		} else {
			children[nkids++] = whom;
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );

	// collect exit status information

	// current child index
	int n = 0;

	do {
		pid_t this;
		int32_t status;

		status = 0xcafe;
		this = wait( &status );

		// what was the result?
		if( this < 1 ) {

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != S_NO_CHILD ) {
				sprint( buf, "!! %c: wait() ret %d status %d (%x)\n",
						ch, this, status, (uint32_t) status );
			} else {
				sprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;

		} else {

			// locate the child
			int ix = -1;

			int i;
			for( i = 0; i < nkids; ++i ) {
				if( children[i] == this ) {
					ix = i;
					break;
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {

				// didn't find an entry for this PID???
				sprint( buf, "!! %c: child PID %d status %d, NOT FOUND\n",
						ch, this, status );

			} else {

				// found this PID in our list of children
				sprint( buf, "== %c: child %d (%d) status %d\n",
						ch, ix, this, status );
			}

		}

		cwrites( buf );

		++n;

	} while( n < nkids );

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
