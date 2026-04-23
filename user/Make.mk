#
# Makefile fragment for the user components of the system.
# 
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += user

########################################
# Compilation/assembly definable options
########################################

#
# General options:
#   RENAME_LIB          Prepend 'u' to library function names when
#                         compiling user-level code (NOTE: MUST BE
#                         SET HERE AND IN ../lib/Make.mk!!!)
#

###################
#  FILES SECTION  #
###################

# NOTE: locations.S must be first in this list!
# could add user/shell.c if you want to use the shell
USER_SRC := user/locations.S \
	user/init.c user/idle.c \
	user/progABC.c user/progDE.c user/progFG.c user/progH.c \
	user/progI.c user/progJ.c user/progKL.c user/progMN.c \
	user/progP.c user/progQ.c user/progR.c user/progS.c \
	user/progTUV.c user/progW.c user/progX.c user/progY.c \
	user/progZ.c user/progVGA.c user/progSEND.c

USER_OBJ := $(patsubst %.c, $(BUILD)/%.o, $(USER_SRC))
USER_OBJ := $(patsubst %.S, $(BUILD)/%.o, $(USER_OBJ))

USER_BIN := $(basename $(USER_SRC))
USER_BIN := $(addprefix $(BUILD)/, $(USER_BIN))

# Extra flags we need
#UCFLAGS := -DRENAME_LIB
UCFLAGS :=
ULDFLAGS := -T user/user.ld -M
ULIBS := -luser -lcommon
ULIBDEPS := $(BUILD)/lib/libuser.a $(BUILD)/lib/libcommon.a

# set this if you want 'idle' to report itself periodically
UCFLAGS += -DVERBOSE_IDLE

# Flag dependencies
UCFLS := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.UCFLAGS
ULFLS := $(BUILD)/.vars.LDFLAGS $(BUILD)/.vars.ULDFLAGS

###################
#  RULES SECTION  #
###################

user:	$(BUILD)/user/user.b

$(BUILD)/user/%.o: user/%.c $(UCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(UCFLAGS) -c -o $@ $<

$(BUILD)/user/%.o: user/%.s $(UCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(UCFLAGS) -c -o $@ $<
	$(OBJDUMP) -S $@ > $(@D)/$*.asm

$(BUILD)/user/user: $(USER_OBJ) $(ULIBDEPS) $(ULFLS)
	@mkdir -p $(@D)
	$(LD) $(ULDFLAGS) $(LDFLAGS) -o $@ $(USER_OBJ) $(ULIBS) > $(@D)/user.map
	$(OBJDUMP) -S $@ > $@.asm
	$(NM) -n $@ > $@.sym
	$(READELF) -a $@ > $@.info
	$(HEXDUMP) -C $@ > $(@D)/user.hex

$(BUILD)/user/user.b:	$(BUILD)/user/user
	$(OBJCOPY) -O binary $(@D)/user $@
	$(HEXDUMP) -C $@ > $(@D)/user.b.hex

# some debugging assist rules
$(BUILD)/user/%.i: user/%.c $(UCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(UCFLAGS) -E -c $< > $(@D)/$*.i

$(BUILD)/user/%.dat: $(BUILD)/user/user
	@mkdir -p $(@D)
	$(OBJCOPY) -S -O binary -j .data $< $@
	$(HEXDUMP) -C $@ > $(@D)/$*.dat.hex

$(BUILD)/user/%.rodat: $(BUILD)/user/user
	@mkdir -p $(@D)
	$(OBJCOPY) -S -O binary -j .rodata $< $@
	$(HEXDUMP) -C $@ > $(@D)/$*.rodat.hex

