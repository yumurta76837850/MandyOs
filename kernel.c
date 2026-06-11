// kernel.c - MandyOs Server Kernel

#include <stdint.h>
#include <stddef.h>
#include "io.h"

// ── VGA Text Mode (debug çıktısı) ──────────────────
#define VGA_BASE  ((volatile uint16_t *)0xB8000)
#define VGA_COLS  80
#define VGA_ROWS  25
#define WHITE_ON_BLACK 0x0F00

static int cursor_x = 0, cursor_y = 0;

static void vga_putchar(char c) {
    if (c == '\n') { cursor_x = 0; cursor_y++; return; }
    if (cursor_x >= VGA_COLS) { cursor_x = 0; cursor_y++; }
    if (cursor_y >= VGA_ROWS)  cursor_y = 0;
    VGA_BASE[cursor_y * VGA_COLS + cursor_x] = WHITE_ON_BLACK | (uint8_t)c;
    cursor_x++;
}

void kprint(const char *s) {
    while (*s) vga_putchar(*s++);
}

// ── IDT (Interrupt Descriptor Table) ──────────────
typedef struct {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} __attribute__((packed)) IDTEntry;

typedef struct {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed)) IDTDescriptor;

#define IDT_SIZE 256
static IDTEntry idt[IDT_SIZE];
static IDTDescriptor idt_desc;

void idt_set_gate(int n, uint64_t handler, uint8_t type) {
    idt[n].offset_low  = handler & 0xFFFF;
    idt[n].selector    = 0x08;
    idt[n].ist         = 0;
    idt[n].type_attr   = type;
    idt[n].offset_mid  = (handler >> 16) & 0xFFFF;
    idt[n].offset_high = (handler >> 32) & 0xFFFFFFFF;
    idt[n].zero        = 0;
}

extern void isr_default(void);  // assembly stub

void idt_init(void) {
    for (int i = 0; i < IDT_SIZE; i++)
        idt_set_gate(i, (uint64_t)isr_default, 0x8E);

    idt_desc.limit = sizeof(idt) - 1;
    idt_desc.base  = (uint64_t)idt;
    __asm__ volatile ("lidt %0" : : "m"(idt_desc));
}

// ── PIC (8259) init ────────────────────────────────
void pic_init(void) {
    // ICW1
    outb(0x20, 0x11);
    outb(0xA0, 0x11);
    // ICW2: Remap IRQ 0-7 → INT 32-39, IRQ 8-15 → INT 40-47
    outb(0x21, 0x20);
    outb(0xA1, 0x28);
    // ICW3
    outb(0x21, 0x04);
    outb(0xA1, 0x02);
    // ICW4
    outb(0x21, 0x01);
    outb(0xA1, 0x01);
    // Mask all interrupts (sonra açılacak)
    outb(0x21, 0xFF);
    outb(0xA1, 0xFF);
}

// ── PIT Timer (IRQ0) ───────────────────────────────
#define PIT_FREQ 1000   // 1000 Hz → 1ms tick

static volatile uint64_t tick_count = 0;

void timer_handler(void) {
    tick_count++;
    outb(0x20, 0x20);  // EOI
}

void pit_init(void) {
    uint32_t divisor = 1193182 / PIT_FREQ;
    outb(0x43, 0x36);
    outb(0x40, divisor & 0xFF);
    outb(0x40, (divisor >> 8) & 0xFF);
}

uint64_t get_ticks(void) { return tick_count; }

// ── Bellek Yönetimi (Basit Bitmap Allocator) ───────
#define MEM_START 0x200000   // 2MB'dan başla
#define PAGE_SIZE 4096
#define MAX_PAGES 65536      // 256MB

uint8_t page_bitmap[MAX_PAGES / 8];

static void bitmap_set(uint32_t page)   { page_bitmap[page/8] |=  (1 << (page%8)); }
static void bitmap_clear(uint32_t page) { page_bitmap[page/8] &= ~(1 << (page%8)); }
static int  bitmap_test(uint32_t page)  { return page_bitmap[page/8] & (1 << (page%8)); }

void pmm_init(void) {
    for (int i = 0; i < MAX_PAGES / 8; i++) page_bitmap[i] = 0;
    // İlk 2MB'yi "kullanılıyor" işaretle
    for (int i = 0; i < 512; i++) bitmap_set(i);
}

void *pmm_alloc(void) {
    for (int i = 0; i < MAX_PAGES; i++) {
        if (!bitmap_test(i)) {
            bitmap_set(i);
            return (void *)(uint64_t)(MEM_START + i * PAGE_SIZE);
        }
    }
    return NULL;  // OOM
}

void pmm_free(void *addr) {
    uint64_t a = (uint64_t)addr;
    if (a < MEM_START) return;
    uint32_t page = (a - MEM_START) / PAGE_SIZE;
    bitmap_clear(page);
}

// ── Basit Heap (kmalloc) ───────────────────────────
static uint8_t *heap_ptr = (uint8_t *)0x400000;  // 4MB'dan başla

void *kmalloc(size_t size) {
    void *ret = heap_ptr;
    heap_ptr += (size + 7) & ~7;  // 8-byte hizalama
    return ret;
}

// ── Process / Scheduler (Basit Round-Robin) ────────
#define MAX_PROCS 64
#define STACK_SIZE (PAGE_SIZE * 4)  // 16KB stack

typedef enum { PROC_EMPTY, PROC_READY, PROC_RUNNING, PROC_BLOCKED } ProcState;

typedef struct {
    uint64_t rsp;     // Stack pointer (context switch)
    uint64_t rip;     // Instruction pointer
    ProcState state;
    int pid;
    char name[32];
    uint64_t stack_base;
} Process;

Process proc_table[MAX_PROCS];
int current_pid = 0;
int proc_count  = 0;

void scheduler_init(void) {
    for (int i = 0; i < MAX_PROCS; i++)
        proc_table[i].state = PROC_EMPTY;
}

int proc_create(const char *name, void (*entry)(void)) {
    for (int i = 0; i < MAX_PROCS; i++) {
        if (proc_table[i].state == PROC_EMPTY) {
            Process *p = &proc_table[i];
            p->pid = i;
            p->state = PROC_READY;
            p->stack_base = (uint64_t)kmalloc(STACK_SIZE);
            p->rsp = p->stack_base + STACK_SIZE - 8;
            p->rip = (uint64_t)entry;
            // Stack'e giriş noktasını koy
            *(uint64_t *)p->rsp = (uint64_t)entry;
            for (int j = 0; j < 32 && name[j]; j++) p->name[j] = name[j];
            proc_count++;
            return i;
        }
    }
    return -1;
}

// ── Debug serial (port I/O ile, init oncesi kullanilabilir) ──
static void dbg_putc(char c) {
    while (!(inb(0x3F8 + 5) & 0x20));
    outb(0x3F8, c);
}
static void dbg_puts(const char *s) {
    while (*s) dbg_putc(*s++);
}

// ── Kernel Main ────────────────────────────────────
void kernel_main(void) {
    extern void serial_init(void);
    extern void serial_print(const char *s);
    extern void pmm_init(void);
    extern void pic_init(void);
    extern void idt_init(void);
    extern void pit_init(void);
    extern void scheduler_init(void);
    extern void syscall_init(void);
    extern void fd_init(void);
    extern void shell_run(void);

    // Debug: 'M' = entered kernel_main
    for (volatile int i = 0; i < 100000; i++);
    outb(0x3F8, 'M');

    for (int i = 0; i < VGA_COLS * VGA_ROWS; i++)
        VGA_BASE[i] = WHITE_ON_BLACK | ' ';

    kprint("MandyOs v0.1 - Server Kernel\n");
    kprint("================================\n");

    // Debug: COM1'e dogrudan yaz (henuz serial_init yok)
    dbg_puts("[1]\n");

    serial_init();
    dbg_puts("[2] serial_init OK\n");
    kprint("[OK] Serial port COM1\n");

    pmm_init();
    dbg_puts("[3] pmm_init OK\n");
    kprint("[OK] Physical Memory Manager\n");

    pic_init();
    dbg_puts("[4] pic_init OK\n");
    kprint("[OK] PIC 8259 yeniden eslestirildi\n");

    idt_init();
    dbg_puts("[5] idt_init OK\n");
    kprint("[OK] IDT yuklendi\n");

    pit_init();
    dbg_puts("[6] pit_init OK\n");
    kprint("[OK] PIT Timer 1000Hz\n");

    scheduler_init();
    dbg_puts("[7] scheduler_init OK\n");
    kprint("[OK] Zamanlayici (Round-Robin)\n");

    syscall_init();
    dbg_puts("[8] syscall_init OK\n");
    kprint("[OK] Syscall MSR kuruldu (LSTAR)\n");

    fd_init();
    dbg_puts("[9] fd_init OK\n");
    kprint("[OK] Dosya tanimlayicilar (stdin/stdout/stderr)\n");

    __asm__ volatile ("sti");
    dbg_puts("[10] interrupts enabled\n");
    kprint("[OK] Interruptlar aktif\n");

    kprint("\nMandyOs hazir. Shell baslatiliyor...\n");
    serial_print("[KERNEL] Boot tamamlandi.\n");

    dbg_puts("[11] calling shell_run...\n");
    shell_run();

    dbg_puts("[12] shell returned?!\n");
    for (;;) __asm__ volatile ("hlt");
}