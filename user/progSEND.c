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

#define MAX_MSG 80 // limit msg length to screen width in chars

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
  char buffer[MAX_MSG];
  int n = read( CHAN_SIO, buffer, MAX_MSG );
  if (n <= 0) {
    sprint( buf, "No bytes read from CHAN_SIO. Terminating!\n" );
    cwrites( buf );
    exit( -1 );
    return( 82 );
  }

  // If the clock bug on real hardware is fixed, this can just be
  // keyboard input
  char *msg;

#ifdef BAD_CLOCK
  msg = "Hello, World! -RLE\0";
#else
  msg = &buffer[0];
#endif

  send( msg );

  exit( 0 );
  return( 83 );
}
#endif
