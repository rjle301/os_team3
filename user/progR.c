#ifndef PROGR_INC_C_
#define PROGR_INC_C_
#include <common.h>

/**
** User function R:   exit, sleep, write, fork, getpid
**
** Reports itself and its sequence number, along with its PID and
** its parent's PID. It then delays, forks, delays, reports again,
** and exits.
**
** Invoked as:  progR  x  n  [ s ]
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
	char ch = 'r';	// default character to print
	int delay = 10;	// initial delay count
	int seq = 99;	// my sequence number
	char buf[128];

	// process the command-line arguments
	ARG_PROC( 4, args, 5, argc, "progR" );
	switch( argc ) {
	case 4:	delay = str2int( argv[3], 10 );
			// FALL THROUGH
	case 3:	seq = str2int( argv[2], 10 );
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

	/*
	** C oddity: a label cannot immediately precede a declaration.
	**
	** Declarations are not considered "statements" in C. Prior to
	** C99, all declarations had to precede any statements inside a
	** block. Labels can only appear before statements.  C99 allowed
	** the mixing of declarations and statements, but did not relax
	** the requirement that labels precede only statements.
	**
	** That's why the declarations of these variables occur before the
	** label, but their initializations occur after the label.
	**
	** As the PSA says on TV, "The more you know..." :-)
	*/

	pid_t pid;

 restart:

	// announce our presence
	pid = getpid();

	sprint( buf, " %c[%d,%d]", ch, seq, pid );
	swrites( buf );

	sleep( SEC_TO_MS(delay) );

	// create the next child in sequence
	if( seq < 5 ) {
		++seq;
		pid_t n = fork( PRIO_INHERIT );
		switch( n ) {
		case -1:
			// failure?
			sprint( buf, "** R[%d] fork code %d\n", pid, n );
			cwrites( buf );
			break;
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
			sleep( SEC_TO_MS(delay) );
		}
	}

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
	sprint( buf, " %c[%d,%d]", ch, seq, pid );
	swrites( buf );

	exit( 0 );

	return( 42 );  // shut the compiler up!

}
#endif
