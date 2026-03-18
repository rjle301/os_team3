#ifndef USHELL_INC_C_
#define USHELL_INC_C_
#include <common.h>

// should we keep going?
static bool_t time_to_stop = false;

// number of spawned but uncollected children
static int children = 0;

/*
** For the test programs in the baseline system, command-line arguments
** follow these rules. The first two entries are as follows:
**
**	argv[0] the name used to "invoke" this process
**	argv[1] the "character to print" (identifies the process)
**
** Most user programs have one or more additional arguments.
**
** See the comment at the beginning of each user-code source file for
** information on the argument list that code expects.
*/

/*
** The spawn table contains entries for processes that are started
** by the shell.
*/
static const proc_t sh_procs[] = {

	// Users A-C each run ProgABC, which loops printing its character
#if defined(SPAWN_A)
	PROCENT( progABC, "userA\rA\r30", PRIO_STD, 'a' ),
#endif
#if defined(SPAWN_B)
	PROCENT( progABC, "userB\rB\r30", PRIO_STD, 'b' ),
#endif
#if defined(SPAWN_C)
	PROCENT( progABC, "userC\rC\r30", PRIO_STD, 'c' ),
#endif

	// Users D and E run progDE, which is like progABC but doesn't exit()
#if defined(SPAWN_D)
	PROCENT( progDE, "userD\rD\r20", PRIO_STD, 'd' ),
#endif
#if defined(SPAWN_E)
	PROCENT( progDE, "userE\rE\r20", PRIO_STD, 'e' ),
#endif

	// Users F and G run progFG, which sleeps between write() calls
#if defined(SPAWN_F)
	PROCENT( progFG, "userF\rF\r20", PRIO_STD, 'f' ),
#endif
#if defined(SPAWN_G)
	PROCENT( progFG, "userG\rG\r10", PRIO_STD, 'g' ),
#endif

	// User H tests reparenting of orphaned children
#if defined(SPAWN_H)
	PROCENT( progH, "userH\rH\r4", PRIO_STD, 'h' ),
#endif

	// User I spawns several children, and waits for all
#if defined(SPAWN_I)
	PROCENT( progI, "userI\rI", PRIO_STD, 'i' ),
#endif

	// User J tries to spawn 2 * N_PROCS children
#if defined(SPAWN_J)
	PROCENT( progJ, "userJ\rJ", PRIO_STD, 'j' ),
#endif

	// Users K and L iterate spawning userX and sleeping
#if defined(SPAWN_K)
	PROCENT( progKL, "userK\rK\r8", PRIO_STD, 'k' ),
#endif
#if defined(SPAWN_L)
	PROCENT( progKL, "userL\rL\r5", PRIO_STD, 'l' ),
#endif

	// Users M and N spawn copies of userW and userZ via progMN
#if defined(SPAWN_M)
	PROCENT( progMN, "userM\rM\r5\rf", PRIO_STD, 'm' ),
#endif
#if defined(SPAWN_N)
	PROCENT( progMN, "userN\rN\r5\rt", PRIO_STD, 'n' ),
#endif

	// There is no user O

	// User P iterates, reporting system time and stats, and sleeping
#if defined(SPAWN_P)
	PROCENT( progP, "userP\rP\r3\r2", PRIO_STD, 'p' ),
#endif

	// User Q tries to execute a bad system call
#if defined(SPAWN_Q)
	PROCENT( progQ, "userQ\rQ", PRIO_STD, 'q' ),
#endif

	// User R reports its PID, PPID, and sequence number; it
	// calls fork() but not exec(), with each child getting the
	// next sequence number, to a total of five copies
#if defined(SPAWN_R)
	PROCENT( progR, "userR\rR\r20\r1", PRIO_STD, 'r' ),
#endif

	// User S loops forever, sleeping 13 sec. on each iteration
#if defined(SPAWN_S)
	PROCENT( progS, "userS\rS\r13", PRIO_STD, 's' ),
#endif

	// Users T-V run progTUV(); they spawn copies of userW
#if defined(SPAWN_T)
	PROCENT( progTUV, "userT\rT\r6", PRIO_STD, 't' ),
#endif
#if defined(SPAWN_U)
	PROCENT( progTUV, "userU\rU\r6", PRIO_STD, 'u' ),
#endif
#if defined(SPAWN_V)
	PROCENT( progTUV, "userV\rV\r6", PRIO_STD, 'v' )
#endif
	
	// these processes are spawned by the ones above, and are never
	// spawned directly.

	// PROCENT( progW, "userW\rW\r20\r3", PRIO_STD, '?' ),
	// PROCENT( progX, "userX\rX\r20", PRIO_STD, '?' ),
	// PROCENT( progY, "userY\rY\r10", PRIO_STD, '?' ),
	// PROCENT( progZ, "userZ\rZ\r10", PRIO_STD, '?' )
};

#define SH_ENTRIES   (sizeof(sh_procs)/sizeof(proc_t))

/*
** usage function
*/
static void usage( void ) {
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
	for( int ix = 0; ix < SH_ENTRIES; ++ix ) {
		swritech( ' ' );
		swritech( sh_procs[ix].select );
	}
	swrites( "\nOther commands: @* (all), @? (help), @x (exit)\n" );
}

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
	char buf[128];

	if( which == '?' ) {

		// builtin "help" command
		usage();

	} else if( which == 'x' ) {

		// builtin "exit" command
		time_to_stop = true;

	} else if( which == '*' ) {

		// torture test! run everything!
		for( int ix = 0; ix < SH_ENTRIES; ++ix ) {
			int status = spawn( sh_procs[ix].entry, sh_procs[ix].args );
			if( status > 0 ) {
				++children;
			}
		}

	} else {

		// must be a single test; find and run it
		for( int ix = 0; ix < SH_ENTRIES; ++ix ) {
			if( sh_procs[ix].select == which ) {
				// found it!
				int status = spawn( sh_procs[ix].entry, sh_procs[ix].args );
				if( status > 0 ) {
					++children;
				}
				return status;
			}
		}

		// uh-oh, made it through the table without finding the program
		sprint( buf, "shell: unknown cmd '%c'\n", which );
		swrites( buf );
		usage();
	}

	return 0;
}

/**
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
	char *ptr = line + n - 1;	// last char in buffer

	// strip the EOLN sequence
	while( n > 0 ) {
		if( *ptr == '\n' || *ptr == '\r' ) {
			--n;
		} else {
			break;
		}
	}

	// add a trailing NUL byte
	if( n > 0 ) {
		line[n] = '\0';
	}

	return n;
}

/**
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
	char line[128];

	ARG_PROC( 1, args, 5, argc, "shell" );
	
	const char *name = argv[0];

	// keep the compiler happy

	// report that we're up and running
	sprint( line, "%s is ready\n", argv[0] );
	swrites( line );

	// print a summary of the commands we'll accept
	usage();

	// loop forever
	while( !time_to_stop ) {
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		swrites( "\n> " );
		int n = read( CHAN_SIO, line, sizeof(line) );
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
			// ignore it
			continue;
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
			continue;
		}

		// find the '@'
		int i = 0;
		for( ptr = line; i < n; ++i, ++ptr ) {
			if( *ptr == '@' ) {
				break;
			}
		}

		// did we find an '@'?
		if( i < n ) {

			// yes; process any commands that follow it
			++ptr;

			for( ; *ptr != '\0'; ++ptr ) {
				char buf[128];
				int pid = run( *ptr );

				if( pid < 0 ) {
					// spawn() failed
					sprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
					cwrites( buf );
				}

				// should we end it all?
				if( time_to_stop ) {
					break;
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
				// wait for the child
				int32_t status;
				char buf[128];
				pid_t whom = wait( &status );

				// figure out the result
				if( whom == S_NO_CHILD ) {
					break;
				} else if( whom < 1 ) {
					sprint( buf, "%s: wait() returned %d\n", name, whom );
				} else {
					--children;
					sprint( buf, "%s: PID %d exit status %d\n",
							name, whom, status );
				}
				// report it
				swrites( buf );
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
	exit( 1 );

	// yeah, yeah....
	return( 0 );
}
#endif
