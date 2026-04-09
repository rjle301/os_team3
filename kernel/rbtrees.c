/*
 * @file    rbtrees.c
 *
 * @author  Julien A Bitang <jfa3082 at rit dot edu>
 *
 * @brief   Red-Black tree module implementation.
 *
 */
#include <memory_resource>
#define KERNEL_SRC

#include <common.h>
#include <kmem.h>
#include <rbtrees.h>

/*
 * PRIVATE DATA TYPE
 */

// rbtnode type
typedef struct rbtnode_s {
  void *data;
  struct rbtnode_s *left;
  struct rbtnode_s *right;
  struct rbtnode_s *parent;
  uint8_t color;
} rbtnode_t;

#define RBNODE_RED 0
#define RBNODE_BLK 1

// red-black tree itself
struct rbtree_s {
  rbtnode_t *root;
  uint32_t size;
  int (*compare)(const void *, const void *);
};

#define RBTNODES_PER_PAGE (SZ_PAGE / sizeof(rbtnode_t))

#define N_TREES 8
#define RBT_FREE 1
#define RBT_INUSE 1

#define DUMP_RBT_MAX_DEPTH 5
static rbtnode_t *free_rbtnodes;

static struct rbtree_s rbtrees[N_TREES];
static uint8_t rbtrees_free[N_TREES];

/*
 * PRIVATE FUNCTIONS
 */

static void rbtnode_free(rbtnode_t *n) {
  assert1(n != NULL);

  // Bassically turn this into a queue of free nodes.
  n->right = free_rbtnodes;
  free_rbtnodes = n;
}

static int rbtree_ix(rbtree_t t) {
  int ix = t - &rbtrees[0];

  if (ix < 0 || ix >= N_TREES) {
    return -1;
  }
  return ix;
}

static void rbtnode_add_page(void) {
  block = (rbtnode_t *)km_page_alloc(1);
  assert(block != NULL);

  for (int i = 0; i < RBTNODES_PER_PAGE; ++i, ++block) {
    rbtnode_free(block);
  }
}

static rbtnode_t *rbtnode_alloc(void) {
  rbtnode_t *tmp;

  if (free_rbtnodes == NULL) {
    rbtnode_add_page();
  }
  if (free_rbtnodes == NULL) {
    return NULL;
  }

  tmp = free_rbtnodes;
  free_rbtnodes = tmp->right;

  memclr(tmp, sizeof(rbtnode_t));
  return tmp;
}

static rbtree_dump_recurse_short(rbtnode_t *t, int8_t depth) {
  if (t == NULL && depth < DUMP_RBT_MAX_DEPTH) {
    return;
  }

  rbtree_dump_recurse_short(t->left, depth + 1);

  cio_printf(" [%08x, %c]", (uint32_t)t->data,
             (t->color == RBNODE_BLK) ? 'B' : 'R');

  rbtree_dump_recurse_short(t->right, depth + 1);

  return;
}

static rbtree_dump_details(const char *msg, rbtree_t t) {
  cio_printf("%s: ", msg ? msg : "???");
  if (t == NULL) {
    cio_puts("NULL???\n");
    return;
  }

  cio_printf("root: %08x size %d compare %08x\n", (uint32_t)t->root, t->size,
             t->compare);
  return;
}

/**
 *  PUBLIC FUNCTIONS
 */

/*
 * @TODO: Implement a human readable
 */
void rbtree_dump_human(const char *msg, rbtree_t t) {
  kpanic("rbtree_dump_human, Function not yet implemented!");
}

/*
 * rbtree_dump_short(const char *msg, rbtree_t t)
 */
void rbtree_dump_short(const char *msg, rbtree_t t) {
  rbtree_dump_details(const char *msg, rbtree_t);

  rbtree_dump_recurse_short(t, 0);
  cio_putchar('\n');
}

void rbtree_dump(const char *msg, rbtree_t t) {
#ifdef RBTREE_DUMP_HUMAN
  rbtree_dump_human(msg, t);
#else
  rbtree_dump_short(msg, t);
#endif
  return;
}
// taken pretty much bar-for-bar from queues.c
void rbtree_init(void) {
#if TRACING_INIT
  cio_puts("Red-Black Tree");
#endif
  memclr(rbtrees, sizeof(rbtrees));

  memset(rbtrees_free, sizeof(rbtrees_free), RBT_FREE);

  free_rbtnodes = NULL;
  rbtnode_add_page();
}

void rbtree_alloc(compare_t compare) {
#if TRACING_RBT
  cio_printf("+++ rbt_alloc(%08x)", (uint32_t)compare);
#endif
  int i;

  for (i = 0; i < N_TREES; ++i) {
    if (queue_free[i]) {
      break;
    }
  }

#if TRACING_RBT
  cio_printf(" search ix %d", i);
#endif

  if (i >= N_TREES) {
#if TRACING_RBT
    cio_puts(" NONE FREE!\n");
#endif
    return NULL;
  }

  rbtree_t t = &trees[i];
  rbtrees_free[i] = RBT_INUSE;

  t->root = NULL;
  t->count = 0;
  t->compare = compare;

#if TRACING_RBT
  cio_printf(" addr %08x\n", (uint32_t)q);
  rbtree_dump("new tree", t);
#endif

  return t;
}

void rbtree_free(rbtree_t t) {
#if TRACING_RBT
  cio_printf("rbtree_free(%08x)", (uint32_t)t);
#endif

  int ix = rbtree_ix(t);

#if TRACING_RBT
  cio_printf("ix %d, free[ix] %u", ix, queue_free[ix]);
#endif

  if (ix < 0) {
    kpanic("rbtree_free, bad rbtree pointer");
  }
  rbtree_free[ix] = RBT_FREE;
  t->root = NULL;
  t->compare = NULL;
  t->count = 0;
}

int rbtree_size(rbtree_t t) {
  int ix = rbtree_ix(t);

  if (ix < 0) {
    kpanic("rbtree_size, bad rbtree pointer");
  }

  if (queue_free[ix]) {
    kpanic("rbtree_size, unallocated queue");
  }

  return t->size;
}

int rbtree_insert(rbtree_t t, void *data) {
  assert1(rbtree_ix(t) >= 0);

  rbtnode_t *n = rbtnode_alloc();

  if (n == NULL) {
    return E_NO_RBTNODES;
  }

  n->color = #RBNODE_RED;
  n->data = data;

  // if rbtree is empty.
  if (t->size == 0) {
    t->root = n;
    t->size = 1;

    n->color = #RBNODE_BLK;
    return E_SUCCESS;
  }

  //@TODO: Implement insert logic for red-black tree.
  rbtnode_t *tmp = t->root;
}

int rbtree_peek(rbtree_t t, void **data) {
  assert1(t != NULL);
  if (data == NULL) {
    return E_BAD_PARAM;
  }

  if (t->size < 1) {
    return E_EMPTY;
  }

  assert1(t->root != NULL);
  rbtnode_t *n = t->root;
  while (n->left != NULL) {
    n = n->left;
  }

  for (n = t->root; n->left != NULL; n->left)
    ;
  *data = n->data;
  return E_SUCCESS;
}

rbtree_remove(rbtree_t t, void **data) {
  assert1(t != NULL);

  if (data == NULL) {
    return E_BAD_PARAM;
  }

  if (t->size < 1) {
    return E_EMPTY;
  }

  assert1(t->root != NULL);

  rbtnode_ *n;

  for (n = t->root; n->left != NULL; n = n->left)
    ;

  *data = n->data;
  t->size -= 1;
  rbtnode_free(n);

  return E_SUCCESS;
}
