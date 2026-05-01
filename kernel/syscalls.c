/**
** @file	syscalls.c
**
** @author	CSCI-452 class of 20255
**
** @brief	System call implementations
*/

#define KERNEL_SRC

#include <common.h>

#include <cio.h>
#include <clock.h>
#include <device/pro100.h>
#include <kmem.h>
#include <procs.h>
#include <sio.h>
#include <stacks.h>
#include <syscalls.h>
#include <x86/pic.h>
#include <x86/vga.h>

/*
** PRIVATE DEFINITIONS
*/

/*
** Macros to simplify tracing a bit
*/

#if TRACING_SYSCALLS

#define SYSCALL_ENTER(x)                                                       \
  do {                                                                         \
    cio_printf("--> %s, pid %08x", __func__, (uint32_t)(x));                   \
  } while (0)

#else

// compiler optimizes out the empty loops
#define SYSCALL_ENTER(x)                                                       \
  do {                                                                         \
  } while (0)

#endif /* TRACING_SYSCALLS */

#if TRACING_SYSRETS

#define SYSCALL_EXIT(x)                                                        \
  do {                                                                         \
    cio_printf("<-- %s %08x\n", __func__, (uint32_t)(x));                      \
  } while (0)

#else

// compiler optimizes out the empty loops
#define SYSCALL_EXIT(x)                                                        \
  do {                                                                         \
  } while (0)

#endif /* TRACING_SYSRETS */

/*
** PRIVATE DATA TYPES
*/

/*
** PUBLIC GLOBAL VARIABLES
*/

/*
** IMPLEMENTATION FUNCTIONS
*/

// a macro to simplify syscall entry point specification
// we don't declare these static because we may want to call
// some of them from other parts of the kernel
#define SYSIMPL(x) void sys_##x(pcb_t *pcb)

/**
** status_return()
**
** Performs the actual work of returning status information from
** an exiting child to the parent.
**
** Assumes the parent exists and has called wait(), and the child
** exists. We do NOT clean up the child, in case the calling routine
** wants to do more work with it before cleaning it up.
**
** @param parent   The parent receiving the information
** @param child    The exiting child
*/
static void status_return(pcb_t *parent, pcb_t *child) {

  // sanity checks
  assert1(parent != NULL);
  assert1(child != NULL);

  // intrinsic return value is the PID
  RET(parent) = child->pid;

  // may also want to return the exit status
  int32_t *ptr = (int32_t *)ARG(parent, 1);

  /*
  ********************************************************
  ** Potential VM issue here!  This code assigns the exit
  ** status into a variable in the parent's address space.
  ** This works in the baseline because we aren't using
  ** any type of memory protection.  If address space
  ** separation is implemented, this code will very likely
  ** STOP WORKING, and will need to be fixed.
  ********************************************************
  */
  if (ptr != NULL) {
    *ptr = child->status;
  }
}

/*
** Second-level syscall handlers
**
** All have this prototype:
**
**	static void sys_NAME( pcb_t *pcb );
**
** where the parameter 'pcb' is a pointer to the PCB of the process
** making the system call.
**
** Values being returned to the user are placed into the EAX
** field in the context save area for that process.
*/

/**
** sys_exit - terminate the calling process
**
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {

  // sanity checks
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // we'll need to notify the parent that this process has exited
  pcb_t *parent = pcb->parent;

  // make sure the parent actually exists and is a
  // different process than the one that is exiting
  assert1(parent != NULL);
  assert1(parent->state != STATE_UNUSED);
  assert1(parent != pcb);

  // grab the termination status
  pcb->status = ARG(pcb, 1);

  // find all children of this process and reparent them
  pcb_t *for_init = NULL;
  do {
    pcb_t *next = pcb_find_child_of(pcb);
    if (next == NULL) {
      // none found
      break;
    }

    // probably not necessary, but for now...
    assert1(next->parent == pcb);

    // found a child
    next->parent = init_pcb;

    // if it has exited, we'll need to wake up init; if there
    // are two or more exited children, we'll remember the
    // last one here, which doesn't matter because 'init' will
    // clean it up, loop, and collect the others
    if (next->state == STATE_ZOMBIE) {
      for_init = next;
    }
  } while (1);

  /*
  ** If we found a child that was already terminated, we need to
  ** wake up the init process if it's already waiting.
  **
  ** Note: we only need to do this for one Zombie child process -
  ** init will loop and collect the others after it finishes with
  ** this one.
  **
  ** Also note: it's possible that the exiting process' parent is
  ** also init, which means we're letting one of zombie children
  ** of the exiting process be cleaned up by init before the
  ** existing process itself is cleaned up by init. This will work,
  ** because after init cleans up the zombie, it will loop and
  ** call wait() again, by which time this exiting process will
  ** be marked as a zombie.
  */
  if (for_init != NULL && init_pcb->state == STATE_WAITING) {

    // dequeue the zombie
    assert(que_remove_by(zombie, for_init) == E_SUCCESS);

    // there is no "wait" queue - procs are just marked as waiting

    // send back the child's status and schedule init
    status_return(init_pcb, for_init);

    // make sure 'init' wakes up
    schedule(init_pcb);

    // we're all done with the child, so get rid of it
    pcb_cleanup(for_init);
  }

  /*
  ** Next, we need to prepare to notify the parent about this
  ** child's termination. The parent may be in any of several
  ** states:
  **
  **    waiting - wake it up, give it the status, clean up this pcb
  **    sleeping - zombify this process
  **    blocked - zombify this process
  **    ready - zombify this process
  */

  if (parent->state == STATE_WAITING) {

    // send back the status
    status_return(parent, pcb);

    // wake up the parent
    schedule(parent);

    // all done with this process
    pcb_cleanup(pcb);

  } else {

    // just want to zombify this process
    pcb_zombify(pcb);
  }

  // either way, we need a new current process
  dispatch();

  SYSCALL_EXIT(0);
}

/**
** sys_wait - wait for a child process to terminate
**
** Implements:
**		int wait( int32_t *status );
**
** Blocks the calling process until a child of the caller terminates.
** Intrinsic return is the PID of the child that terminated, or an error
** code; on success, returns the child's termination status via 'status'
** if that pointer is non-NULL.
*/
SYSIMPL(wait) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // find a child of this process that has terminated, and
  // even if we don't find one, make sure we know if there were
  // any children at all
  int nkids = 0;
  pcb_t *child = NULL;

  /*
  ** old approach:
  **
  ** do {
  **     child = pcb_find_child_of( pcb );
  **     if( child == NULL ) {
  **         break;
  **     }
  **
  **     assert1( child->parent == pcb );
  **
  **     ++nkids;
  **
  **     if( child->state == STATE_ZOMBIE ) {
  **         break;
  **     }
  ** } while( 1 );
  **
  ** that won't work, because pcb_find_child_of() always
  ** starts at the beginning of the table. grrr. instead,
  ** we will scan the table ourselves.
  */

  for (int i = 0; i < N_PROCS; ++i) {

    // next process to check
    pcb_t *tmp = &ptable[i];

    // a winning entry is one that:
    //    is not the process calling wait()
    //    is a child of the process calling wait()
    //    is a zombie

    if (tmp != pcb && tmp->parent == pcb && tmp->state != STATE_UNUSED) {
      // definitely a child of this parent
      ++nkids;
      // is it a zombie?
      if (tmp->state == STATE_ZOMBIE) {
        // we have a winner!
        child = tmp;
        break;
      }
    }
  }

  // if child is not NULL, we found an exited child, so we can just
  // return its information and clean it up

  if (child != NULL) {
    // return the info
    status_return(pcb, child);
    // clean things up
    pcb_cleanup(child);
    // back into the calling process
    return;
  }

  // no exited child was found; if we didn't find any at all,
  // return an error code

  if (nkids < 1) {
    RET(pcb) = S_NO_CHILD;
    return;
  }

  // there is at least one child, but it hasn't exited yet;
  // block this process and dispatch another one

  pcb->state = STATE_WAITING;
  dispatch();

  SYSCALL_EXIT(0);
}

/**
** sys_fork - create a new process at the indicated priority
**
** Implements:
**		pid_t fork( prio_t priority );
**
** Creates a new process that is a duplicate of the calling process,
** running at the specified process priority (or at the parent's priority
** if the special priority value PRIO_INHERIT is supplied).  On success,
** returns the child's PID to the parent and 0 to the child; else, returns
** an error code to the parent.
*/
SYSIMPL(fork) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // allocate a PCB; if this fails, let the caller know
  pcb_t *new;
  int status = pcb_alloc(&new);
  if (status != E_SUCCESS) {
    RET(pcb) = S_ERROR;
    SYSCALL_EXIT(S_ERROR);
    return;
  }

  // next, allocate a stack
  uint32_t *stk;
  status = stk_alloc(&stk);

  if (status != E_SUCCESS) {
    // must also free the PCB
    pcb_free(new);
    RET(pcb) = S_ERROR;
    SYSCALL_EXIT(S_ERROR);
    return;
  }

  // OK, we have all the pieces, start to fill things in;
  // begin by clearing the PCB
  memclr(new, sizeof(pcb_t));

  new->state = STATE_NEW;

  new->stack = stk;
  new->parent = pcb;
  new->pid = next_pid++;
  new->priority = ARG(pcb, 1);
  new->vruntime = 0;

  // see if we're supposed to inherit the parent's priority
  if (new->priority == PRIO_INHERIT) {
    new->priority = pcb->priority;
  }

  // duplicate the runtime stack
  blkmov(stk, pcb->stack, SZ_STACK);

  /*
   ** Next, we need to update the ESP and EBP values in the child's
   ** stack.  The problem is that because we duplicated the parent's
   ** stack, these pointers are still pointing back into that stack,
   ** which will cause problems as the two processes continue to execute.
   **
   ** Note: if there are other pointers to things in the parent's stack
   ** (e.g., pointers to local variables), we do NOT locate and update
   ** them, as that's impractical. As a result, user code that relies on
   ** such pointers may behave strangely after a fork().
   */

  // Figure out the byte offset from one stack to the other.
  int32_t offset = (void *)stk - (void *)pcb->stack;

  // Add this to the child's context pointer.
  new->context = (context_t *)(((void *)pcb->context) + offset);

  // Fix the child's ESP and EBP values IFF they're non-zero.
  if (REG(new, ebp) != 0) {
    REG(new, ebp) += offset;
  }

  if (REG(new, esp) != 0) {
    REG(new, esp) += offset;
  }

  // Follow the EBP chain through the child's stack.
  uint32_t *bp = (uint32_t *)REG(new, ebp);
  uint32_t *lastbp = NULL;
  while (bp) {
    *bp += offset;
    lastbp = bp;
    bp = (uint32_t *)*bp;
  }

  /*
  ** lastbp now points to the EBP save area in the first stack
  ** frame, which is the main() for the process. Immediately
  ** below that is the return address, and immediately below
  ** that is the arg string pointer. We need to fix that.
  */
  lastbp += 2;
  *lastbp += offset;

  // Set the return values for the two processes.
  RET(pcb) = new->pid;
  RET(new) = 0;

  // Schedule the child, and let the parent continue.
  schedule(new);

  SYSCALL_EXIT(new->pid);
  return;
}

/**
** sys_exec - replace the memory image of a process
**
** Implements:
**		void exec( uint32_t prog, const char *args );
**
** Replaces the memory image of the calling process with that of the
** indicated program, using the specified command-line arguments.
**
** Returns only on failure.
*/
SYSIMPL(exec) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // grab the arguments
  uint32_t where = ARG(pcb, 1);
  const char *args = (const char *)ARG(pcb, 2);

  // we create a new stack for the process so we don't have to
  // worry about overwriting data in the old stack; however, we
  // need to keep the old one around until after we have copied
  // all the argument data from it.
  uint32_t *oldstack = pcb->stack;
  uint32_t *stk;
  int status = stk_alloc(&stk);

  // if the alloc fails, we're done
  if (status != E_SUCCESS) {
    // process will probably never look at this
    RET(pcb) = S_ERROR;
    SYSCALL_EXIT(pcb->pid);
    return;
  }

  // set up the new stack using the old stack data
  pcb->context = stk_setup(stk, where, args);
  assert1(pcb->context != NULL);

  pcb->stack = stk;

  // now we can safely free the old stack
  stk_free(oldstack);

  /*
   ** Decision:
   **	(A) schedule this process and dispatch another,
   **	(B) let this one continue in its current time slice
   **	(C) reset this one's time slice and let it continue
   **
   ** We choose option B.
   */

  SYSCALL_EXIT(pcb->pid);
}

/**
** sys_read - read into a buffer from an input channel
**
** Implements:
**		int read( uint32_t chan, void *buffer, uint32_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // grab the arguments
  uint32_t chan = ARG(pcb, 1);
  uint32_t len = ARG(pcb, 3);

  /*
  ******************************************************************
  ** Potential VM issue here!
  **
  ** This line MUST CHANGE if VM is implemented, because the pointer
  ** being retrieved is a pointer in user space, not kernel space.
  ******************************************************************
  */
  char *buf = (char *)ARG(pcb, 2);

  // if the buffer is of length 0, we're done!
  if (len == 0) {
    RET(pcb) = 0;
    SYSCALL_EXIT(0);
    return;
  }

  // try to get the next character(s)
  int n = 0;

  if (chan == CHAN_CIO) {

    // console input is non-blocking
    if (cio_input_queue() < 1) {
      RET(pcb) = 0;
      SYSCALL_EXIT(0);
      return;
    }
    // at least one character
    n = cio_gets(buf, len);
    RET(pcb) = n;
    SYSCALL_EXIT(n);
    return;

  } else if (chan == CHAN_SIO) {

    if (n < 1) {
      // nothing available, so we'll block
      pcb->state = STATE_BLOCKED;
      assert1(que_insert(sioread, (void *)pcb) == E_SUCCESS);
      // dispatch a new process
      dispatch();
      SYSCALL_EXIT(0);
      return;
    }

    if (n < 1) {
      // nothing available, so we'll block
      pcb->state = STATE_BLOCKED;
      assert1(que_insert(sioread, (void *)pcb) != E_SUCCESS);
      // dispatch a new process
      dispatch();
      SYSCALL_EXIT(0);
      return;
    }

    // got one or more characters; let the user know
    RET(pcb) = n;
    SYSCALL_EXIT(n);
    return;
  }

  // bad channel code
  RET(pcb) = S_BAD_CHAN;
  SYSCALL_EXIT(S_BAD_CHAN);
  return;
}

/**
** sys_write - write from a buffer to an output channel
**
** Implements:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // grab the parameters
  uint_t chan = ARG(pcb, 1);
  uint_t length = ARG(pcb, 3);

  /*
  ******************************************************************
  ** Potential VM issue here!
  **
  ** This line MUST CHANGE if VM is implemented, because the pointer
  ** being retrieved is a pointer in user space, not kernel space.
  ******************************************************************
  */
  char *buf = (char *)ARG(pcb, 2);

  // this is almost insanely simple, but it does separate the
  // low-level device access fromm the higher-level syscall implementation

  // assume we write the indicated amount
  int rval = length;

  // simplest case
  if (length >= 0) {

    if (chan == CHAN_CIO) {

      cio_write(buf, length);

    } else if (chan == CHAN_SIO) {

      sio_write(buf, length);

    } else {

      rval = S_BAD_CHAN;
    }
  }

  RET(pcb) = rval;

  SYSCALL_EXIT(rval);
  return;
}

/**
** sys_sleep - put the calling process to sleep for some length of time
**
** Implements:
**		void  sleep( uint32_t n );
**
** Puts the calling process to sleep for 'n' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // get the desired duration
  uint32_t n = ARG(pcb, 1);

  if (n == 0) {

    // back on the ready queue
    schedule(pcb);

    // pick a new process
    dispatch();

  } else {

    // sleep for a while
    pcb->state = STATE_SLEEPING;
    pcb->wakeup = system_time + n;

    if (que_insert(sleeping, pcb) != E_SUCCESS) {
      // something strange is happening
      WARNING("sleep pcb insert failed");
    } else {
      // pick a new process
      dispatch();
    }
  }

  SYSCALL_EXIT(pcb->pid);
}

/**
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {

  // sanity check!
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // return the time
  RET(pcb) = pcb->pid;

  SYSCALL_EXIT(pcb->pid);
}

/**
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {

  // sanity check!
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // return the time
  RET(pcb) = system_time;

  SYSCALL_EXIT(pcb->pid);
}

/**
** sys_getprio - the scheduling priority of the specified process
**
** Implements:
**		int getprio( pid_t pid );
**
** The special value 0 can be supplied as the PID; it is interpreted
** as an alias for the calling process' PID.
*/
SYSIMPL(getprio) {

  // sanity check!
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // check the PID
  pid_t pid = ARG(pcb, 1);

  // if it's this process, no search is required
  if (pid == 0 || pid == pcb->pid) {
    RET(pcb) = (uint32_t)(pcb->priority);
    SYSCALL_EXIT(pcb->pid);
    return;
  }

  // not this process, so we need to search
  pcb_t *p = pcb_find_pid(pid);

  if (pcb != NULL && pcb->state != STATE_UNUSED) {
    // found it!
    RET(pcb) = (uint32_t)(p->priority);
  } else {
    // no such process
    RET(pcb) = S_NOT_FOUND;
  }

  SYSCALL_EXIT(pcb->pid);
}

/**
** sys_setvga256linear - sets 320x200 255 color graphics mode for vga
**
** Implements:
**		void setvga256linear();
**
**
*/
SYSIMPL(setvga256linear) {

  // sanity check!
  assert(pcb != NULL);

  // Calls Chris Giese's register assignment
  set_vga_256linear();
}

/**
** sys_setvgatextmode - sets 80x25 text mode for vga
**
** Implements:
**		void setvgatextmode();
**
**
*/
SYSIMPL(setvgatextmode) {

  // sanity check!
  assert(pcb != NULL);

  // Calls Chris Giese's register assignment for reverting to text mode
  set_text_mode();
}

/**
** sys_writepixel - Writes a pixel to some (x, y) on the screen.
**
** Implements:
**		void writepixel(unsigned x, unsigned y, unsigned c);
**
** Has undefined behavior if vga driver is not 320x200 255 color graphics mode.
*/
SYSIMPL(writepixel) {

  // sanity check!
  assert(pcb != NULL);

  unsigned x = ARG(pcb, 1);
  unsigned y = ARG(pcb, 2);
  unsigned c = ARG(pcb, 3);

  // Calls Chris Giese's register assignment for writing a color to a pixel at
  // some coordinate (x, y)
  write_pixel(x, y, c);
}

/**
** sys_getwidth - Gets the width of the screen.
**
** Implements:
**		void getwidth();
**
** If in graphics mode, is in pixels. If in text mode, is in columns.
*/
SYSIMPL(getwidth) {

  // sanity check!
  assert(pcb != NULL);

  RET(pcb) = return_width();
}

/**
** sys_height - Gets the height of the screen.
**
** Implements:
**		void getheight();
**
** If in graphics mode, is in pixels. If in text mode, is in rows.
*/
SYSIMPL(getheight) {

  // sanity check!
  assert(pcb != NULL);

  RET(pcb) = return_height();
}

/**
** sys_getfbsegment - Gets the starting address of the current vga memory region
* accessed by the vga driver.
**
** Implements:
**		unsigned getfbsegment();
**
*/
SYSIMPL(getfbsegment) {

  assert(pcb != NULL);

  RET(pcb) = return_fb_segment();
}

/**
** sys_send - sends specified message over ethernet
**
** Implements
**    void send(char *data)
**
** This should probably return some int to the user process
** to indicate the status of the transmit.
*/
SYSIMPL(send) {

  // sanity check
  assert(pcb != NULL);

  SYSCALL_ENTER(pcb->pid);

  // Get the message from the user process
  char *data = (char *)ARG(pcb, 1);

  // Maybe do some error checking on the data before sending?
  pro100_transmit(data);

  // 0 is success, something else is error
  // return 0;

  SYSCALL_EXIT(pcb->pid);
}

/*
** PRIVATE FUNCTIONS AND GLOBAL VARIABLES
*/

/*
** The system call jump table
**
** Initialized using designated initializers to ensure the entries
** are correct even if the syscall code values should happen to change.
** This also makes it easy to add new system call entries, as their
** position in the initialization list is irrelevant.
*/

static void (*const syscalls[N_SYSCALLS])(pcb_t *) = {
    [SYS_exit] = sys_exit,
    [SYS_wait] = sys_wait,
    [SYS_fork] = sys_fork,
    [SYS_exec] = sys_exec,
    [SYS_read] = sys_read,
    [SYS_write] = sys_write,
    [SYS_sleep] = sys_sleep,
    [SYS_getpid] = sys_getpid,
    [SYS_gettime] = sys_gettime,
    [SYS_getprio] = sys_getprio,
    [SYS_setvga256linear] = sys_setvga256linear,
    [SYS_setvgatextmode] = sys_setvgatextmode,
    [SYS_writepixel] = sys_writepixel,
    [SYS_getwidth] = sys_getwidth,
    [SYS_getheight] = sys_getheight,
    [SYS_getfbsegment] = sys_getfbsegment,
    [SYS_send] = sys_send};

/**
** Name:	sys_isr
**
** System call ISR
**
** @param[in] vector   Vector number for this interrupt
** @param[in] code     Error code (0 for this interrupt)
*/
static void sys_isr(int vector, int code) {

  // keep the compiler happy
  (void)vector;
  (void)code;

  // sanity checks!
  assert(current != NULL);
  assert(current->context != NULL);

  // retrieve the syscall code
  code = REG(current, eax);

#if TRACING_SYSCALLS || TRACING_SYSRETS
  cio_printf("** --> SYS pid %u code %u\n", current->pid, code);
#endif

  // validate it
  if (code < 0 || code >= N_SYSCALLS) {
    // bad syscall number
    // could kill it, but we'll just force it to exit
    cio_printf("sys_isr: pid %d bad syscall (%d)\n", current->pid, code);
    code = SYS_exit;
    ARG(current, 1) = S_BAD_SYSCALL;
  }

  // call the handler
  syscalls[code](current);

#if TRACING_SYSCALLS || TRACING_SYSRETS
  cio_printf("** <-- SYS pid %u ret %u\n", current->pid, RET(current));
#endif

  // tell the PIC we're done
  outb(PIC1_CMD, PIC_EOI);
}

/*
** PUBLIC FUNCTIONS
*/

/**
** Name:  sys_init
**
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init(void) {

#if TRACING_INIT
  cio_puts(" Sys");
#endif

  // install the second-stage ISR
  install_isr(VEC_SYSCALL, sys_isr);
}
