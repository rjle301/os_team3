/**
** @file	stacks.h
**
** @author	CSCI-452 class of 20255
**
** @brief	Stack module declarations
**
** Our stacks are fixed in size, and consist of one or more pages of
** memory (defined in <param.h>). We maintain a simple free list of
** unused stacks to simplify reuse of stacks.
*/

#ifndef STACKS_H_
#define STACKS_H_

#include <common.h>
#include <kmem.h>
#include <procs.h>

/*
** General (C and/or assembly) definitions
*/

// stack size in pages is defined in <params.h>
#define	SZ_STACK      (STACK_PAGES * SZ_PAGE)
#define STACK_WDS     (SZ_STACK / sizeof(uint32_t))

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

/*
** Types
*/

/*
** Globals
*/

/*
** Prototypes
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
**    Cannot be called before kmem is initialized (dynamic allocation)
**    Must be called before interrupt handling has begun
**    Must be called before any process creation can be done
*/
void stk_init( void );

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
int stk_alloc( uint32_t **stk );

/**
** stk_free()
**
** Deallocate a stack
**
** @param stk   The stack to be returned to the free list
*/
void stk_free( uint32_t *stk );

/**
** stk_setup(stk,entry,args)
**
** Sets up the stack for a new process.
**
** @param stk    - The stack to be set up
** @param entry  - Entry point for the new process
** @param args   - Argument vector to be put in place
**
** @return A pointer to the context_t on the stack, or NULL
*/
context_t *stk_setup( uint32_t *stk, uint32_t entry, const char *args );

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
void stk_dump( const char *msg, uint32_t *stk, uint32_t limit );


#endif  /* !ASM_SRC */

#endif
