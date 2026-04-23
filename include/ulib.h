/**
** @file    ulib.h
**
** @author  Various CSCI-452 classes
**
** @brief   Declarations for user-level library functions
**
** This header provides prototypes for library functions that are
** only callable from user-level code. "Common" library functions
** are detailed in <lib.h>, which will include this file when
** compiling user-level code.
*/

#ifndef ULIB_H_
#define ULIB_H_

#include <common.h>

/*
** General (C and/or assembly) definitions
*/

#ifndef ASM_SRC

/*
*************************************************
** MISCELLANEOUS SUPPORT FUNCTIONS **************
*************************************************
*/

/**
** parseArgs(argc,args,n,argv)
**
** Parse a command-line argument string into an argument vector
**
** @param argc    Count of arguments expected in the string
** @param args    The command-line argument string
** @param sep     The character separating arguments within 'args'
** @param n       Length of the argv array
** @param argv    The argv array
**
** @returns The number of argument strings put into the argv array
**
** Takes the argc and args parameters to the process' main() function
** along with an array of char *; fills in the array with pointers to
** the beginnings of the argument strings, followed by a NULL pointer.
** Replaces the separator character with NUL characters.  Only converts
** the first n-1 entries, so the final entry will contain all remaining
** characters from the string.
*/
int parseArgs( int argc, char *args, char sep, int n, char *argv[] );

/**
** Name:    expand_args(buf1,buf2,max)
**
** This silly little function exists solely to copy the second
** parameter into the first parameter, replacing non-printing
** characters with hex escape sequences.
**
** @param[out] buf1   Destination buffer
** @param[in]  buf2   Source buffer
** @param[in]  max    Size of buf1
**
** @return The number of characters placed into buf1
*/
int expand_args( char *buf1, char *buf2, uint32_t max );

/*
*************************************************
** SYSTEM CALLS *********************************
*************************************************
*/

/**
** exit()
**
** Terminates the calling process with a specified termination status.
**
** @param[in] status   Termination status of this process
**
** Does not return.
*/
void exit( int32_t status );

/**
** wait()
**
** Block the calling process until one of its children terminates.
**
** @param[out] status   Pointer to status return variable, or NULL
**
** @return PID of the terminating child, or -1 if there are no children
*/
pid_t wait( int32_t *status );

/**
** fork()
**
** Create a new process that is the duplicate of the calling process at
** that moment in time.
**
** @param[in] priority   The desired process priority for the child
**
** @return PID of the child in the parent, 0 in the child;
**         on error, -1 in the parent
*/
pid_t fork( prio_t priority );

/**
** exec()
**
** Replace the memory image of the calling process with the specified
** program image.
**
** @param[in] prog   The program to be loaded
** @param[in] args   Command-line arguments for the program
**
** @return Does not return on success; on error, returns, which
**         itself indicates an error.
*/
void exec( uint32_t prog, char *args );

/**
** read()
**
** Read from the indicated channel into the specified buffer.
**
** @param[in]  chan   Input channel to read from
** @param[out] buf    Buffer into which the data is to be placed
** @param[in]  len    Maximum amount of data the buffer will hold
**
** @return The number of bytes actually read, or a negative number
**         on error.
*/
int read( uint32_t chan, void *buf, uint32_t len );

/**
** write()
**
** Write from the specified buffer to the indicated channel.
**
** @param[in] chan   Output channel to write to
** @param[in] buf    Buffer from which the data is to be copied
** @param[in] len    Number of bytes of data to be written
**
** @return The number of bytes actually written, or a negative number
**         on error.
*/
int write( uint32_t chan, const void *buf, uint32_t len );

/**
** sleep()
**
** Block the calling process until the specified length of time has passed.
** A sleep time of 0 is intepreted as a request to yield the CPU.
**
** @param[in] n   Number of TODO to sleep
*/
void sleep( uint32_t n );

/**
** getpid()
**
** Return the PID of the calling process.
**
** @return The PID of the calling process.
*/
pid_t getpid( void );

/**
** gettime()
**
** Return the current system time (in clock ticks)
**
** @return The current system time.
*/
time_t gettime( void );

/**
** getprio()
**
** Get the process priority for the specified process.
**
** @param pid  The process to check
**
** @return The priority value of the process, or S_NOT_FOUND
*/
int getprio( pid_t pid );

/**
** bogus()
**
** Perform a bad system call. Intentionally attempts to invoke a
** system call that doesn't exist in order to test the system's
** handling of that situation.
**
** The syscall ISR should catch this and convert it into
**
**     exit( S_BAD_SYSCALL );
**
** Should not return.
*/
void bogus( void );

/**
** setvga256linear()
**
** Sets the VGA graphics mode to 256 linear graphics mode (Mode 13h).
**
** Should not return.
*/
void setvga256linear( void );


/**
** settextmode()
**
** Sets the VGA graphics mode to 80x25 text mode (Mode 3).
**
** Should not return.
*/
void setvgatextmode( void );

/**
** write()
**
** Write a specific color to an area on the screen.
**
** @param[in] x     x coordinate of the pixel in question
** @param[in] y     y coordinate of the pixel in question
** @param[in] c     Color to write to the screen.
**
** Should not return.
*/
void writepixel(unsigned x, unsigned y, unsigned c);


/**
** returnwidth()
**
** Get the screen width (in pixels in Mode 13h, in characters in Mode 3)
**
**
** @return The current screen width.
*/
unsigned getwidth( void );


/**
** returnheight()
**
** Get the screen height (in pixels in Mode 13h, in characters in Mode 3)
**
**
** @return The current screen height.
*/
unsigned getheight( void );


/**
** returnfbsegment()
**
** Get the location of the fb segment.
**
**
** @return The address where VGA is looking at..
*/
unsigned getfbsegment( void );

/**
** send(char* data)
**
** Constructs an ethernet frame out of the data and sends it over ethernet
**
** @param data  The data being sent over ethernet
**
** @return None
*/
void send( char *data );

/*
*************************************************
** CONVENIENT "SHORTHAND" VERSIONS OF SYSCALLS **
*************************************************
**
** These are library functions that perform specific common
** variants of system calls. This helps reduce the total number
** of system calls, keeping our baseline OS as lean and mean
** as we can make it. :-)
*/

/**
** spawn - create a new process running a different program
**
** usage:   pid = spawn(what,args);
**
** Creates a new process and then execs 'what'. The new process
** inherits the priority of the parent; if that's not the desired
** result, use fork() and exec() directly.
**
** @param what  The program table index of the program to spawn
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t what, char *args );


/**
** cwritech(ch) - write a single character to the console
**
** @param ch The character to write
**
** @return  The return value from calling write()
*/
int cwritech( char ch );

/**
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str );

/**
** cwrite(buf,leng) - write a sized buffer to the console
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @return  The return value from calling write()
*/
int cwrite( const char *buf, uint32_t leng );

/**
** swritech(ch) - write a single character to the SIO
**
** @param ch The character to write
**
** @return  The return value from calling write()
*/
int swritech( char ch );

/**
** swrites(str) - write a NUL-terminated string to the SIO
**
** @param str The string to write
**
** @return  The return value from calling write()
*/
int swrites( const char *str );

/**
** swrite(buf,leng) - write a sized buffer to the SIO
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @return  The return value from calling write()
*/
int swrite( const char *buf, uint32_t leng );

#endif /* !ASM_SRC */

#endif
