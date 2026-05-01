/*
** @file    procs.c
**
** @author  CSCI-452 class of 20255
**
** @brief   Process-related implementations
**
** Our process table is an array of statically-allocated PCB structures.
** We allocate PCBs by scanning the table, looking for an entry whose
** state is STATE_UNUSED; we deallocate a PCB by setting its state to
** STATE_UNUSED.
**
** If a PCB's state is STATE_UNUSED, none of the other data in the PCB
** is valid.
**
** NOTE: if this module is changed to use dynamic allocation, most of
** the functions here will need to be rewritten. Look for the line
**
**     ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** in the header comment for the function.
*/

#define KERNEL_SRC

#include <common.h>

#include <clock.h>
#include <kmem.h>
#include <memory.h>
#include <procs.h>
#include <queues.h>
#include <stacks.h>

/*
** PRIVATE DEFINITIONS
*/

/*
** PRIVATE DATA TYPES
*/

/*
** PRIVATE GLOBAL VARIABLES
*/
static time_t last_dispatch = 0;
/*
** PUBLIC GLOBAL VARIABLES
*/

// public-facing queue handles
rbtree_t ready;
queue_t sleeping;
queue_t zombie;
queue_t blocked;
queue_t sioread;

// pointer to the currently-running process
pcb_t *current;

// the process table
pcb_t ptable[N_PROCS];

// next available PID
pid_t next_pid;

// pointer to the PCB for the 'init' process
pcb_t *init_pcb;

// table of state name strings
const char state_str[N_STATES][4] = {
    [STATE_UNUSED] = "Unu",   // pcb is free
    [STATE_NEW] = "New",      // allocated, but not yet runnable
    [STATE_READY] = "Rdy",    // ready for execution
    [STATE_RUNNING] = "Run",  // currently executing
    [STATE_SLEEPING] = "Slp", // sleeping
    [STATE_BLOCKED] = "Blk",  // blocked for some reason
    [STATE_ZOMBIE] = "Zom"    // terminated but not yet reaped
};

//// table of priority name strings
// const char prio_str[N_PRIOS][5] = {
//    [PRIO_HIGH] = "High", [PRIO_STD] = "Std ", [PRIO_LOW] = "Low "};
//

/*
** PRIVATE FUNCTIONS
*/

/**
** pcb_ix()
**
** Calculate the index of a PCB in the process table.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[in] p  The PCB to be checked
**
** @return The index (0..N_PROCS-1) if valid, else -1
*/
static int pcb_ix(pcb_t *p) {

  int ix = p - &ptable[0];

  if (ix < 0 || ix >= N_PROCS) {
    return -1;
  }

  return ix;
}

/**
** comp_wakeup()
**
** Comparison function for queue sorting; orders the
** queue in ascending order by wakeup time.
**
** @param p1   First PCB
** @param p2   Second PCB
**
** @return integer indicating the relationship between the wakeup times:
**   < 0 --> 'p1' < 'p2'
**   = 0 --> 'p1' = 'p2'
**   > 0 --> 'p1' > 'p2'
*/
static int comp_wakeup(const void *p1, const void *p2) {
  time_t w1 = ((pcb_t *)p1)->wakeup;
  time_t w2 = ((pcb_t *)p2)->wakeup;

  if (w1 < w2)
    return -1;
  else if (w1 == w2)
    return 0;
  else
    return 1;
}

/**
** comp_vruntime()
**
** Comparison function for red-black tree sorting.
** Compares the virtual runtime of two processes.
**
** @param p1   First PCB
** @param p2   Second PCB
**
** @return integer indicating the relationship between the virtual runtimes:
**   < 0 --> 'p1' < 'p2'
**   = 0 --> 'p1' = 'p2'
**   > 0 --> 'p1' > 'p2'
*/
static int comp_vruntime(const void *p1, const void *p2) {
  int32_t vr1 = ((pcb_t *)p1)->vruntime;
  int32_t vr2 = ((pcb_t *)p2)->vruntime;

  assert1(vr1 >= 0);
  assert1(vr2 >= 0);

  return vr1 - vr2;
}

/*
** PUBLIC FUNCTIONS
*/

/*
** Debugging/tracing routines
*/

/**
** Name:    ctx_sanity_check
**
** Performs a "sanity check" on the user context
**
** @param ctx[in]   A pointer to the context to be checked
*/
void ctx_sanity_check(register context_t *c) {
  bool_t any = false;

  // check the segment registers
  if (c->cs != GDT_CODE || c->ss != GDT_STACK || c->gs != GDT_DATA ||
      c->fs != GDT_DATA || c->es != GDT_DATA || c->ds != GDT_DATA) {
    any = true;
    cio_printf("CTXchk: cs %04x ss %04x ds %04x es %04x fs %04x gs %04x\n",
               c->cs, c->ss, c->ds, c->es, c->fs, c->gs);
  }

  // ESP and EBP should be in the range 0x100000..0x200000 if non-zero
  // because the stacks are allocated starting in the second MB of memory
  // EIP should be in the range 0x10000..0x40000 because that's where
  // all the code is
  if ((c->esp != 0 && (c->esp < 0x100000 || c->esp > 0x200000)) ||
      (c->ebp != 0 && (c->ebp < 0x100000 || c->ebp > 0x200000)) ||
      c->eip < 0x10000 || c->eip > 0x40000) {
    any = true;
    cio_printf("        esp %08x ebp %08x eip %08x\n", c->esp, c->ebp, c->eip);
  }

  if (any) {
    if (current != NULL) {
      pcb_dump("current process", current, true);
      cio_putchar('\n');
    }
    // delay, because we're probably in trouble
    delay(DELAY_10_SEC);
  }
}

/**
** ctx_dump(msg,context)
**
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump(const char *msg, register context_t *c) {

  // first, the message (if there is one)
  if (msg) {
    cio_puts(msg);
  }

  // the pointer
  cio_printf(" @ %08x:\n", (uint32_t)c);

  // if it's NULL, why did you bother calling me?
  if (c == NULL) {
    cio_puts(" NULL???\n");
    return;
  }

  // now, the contents
  cio_printf("  ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
             c->ss & 0xff, c->gs & 0xff, c->fs & 0xff, c->es & 0xff,
             c->ds & 0xff, c->cs & 0xff);
  cio_printf("  edi %08x esi %08x ebp %08x esp %08x\n", c->edi, c->esi, c->ebp,
             c->esp);
  cio_printf("  ebx %08x edx %08x ecx %08x eax %08x\n", c->ebx, c->edx, c->ecx,
             c->eax);
  cio_printf("  vec %08x cod %08x eip %08x efl %08x\n", c->vector, c->code,
             c->eip, c->eflags);
}

/**
** ctx_dump_all(msg)
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all(const char *msg) {

  if (msg != NULL) {
    cio_puts(msg);
  }

  int n = 0;
  register pcb_t *pcb = ptable;
  for (int i = 0; i < N_PROCS; ++i, ++pcb) {
    if (pcb->state != STATE_UNUSED) {
      ++n;
      cio_printf("%2d(%d): ", n, pcb->pid);
      ctx_dump(NULL, pcb->context);
    }
  }
}

/**
** pcb_dump(msg,pcb,all)
**
** Dumps the contents of this PCB to the console
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump(const char *msg, register pcb_t *pcb, bool_t all) {

  // first, the message (if there is one)
  if (msg) {
    cio_puts(msg);
  }

  // the pointer
  cio_printf(" @ %08x:", (uint32_t)pcb);

  // if it's NULL, why did you bother calling me?
  if (pcb == NULL) {
    cio_puts(" NULL???\n");
    return;
  }

  cio_printf(" %d %s", pcb->pid,
             pcb->state >= N_STATES ? "???" : state_str[pcb->state]);

  if (!all) {
    // just printing IDs and states on one line
    return;
  }

  // now, the rest of the contents
  cio_printf(" vruntime %u", pcb->vruntime);

  cio_printf(" xit %d wake %08x\n", pcb->status, pcb->wakeup);

  cio_printf(" parent %08x", (uint32_t)pcb->parent);
  if (pcb->parent != NULL) {
    cio_printf(" (%u)", pcb->parent->pid);
  }

  cio_printf(" context %08x stk %08x", (uint32_t)pcb->context,
             (uint32_t)pcb->stack);

  cio_printf(" fill");
  for (int i = 0; i < sizeof(pcb->filler); ++i) {
    cio_putchar(' ');
    put_char_or_code(pcb->filler[i]);
  }

  cio_putchar('\n');
}

/**
** ptable_dump(msg,all)
**
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump(const char *msg, bool_t all) {

  if (msg) {
    cio_puts(msg);
  }
  cio_putchar(' ');

  int used = 0;
  int empty = 0;

  register pcb_t *pcb = ptable;
  for (int i = 0; i < N_PROCS; ++i, ++pcb) {
    if (pcb->state == STATE_UNUSED) {

      // an empty slot
      ++empty;

    } else {

      // a non-empty slot
      ++used;

      // if not dumping everything, add commas if needed
      if (!all && used) {
        cio_putchar(',');
      }

      // report the table slot #
      cio_printf(" #%d:", i);

      // and dump the contents
      pcb_dump(NULL, pcb, all);
    }
  }

  // only need this if we're doing one-line output
  if (!all) {
    cio_putchar('\n');
  }

  // sanity check - make sure we saw the correct number of table slots
  if ((used + empty) != N_PROCS) {
    cio_printf("Table size %d, used %d + empty %d = %d???\n", N_PROCS, used,
               empty, used + empty);
  }
}

/**
** Name:    ptable_dump_stats
**
* Calculate the number of processes in each state, and either
** print that information out, or return it through a parameter.
**
** @param tbl  Table to use, or NULL
**
** @return The number of process table entries in an "unknown" state.
*/
uint32_t ptable_dump_stats(uint32_t *tbl) {
  uint32_t nstate[N_STATES];
  memclr(nstate, sizeof(nstate));
  uint32_t unknown = 0;

  int n = 0;
  pcb_t *ptr = ptable;
  while (n < N_PROCS) {
    if (ptr->state < 0 || ptr->state >= N_STATES) {
      ++unknown;
    } else {
      ++nstate[ptr->state];
    }
    ++n;
    ++ptr;
  }

  // if tbl is not NULL, we just want the data
  if (tbl != NULL) {
    memcpy(tbl, nstate, sizeof(nstate));
    return unknown;
  }

  // report the data
  cio_printf("Ptable: %u ???", unknown);
  for (n = 0; n < N_STATES; ++n) {
    if (nstate[n]) {
      cio_printf(" %u %s", nstate[n], state_str[n]);
    }
  }
  cio_putchar('\n');

  return unknown;
}

/*
** Process operations
*/

/**
** pcb_init()
**
** Initialize the process module.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
*/
void pcb_init(void) {

#if TRACING_INIT
  cio_puts(" PCB");
#endif

  // start with the process table
  memclr(ptable, sizeof(ptable));

  // next, set up the queues

  /** Old code :)
      assert( (ready[PRIO_HIGH] = que_alloc(NULL)) != NULL );
      assert( (ready[PRIO_STD]  = que_alloc(NULL)) != NULL );
      assert( (ready[PRIO_LOW]  = que_alloc(NULL)) != NULL );
  */

  assert((ready = rbtree_alloc(comp_vruntime)) != NULL);
  assert((sleeping = que_alloc(comp_wakeup)) != NULL);
  assert((zombie = que_alloc(NULL)) != NULL);
  assert((blocked = que_alloc(NULL)) != NULL);
  assert((sioread = que_alloc(NULL)) != NULL);

  // prep all the other variables
  current = NULL;
  init_pcb = NULL;
  next_pid = FIRST_USER_PID;
}

/**
** pcb_alloc()
**
** Allocate an unused PCB from the process table.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[out] pcb   Pointer to a pcb_t * where the pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc(pcb_t **pcb) {

  // sanity check!
  assert1(pcb != NULL);

  // locate the first unused PCB in the table
  register pcb_t *p;
  for (p = ptable; p < &ptable[N_PROCS]; ++p) {
    // did we find one?
    if (p->state == STATE_UNUSED) {
      // yes!
      *pcb = p;
      return E_SUCCESS;
    }
  }

  // sorry, nothing's free
  return E_NO_PCBS;
}

/**
** pcb_free()
**
** Return a PCB to the list of free PCBs.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[out] pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free(pcb_t *pcb) {

  // sanity check
  assert1(pcb != NULL);

  // mark the PCB as available
  pcb->state = STATE_UNUSED;
}

/**
** pcb_find_pid()
**
** Locate the PCB for the process with the specified PID
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[in] pid   The PID to be located
**
** @return Pointer to the PCB, or NULL if not found
*/
pcb_t *pcb_find_pid(pid_t pid) {

  // must be a valid PID
  assert1(pid >= FIRST_USER_PID);

  // scan the process table
  register pcb_t *p = ptable;

  // find an entry whose PID matches our parameter
  // AND which isn't an "unused" PCB
  for (p = ptable; p < &ptable[N_PROCS]; ++p) {
    // see if the pids match and this PCB is in use
    if (p->pid == pid && p->state != STATE_UNUSED) {
      return p;
    }
  }

  // didn't find it!
  return NULL;
}

/**
** pcb_find_child_of()
**
** Locate the PCB for a process whose parent is the supplied PCB.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[in] parent   Pointer to the parent's PCB
**
** @return Pointer to the child's PCB, or NULL
*/
pcb_t *pcb_find_child_of(register pcb_t *parent) {

  // must be a valid PCB pointer
  assert1(parent >= ptable && parent < &ptable[N_PROCS]);

  // scan the process table
  register pcb_t *p = ptable;

  // find an entry whose parent pointer matches our parameter
  // AND which isn't an "unused" PCB
  for (p = ptable; p < &ptable[N_PROCS]; ++p) {
    if (p != parent && p->parent == parent && p->state != STATE_UNUSED) {
      return p;
    }
  }

  // didn't find it!
  return NULL;
}

/**
** Name:	pcb_zombify
**
** Turn the indicated process into a Zombie. This function
** performs work for exit().
**
** We could move the reparenting code from exit() here if we
** wanted to implement another syscall that could zombify a
** process (e.g., kill() or something similar).
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify(register pcb_t *pcb) {

#if TRACING_PCB
  cio_printf("** pcb_zombify(0x%08x)\n", (uint32_t)pcb);
#endif

  // should this be an error?
  if (pcb == NULL) {
    return;
  }

  // mark this process as a zombie
  pcb->state = STATE_ZOMBIE;

  // queue it up
  assert(que_insert(zombie, pcb) == E_SUCCESS);

  /*
  ** Note: we don't call _dispatch() here - we leave that for
  ** the calling routine, as it's possible we don't need to
  ** choose a new current process.
  */
}

/**
** Name:	pcb_cleanup
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup(pcb_t *pcb) {

#if TRACING_PCB
  cio_printf("** pcb_cleanup(0x%08x)\n", (uint32_t)pcb);
#endif

  // avoid deallocating a NULL pointer
  if (pcb == NULL) {
    // should this be an error?
    return;
  }

  // release the stack if we need to
  if (pcb->stack != NULL) {
    stk_free(pcb->stack);
    // just to be safe
    pcb->stack = NULL;
  }

  // release the PCB itself
  pcb_free(pcb);
}

/*
** Scheduler routines
*/

/**
** schedule(pcb)
**
** Schedule the supplied process
**
** @param pcb[in,out]   Pointer to the PCB of the process to be scheduled
*/
void schedule(pcb_t *p) {
#if TRACING_SCHED
  cio_printf("schedule(%08x)\n", (uint32_t)p);
#endif

  // sanity check - bad pointer
  assert1(pcb_ix(p) >= 0);

  if (rbtree_insert(ready, p) == E_NO_RBTNODES) {
    PANIC(0, "Schedule(): Failed to insert Process; no free nodes remaining!");
  }
  // verify the priority value is good
  // assert1(p->priority >= PRIO_FIRST && p->priority <= PRIO_LAST);

  // add it to the ready queue
  //  if (que_insert(ready[p->priority], p) != E_SUCCESS) {
  //    PANIC(0, "schedule, que insert fail");
  //  }

  // mark it as ready
  p->state = STATE_READY;
}

/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch(void) {
  uint32_t elapsed = system_time - last_dispatch;
  if (current != NULL) {
    current->vruntime += elapsed;
  }

  pcb_t *p = NULL;

#if TRACING_DISPATCH
  cio_puts("dispatch(), checking");
#endif

  // grab whoever is at the head of the highest queue
  //  for (int i = PRIO_FIRST; i <= PRIO_LAST; ++i) {
  // #if TRACING_DISPATCH
  //    cio_printf(" %d", i);
  // #endif
  //    if (que_remove(ready[i], (void **)&p) == E_SUCCESS) {
  // #if TRACING_DISPATCH
  //      cio_puts(" HIT");
  // #endif
  //      break;
  //    }
  //  }

  switch (rbtree_remove(ready, (void **)&p)) {
  case E_BAD_PARAM:
    kpanic("Dispatch(): Null Pointer Given!");
    break;
  case E_EMPTY:
    kpanic("Dispatch(): Run tree is empty!");
    break;
  }

  assert(p != NULL);
#if TRACING_DISPATCH
  pcb_dump("dispatching pcb", p, true);
#endif

  // set the process up for success
  current = p;
  current->state = STATE_RUNNING;
  current->quantum = Q_STD;
  last_dispatch = system_time;
}
