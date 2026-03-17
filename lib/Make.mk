#
# Makefile fragment for the library components of the system.
# 
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += lib

########################################
# Compilation/assembly definable options
########################################

#
# General options:
#   RENAME_LIB          Prepend 'u' to library function names when
#                         compiling user-level code (NOTE: MUST BE
#                         SET HERE AND IN ../user/Make.mk!!!)
#

###################
#  FILES SECTION  #
###################

#
# library file lists
#

# "common" library functions, used by kernel and users
CLIB_SRC := lib/blkmov.c lib/bound.c lib/cvtdec.c lib/cvtdec0.c \
	lib/cvthex.c lib/cvtoct.c lib/cvtuns.c lib/cvtuns0.c \
	lib/memclr.c lib/memcpy.c lib/memmove.c lib/memset.c \
	lib/pad.c lib/padstr.c lib/sprint.c lib/str2int.c \
	lib/strcat.c lib/strchr.c lib/strcmp.c lib/strcpy.c lib/strlen.c

# user-only library functions
ULIB_SRC := lib/uextras.c lib/usys.S

# kernel-only library functions
KLIB_SRC := lib/kextras.c

# lists of object files
CLIB_OBJ:= $(patsubst lib/%.c, $(BUILD)/lib/c%.o, $(CLIB_SRC))

ULIB_OBJ:= $(patsubst lib/%.c, $(BUILD)/lib/%.o, $(ULIB_SRC))
ULIB_OBJ:= $(patsubst lib/%.S, $(BUILD)/lib/%.o, $(ULIB_OBJ))

KLIB_OBJ := $(patsubst lib/%.c, $(BUILD)/lib/%.o, $(KLIB_SRC))
KLIB_OBJ := $(patsubst lib/%.S, $(BUILD)/lib/%.o, $(KLIB_OBJ))

# library file names
CLIB_NAME := libcommon.a
ULIB_NAME := libuser.a
KLIB_NAME := libkernel.a

# extra flags we need for the common, user, and kernel libraires
CLCFLAGS :=
ULCFLAGS :=
KLCFLAGS :=

# Flag dependencies
CLCFLIST := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.CLCFLAGS
ULCFLIST := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.ULCFLAGS
KLCFLIST := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.KLCFLAGS

###################
#  RULES SECTION  #
###################

# how to make everything
lib:	$(BUILD)/lib/$(CLIB_NAME) \
	$(BUILD)/lib/$(KLIB_NAME) \
	$(BUILD)/lib/$(ULIB_NAME)

$(BUILD)/lib/c%.o:	lib/%.c $(CLCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CLCFLAGS) -c -o $@ $<

$(BUILD)/lib/%.o:	lib/%.c $(ULCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(ULCFLAGS) -c -o $@ $<

$(BUILD)/lib/%.o:	lib/%.S $(ULCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(ULCFLAGS) -c -o $@ $<
	$(OBJDUMP) -S $@ > $(@D)/$*.asm

# $(BUILD)/lib/u%.o:	lib/%.c $(ULCFLIST)
# 	@mkdir -p $(@D)
# 	$(CC) $(CFLAGS) $(ULCFLAGS) -c -o $@ $<
# 
# $(BUILD)/lib/u%.o:	lib/%.S $(ULCFLIST)
# 	@mkdir -p $(@D)
# 	$(CC) $(CFLAGS) $(ULCFLAGS) -c -o $@ $<
# 	$(OBJDUMP) -S $@ > $(@D)/$*.asm
# 
# $(BUILD)/lib/k%.o:	lib/%.c $(KLCFLIST)
# 	@mkdir -p $(@D)
# 	$(CC) $(CFLAGS) $(KLCFLAGS) -c -o $@ $<
# 
# $(BUILD)/lib/k%.o:	lib/%.S $(KLCFLIST)
# 	@mkdir -p $(@D)
# 	$(CC) $(CFLAGS) $(KLCFLAGS) -c -o $@ $<
# 	$(OBJDUMP) -S $@ > $(@D)/$*.asm

$(BUILD)/lib/$(CLIB_NAME):	$(CLIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(CLIB_OBJ)

$(BUILD)/lib/$(KLIB_NAME):	$(KLIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(KLIB_OBJ)

$(BUILD)/lib/$(ULIB_NAME):	$(ULIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(ULIB_OBJ)

# some debugging assist rules
$(BUILD)/lib/c%.i: lib/%.c $(CLCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CLCFLAGS) -E -c $< > $(@D)/c$*.i

$(BUILD)/lib/u%.i: lib/%.c $(CLCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CLCFLAGS) -E -c $< > $(@D)/u$*.i

$(BUILD)/lib/k%.i: lib/%.c $(CLCFLIST)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CLCFLAGS) -E -c $< > $(@D)/k$*.i

