/*
 * @file rbtrees.h
 *
 * @author Julien A Bitang
 *
 * @brief Red Black Tree module delcaration
 *
 * A generic, opaque red black tree implementation. Primarily used for
 * scheduler.
 *
 * view also: rbtrees.c
 */

#ifndef RBTREE_H_
#define RBTREE_H_

#include "common.h"

// Red-Black Tree as seen by the outside.
typedef struct rbtree_s *rbtree_t;

// A comparison function.
typedef int (*compare_t)(const void *, const void *);

/*
 * rbtree_dump(cost char *msg,rbtree_t t)
 *
 * dump the contents o the specified rbtree_t to console.
 *
 * @param[in] msg Optional message to print
 * @param[in] t rbtree_t to dump
 */
void rbtree_dump(const char *msg, rbtree_t t);

/*
 * rbtree_init()
 *
 * Initialize rbtree module.
 */
void rbtree_init(void);

/*
 * rbtree_alloc()
 *
 * Allocs memory for a new red-black tree.
 *
 * @param[in] Optional compare Pointer to comparison function for tree, NULL
 * indicates no comparison.
 *
 * @return A pointer to allocated tree, or NULL on failure
 */
rbtree_t rbtree_alloc(compare_t compare);

/*
 *  rbtree_free(rbtree_t t)
 *
 *  Deallocates a red-black tree.
 *
 * @param[in,out] t the tree to be deallocated
 *
 * if parameter is NULL or invalid, panics.
 */
void rbtree_free(rbtree_t t);

/*
 *  rbtree_size(rbtree_t)
 *
 *  Returns the number of none-nil nodes in tree.
 *
 *  @param[in] t the tree to be examined.
 *
 *  @return the none-nil node count.
 *
 *  Panics if t is NULL or invalid
 */
int rbtree_size(rbtree_t t);

/*
 *  rbtree_insert(rbtree_t t, void *data)
 *
 *  Add an entry to the tree.
 *
 *  @param[in,out] t    the tree to be manipulated
 *  @param[in]     data the value of data to be added
 *
 *  @return The insertion status
 */
int rbtree_insert(rbtree_t t, void *data);

/*
 *  rbtree_peek(rbtree_t t, void **data)
 *
 *  peeks at the left most leaf in the tree.
 *
 *  @param[in]  t    The tree to be examined
 *  @param[out] data Where to save the value from first tree node
 *
 *  @return E_SUCCESS if there was an entry; error code otherwise.
 */
int rbtree_peek(rbtree_t t, void **data);

/*
 * rbtree_remove(rbtree_t t, void **data)
 *
 *  @param[in,out] t    The tree to be manipulated.
 *  @param[out]    data Where to save the removed data value.
 *
 *  @return the removal status.
 */
int rbtree_remove(rbtree_t t, void **data);

#endif
