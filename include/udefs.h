/**
** @file    udefs.h
**
** @author  CSCI-452 class of 20255
**
** @brief   "Userland" configuration information
*/

#ifndef UDEFS_H_
#define UDEFS_H_

#include <common.h>

/*
** General (C and/or assembly) definitions
**
** This section of the header file contains definitions that can be
** used in either C or assembly-language source code.
*/

// delay loop counts

#define DELAY_LONG		100000000
#define DELAY_MED		4500000
#define DELAY_SHORT		2500000

#define DELAY_STD		DELAY_SHORT

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

// convenience macros

// a delay loop - kind of ugly, but it works

#define DELAY(n)	do { \
		for(int _dlc = 0; _dlc < (DELAY_##n); ++_dlc) continue; \
	} while(0)

/*
** All user main() functions have the following prototype:
**
**	int name( char *args );
**
** To simplify declaring them, we define a macro that expands into
** that header. This can be used both in the implementation (followed
** by the function body) and in places where we just need the prototype
** (following it with a semicolon).
**
** Each is designed to test some facility of the OS; see the file
** doc/usermatrix.txt for a summary of which system calls are tested
** by each user function.
**
** Output from user processes is usually alphabetic.  Uppercase
** characters are "expected" output; lowercase are (typically)
** "erroneous" output.
**
** More specific information about each user process can be found in
** the header comment for that function in its source file.
**
** To make a specific user process available for spawning, uncomment its
** SPAWN_x definition in the list at the end of this header file.
*/

#define USERMAIN(f)	int f( char *args )

// these are always started
USERMAIN(init);    USERMAIN(idle);    USERMAIN(shell);

// these are started by other processes (e.g., the shell)
USERMAIN(progABC); USERMAIN(progDE);  USERMAIN(progFG); USERMAIN(progH);
USERMAIN(progI);   USERMAIN(progJ);   USERMAIN(progKL); USERMAIN(progMN);
USERMAIN(progO);   USERMAIN(progP);   USERMAIN(progQ);  USERMAIN(progR);
USERMAIN(progS);   USERMAIN(progTUV); USERMAIN(progW);  USERMAIN(progX);
USERMAIN(progY);   USERMAIN(progZ);

// user command-line argument separator character
#define	ARG_SEP    '\r'

/*
** Command-line argument processing is done the same way for all
** user processes; this macro expands into the code to do it.
**
** ASSUMES that the arg buffer parameter is really a C string
** pointer, and not an arbitrary array of bytes.  If the argument
** is actually binary data (e.g., a struct, or binary numbers),
** DO NOT USE THIS MACRO.
*
** Usage:
**    ARG_PROC( #exp, argparam, argvlen, countvar, my_name );
**
**      #_exp     - how many arguments we expect (0 == variable)
**      argparam  - the arg buffer param (assumed to really be char *)
**      argvlen   - how large to make argv (>= #_expected + 1)
**      countvar  - variable to create that will hold the arg count
**      my_name   - string literal to use as the function's name
**
** Creates argv[argvlen] and countvar; calls parseArgs() to process
** the argument string using the default separator character ('\r');
** assigns the return value to count_var.  Prints a console message if the
** return value from parseArgs() is not equal to the #_expected value
** (if #_expected is non-zero).
**
** We create argv here because this allows us to ensure that all its
** elements contain NULL pointers.  The C standard states, in section
** 6.7.8, that
**
**   "21 If there are fewer initializers in a brace-enclosed list
**       than there are elements or members of an aggregate, or
**       fewer characters in a string literal used to initialize an
**       array of known size than there are elements in the array,
**       the remainder of the aggregate shall be initialized
**       implicitly the same as objects that have static storage
**       duration."
**
** We use an initializer list with a single 0 in it to force argv[0]
** to contain a NULL pointer, and the other entries automatically 
** contain NULL thanks to the C specification. :-)
**
** Example:
**
**    ARG_PROC( 3, args, 5, nargs, "me" );
**
** says we expect 3 arguments in 'args', will accept up to 4 (plus NULL),
** creates 'argv' and 'nargs', and initializes 'nargs' to the actual arg
** count.
*/
#define ARG_PROC( n, str, vlen, count, name ) \
	char *argv[ vlen ] = { 0 }; \
	int count = parseArgs( n, (char *) str, ARG_SEP, vlen, argv );

// could add the following to check argument counts
//	if( n != 0 && count != n ) {
//		char _buf[128];
//		sprint( _buf, "%s: got %d args, expected %d", name, count, n );
//		cwrites( _buf );
//	}

/*
** User process tables
**
** Both 'init' and 'shell' contain tables of user processes. These
** provide entry points, priority values, and command-line arguments
** for various user processes.
*/

typedef struct proc_s {
	uint32_t entry;          // process entry point
	char *args;              // command-line argument string
	prio_t priority;         // process priority
	char select;             // identifying character
} proc_t;

/*
** Create a spawn table entry for a process with a string literal
** as its argument buffer.  We rely on the fact that the C standard
** ensures our array of pointers will be filled out with NULLs
**
** Example:
**
** PROCENT( progABC, PRIO_STD, "a", "proga\ra\r30" }
*/
// #define PROCENT(e,p,s,a) { (uint32_t) e, 0, p, s, a }
#define PROCENT(ent,args,prio,sel) { (uint32_t) ent, args, prio, sel }

// sentinel value for the end of the table - must be a value that
// will never occur as the actual entry point of a function
#define TBLEND  0xfeedbead

/*
** User process controls.
**
** To enable a specific test, define the symbol SPAWN_name here, and
** guard the places in other code that use or refer to that test. For
** example, test 'A' is enabled by definining SPAWN_A here, and all
** places that refer to test 'A' are guarded with:
**
**      #ifdef SPAWN_A
**          ... conditionally-compiled code
**      #endif
**
** Generally, most of these will exit with a status of 0.  If a process
** returns from its main function when it shouldn't (e.g., if it had
** called exit() but continued to run), it will usually return a status
** of ?.
*/

/*
** The standard set of test programs, start by the shell (which is started
** automatically from the initial user process)
*/

#define SPAWN_A
#define SPAWN_B
#define SPAWN_C
#define SPAWN_D
#define SPAWN_E
#define SPAWN_F
#define SPAWN_G
#define SPAWN_H
#define SPAWN_I
#define SPAWN_J
#define SPAWN_K
#define SPAWN_L
#if 0
#define SPAWN_M
#define SPAWN_N
there is no user 'O'
#define SPAWN_P
#define SPAWN_Q
#endif
#define SPAWN_R
#define SPAWN_S
#if 0
#define SPAWN_T
#define SPAWN_U
#define SPAWN_V
#endif
// users 'W' through 'Z' are spawned by other processes

#endif /* !ASM_SRC */

#endif
