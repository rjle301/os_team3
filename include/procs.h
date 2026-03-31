/*
** @file    procs.h
**
** @author  CSCI-452 class of 20255
**
** @brief   Process-related declarations
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

#ifndef PROCS_H_
#define PROCS_H_

#include <common.h>

#include <queues.h>

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

/*
** Process states
*/
enum state_e {
  // pre-viable
  STATE_UNUSED = 0,
  STATE_NEW,
  // runnable
  STATE_READY,
  STATE_RUNNING,
  // runnable, but waiting for some event
  STATE_SLEEPING,
  STATE_BLOCKED,
  STATE_WAITING,
  // no longer runnable
  STATE_ZOMBIE
  // sentinel value
  ,
  N_STATES
};

// these may be handy for checking general conditions of processes
// they depend on the order of the state names in the enum!
#define FIRST_VIABLE STATE_READY
#define FIRST_BLOCKED STATE_SLEEPING
#define LAST_VIABLE STATE_WAITING

// process state
typedef uint8_t state_t;

/*
** Process priorities are defined in <defs.h> so that they
** are visible to user-level code.
*/

// quantum values, in clock ticks
// (could be an enum, but we only have one...)
#define Q_STD 3

/*
** PID-related definitions
*/
#define PID_INIT 1
#define FIRST_USER_PID 2

// pid_t is defined in <types.h>

/*
** Process context structure
**
** NOTE:  the order of data members here depends on the
** register save code in isr_stubs.S!!!!
**
** This will be at the top of the user stack when we enter
** an ISR.  In the case of a system call, it will be followed
** by the return address and the system call parameters.
*/

typedef struct context_s {
  uint32_t ss; // pushed by isr_save
  uint32_t gs;
  uint32_t fs;
  uint32_t es;
  uint32_t ds;
  uint32_t edi;
  uint32_t esi;
  uint32_t ebp;
  uint32_t esp;
  uint32_t ebx;
  uint32_t edx;
  uint32_t ecx;
  uint32_t eax;
  uint32_t vector;
  uint32_t code; // pushed by isr_save or the hardware
  uint32_t eip;  // pushed by the hardware
  uint32_t cs;
  uint32_t eflags;
} context_t;
// SZ_CONTEXT is defined in <offsets.h>

/*
** The process control block
**
** Fields are ordered by size to avoid padding
**
** Currently, this is 32 bytes long. It could be reduced in size by
** making the small numeric fields at the end into smaller fields; e.g.,
** 'pid' could be two bytes, and 'state' through 'stkpgs' could be one
** byte each.
**
** It's probably a good idea to keep it as a multiple of 8 or 16 bytes
** to avoid alignment issues when creating an array of PCBs, or keep it
** at a power-of-2 size to simplify splitting a page or slice of memory
** into a collection of PCBs if you switch to dynamic allocation of PCBs.
*/

typedef struct pcb_s {

  // four-byte fields
  // start with these four bytes, for easy access in assembly
  context_t *context; // pointer to context save area on stack

  // Memory information
  uint32_t *stack; // stack for this process

  // process state/environment
  struct pcb_s *parent; // pointer to PCB of our parent process
  uint32_t wakeup;      // wakeup time, for sleeping processes
  int32_t status;       // termination status, for parent's use

  // vruntime
  int32_t vrunttime;

  // these things may not need to be four bytes
  pid_t pid; // PID of this process

  // one-byte fields
  state_t state;   // process' current state
  prio_t priority; // process priority level
  uint8_t quantum; // remaining quantum for this process

  // filler out to 32 bytes
  uint8_t filler[1];

} pcb_t;
// SZ_PCB is defined in <offsets.h>

/*
** Globals
*/

// public-facing process queues
extern queue_t ready[N_PRIOS]; // a MLQ
extern queue_t sleeping;
extern queue_t zombie;
extern queue_t blocked;
extern queue_t sioread;

// pointer to the currently-running process
extern pcb_t *current;

// the process table
extern pcb_t ptable[N_PROCS];

// next available PID
extern pid_t next_pid;

// pointer to the PCB for the 'init' process
extern pcb_t *init_pcb;

// table of state name strings
extern const char state_str[N_STATES][4];

// table of priority name strings
extern const char prio_str[N_PRIOS][5];

/*
** Prototypes
*/

/*
** Debugging/tracing routines
*/

/**
** Name:	ctx_sanity_check
**
** Performs a "sanity check" on the user context
**
** @param ctx[in]   A pointer to the context to be checked
*/
void ctx_sanity_check(register context_t *c);

/**
** Name:	ctx_dump
**
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump(const char *msg, register context_t *c);

/**
** Name:	ctx_dump_all
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all(const char *msg);

/**
** Name:	pcb_dump
**
** Dumps the contents of this PCB to the console
**
** @param msg[in]  An optional message to print before the dump
** @param p[in]    The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump(const char *msg, register pcb_t *p, bool_t all);

/**
** Name:	ptable_dump
**
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump(const char *msg, bool_t all);

/**
** Name:	ptable_dump_stats
**
** Calculate the number of processes in each state, and either
** print that information out, or return it through a parameter.
**
** @param tbl  Table to use, or NULL
**
** @return The number of process table entries in an "unknown" state.
*/
uint32_t ptable_dump_stats(uint_t *tbl);

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
void pcb_init(void);

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
int pcb_alloc(pcb_t **pcb);

/**
** pcb_free()
**
** Return a PCB to the list of free PCBs.
**
** ASSUMES PCBS ARE ALLOCATED STATICALLY.
**
** @param[out] pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free(pcb_t *pcb);

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
pcb_t *pcb_find_pid(pid_t pid);

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
pcb_t *pcb_find_child_of(register pcb_t *parent);

/**
** Name:    pcb_zombify
**
** Turn the indicated process into a Zombie. This function
** performs work for exit().
**
** We could move the reparenting code from exit() here if we
** wanted to implement another syscall that could zombify a
** process (e.g., kill() or something similar).
**
** @param pcb[in,out]   Pointer to the newly-undead PCB
*/
void pcb_zombify(register pcb_t *pcb);

/**
** Name:    pcb_cleanup
**
** Reclaim a process' data structures
**
** @param pcb[in]   The PCB to reclaim
*/
void pcb_cleanup(pcb_t *pcb);

/*
** Scheduler routines
*/

/**
** schedule(pcb)
**
** Schedule the supplied process
**
** @param[in,out] pcb   Pointer to the PCB of the process to be scheduled
*/
void schedule(pcb_t *pcb);

/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch(void);

#endif /* !ASM_SRC */

#endif
