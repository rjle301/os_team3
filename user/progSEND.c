#ifndef PROGSEND_INC_C
#define PROGSEND_INC_C

#include <common.h>

/**
** User function SEND:  send
**
** Creates a message, then sends that message over ethernet to another machine
** in the lab
** 
** Invoked as progS
*/


USERMAIN( progSEND ) {

  // ignore command line args
  (void) args;

	// get some current information
	pid_t pid = getpid();
	time_t now = gettime();
	prio_t prio = getprio( 0 );

	char buf[128];
	sprint( buf, "send [%d], started @ %u\n", pid, prio, now );
	cwrites( buf );
  
  // Send a message
  char *msg = "Hello, World! -RLE";
  send( msg );

  exit( 0 );

  return( 83 );
}
#endif
