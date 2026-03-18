/**
** @file	stacks.c
**
** @author	CSCI-452 class of 20235
**
** @brief	Stack module implementation
**
** Our stacks are fixed in size, and consist of one or more pages of
** memory (defined in <param.h>). We maintain a simple free list of
** unused stacks to simplify reuse of stacks.
**
** Compile-time options - define in Makefile:
**
**    STATIC_STACKS    Use a static array of stacks (vs. dynamic allocation)
**
** If compiled with the symbol STATIC_STACKS defined, this module
** uses a static array of stacks, and selects the stack for a 
** process based on the PCB's position in the ptable array
** in the process module.
**
** If compiled without that symbol, this module dynamically allocates
** stacks for processes as needed, and keeps deallocated stacks in
** a free list for quick re-use.
*/

#define	KERNEL_SRC

#include <common.h>
#include <stacks.h>
#include <memory.h>
#include <list.h>

// need the prototype for fake_exit()
void fake_exit( void );

/*
** PRIVATE DEFINITIONS
*/

/*
** PRIVATE DATA TYPES
*/

/*
** PRIVATE GLOBAL VARIABLES
*/

// the stack free list is a list of blocks
static list_t *free_stacks;

/*
** When doing static stack allocation, we preallocate N_PROCS + 1 stacks
** (one for each process, plus one for the kernel), and we preload the
** "free stacks" list with these. This allows stk_alloc() and
** stk_dealloc() to work the same way regardless of how the stacks are
** actually allocated.
*/

#ifdef STATIC_STACKS
static uint32_t stackset[N_PROCS+1][STACK_WDS] ATTR_ALIGNED(4096);
#endif

/*
** PUBLIC GLOBAL VARIABLES
*/

// kernel stack
uint32_t *kstack;

// kernel stack pointer
uint32_t *kesp;

/*
** PRIVATE FUNCTIONS
*/

/*
** PUBLIC FUNCTIONS
*/

/*
** Module initialization
*/

/**
** stk_init()
**
** Initializes the stack module.
**
** Dependencies:
**    Cannot be called before kmem is initialized (if using dynamic alloc)
**    Must be called before interrupt handling has begun
**    Must be called before any process creation can be done
*/
void stk_init( void ) {

#if TRACING_INIT
	cio_puts( " Stk" );
#endif

	// reset the "free stacks" pool
	free_stacks = NULL;

#ifdef STATIC_STACK
	/*
	** For STATIC_STACKS, we have a fixed-sized pool of NPROCS+1
	** stacks, and we start by putting them all on the free list.
	**
	** We don't need to do this if we're using dynamic storage.
	*/
	for( int i = 0; i < (N_PROCS + 1); ++i ) {
		stk_dealloc( &stackset[i] );
	}
#endif

	// allocate the kernel stack
	assert( stk_alloc(&kstack) == E_SUCCESS );

	// initial kernel stack pointer points to last word of stack
	kesp = kstack + STACK_WDS - 1;
}

/*
** Stack manipulation
*/

/**
** stk_alloc()
**
** Allocate a stack.
**
** @param stk   A pointer to where the address of the stack is returned
**
** @return The status of the allocation attempt
*/
int stk_alloc( uint32_t **stk ) {
	uint32_t *new;

#if TRACING_STACK
	cio_puts( "stk_alloc()\n" );
#endif

	if( free_stacks == NULL ) {

#ifdef STATIC_STACKS
		// this is a serious problem if we're not using
		// dynamic allocation of stack space!
		kpanic( "stk_alloc: no more static stacks!!!" );
#else
		// must allocate a new stack
		new = (uint32_t *) km_page_alloc( STACK_PAGES );
#endif

	} else {

		// can re-use an existing stack
		list_t *tmp = free_stacks;
		free_stacks = tmp->next;
		new = (uint32_t *) tmp;
	}

	// if we succeeded, clean up the space for the caller
	if( new != NULL ) {
		memclr( new, SZ_STACK );
		*stk = new;
	}

	// return the proper stack

	return new != NULL ? E_SUCCESS : E_FAILURE;
}

/**
** stk_free() - deallocate a stack
**
** @param stk   The stack to be returned to the free list
**
** Note: this works regardless of whether or not we're dynamically
** allocating our stack space.
*/
void stk_free( uint32_t *stk )
{

#if TRACING_STACK
	// TODO
	cio_printf( "stk_free(%08x)\n", (uint32_t) stk );
#endif

	// sanity check
	assert1( stk != NULL );

	list_t *tmp = (list_t *) stk;

	// link it into the free list
	tmp->next = free_stacks;
	free_stacks = tmp;
}

/**
** stk_setup - set up the stack for a new process
**
** @param stk    - The stack to be set up
** @param entry  - Entry point for the new process
** @param args   - Argument vector to be put in place
**
** @return A pointer to the context_t on the stack, or NULL
*/
context_t *stk_setup( uint32_t *stk, uint32_t entry, const char *args ) {

#if TRACING_STACK_SETUP
	cio_printf( "\nstksetup: stk %08x, entry %08x, args %08x",
			(uint32_t) stk, entry, (uint32_t) args );
	cio_printf( " '%s'\n", args );
#endif

	/*
	** The pages for the stack were cleared when they were allocated,
	** so we don't need to remember to do that.
	**
	** We reserve one longword at the bottom of the stack as a "buffer".
	**
	** The user code is not linked with a startup function, so it is
	** not "called" in the traditional sense. We need to simulate this
	** call by pushing a fake "return address" which points into a 
	** dummy function. That function's purpose is to handle a return
	** from the user code's main() function by calling exit().
	** 
	**      esp ->  context      <- context save area
	**              ...          <- context save area
	**              context      <- context save area
	**              fake_exit    <- return address for faked call to main()
	**              argv         <- arg string pointer for main()
	**               ...         <- arg character strings
	**                0          <- last word in stack
	**
	** Stack alignment rules for the SysV ABI i386 supplement dictate that
	** the 'argc' parameter must be at an address that is a multiple of 16;
	** see below for more information.
	**
	** Ultimately, this is what the bottom end of the stack will look like:
	**
	**          avptr (at a multiple of 16 address)
	**  retaddr  |
	**     |     |
	**     v     v
	**    addr  argv  str..................              zero
	**   [....][....][....][....] ... [...0] [0000] ... [0000]
	**           |    ^                                      ^
	**           |    |                                      |
	**           ------                 end of stack --------|
	*/

	/*
	** First, calculate the space we'll need for all this stuff.
	*/

	// total number of words we need - start with a 0 at the end
	uint32_t totwords = 1;

	// number of bytes in the arg string
	uint32_t argbytes = (uint32_t) strlen( args ) + 1;

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
	uint32_t argwords = DIV4(argbytes);

	totwords += argwords;

	// also need one word for the arg pointer
	totwords += 1;

	/*
	** Find the position of the arg pointer in the stack.
	**
	** The stack is page-aligned, so the address of the first byte
	** following it is page-aligned. We need to back up from there
	** to figure out where the arg pointer will go, and then adjust
	** that address so that it's at a multiple of 16.
	*/

	uint32_t *stackend = stk + STACK_WDS; // pointer arithmetic roolz!

	// back up
	uint32_t *avptr = stackend - totwords;

	// back up to multiple-of-16 address
	avptr = (uint32_t *) ( (uint32_t) avptr & MOD16_MASK);

#if TRACING_STACK_SETUP
	cio_printf( "\nsetup: wds %08x avptr %08x argb %u\n",
			totwords, (uint32_t) avptr, argbytes );
#endif

	/*
	** Start to fill in the stack.
	**
	********************************************************************
    ** Potential VM issue here!
	**
	** This code assigns into the user stack. We're assuming the address
	** is a kernel-space address; if the system changes to use VM, MAKE
	** SURE THAT ASSUMPTION STILL HOLDS TRUE.
    ********************************************************************
	*/

	// assign the arg pointer
	*avptr = (uint32_t) (avptr + 1);

	// copy the arg string
	memmove( (void *)(avptr+1), args, argbytes );

	// add the return address
	--avptr;
	*avptr = user_locs[ULOC_FAKE];
#if TRACING_STACK_SETUP
	cio_printf( "\nsetup: entry %08x, fake return %08x\n",
			entry, (uint32_t) *avptr );
#endif

	/*
	** Almost done!
	**
	** Now we need to set up the initial context for the executing
	** process.
	**
	** When this process is dispatched, the context restore code will
	** pop all the saved context information off the stack, including
	** the saved EIP, CS, and EFLAGS. We set those fields up so that
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *ctx = ((context_t *) avptr ) - 1;

	/*
	** The stack was cleared before we got it, so all the context
	** fields currently contain zeroes.  We now need to fill in
	** the important fields.
	**
	** Note: we don't need to set the ESP value for the process,
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves ESP
	** where it winds up naturally
	*/

	ctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
	ctx->eip = entry;                // initial EIP
	ctx->cs = GDT_CODE;              // segment registers
	ctx->ss = GDT_STACK;
	ctx->ds = ctx->es = ctx->fs = ctx->gs = GDT_DATA;

#if TRACING_STACK_SETUP
	ctx_dump( "\nstack_setup: new context", ctx );
	delay( DELAY_2_SEC );
	stk_dump( "\nstack setup: new stack", stk, 0 );
	delay( DELAY_5_SEC );
#endif

	/*
	** Return the new context pointer to the caller
	*/
	
	return ctx;
}

/**
** stk_dump(msg,stk,lim)
**
** Dumps the contents of a stack to the console.  Assumes the stack
** is a multiple of four words in length.
**
** If a limit is given, that many words from the end of the stack
** will be dumped.
**
** @param msg   An optional message to print before the dump
** @param stk   The stack to dump out
** @param lim   Limit on the number of words to dump (0 for all)
*/

// buffer sizes (rounded up a bit)
#define HBUFSZ      48
#define CBUFSZ      24

void stk_dump( const char *msg, uint32_t *stk, uint32_t limit )
{
	uint32_t words = STACK_WDS;
	int eliding = 0;
	char oldbuf[HBUFSZ], buf[HBUFSZ], cbuf[CBUFSZ];
	uint32_t addr = (uint32_t ) stk;
	uint32_t *sp = (uint32_t *) stk;
	char hexdigits[] = "0123456789ABCDEF";

	// if a limit was specified, dump only that many words

	if( limit > 0 ) {
		words = limit;
		if( (words & 0x3) != 0 ) {
			// round up to a multiple of four
			words = (words + 3) & MOD4_MASK;
		}
		// skip to the new starting point
		sp += (STACK_WDS - words);
		addr = (uint32_t) sp;
	}

	cio_puts( "*** stack" );
	if( msg != NULL ) {
		cio_printf( " (%s):\n", msg );
	} else {
		cio_puts( ":\n" );
	}

	/**
	** Output lines begin with the 8-digit address, followed by a hex
	** interpretation then a character interpretation of four words:
	**
	** aaaaaaaa*..xxxxxxxx..xxxxxxxx..xxxxxxxx..xxxxxxxx..cccc.cccc.cccc.cccc
	**
	** Output lines that are identical except for the address are elided;
	** the next non-identical output line will have a '*' after the 8-digit
	** address field (where the '*' is in the example above).
	*/

	oldbuf[0] = '\0';

	while( words > 0 ) {
		register char *bp = buf;   // start of hex field
		register char *cp = cbuf;  // start of character field
		uint32_t start_addr = addr;

		// iterate through the words for this line

		for( int i = 0; i < 4; ++i ) {
			register uint32_t curr = *sp++;
			register uint32_t data = curr;

			// convert the hex representation

			// two spaces before each entry
			*bp++ = ' ';
			*bp++ = ' ';

			// we could speed this up by advancing bp by 8 and
			// working backwards, shifting right by 4 at the
			// end and decrementing bp.
			for( int j = 0; j < 8; ++j ) {
				// print the leftmost nybble
				uint32_t value = (data >> 28) & 0xf;
				*bp++ = hexdigits[value];
				// move next nybble into the high-order bit positions
				data <<= 4;
			}

			// now, convert the character version
			data = curr;

			// one space before each entry
			*cp++ = ' ';

			// again, we could speed this up by working backwards
			for( int j = 0; j < 4; ++j ) {
				uint32_t value = (data >> 24) & 0xff;
				*cp++ = (value >= ' ' && value < 0x7f) ? (char) value : '.';
				data <<= 8;
			}
		}
		*bp = '\0';
		*cp = '\0';
		words -= 4;
		addr += 16;

		// if this line looks like the last one, skip it

		if( strcmp(oldbuf,buf) == 0 ) {
			++eliding;
			continue;
		}

		// it's different, so print it

		// start with the address
		cio_printf( "%08x%c", start_addr, eliding ? '*' : ' ' );
		eliding = 0;

		// print the words
		cio_printf( "%s %s\n", buf, cbuf );

		// remember this line
		memcpy( (uint8_t *) oldbuf, (uint8_t *) buf, HBUFSZ );
	}
}
