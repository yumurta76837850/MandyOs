# MandyOs

**x86_64 hobby operating system kernel** developed from scratch for learning purposes.

> ⚠️ **Durum / Status:** Bu proje henüz **tamamen geliştirme aşamasındadır** ve bitmesine daha çok vardır. Şu an için çalışan bir çekirdek (kernel) ve temel bileşenler mevcut olsa da, eksik ve kararlı olmayan birçok kısım bulunmaktadır. Gerçek bir işletim sistemi olmaktan oldukça uzaktır.
>
> **English:** This project is still **heavily in development** with a long way to go before completion. While a working kernel and basic components exist, many parts are incomplete or unstable. It is far from being a real operating system.

---

## Özellikler / Features

- Custom **two-stage bootloader** (real mode MBR → protected mode → long mode)
- **x86_64 long mode** with 4-level paging (PAE)
- **Interrupt handling** (IDT, PIC 8259)
- **PIT** (Programmable Interval Timer) at 1000 Hz
- **Bitmap-based physical memory manager**
- **Bump-allocator heap** (`kmalloc`)
- **Round-robin process scheduler**
- **System calls** via `SYSCALL`/`SYSRET` MSRs
- **Serial (COM1) I/O** — debug output and interactive shell
- **VGA text mode** (80×25) for kernel messages
- Built-in **shell** with commands: `help`, `uptime`, `mem`, `ps`, `pid`, `info`, `ticks`, `memtest`, `echo`, `clear`, `reboot`, `halt`

---

## Gereksinimler / Requirements

- **NASM** — assembler
- **GCC** cross-compiler (i686-elf or x86_64-elf) or a host GCC with freestanding support
- **GNU LD** — linker
- **QEMU** (x86_64) — for emulation
- **GNU Make** — build system
- **MinGW/MSYS2** (on Windows) or standard toolchain (on Linux/WSL)

---

## Derleme ve Çalıştırma / Build & Run

```bash
# Tümünü derle / Build everything
make all

# QEMU'da çalıştır / Run in QEMU
make run

# Temizle / Clean build artifacts
make clean
```

Varsayılan `make run` komutu şu parametrelerle QEMU'yu başlatır:

```
qemu-system-x86_64 -fda mandyos.img -boot a -m 512M -serial stdio -no-reboot
```

---

## Proje Yapısı / Project Structure

```
├── boot.asm              # Stage 1 bootloader (512-byte MBR)
├── stage2.asm            # Stage 2 bootloader → protected mode
├── kernel_entry.asm      # 32-bit → long mode geçişi / Long mode transition
├── kernel.c              # Ana çekirdek / Main kernel
├── kernel_entry.o        # Derlenmiş kernel girişi
├── serial.c              # COM1 sürücüsü / Serial driver
├── shell.c               # Komut satırı / Interactive shell
├── syscall.c             # Sistem çağrıları / System calls
├── syscall_entry.asm     # SYSCALL giriş stobu / Syscall entry stub
├── syscall_msr.c         # MSR yapılandırması / MSR setup
├── syscall.h             # Sistem çağrı tanımları / Syscall definitions
├── io.h                  # Port I/O yardımcıları / Port I/O helpers
├── linker.ld             # Bağlayıcı betiği / Linker script
├── Makefile              # Yapı sistemi / Build system
└── mandyos.img           # Oluşturulan disket imajı / Generated floppy image
```

---

## Bilinen Eksiklikler / Known Limitations

- Scheduler tanımlanmış ancak henüz aktif olarak process oluşturulmuyor
- PIC maskesi tüm kesmeleri kapalı tutuyor (PIT kesmesi tetiklenmiyor)
- `fork`, `exec`, `open`, `close` gibi sistem çağrıları tanımlanmış ancak **gerçeklenmemiş**
- Sayfa hataları (page faults) ve çift hatalar (double faults) meydana gelebiliyor
- Bellek yönetimi henüz temel seviyede (bump allocator)
- Kullanıcı alanı (userspace) henüz mevcut değil
- Dosya sistemi yok

---

## Lisans / License

Bu proje eğitim amaçlıdır. Herhangi bir lisans belirtilmemiştir.

This project is for educational purposes. No license is specified.
