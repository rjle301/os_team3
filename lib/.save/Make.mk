#
# Makefile fragment for the library components of the system.
# 
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += lib

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
	lib/strcat.c lib/strcmp.c lib/strcpy.c lib/strlen.c

# user-only library functions
ULIB_SRC := lib/uextras.c lib/usys.S

# kernel-only library functions
KLIB_SRC := lib/kextras.c

# lists of object files
CLIB_OBJ:= $(patsubst lib/%.c, $(BUILD)/lib/%.o, $(CLIB_SRC))

ULIB_OBJ:= $(patsubst lib/%.c, $(BUILD)/lib/%.o, $(ULIB_SRC))
ULIB_OBJ:= $(patsubst lib/%.S, $(BUILD)/lib/%.o, $(ULIB_OBJ))

KLIB_OBJ := $(patsubst lib/%.c, $(BUILD)/lib/%.o, $(KLIB_SRC))
KLIB_OBJ := $(patsubst lib/%.S, $(BUILD)/lib/%.o, $(KLIB_OBJ))

# library file names
CLIB_NAME := libcommon.a
ULIB_NAME := libuser.a
KLIB_NAME := libkernel.a

###################
#  RULES SECTION  #
###################

# how to make everything
lib:	$(BUILD)/lib/$(CLIB_NAME) \
	$(BUILD)/lib/$(KLIB_NAME) \
	$(BUILD)/lib/$(ULIB_NAME)

$(BUILD)/lib/%.o:	lib/%.c $(BUILD)/.vars.CFLAGS
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/lib/%.o:	lib/%.S $(BUILD)/.vars.CFLAGS
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
	$(OBJDUMP) -S $@ > $(@D)/$*.asm

$(BUILD)/lib/$(CLIB_NAME):	$(CLIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(CLIB_OBJ)

$(BUILD)/lib/$(KLIB_NAME):	$(KLIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(KLIB_OBJ)

$(BUILD)/lib/$(ULIB_NAME):	$(ULIB_OBJ)
	$(AR) $(ARFLAGS) $@ $(ULIB_OBJ)

# some debugging assist rules
$(BUILD)/lib/%.i: lib/%.c $(BUILD)/.vars.CFLAGS
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -E -c $< > $(@D)/$*.i
