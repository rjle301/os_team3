/**
** @file    params.h
**
** @author  CSCI-452 class of 20255
**
** @brief   System configuration settings
**
** This header file contains many of the "easily tunable" system
** settings, such as clock rate, number of simultaneous user
** processes, etc. This provides a sort of "one-stop shop" for
** things that might be tweaked frequently.
*/

#ifndef PARAMS_H_
#define PARAMS_H_

/*
** General (C and/or assembly) definitions
*/

// Upper bound on the number of simultaneous user-level
// processes in the system (completely arbitrary)
#define N_PROCS        25

// Limit on the number of bytes in command-line argument strings,
// including the trailing NUL byte (also completely arbitrary)
#define MAX_ARG_CHARS  256

// Clock frequency (Hz)
#define CLOCK_FREQ     1000
#define TICKS_PER_MS   1

// Stack size, in pages
#define	STACK_PAGES    2

#endif
