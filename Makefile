#
# Makefile for the 20255 operating system.
#

##########################################
# Compilation/assembly definable options
#
# See also the */Make.mk files for options
# settable for those parts of the system
##########################################

#
# General options:
#   CLEAR_BSS           include code to clear all BSS space
#   GET_MMAP            get BIOS memory map via int 0x15 0xE820
#   FORCE_INLINING      force "inline" functions to be inlined even if
#                         we aren't compiling with at least -O2
#   VIDEO_BW            Use black-on-white for the console display
#   CIO_DUP2_SIO        CIO output can be duped to SIO
#

GEN_OPTS := -DCLEAR_BSS -DGET_MMAP
GEN_OPTS += -DVIDEO_BW
GEN_OPTS += -DCIO_DUP2_SIO
GEN_OPTS += -DFORCE_INLINING

#
# Debugging options:
#   ANNOUNCE_ENTRY      announce entry and exit from kernel functions
#   SLOW_KINIT          add 2-second delays in the main() function
#   RPT_INT_UNEXP       report any 'unexpected' interrupts
#   RPT_INT_MYSTERY     report interrupt 0x27 specifically
#   TRACE_CX            context restore tracing
#   CX_SANITY_CHK       perform a "sanity check" before context restore
#   DBLV=n              enable "sanity check" debug level 'n' (0/1/2/3/4)
#   SYSTEM_STATUS=n     report system status ever 'n' seconds
#   CATCH_OP_FAULTS     catch illegal opcode faults (vector 0x06)
#   CATCH_GP_FAULTS     catch GP faults (vector 0x0d)
#
# Some modules have their own internal debugging options, described
# in their introductory comments.
#
# Define DBLV as 0 for minimal runtime checking (critical errors only).
# If not defined, DBLV defaults to 9999.
#

DBG_OPTS := -DRPT_INT_UNEXP
DBG_OPTS := -DSLOW_KINIT
DBG_OPTS += -DTRACE_CX
DBG_OPTS += -DCX_SANITY_CHK
DBG_OPTS += -DSYSTEM_STATUS=5
DBG_OPTS += -DCATCH_OP_FAULTS
DBG_OPTS += -DCATCH_GP_FAULTS

#
# T_ options are used to define bits in a "tracing" bitmask, to allow
# checking of individual conditions. The following are defined:
#
#   T_PCB                   PCB alloc/dealloc
#   T_QUE                   PCB queue manipulation
#   T_SCH, T_DSP            Scheduler and dispatcher
#   T_SCALL, T_SRET         System call entry and exit
#   T_EXIT                  Process exit actions
#   T_KM , T_KMI, T_KMF     Kmem module tracing (general, init, freelist)
#   T_INIT                  Module init function tracing
#   T_SIO, T_SIOR, T_SIOW   General SIO module checks
#   T_STK, T_STKS           Stack operations (alloc/free, setup)
#	T_PCI					PCI module init and device discovery
#
# You can add compilation options "on the fly" by using EXTRAS=thing
# on the command line.  For example, to compile with -H (to show the
# hierarchy of #includes):
#
#	make EXTRAS=-H
#

TRACE_OPTS := -DT_INIT
TRACE_OPTS += -DT_QUE
TRACE_OPTS += -DT_KM -DT_KMI -DT_KMF
TRACE_OPTS += -DT_STKS
TRACE_OPTS += -DT_SCH
TRACE_OPTS += -DT_DSP
TRACE_OPTS += -DT_SCALL -DT_SRET
TRACE_OPTS += -DT_PCI
TRACE_OPTS += -DT_RBT
TRACE_OPTS += -DT_P100

KERNEL_OPTS := $(GEN_OPTS) $(DBG_OPTS) $(TRACE_OPTS) $(EXTRAS)

##############################################################
# YOU SHOULD NOT NEED TO CHANGE ANYTHING BELOW THIS POINT!!! #
##############################################################

#
# Compilation/assembly control
#

#
# We only want to include from the common header directory
#
INCLUDES := -I./include

#
# All our object code will live in one place
# 
BUILD := build
LIBDIR := $(BUILD)/lib

#
# Things we need to convert to object form
#
SUBDIRS := 

#
# Commands we'll be using
#
CPP	:= cpp
CC	:= gcc
AS	:= as
LD	:= ld
AR	:= ar
HEXDUMP	:= hexdump
OBJDUMP	:= objdump
OBJCOPY	:= objcopy
NM	:= nm
PERL	:= perl
READELF := readelf

#
# Compilation/assembly/linking commands and options
#
CPPFLAGS := -nostdinc $(INCLUDES)

#
# Compiler settings for 32-bit binaries
#
CFLAGS := -m32 -fno-pie -std=c99 -ggdb
CFLAGS += -fno-stack-protector -fno-builtin
CFLAGS += -Wall -Wstrict-prototypes -MD $(CPPFLAGS)
# Things you may want to add:
# CFLAGS += -O2

# Settings for the assembler
ASFLAGS := --32

# Settings for the linker
LDFLAGS := -melf_i386 -no-pie -nostdlib -L$(LIBDIR)

# Settings for the library archiver
ARFLAGS := rsU

# delete target files if there is an error, or if make is interrupted
.DELETE_ON_ERROR:

# don't delete intermediate files
.PRECIOUS:	%.o $(BUILD)/boot/%.o $(BUILD)/kernel/%.o \
	$(BUILD)/lib/%.o $(BUILD)/user/%.o

#
# Update $(BUILD)/.vars.X if variable X has changed since the last time
# 'make' was run.
#
# Rules that use variable X should depend on $(BUILD)/.vars.X.  If
# the variable's value has changed, this will update the vars file and
# force a rebuild of the rule that depends on it.
# 

$(BUILD)/.vars.%: FORCE
	echo "$($*)" | cmp -s $@ || echo "$($*)" > $@

.PRECIOUS:	$(BUILD)/.vars.%

.PHONY:	FORCE

#		
# Transformation rules - these ensure that all necessary compilation
# flags are specified
#
# Note use of 'cpp' to convert .S files to temporary .s files: this allows
# use of #include/#define/#ifdef statements. However, the line numbers of
# error messages reflect the .s file rather than the original .S file. 
# (If the .s file already exists before a .S file is assembled, then
# the temporary .s file is not deleted.  This is useful for figuring
# out the line numbers of error messages, but take care not to accidentally
# start fixing things by editing the .s file.)
#
# The .c.X rule produces a .X file which contains the original C source
# code from the file being compiled mixed in with the generated
# assembly language code.  Can be helpful when you need to figure out
# exactly what C statement generated which assembly statements!
#

.SUFFIXES:	.S .b .X .i

.c.X:
	$(CC) $(CFLAGS) -g -c -Wa,-adhln $*.c > $*.X

.c.s:
	$(CC) $(CFLAGS) -S $*.c

#
# An older transformation rule for .S to .o - runs CPP on the .S file
# to produce a .s file, then assembles the .s file.
#
#.S.s:
#	$(CPP) $(CPPFLAGS) -o $*.s $*.S
#
#.S.o:
#	$(CPP) $(CPPFLAGS) -o $*.s $*.S
#	$(AS) $(ASFLAGS) -o $*.o $*.s -a=$*.lst
#	$(RM) -f $*.s

.s.b:
	$(AS) $(ASFLAGS) -o $*.o $*.s -a=$*.lst
	$(LD) $(LDFLAGS) -Ttext 0x0 -s --oformat binary -e begtext -o $*.b $*.o

#.c.o:
#	$(CC) $(CFLAGS) -c $*.c

.c.i:
	$(CC) -E $(CFLAGS) -c $*.c > $*.i

#
# Location of the QEMU binary
#
# QEMU := /home/course/csci352/bin/qemu-system-i386
QEMU := /usr/bin/qemu-system-i386

# try to generate a unique GDB port
GDBPORT := $(shell expr `id -u` % 5000 + 25000)

# QEMU's gdb stub command line changed in 0.11
QEMUGDB := $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)

# options for QEMU
#
# run 'make' with -DQEMUEXTRA=xxx to add option 'xxx' when QEMU is run
#
# does not include a '-serial' option, as that may or may not be needed
QEMUOPTS := -drive file=disk.img,index=0,media=disk,format=raw $(QEMUEXTRA)

########################################
# RULES SECTION
########################################

#
# All the individual parts
#

all:	util lib bootstrap kernel user disk.img all.sym

# Rules etc. for the various sections of the system
include lib/Make.mk
include boot/Make.mk
include user/Make.mk
include kernel/Make.mk
include util/Make.mk

#
# Rules for building the disk image
#
# NOTE: the target addresses for kernel.b and user.b must agree
# with the values SYSTEM_ADDR and USER_ADDR (respectively) defined
# in include/memory.h, and with the initial '.' values assigned in
# kernel/kernel.ld and user/user.ld.
#

disk.img: $(BUILD)/kernel/kernel.b $(BUILD)/boot/boot $(BUILD)/user/user.b BuildImage
	./BuildImage -o disk.img -b $(BUILD)/boot/boot \
		$(BUILD)/kernel/kernel.b 0x10000 \
		$(BUILD)/user/user.b 0x30000
	$(HEXDUMP) -C disk.img > disk.img.hex

all.sym: $(BUILD)/kernel/kernel.sym $(BUILD)/user/user.sym
	cat $(BUILD)/kernel/kernel.sym $(BUILD)/user/user.sym > all.sym

#
# Rules for running with QEMU
#

# how to create the .gdbinit config file if we need it
.gdbinit: util/gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

# "ordinary" gdb
gdb:
	gdb -q -n -x .gdbinit

# gdb with the super-mega-fancy Text User Interface
gdb-tui:
	gdb -q -n -x .gdbinit -tui

docker-build: Dockerfile
	docker build -t sysprog:build .

docker-run: Dockerfile
	docker run --rm -v .:/src sysprog:build

qemu: disk.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-nox: disk.img
	$(QEMU) -nographic $(QEMUOPTS)

qemu-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

qemu-nox-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

#
# Create a printable namelist from the kernel file
#
# kernel.nl:   only global symbols
# kernel.nll:  all symbols
#

kernel.nl: $(BUILD)/kernel/kernel
	nm -Bng $(BUILD)/kernel/kernel.o | pr -w80 -3 > kernel.nl

kernel.nll: $(BUILD)/kernel/kernel
	nm -Bn $(BUILD)/kernel/kernel.o | pr -w80 -3 > kernel.nll

#
# Generate a disassembly
#

kernel.dis: $(BUILD)/kernel/kernel
	objdump -d $(BUILD)/kernel/kernel > kernel.dis

#
# Cleanup etc.
#

clean:
	rm -f .gdbinit *.nl *.nll *.lst *.i *.X *.dis
	rm -rf $(BUILD)

realclean:	clean
	rm -f LOG *.img *.img.hex all.sym $(UTIL_BIN)

#
# Automatically generate dependencies for header files included
# from C source files.
#
$(BUILD)/.deps: $(foreach dir, $(SUBDIRS), $(wildcard $(BUILD)/$(dir)/*.d))
	@mkdir -p $(@D)
	$(PERL) util/mergedep.pl $@ $^

-include $(BUILD)/.deps

.PHONY:	all clean realclean
