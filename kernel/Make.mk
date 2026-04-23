# 
# Makefile fragment for the kernel component of the system.
#
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += kernel

###################
#  FILES SECTION  #
###################

BOOT_OBJ := $(patsubst %.c, $(BUILD)/%.o, $(BOOT_SRC))

KERN_SRC := kernel/entry.S kernel/isrs.S \
	kernel/cio.c kernel/clock.c kernel/kernel.c kernel/kmem.c \
	kernel/list.c kernel/procs.c kernel/queues.c kernel/sio.c \
	kernel/stacks.c kernel/support.c kernel/syscalls.c kernel/vgadriver.c \
  kernel/pci.c kernel/device/pro100.c

KERN_OBJ := $(patsubst %.c, $(BUILD)/%.o, $(KERN_SRC))
KERN_OBJ := $(patsubst %.S, $(BUILD)/%.o, $(KERN_OBJ))

# Extra flags we need
KCFLAGS := $(KERNEL_OPTS)
KLDFLAGS := -T kernel/kernel.ld -M
KLIBS := -lkernel -lcommon
KLIBDEPS := $(BUILD)/lib/libkernel.a $(BUILD)/lib/libcommon.a

# Flag dependencies
KCFLS := $(BUILD)/.vars.CFLAGS $(BUILD)/.vars.KCFLAGS
KLFLS := $(BUILD)/.vars.LDFLAGS $(BUILD)/.vars.KLDFLAGS

###################
#  RULES SECTION  #
###################

kernel:	$(BUILD)/kernel/kernel.b

$(BUILD)/kernel/%.o: kernel/%.c $(KCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(KCFLAGS) -c -o $@ $<

$(BUILD)/kernel/%.o:	kernel/%.S $(KCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(KCFLAGS) -c -o $@ $<
	$(OBJDUMP) -S $@ > $(@D)/$*.asm

$(BUILD)/kernel/kernel: $(KERN_OBJ) $(KLIBDEPS) $(KLFLS)
	@mkdir -p $(@D)
	$(LD) $(KLDFLAGS) $(LDFLAGS) -o $@ $(KERN_OBJ) $(KLIBS) > $(@D)/kernel.map
	$(OBJDUMP) -S $@ > $@.asm
	$(NM) -n $@ > $@.sym
	$(READELF) -a $@ > $@.info
	$(HEXDUMP) -C $@ > $(@D)/kernel.hex

$(BUILD)/kernel/kernel.b: $(BUILD)/kernel/kernel $(KLFLS)
	$(OBJCOPY) -O binary $(@D)/kernel $@
	$(HEXDUMP) -C $@ > $(@D)/kernel.b.hex

# some debugging assist rules
$(BUILD)/kernel/%.i: kernel/%.c $(KCFLS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(KCFLAGS) -E -c $< > $(@D)/$*.i

$(BUILD)/kernel/%.dat: $(BUILD)/kernel/kernel
	@mkdir -p $(@D)
	$(OBJCOPY) -S -O binary -j .data $< $@
	$(HEXDUMP) -C $@ > $(@D)/$*.dat.hex

$(BUILD)/kernel/%.rodat: $(BUILD)/kernel/kernel
	@mkdir -p $(@D)
	$(OBJCOPY) -S -O binary -j .rodata $< $@
	$(HEXDUMP) -C $@ > $(@D)/$*.rodat.hex

