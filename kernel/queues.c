/*
** @file    queues.c
**
** @author  CSCI-452 class of 20255
**
** @brief   Queue module implementation
**
** Queue organization
** ------------------
** Our queues are self-ordering, generic queues.  A queue can contain
** any type of data.  This is accomplished through the use of intermediate
** nodes called qnodes, which contain a void* data member, allowing them
** to point to any type of integral data (integers, pointers, etc.).
** The qnode list is doubly-linked for ease of traversal.
**
** Each queue has associated with it a comparison function, which may be
** NULL.  Insertions into a queue are handled according to this function.
** If the function pointer is NULL, the queue is FIFO, and the insertion
** is always done at the end of the queue.  Otherwise, the insertion is
** ordered according to the results from the comparison function.
**
** The queue is opaque to the rest of the kernel, for safety reasons.
*/

#define	KERNEL_SRC

#include <common.h>
#include <kmem.h>
#include <queues.h>

/*
** PRIVATE DATA TYPES
*/

// the qnode type
typedef struct qnode_s {
	void *data;            // pointer to whatever is being held here
	struct qnode_s *next;  // successor in the queue
} qnode_t;

// the queue type itself (the typedef is in queue.h)
struct queue_s {
	qnode_t *head;     // first item in the queue
	qnode_t *tail;     // last item in the queue
	uint32_t count;    // current occupancy
	int( *compare)(const void *,const void *);  // ordering function
};

/*
** PRIVATE DEFINITIONS
*/

// how many qnodes can we get from a memory page?
#define QNODES_PER_PAGE   (SZ_PAGE / sizeof(qnode_t))

// how many queues do we support?
#define N_QUEUES          8

// queue allocation flags
#define QUE_FREE          1
#define QUE_INUSE         0

/*
** PRIVATE GLOBAL VARIABLES
*/

// list of free qnodes
static qnode_t *free_qnodes;

// our collection of queues
static struct queue_s queues[N_QUEUES]; // the queues themselves
static uint8_t queue_free[N_QUEUES];    // "bitmap" free list

/*
** PUBLIC GLOBAL VARIABLES
*/

/*
** PRIVATE FUNCTIONS
*/

/**
** que_ix()
**
** Calculate the index of a queue in the array of queues.
**
** @param[in] q  The queue to be checked
**
** @return The index (0..N_QUEUES-1) if valid, else -1
*/
static int que_ix( queue_t q ) {

	int ix = q - &queues[0];

	if( ix < 0 || ix >= N_QUEUES ) {
		return -1;
	}

	return ix;
}

/**
** qnode_free()
**
** Deallocates the supplied qnode
**
** @param[in] qn   The qnode to be put on the free list
*/
static void qnode_free( qnode_t *qn ) {
	// sanity check!
	assert1( qn != NULL );
	
	qn->next = free_qnodes;
	free_qnodes = qn;
}

/**
** qnode_add_page()
**
** Extend the set of available qnodes by allocating a page
** of memory and carving it into qnode structures.
*/
static void qnode_add_page( void ) {
	qnode_t *block;

	// allocate a page of memory
	block = (qnode_t *) km_page_alloc( 1 );

	assert( block != NULL );

	// iterate through it, deallocating each qnode
	for( int i = 0; i < QNODES_PER_PAGE; ++i, ++block ) {
		qnode_free( block );
	}
}

/**
** qnode_alloc()
**
** Allocate a qnode
**
** @return A pointer to the allocated node, or NULL
*/
static qnode_t *qnode_alloc( void ) {
	qnode_t *tmp;
	
	// if the list is empty, grab another slice and repopulate it
	if( free_qnodes == NULL ) {
		qnode_add_page();
		// if it's still empty, we're done
		if( free_qnodes == NULL ) {
			return NULL;
		}
	}
	
	// take the first node from the list
	tmp = free_qnodes;
	free_qnodes = tmp->next;

	// make sure we clean it out
	memclr( tmp, sizeof(qnode_t) );
	
	return tmp;
}
	
/*
** PUBLIC FUNCTIONS
*/

/*
** Debugging/tracing routines
*/

/**
** que_dump(msg,que)
**
** dump the contents of the specified queue_t to the console
**
** @param[in] msg  Optional message to print
** @param[in] q    queue_t to dump
*/
void que_dump( const char *msg, queue_t q ) {

    // report on this queue
    cio_printf( "%s: ", msg ? msg : "???" );
    if( q == NULL ) {
        cio_puts( "NULL???\n" );
        return;
    }

    // first, the basic data
    cio_printf( "head %08x tail %08x len %d",
                  (uint32_t) q->head, (uint32_t) q->tail, q->count );

    // next, how the queue is ordered
    if( q->compare ) {
        cio_printf( " compare %08x\n", (uint32_t) q->compare );
    } else {
        cio_puts( " FIFO\n" );
    }

    // if there are members in the queue, dump the first nodes
    if( q->count > 0 ) {
        cio_puts( " data: " );
        qnode_t *tmp = q->head;
        for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
            cio_printf( " [%08x]", (uint32_t) tmp->data );
        }

        if( tmp != NULL ) {
            cio_puts( " ..." );
        }

        cio_putchar( '\n' );
    }
}

/*
** Queue operations
*/

/**
** que_init()
**
** Initialize the queue module.
*/
void que_init( void ) {

#if TRACING_INIT
	cio_puts( " Que" );
#endif

	// clear out the queue data structures
	memclr( queues, sizeof(queues) );

	// set all the "free" flags
	memset( queue_free, sizeof(queue_free), QUE_FREE );

	// reset the free list (just in case)
	free_qnodes = NULL;

	// create the first set of qnodes for use
	qnode_add_page();
}

/**
** queue_alloc()
**
** Allocate and initialize a queue.
**
** @param[in] compare  Pointer to the ordering function for the queue, or NULL
**
** @return A pointer to the allocated queue, or NULL on failure
*/
queue_t que_alloc( compare_t compare ) {

#if TRACING_QUEUE
	cio_printf( "+++ qalloc(%08x)", (uint32_t) compare );
#endif

	// locate a free queue
	int i;

	for( i = 0; i < N_QUEUES; ++i ) {
		if( queue_free[i] ) {
			break;
		}
	}

#if TRACING_QUEUE
	cio_printf( " search ix %d", i );
#endif

	// did we find one?
	if( i >= N_QUEUES ) {
		// nope!
#if TRACING_QUEUE
	cio_puts( " NONE FREE?\n" );
#endif
		return NULL;
	}

	// found one - let's use it
	queue_t q = &queues[i];
	queue_free[i] = QUE_INUSE;

	// make sure it's cleaned out
	q->head = q->tail = NULL;
	q->count = 0;
	q->compare = compare;
#if TRACING_QUEUE
	cio_printf( " addr %08x\n", (uint32_t) q );
	que_dump( "new q", q );
#endif
	
	// send it on its way
	return q;
}

/**
** que_free()
**
** Deallocate a queue.
**
** @param[in,out] q     The queue to be deallocated
**
** If the parameter is NULL or invalid, panics.
*/
void que_free( queue_t q ) {

#if TRACING_QUEUE
	cio_printf( "qfree(%08x)", (uint32_t) q );
#endif

	// which queue was it?
	int ix = que_ix( q );
#if TRACING_QUEUE
	cio_printf( " ix %d, free[ix] %u", ix, queue_free[ix] );
#endif

	if( ix < 0 ) {
		kpanic( "que_free, bad queue pointer" );
	}

	// valid index - is it in use?
	if( queue_free[ix] ) {
		kpanic( "que_free of already-free queue" );
	}

	// all is well - return the queue to the free list
	queue_free[ix] = QUE_FREE;
	q->head = q->tail = NULL;
	q->compare = NULL;
	q->count = 0;
}

/**
** que_length()
**
** Return the occupancy count of a queue.
**
** @param[in] q     The queue to be examined
**
** @return The occupancy count
**
** If the parameter is NULL or invalid, panics.
*/
int que_length( queue_t q ) {

	// get the queue index
	int ix = que_ix( q );

	if( ix < 0 ) {
		kpanic( "que_length, bad que pointer" );
	}

	// is the queue in use?
	if( queue_free[ix] ) {
		kpanic( "que_length, unallocated queue" );
	}

	// all is well - return the occupancy

	return q->count;
}

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
int que_insert( queue_t q, void *data ) {

	// validate the queue parameter
	assert1( que_ix(q) >= 0 );
	
	// to insert, we'll need a qnode
	qnode_t *qn = qnode_alloc();
	if( qn == NULL ) {
		return E_NO_QNODES;
	}
	
	// value being inserted
	qn->data = data;
	
	// if the queue is empty, we don't care about ordering
	if( q->count == 0 ) {

		// sanity check of "empty" - pointers should both be NULL
		// if there's nothing in the queue
		assert1( q->head == NULL && q->tail == NULL );

		// this is the new first and last node in the queue
		q->head = q->tail = qn;

		// this is the only thing in the queue
		q->count = 1;

		return E_SUCCESS;
	}
	
	// sanity check - pointers should not be NULL
	// if the queue isn't empty
	assert1( q->head != NULL && q->tail != NULL );
	
	/*
	** Queues can be ordered or FIFO. If there is no comparison
	** function for the queue, it's FIFO, so we just append the
	** new value.
	*/

	if( q->compare == NULL ) {

		// add after current "last" element
		q->tail->next = qn;

		// this is now the tail end
		q->tail = qn;

		// track occupancy
		q->count += 1;

		return E_SUCCESS;
	}

	/*
	** If we are here, this must be an ordered queue. We need to
	** traverse the queue looking for the first entry that must be
	** after the value we're inserting.
	*/

	register compare_t fcn = q->compare;
	register qnode_t *prev, *curr;
	
	// begin at the front, and do a standard hand-over-hand traversal
	prev = NULL;
	curr = q->head;
	
	/*
	** The comparison function returns:
	**
	**     < 0 if p1 < p2
	**     = 0 if p1 == p2
	**     > 0 if p1 > p2
	**
	** What '<', '=', and '>' mean may vary; we treat it
	** as a simple ascending ordering.
	*/
	while( curr != NULL && fcn(data,curr->data) >= 0 ) {
		prev = curr;
		curr = curr->next;
	}

	/*
	** We have the insertion point. Here are the possible situations:
	**
	**    prev   curr   meaning
	**    =====  =====  ======================
	**    NULL   NULL   can't happen (queue would be empty)
	**    NULL   !NULL  inserting at beginning (new 'head')
	**    !NULL  !NULL  inserting between 'prev' and 'curr'
	**    !NULL  NULL   appending after 'prev' (new 'tail')
	*/

	// always true, even if appending
	qn->next = curr;

	if( prev == NULL ) {

		// inserting at beginning, so this is a new 'head' entry
		q->head = qn;

	} else {

		// middle or end insertion, so predecessor points to new entry
		prev->next = qn;

		// if there is no successor, this is the new 'tail' entry
		if( curr == NULL ) {
			q->tail = qn;
		}

	}

	// one more thing in the queue
	q->count += 1;

	return E_SUCCESS;
}

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
int que_peek( queue_t q, void **data ) {

	// NULL q means real problems
	assert1( q != NULL );

	// NULL data pointer might be recoverable
	if( data == NULL ) {
		return E_BAD_PARAM;
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
		return E_EMPTY;
	}
	
	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );
	
	// all we need is the data field from the 'head' node
	*data = q->head->data;
	
	return E_SUCCESS;
}

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
int que_remove( queue_t q, void **data ) {

	// NULL q means real problems
	assert1( q != NULL );

	// NULL data pointer might be recoverable
	if( data == NULL ) {
		return E_BAD_PARAM;
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
		return E_EMPTY;
	}

	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );
	
	// get the first node and retrieve the data field from it
	qnode_t *qn = q->head;
	*data = qn->data;
	
	// second node is now the new 'head' of the queue
	q->head = qn->next;
	if( q->head == NULL ) {
		// if there wasn't one, also reset the tail pointer
		q->tail = NULL;
	}
	
	// one fewer entry
	q->count -= 1;
	
	// release the qnode
	qnode_free( qn );
	
	return E_SUCCESS;
}

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
int que_remove_by( queue_t q, void *data ) {

	// NULL q means real problems
	assert1( q != NULL );

	// NULL data pointer might be recoverable
	if( data == NULL ) {
		return E_BAD_PARAM;
	}
	
	// can't return anything if the queue is empty!
	if( q->count < 1 ) {
		return E_EMPTY;
	}

	// non-zero count means the pointers can't be NULL
	assert1( q->head != NULL && q->tail != NULL );

	// standard hand-over-hand traversal
	register qnode_t *prev, *curr;
	
	prev = NULL;
	curr = q->head;
	
	/*
	** We walk the queue until either we run off the end, or
	** we find a node containing the desired data value.
	*/
	while( curr != NULL && data != curr->data ) {
		prev = curr;
		curr = curr->next;
	}
	
	// did we find the entry?
	if( curr == NULL ) {
		return E_NOT_FOUND;
	}

	// found it - was it the first node?
	if( prev == NULL ) {
		// yes, so there's a new head node
		q->head = curr->next;
	} else {
		// no, so the predecessor must point to the successor
		prev->next = curr->next;
	}
	
	// if there is no successor, we removed the last entry
	if( curr->next == NULL ) {
		q->tail = prev;
	}

	// it's gone
	q->count -= 1;	
	
	// return the qnode to the free pool
	qnode_free( curr );
		
	return E_SUCCESS;
}
