/**
** @file	clock.c
**
** @author	CSCI-452 class of 20255
**
** @brief	Clock module implementation
**
** We use Counter 0 of the 8254 Programmable Interval Timer as our
** system clock.
**
** Compile-time options - define in Makefile:
**
**    SYSTEM_STATUS=n    Report the system status every 'n' seconds
*/

#define KERNEL_SRC

#include <common.h>

#include <clock.h>
#include <procs.h>

#include <x86/arch.h>
#include <x86/pic.h>
#include <x86/pit.h>

/*
** PRIVATE DEFINITIONS
*/

/*
** PRIVATE DATA TYPES
*/

/*
** PRIVATE GLOBAL VARIABLES
*/

// pinwheel control variables
static int pinwheel;   // pinwheel counter
static uint32_t pindex;     // index into pinwheel string

/*
** PUBLIC GLOBAL VARIABLES
*/

// current system time
uint32_t system_time;

/*
** PRIVATE FUNCTIONS
*/

/**
** Name:	clk_isr
**
** The ISR for the clock
**
** @param vector    Vector number for the clock interrupt
** @param code      Error code (0 for this interrupt)
*/
static void clk_isr( int vector, int code ) {

	// keep the compiler happy
	(void) vector;
	(void) code;

	// spin the pinwheel

	++pinwheel;
	if( pinwheel == (CLOCK_FREQ / 10) ) {
		pinwheel = 0;
		++pindex;
		cio_putchar_at( 0, 0, "|/-\\"[ pindex & 3 ] );
	}

#if defined(SYSTEM_STATUS)
	// Periodically, dump the queue lengths and the SIO status (along
	// with the SIO buffers, if non-empty).
	//
	// Define the symbol SYSTEM_STATUS with a value equal to the desired
	// reporting frequency, in seconds.

	cio_printf_at( 1, 0, " time %08x", system_time );
	if( (system_time % SEC_TO_TICKS(SYSTEM_STATUS)) == 0 ) {

		// get process table counts
		uint32_t nst[N_STATES];
		uint32_t nunk;
		nunk = ptable_dump_stats( nst );

		// report queue info and wait/unknown states
		char tbuf[128]; // extra space, just in case
		sprint( tbuf,
				" curr %d, Qs: R[%d,%d,%d] S[%d] Z[%d] B[%d] I[%d] W[%u] ?[%u]",
				current ? current->pid : -1,
				que_length(ready[PRIO_HIGH]),
				que_length(ready[PRIO_STD]),
				que_length(ready[PRIO_LOW]),
				que_length(sleeping),
				que_length(zombie),
				que_length(blocked),
				que_length(sioread),
				nst[STATE_WAITING],
				nunk
		);
		// make sure we don't run off the end of our line
		if( strlen(tbuf) > 60 ) {
			tbuf[60] = ' ';
			tbuf[61] = '*';
			tbuf[62] = '*';
			tbuf[63] = '\0';
		}
		cio_puts_at( 15, 0, tbuf );
	}
#endif

	// time marches on!
	++system_time;

	/*
	** Wake up any sleeping processes whose time has come.
	**
	** This will give same-priority awakened processes preference over
	** the current process when it is scheduled again.
	*/

	do {
		pcb_t *pcb;

		// peek at the first member of the queue
		int status = que_peek( sleeping, (void **) &pcb );

		// it's possible there's nobody to awaken
		if( status == E_EMPTY ) {
			break;
		}

		// if the queue wasn't empty, make sure we got something useful
		if( pcb == NULL ) {
			sprint( b256, "clk_isr: sleeping peek status %d, pcb NULL\n",
					status );
			kpanic( b256 );
		}

		/*
		** The sleep queue is sorted in ascending order by wakeup
		** time, so we know that the retrieved PCB's wakeup time is
		** the earliest of any process on the queue. If that time
		** hasn't arrived yet, there's nobody left to awaken.
		*/

		if( pcb->wakeup > system_time ) {
			break;
		}

		// OK, we need to wake this process up
		assert( que_remove(sleeping,(void **)&pcb) == E_SUCCESS );
		schedule( pcb );

	} while( 1 );

	// next, we decrement the current process' remaining time
	current->quantum -= 1;

	// has it expired?
	if( current->quantum < 1 ) {
		// yes! reschedule it
		schedule( current );
		// and pick a new process
		dispatch();
	}

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}

/*
** PUBLIC FUNCTIONS
*/

/**
** Name:  clk_init
**
** Initializes the clock module
**
*/
void clk_init( void ) {

#if TRACING_INIT
	cio_puts( " Clk" );
#endif

	// start the pinwheel
	pinwheel = -1;
	pindex = 0;

	// return to the dawn of time
	system_time = 0;

	// configure the clock
	uint32_t divisor = PIT_FREQ / CLOCK_FREQ;

	// load counter 0 divisor, use mode 3 (square wave, interrupt on 
	outb( PIT_CONTROL_PORT, PIT_0_SELECT |
	                        PIT_LOAD |
	                        PIT_SQUARE |
	                        PIT_DECIMAL );

	outb( PIT_0_PORT, divisor & 0xff );        // LSB of divisor
	outb( PIT_0_PORT, (divisor >> 8) & 0xff ); // MSB of divisor

	// register the second-stage ISR
	install_isr( VEC_TIMER, clk_isr );
}
