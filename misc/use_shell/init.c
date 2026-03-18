#ifndef UINIT_INC_C_
#define UINIT_INC_C_

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
** started by 'init'. Typically, this includes the 'idle' process
** and a 'shell' process.
*/
static const proc_t in_procs[] = {

	// the idle process; it runs at Deferred priority,
	// so it will only be dispatched when there is
	// nothing else available to be dispatched

	PROCENT( idle, "idle\r.", PRIO_LOW, '!' ),
	// { (uint32_t) idle, 0, "idle\r.", PRIO_LOW, '!' },

	// the user shell
	PROCENT( shell, "shell", PRIO_STD, '@' ),
	// { (uint32_t) shell, 0, "shell", PRIO_STD, '@' }
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
		sprint( buf, " %c(%d) ", ch, p );
		swrites( buf );

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
		sprint( buf, "init: starting %08x\n", in_procs[ix].entry );
		cwrites( buf );
		process( ix );
	}

	swrites( " !!!\r\n\n" );
	cwrites( " !!!\r\n\n" );

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
					// (in case the spawn attempt fails)
					proc_pids[ix] = 0;
					// and restart it
					process( ix );
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
