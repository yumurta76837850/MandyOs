# Detect OS
UNAME_S := $(shell uname -s)

# Linux (WSL dahil) — native ELF toolchain
ifeq ($(UNAME_S),Linux)
  CC     = gcc
  AS     = nasm
  LD     = ld
  OBJCPY = objcopy
  DD     = dd
  ASFMT  = elf64
  LDEMU  = elf_x86_64
  RM     = rm -f
  COPY   = cp
  null   =
endif

# Windows (MSYS2/MINGW/UCRT64)
ifneq (,$(findstring NT,$(UNAME_S)))
  CC     = gcc
  AS     = nasm
  LD     = ld
  OBJCPY = objcopy
  DD     = dd
  ASFMT  = win64
  LDEMU  = i386pep
  RM     = rm -f
  COPY   = cp
  null   =
endif

CFLAGS = -ffreestanding -fno-stack-protector -fno-pic \
        -mno-red-zone -nostdlib -O2 -Wall -Wextra

OBJS_ASM = kernel_entry.o syscall_entry.o
OBJS_C   = kernel.o syscall_msr.o syscall.o serial.o shell.o

all: mandyos.img

# Assembly objects
kernel_entry.o: kernel_entry.asm
	$(AS) -f $(ASFMT) -o $@ $<

syscall_entry.o: syscall_entry.asm
	$(AS) -f $(ASFMT) -o $@ $<

boot.bin: boot.asm
	$(AS) -f bin -o $@ $<

stage2.bin: stage2.asm
	$(AS) -f bin -o $@ $<

# C objects
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Link — Linux: ELF, Windows: PE
ifeq ($(UNAME_S),Linux)
kernel.elf: $(OBJS_ASM) $(OBJS_C)
	$(LD) -m $(LDEMU) -T linker.ld -o $@ $^
else
kernel.elf: $(OBJS_ASM) $(OBJS_C)
	$(LD) -m $(LDEMU) --image-base 0x100000 -e _start -o $@ $^
endif

kernel.bin: kernel.elf
	$(OBJCPY) -O binary $< $@

# Disk image
mandyos.img: boot.bin stage2.bin kernel.bin
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=boot.bin of=$@ conv=notrunc
	$(DD) if=stage2.bin of=$@ bs=512 seek=1 conv=notrunc
	$(DD) if=kernel.bin of=$@ bs=512 seek=17 conv=notrunc

mandyos.iso: mandyos.img
	$(COPY) $< $@

run: mandyos.img
	qemu-system-x86_64 -fda mandyos.img -boot a \
	    -m 512M -serial stdio -no-reboot

clean:
	$(RM) *.o *.bin *.elf *.img *.iso $(null)

.PHONY: all clean run
