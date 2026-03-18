Some debugging notes.
=========================================================================
Sunday, 3/15:
-------------------------------------------------------------------------

2026/03/15 3:37pm

Here's the current state of the system. "Runs fine" means runs for at least
0x30000 clock ticks (196,608 - about 3.25 minutes).

Running without M, N, P, or Q:

  A, B, C, D, E, F, G, J, I, J, K, L, -, -, -, -, R, S, T, U, V : runs fine

Adding M, N, P, and Q one at a time:

  A, B, C, D, E, F, G, J, I, J, K, L, M, -, -, -, R, S, T, U, V : runs for
  0x420 clock ticks (about one second), then blows up with a GPF.

  A, B, C, D, E, F, G, J, I, J, K, L, -, N, -, -, R, S, T, U, V : runs fine

  A, B, C, D, E, F, G, J, I, J, K, L, -, -, P, -, R, S, T, U, V : runs fine

  A, B, C, D, E, F, G, J, I, J, K, L, -, -, -, Q, R, S, T, U, V : runs for
  0x41d clock ticks (about one second), then blows up with a GPF.

M and N do the same thing, with one difference - M spawns userW processes,
and N spawns both userW and userZ processes. N beats on the system more,
but runs; M is easier on the system, and it faults very quickly.

Adding N and P together:

  A, B, C, D, E, F, G, J, I, J, K, L, -, N, P, -, R, S, T, U, V : runs for
  0x7552 clock ticks (30,034 - about 30 seconds), then blows up with a GPF.

Now, running only these four processes:

  Running M, N, P, or Q by itself: no problems.

  Running M and N together with no other processes: no problems.

  Running M, N, and P together with no other processes: no problems.

  Running M, N, P, and Q together with no other processes: no problems.

Adding others back in:

  ABCDE with MNPQ: no problems
  ABCDEFG with MNPQ: no problems
  ABCDEFGHI with MNPQ: no problems
  ABCDEFGHIJKL with MNPQ: no problems

Adding the remaining processes:

  ABCDEFGHIJKLMNPQ with R: no problems
  ABCDEFGHIJKLMNPQ with RS: GPF at 0x43 clock ticks
  ABCDEFGHIJKLMNPQ with RT: GPF at 0x42 clock ticks
  ABCDEFGHIJKLMNPQ with RU: GPF at 0x42 clock ticks
  ABCDEFGHIJKLMNPQ with RV: GPF at 0x41 clock ticks

Of course, S, T, U, and V all run individually without problems, and run
together with no problems.

-------------------------------------------------------------------------

2026/03/15 1:22pm

Modified the Makefile and */Make.mk files to not apply all the kernel
compilation options to all files being compiled - only to boot/boot.S
and kernel/*.[cS]. This speeds up the compilation signficantly when a
header that affects only the kernel or only the user code is modified.
For now, the debugging symbols are defined in Makefile so they're 
available in both boot/Make.mk and kernel/Make.mk.

I moved "-ggdb" into the Makefile in CFLAGS, so it will be used when
compiling everything.

Added a GPF handler to kernel/support.c, optionally used when the code
is compiled with CATCH_GP_FAULTS defined. With this and CATCH_OP_FAULTS
defined. the code now runs with these handlers in place.

I modified lib/Make.mk to have separate compilation rules for the
the common, user, and kernel libraries. This will allow the specification
of separate compilation options for each set (e.g., if we need to enable
the RENAME_LIB compilation option). I also modified the kernel/Make.mk
and user/Make.mk files to have their respective binaries depend on the
libraries each uses, so changing library code will trigger recompilation
of kernel and/or user code that uses the modified library function(s).

Most importantly, with these changes, setting the process state to
STATE_SLEEPING in sys_sleep() no longer causes the system to crash.

=========================================================================
Friday, 3/13:
-------------------------------------------------------------------------

2026/03/13 7:26pm

Corrected the UCASE macro in include/defs.h.

Added a syscall status return value S_BAD_CHAN. The read() and write()
implementations were returning S_BAD_PARAM and E_BAD_CHAN, so adding
S_BAD_CHAN seemed to be a reasonable compromise.

Added KERNEL_SRC and ASM_SRC defines in kernel/entry.S and kernel/isrs.S
(I'm not sure why they weren't there before, but they are now).

The problem in sys_sleep() with setting state to STATE_SLEEPING persists.
Without that, the code runs; with it, the code blows up with an illegal
opcode fault.

I added a fault handler specifically for the opcode fault; define the
symbol CATCH_OP_FAULTS to compile it. However, doing that causes the
system to panic in sys_exit() with a NULL pcb parameter when the
STATE_SLEEPING line is commented out, and the system faults even earlier
when that line is not commented out. Bleh.

=========================================================================
Thursday, 3/12:
-------------------------------------------------------------------------

This is interesting. While playing with the code, I realized that
sys_sleep() never set the state of the process to STATE_SLEEPING. I added
that line, and the code no longer runs - it faults with an invalid opcode
fault. If I comment out that line (line #691 in kernel/syscalls.c), the
code works; uncomment it, and it blows up.

Adding that line of code affects the addresses of everything between that
and the end of the text section; nothing else changes.

=========================================================================
Wednesday, 3/11:
-------------------------------------------------------------------------

2026/03/12 4:57pm

No big changes. I added a couple of string functions to the library -
strchr() and strrchr() - and added some additional input validation to
str2int(). No snapshot generated for these minor changes.

=========================================================================
Tuesday, 3/10:
-------------------------------------------------------------------------

2026/03/10 6:10pm

Runs, but only if there are no more than about 17 user processes (plus
'init' and 'idle'). For example, these combinations run fine:

    Skipping: M N P Q, N P Q R, Q R S T, S T U V

Other combinations don't:

    Skipping: A B C D, E F G H, I J K L, R S T U

The smallest combination I've found that fails is Q R S T.

I've left the configuration at all user processes except M, N, P, and Q
in this snapshot.

=========================================================================
Sunday, 3/08:
-------------------------------------------------------------------------

2026/03/08 7:12pm:

Removed the shell and have 'init' start all the user processes itself.
This gets most of them into execution. (The original files from user/
that use the shell are in misc/use_shell.) This gets us to the point
where lots of users are running; the system hangs briefly, then gets a
GPF. At that moment, it's processing - believe it or not - a call to 
the bogus() syscall.

-------------------------------------------------------------------------

2026/03/08 6:34pm:

There was some strange interaction between the expansion of the assert()
macro and the parameter passed into sys_write() - i.e., the PCB pointer
parameter - that caused it to overwrite the parameter at some point
during system execution, triggering the assertion to fail. I rewrote it
to not use the PANIC() macro, and that seems to have fixed the problem.
(Without diving into the assembly code, I'm not sure what the exact
problem was.) I rewrote the assert[1234N]() versions, as well.

The system now runs to the point where 'init' starts its two child
processes, and then calls wait(). However, there's a logic error in
sys_wait() that causes an infinite loop: if there is at least one child
of the calling process but the first child in the process table has not
yet exited, the "find an exited child" loop never ends, because
pcb_find_child_of() starts at the beginning of the process table when
it's called - thus, it always finds the same child. Because this loop is
in the kernel, no user process ever gets to execute, so we're there
forever.

The process table itself is currently only accessed in the kernel/procs.c
source file, but it is visible throughout the kernel. Rather than try to
fix the problem by making pcb_find_child_of() more intelligent, we'll
just use the brute force method of scanning the process table directly.

This gets past the crash in sys_write(); now the issue is the shell
looping forever waiting for input.

-------------------------------------------------------------------------

2026/03/08 4:46pm:

Reduced the user blob size by five sectors. We had been using the linker
to create the binary blob versions of the kernel and user blobs; I
changed their Make.mk files to use objcopy (as is used for the bootstrap
binary version), and for reasons that are not clear to me the size of
the user blob went from 46 sectors to 41.

I dumped the text, data, and rodata sections from 'kernel' and 'user' for
both versions; they are identical.  Comparing the link maps (kernel.map,
user.map) shows differences in the .debug_str and .debug_line_str
sections, but the associated numbers for those sections are *larger*
for the objcopy version.

=========================================================================
Friday, 3/06:
-------------------------------------------------------------------------

2026/03/06 5:44pm

We have user processes! The problem with 'init' not starting up any other
process was that the process table was being placed at the wrong address
in memory. When linked, the user blob had these address ranges:

    0x30000 - 0x33979    text
    0x35000 - 0x35fff    data
    0x36000 - 0x36010    bss

Note the gap from 0x34000 to 0x34fff - that's where the rodata section
would be.

When loaded into memory, however, the linked code was trying to find the
table at 0x34000. What was there was nothing but bytes containing 0, so
the loop that spawns processes said "Oh, that's the end of the array"
and didn't start anything up.

I modified 'init' and 'shell' to change the way the spawn table was
processed, and to put those tables into the rodata section. We now see
'init' start running, and it then starts 'idle' and 'shell'. Shortly
after that, we get a kernel panic in sys_write(), but at least it's
progress!

=========================================================================
Thursday, 3/05:
-------------------------------------------------------------------------

2026/03/05 4:53pm

This snapshot includes all the things we were playing around with during
class today. The current state is that the system boots and runs, and
we're getting clock (etc.) interrupts, but user code never executes, as
evidenced by the fact that the context trace always shows the same EIP
for the user process. Even if the process is just running a tight loop,
if it's running, there should be some variation in the EIP value from one
interrupt to the next.

=========================================================================
Wednesday, 3/04:
-------------------------------------------------------------------------

2026/03/04 7:25pm

Added some code to debug the KMEM module. Currently, getting to the point
where two page allocations occur, and then an interrupt through vector 0x15
(Control Protection Exception). Out of time for debugging today.

-------------------------------------------------------------------------

2026/03/04 1:56pm

We're at the point where 'init' is running to the point where it reports
that it is starting user processes. If TRACE_CX is defined, the code then
faults attempting to "return" to 0x53f000ff. This is not consistently
repeatable; sometimes the code hangs, and sometimes it continues running,
but (A) no other output is produced, and (B) the context output shows the
SS register contents alternating through several values (including
0x104ff7, which is an address in a user stack). About one in five times,
the code continues running with the weird SS behavior.

If TRACE_CX is not defined, it faults trying to return to 0x74696e69. This
is reliably repeatable.  0x74696e69 is the ASCII sequence "init"
(little-endian!).

All of this suggests something untoward is happening that is messing up
the user stack.

-------------------------------------------------------------------------

2026/03/04 11:33am

I added several globals to kernel/kernel.c that contain the starting and
ending addresses of each of the program sections; these are reported by the
kernel main() immediately after cio_init() is called.

I modified main() so that the delays can be conditionally compiled in for
debugging if they are needed.

I fixed the rodata section issue. The linker script for the kernel (in
kernel/kernel.ld) was putting the rodata section immediately after the
text section; however, the 'ld' command that created the binary version 
of the kernel (build/kernel/kernel.b) was shifting rodata to the next page
boundary. The linked kernel code was using the addresses from the original
link, which were in the text section, but the actual data didn't begin
until the following page. in memory. I modified the linker script for the
kernel to move rodata to the next page, and booting the system allows it
to reach the point where 'init' begins to execute.

At that point, the system faults.

=========================================================================
Tuesday, 3/03:
-------------------------------------------------------------------------

2026/03/03 7:19pm

It looks like the RODATA section is getting misplaced - the strange output
we see is because something is going awry between the call to a CIO
function and when we get there. For example, in sio_init(), the first thing
that happens is

    cio_puts( " Sio" );

When this gets into cio_puts(), here's what it sees:

    cio_puts( "context != NULL failed" )

After that, it goes downhill very fast, with calls to cio_*() functions
getting stranger and stranger parameters.
