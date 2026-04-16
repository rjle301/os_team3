#ifndef INIT_INC_C_
#define INIT_INC_C_

#include <common.h>

/**
** Initial process; it starts the other top-level user processes.
**
** Prints a message at startup, '+' after each user process is spawned,
** and '!' before transitioning to wait() mode to the SIO, and
** startup and transition messages to the console. It also reports
** each child process it collects via wait() to the console along
** with that child's exit status.
*/

/*
** This table contains one entry for each process that should be
** started by 'init'.
**
** If compiled with the symbol RUN_SHELL defined, starts up the
** idle process and the shell, and restarts them if they exit;
** otherwise, starts the idle process and all the user test programs,
** and only restarts idle if it exits.
*/
static const proc_t in_procs[] = {

	// the idle process; it runs at Deferred priority,
	// so it will only be dispatched when there is
	// nothing else available to be dispatched
	PROCENT( idle, "idle\r.", PRIO_LOW, '!' ),

#ifdef RUN_SHELL

  PROCENT( progSEND, "send", PRIO_STD, '$' ),

#else

#if defined(SPAWN_SEND)
  PROCENT( progSEND, "userSEND", PRIO_STD, '$'),
#endif

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

#endif
};

#define IN_ENTRIES   (sizeof(in_procs)/sizeof(proc_t))

static pid_t proc_pids[ IN_ENTRIES ];

// character to be printed by 'init'
static char ch = '+';

/**
** process - spawn all user processes listed in the supplied table
**
** @param[in] ix  index of the spawn table entry to be used
*/

static void process( int ix )
{
	char buf[128];

	if( ix < 0 || ix >= IN_ENTRIES ) {
		sprint( buf, "INIT: process(%d)???\n", ix );
		cwrites( buf );
		return;
	}

	// pointer to the selected entry
	const proc_t *proc = &in_procs[ix];

	// kick off the process
	pid_t p = fork( proc->priority );
	if( p < 0 ) {

		// error!
		sprint( buf, "INIT: fork for 0x%08x failed\n",
				(uint32_t) (proc->entry) );
		cwrites( buf );

	} else if( p == 0 ) {

		// send it on its way
		exec( proc->entry, proc->args );

		// uh-oh - should never get here!
		sprint( buf, "INIT: exec(0x%08x) failed\n",
				(uint32_t) (proc->entry) );
		cwrites( buf );

	} else {

		// parent just reports that another one was started
		// sprint( buf, " %c(%d) ", ch, p );
		// swrites( buf );

		// remember the pid for later
		proc_pids[ix] = p;

	}
}

/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
	char buf[128];
	// char ch = '+';

	ARG_PROC( 2, args, 5, argc, "init" );
	if( argc == 2 ) {
		ch = argv[1][0];
	}

	// test the sio
	// "I hear, I see, I learn"
	swrites( "\n\nAudio, video, disco!\n\n\r" );

	// DELAY(SHORT);

	/*
	** Start all the user processes
	*/

	sprint( buf, "%s: starting user processes\n", argv[0] );
	cwrites( buf );

	for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
		// sprint( buf, "init: starting %08x\n", in_procs[ix].entry );
		// cwrites( buf );
		process( ix );
	}

	swrites( " !!!\r\n\n" );
	// cwrites( " !!!\r\n\n" );

	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	sprint( buf, "%s: transitioning to wait() mode\n", argv[0] );
	cwrites( buf );

	for(;;) {
		int32_t status;
		pid_t whom = wait( &status );

		// PIDs must be positive numbers!
		if( whom <= 0 ) {

			sprint( buf, "%s: wait() returned %d???\n", argv[0], whom );
			cwrites( buf );

		} else {

			// got one; report it
			sprint( buf, "%s: pid %d exit(%d)\n", argv[0], whom, status );
			cwrites( buf );

			// figure out if this is one of ours
			for( int ix = 0; ix < IN_ENTRIES; ++ix ) {
				if( proc_pids[ix] == whom ) {
					// one of ours - reset the PID field
					// (in case a respawn attempt fails)
					proc_pids[ix] = 0;

					/*
					** If this was idle, or if this was the shell,
					** restart it. Idle is always entry #0; if we're
					** using the shell it will be entry #1.
					*/
					if( ix == 0
#ifdef RUN_SHELL
						|| ix == 1
#endif
							) {   // idle
						// restart this process
						process( 0 );
					}
					break;
				}
			}
		}
	}

	/*
	** SHOULD NEVER REACH HERE
	*/

	cwrites( "*** INIT IS EXITING???\n" );
	exit( 1 );

	return( 1 );  // shut the compiler up
}
#endif
