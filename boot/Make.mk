#
# Makefile fragment for the bootstrap component of the system.
# 
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += boot

###################
#  FILES SECTION  #
###################

BOOT_SRC := boot/boot.S

BOOT_OBJ := $(BUILD)/boot/boot.o

# Extra flags we need
BCFLAGS := $(KERNEL_OPTS)
BLDFLAGS := -N -Ttext 0 -s -e begtext

# Flag dependencies
BCFLS := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.BCFLAGS
BLFLS := $(BUILD)/.vars.LDFLAGS $(BUILD)/.vars.BLDFLAGS

###################
#  RULES SECTION  #
###################

bootstrap: $(BUILD)/boot/boot

$(BUILD)/boot/%.o:	boot/%.c $(BCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(BCFLAGS) -c -o $@ $<

$(BUILD)/boot/%.o:	boot/%.S $(BCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(BCFLAGS) -c -o $@ $<
	$(OBJDUMP) -S $@ > $(@D)/$*.asm

$(BUILD)/boot/boot: $(BOOT_OBJ)
	@mkdir -p $(@D)
	$(LD) $(LDFLAGS) $(BLDFLAGS) -o $@.out $^
	$(OBJCOPY) -S -O binary -j .text $@.out $@
