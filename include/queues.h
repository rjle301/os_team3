/*
** @file    queues.h
**
** @author  CSCI-452 class of 20255
**
** @brief   Queue module declarations
**
** Our queues are generic, opaque data structures. To the rest of
** the kernel, a queue is just a pointer. Queues are self-ordering.
**
** Definitions for the actual queue structures are in queue.c.
*/

#ifndef QUEUE_H_
#define QUEUE_H_

#include "common.h"

/*
** General (C and/or assembly) definitions
*/

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

/*
** Types
*/

// A queue (as it appears to the outside world)
typedef struct queue_s *queue_t;

/*
** Function pointer types (defined here for convenience)
*/

// ordering functions take two void* params and
// return a strcmp-style result
typedef int (*compare_t)(const void*,const void*);

/*
** Globals
*/

/*
** Prototypes
*/

/*
** Debugging/tracing routines
*/

/**
** que_dump(msg,que)
**
** dump the contents of the specified queue_t to the console
**
** @param[in]  msg  Optional message to print
** @param[in]  q    queue_t to dump
*/
void que_dump( const char *msg, queue_t q );

/*
** Queue operations
*/

/**
** Name:  que_init
**
** Initialize the queue module.
*/
void que_init( void );

/**
** que_alloc()
**
** Allocate and initialize a queue.
**
** @param[in]  compare   Pointer to the comparison function for the queue, or NULL
**
** @return A pointer to the allocated queue, or NULL on failure
*/
queue_t que_alloc( compare_t compare );

/**
** que_free()
**
** Deallocate a queue
**
** @param[in,out] q   The queue to be deallocated
**
** If the parameter is NULL or invalid, panics.
*/
void que_free( queue_t q );

/**
** que_length()
**
** Return the occupancy count of a queue.
**
** @param[in]  q   The queue to be examined
**
** @return The occupancy count
**
** If the parameter is NULL or invalid, panics.
*/
int que_length( queue_t q );

/**
** que_insert()
**
** Add an entry to a queue.
**
** @param[in,out] q     The queue to be manipulated
** @param[in]     data  The value to add to the queue
**
** @return The insertion status
*/
int que_insert( queue_t q, void *data );

/**
** que_peek()
**
** Peek at the first entry in a queue. If there is no entry in
** the queue, *data will be untouched.
**
** @param[in]  q     The queue to be examined
** @param,out] data  Where to save the value from the first queue node
**
** @return E_SUCCESS if there was an entry, else an error code
*/
int que_peek( queue_t q, void **data );

/**
** que_remove()
**
** Remove the first entry from a queue. Like que_peek(), but actually
** removes the node from the queue.
**
** @param[in,out] q     The queue to be manipulated
** @param[out]    data  Where to save the removed data value
**
** @return The removal status
*/
int que_remove( queue_t q, void **data );

/**
** que_remove_by()
**
** Remove a specific entry from a queue. This is like _que_remove(),
** but we must locate the entry to be removed from the list.
**
** Also, we don't return the removed data field, because the caller
** must already have it (because it was supplied to use in the call).
**
** Finally, if there are multiple entries with the desired data value,
** we remove the first one. It is up to the caller to determine whether
** or not this was the desired version.
**
** @param[in,out] q     The queue to be manipulated
** @param[in]     data  The entry to be located and removed
**
** @return The removal status
*/
int que_remove_by( queue_t q, void *data );

#endif  /* !ASM_SRC */

#endif  /* QUEUE_H_ */
