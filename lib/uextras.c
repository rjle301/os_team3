/**
** @file	uextras.c
**
** @author	CSCI-452 class of 20255
**
** @brief	User-specific library functions.
*/

#ifndef UEXTRAS_H_
#define UEXTRAS_H_

#include <common.h>

/*
**********************************************
** MISCELLANEOUS SUPPORT FUNCTIONS ***********
**********************************************
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
int parseArgs( int argc, char *args, char sep, int n, char *argv[] ) {

	/*
	** Argument strings look like this:
	**
	**    ccccXccccXccccXc....XccccN
	**
	** where X is the separator character, and N is a trailing NUL byte.
	** We look for the separator characters, replacing them with NULs,
	** until either we hit the end of the string, or we fill up the
	** argv array.
	*/

	// NULL argument string -> no arguments!
	if( args == NULL ) {
		return( -1 );
	}

	// argv must have argc+1 (or more) entries
	if( argc >= n ) {
		// expecting more arguments than we have argv[]
		// entries for???
		return( -1 );
	}

	int i;
	char *ptr = args;

	// iterate through the arguments in the string
	for( i = 0 ; i < argc && i < (n-1); ++i ) {

		// remember where the current argument begins
		argv[i] = ptr;

		// find the next separator
		while( *ptr ) {
			if( *ptr == sep ) {
				// found it - replace it and move on
				*ptr++ = '\0';
				break;
			} else {
				// didn't find it, so keep looking
				++ptr;
			}
		}

		// have we reached the end of the arg string?
		if( *ptr == '\0' ) {
			break;
		}
	}

	// NULL pointer to terminate the argv array
	// argv[i] = NULL;

	// return the converted argument count
	return( i + 1 );
}

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
int expand_args( char *buf1, char *buf2, uint32_t max ) {
	uint32_t len = 0;
	--max; // room for a NUL

	while( *buf2 && len < max ) {
		uchar_t ch = *buf2++;
		if( ch >= ' ' && ch < 0x7f ) {
			*buf1++ = ch;
		} else {
			*buf1++ = '\\';
			++len;  // one additional character
			// we treat a few of these specially
			if( ch == '\r' )      *buf1++ = 'r';
			else if( ch == '\t' ) *buf1++ = 't';
			else if( ch == '\n' ) *buf1++ = 'n';
			else {
				// use a hex sequence
				*buf1++ = 'x';
				*buf1++ = hexdigits[ (ch >> 4) & 0xf ];
				*buf1++ = hexdigits[  ch       & 0xf ];
				// two additional characters
				len += 2;
			}
			++len;
		}
		++len; // added 1, or 2, or 4 characters
	}
	*buf1 = '\0';

	return len;
}

/*
**********************************************
** CONVENIENT "SHORTHAND" VERSIONS OF SYSCALLS
**********************************************
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
int32_t spawn( uint32_t what, char *args ) {

	// create the child
	pid_t pid = fork( PRIO_INHERIT );
	if( pid != 0 ) {
		// failure, or we are the parent
		return( pid );
	}

	// try to get it going
	exec( what, args );

	// uh-oh....

	// get our pid
	pid = getpid();
	
	// get the program name from the arg list
	char buf[512];
	char pname[16];
	char *bp = pname;
	while( *args >= ' ' && *args < 0x7f ) {
		*bp++ = *args++;
	}
	*bp = '\0';

	// create the message
	sprint( buf, "Child %d exec(%08x,'%s') failed\n", pid, what, pname );

	cwrites( buf );

	exit( S_ERROR );

	return 42;    // shut the compiler up
}

/**
** cwritech(ch) - write a single character to the console
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
	return( write(CHAN_CIO,&ch,1) );
}

/**
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
	int len = strlen(str);
	return( write(CHAN_CIO,str,len) );
}

/**
** cwrite(buf,leng) - write a sized buffer to the console
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t leng ) {
	return( write(CHAN_CIO,buf,leng) );
}

/**
** swritech(ch) - write a single character to the SIO
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
	return( write(CHAN_SIO,&ch,1) );
}

/**
** swrites(str) - write a NUL-terminated string to the SIO
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
	int len = strlen(str);
	return( write(CHAN_SIO,str,len) );
}

/**
** swrite(buf,leng) - write a sized buffer to the SIO
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t leng ) {
	return( write(CHAN_SIO,buf,leng) );
}

#endif
