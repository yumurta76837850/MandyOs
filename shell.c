// shell.c — MandyOs Kernel Shell
#include "syscall.h"
#include <stdint.h>
#include <stddef.h>

// ─── Harici ───────────────────────────────────────
extern void serial_print(const char *s);
extern void serial_write(char c);
extern uint8_t serial_read_byte(void);
extern uint64_t get_ticks(void);
extern void *kmalloc(size_t);
extern int current_pid;  // kernel.c'de global

// ─── String yardımcıları ──────────────────────────
static size_t kstrlen(const char *s) {
    size_t n = 0;
    while (s[n]) n++;
    return n;
}

static int kstrcmp(const char *a, const char *b) {
    while (*a && *a == *b) { a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}

static int kstrncmp(const char *a, const char *b, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (a[i] != b[i]) return (unsigned char)a[i] - (unsigned char)b[i];
        if (!a[i]) return 0;
    }
    return 0;
}

static void kprint_num(uint64_t n) {
    if (n == 0) { serial_write('0'); return; }
    char buf[21];
    int  i = 20;
    buf[20] = '\0';
    while (n > 0) { buf[--i] = '0' + (n % 10); n /= 10; }
    serial_print(buf + i);
}

static void kprint_hex(uint64_t n) {
    const char *hex = "0123456789ABCDEF";
    serial_print("0x");
    for (int i = 60; i >= 0; i -= 4)
        serial_write(hex[(n >> i) & 0xF]);
}

// ─── Komut ayrıştırma ────────────────────────────
#define MAX_ARGS  16
#define MAX_LINE  256

typedef struct {
    char  raw[MAX_LINE];
    char *argv[MAX_ARGS];
    int   argc;
} Command;

static void parse_command(Command *cmd) {
    cmd->argc = 0;
    char *p = cmd->raw;

    while (*p == ' ') p++;

    while (*p && cmd->argc < MAX_ARGS) {
        cmd->argv[cmd->argc++] = p;
        while (*p && *p != ' ') p++;
        if (*p) { *p = '\0'; p++; }
        while (*p == ' ') p++;
    }
}

// ─── Komut: help ──────────────────────────────────
static void cmd_help(void) {
    serial_print(
        "\r\nMandyOs Komutlari:\r\n"
        "  help       - Bu yardim menusu\r\n"
        "  uptime     - Sistem calisma suresi\r\n"
        "  mem        - Bellek durumu\r\n"
        "  ps         - Calisan processler\r\n"
        "  pid        - Mevcut PID\r\n"
        "  clear      - Ekrani temizle\r\n"
        "  echo <msg> - Mesaj yazdir\r\n"
        "  reboot     - Sistemi yeniden basla\r\n"
        "  halt       - Sistemi durdur\r\n"
        "  info       - Sistem bilgisi\r\n"
        "  ticks      - Ham tick sayaci\r\n"
        "  memtest    - Basit bellek testi\r\n"
    );
}

// ─── Komut: uptime ────────────────────────────────
static void cmd_uptime(void) {
    uint64_t sec  = get_ticks() / 1000;
    uint64_t min  = sec / 60;
    uint64_t hour = min / 60;
    sec  %= 60;
    min  %= 60;

    serial_print("\r\nUptime: ");
    kprint_num(hour); serial_print("s ");
    kprint_num(min);  serial_print("d ");
    kprint_num(sec);  serial_print("sn\r\n");
}

// ─── Komut: mem ───────────────────────────────────
extern uint8_t page_bitmap[];
#define MAX_PAGES 65536

static void cmd_mem(void) {
    int used = 0;
    for (int i = 0; i < MAX_PAGES; i++) {
        if (page_bitmap[i / 8] & (1 << (i % 8))) used++;
    }
    int total = MAX_PAGES;
    int free  = total - used;

    serial_print("\r\nBellek Durumu:\r\n");
    serial_print("  Toplam : "); kprint_num(total * 4); serial_print(" KB\r\n");
    serial_print("  Kullanilan: "); kprint_num(used  * 4); serial_print(" KB\r\n");
    serial_print("  Bos    : "); kprint_num(free  * 4); serial_print(" KB\r\n");
}

// ─── Komut: ps ────────────────────────────────────
typedef enum { PROC_EMPTY, PROC_READY, PROC_RUNNING, PROC_BLOCKED } ProcState;
typedef struct {
    uint64_t  rsp;
    uint64_t  rip;
    ProcState state;
    int       pid;
    char      name[32];
    uint64_t  stack_base;
} Process;

extern Process proc_table[];
#define MAX_PROCS 64

static const char *proc_state_str(ProcState s) {
    switch (s) {
        case PROC_READY:   return "HAZIR  ";
        case PROC_RUNNING: return "CALISIYOR";
        case PROC_BLOCKED: return "BLOKLU ";
        default:           return "?      ";
    }
}

static void cmd_ps(void) {
    serial_print("\r\nPID  DURUM       AD\r\n");
    serial_print("---  ---------   ----------\r\n");
    for (int i = 0; i < MAX_PROCS; i++) {
        if (proc_table[i].state == PROC_EMPTY) continue;
        kprint_num(proc_table[i].pid);
        serial_print("    ");
        serial_print(proc_state_str(proc_table[i].state));
        serial_print("   ");
        serial_print(proc_table[i].name);
        serial_print("\r\n");
    }
}

// ─── Komut: info ──────────────────────────────────
static void cmd_info(void) {
    serial_print(
        "\r\nMandyOs v0.8\r\n"
        "  Mimari  : x86_64\r\n"
        "  Mod     : 64-bit Long Mode\r\n"
        "  Timer   : PIT 1000 Hz\r\n"
        "  Scheduler: Round-Robin\r\n"
        "  Arayuz  : Serial COM1 (38400)\r\n"
    );
}

// ─── Komut: memtest ───────────────────────────────
static void cmd_memtest(void) {
    serial_print("\r\nBellek testi basliyor...\r\n");
    volatile uint8_t *p = (volatile uint8_t *)0x300000;  // 3MB sabit alan
    uint8_t pattern = 0xAB;
    int errors = 0;

    for (int i = 0; i < 4096; i++) p[i] = pattern;
    for (int i = 0; i < 4096; i++) {
        if (p[i] != pattern) errors++;
    }

    if (errors == 0)
        serial_print("  [PASS] 4096 byte test gecti\r\n");
    else {
        serial_print("  [FAIL] Hata sayisi: ");
        kprint_num(errors);
        serial_print("\r\n");
    }
}

// ─── Komut: reboot ────────────────────────────────
static void cmd_reboot(void) {
    serial_print("\r\nYeniden baslatiliyor...\r\n");
    // PS/2 controller reset
    uint8_t tmp;
    do {
        __asm__ volatile (
            "inb $0x64, %0" : "=a"(tmp)
        );
    } while (tmp & 2);
    __asm__ volatile ("outb %0, $0x64" :: "a"((uint8_t)0xFE));
    for (;;) __asm__ volatile ("hlt");
}

// ─── Komut: halt ──────────────────────────────────
static void cmd_halt(void) {
    serial_print("\r\nSistem durduruluyor... Hosca kalin.\r\n");
    __asm__ volatile ("cli");
    for (;;) __asm__ volatile ("hlt");
}

// ─── Echo ─────────────────────────────────────────
static void cmd_echo(Command *cmd) {
    serial_print("\r\n");
    for (int i = 1; i < cmd->argc; i++) {
        serial_print(cmd->argv[i]);
        if (i < cmd->argc - 1) serial_write(' ');
    }
    serial_print("\r\n");
}

// ─── Satır okuma ──────────────────────────────────
static void shell_readline(char *buf, int max) {
    int i = 0;
    while (i < max - 1) {
        char c = (char)serial_read_byte();

        if (c == '\r' || c == '\n') {
            serial_print("\r\n");
            break;
        }
        if ((c == 127 || c == '\b') && i > 0) {
            // Backspace
            serial_print("\b \b");
            i--;
            continue;
        }
        if (c < 32) continue;  // Kontrol karakterlerini atla

        buf[i++] = c;
        serial_write(c);       // Echo
    }
    buf[i] = '\0';
}

// ─── Shell Ana Döngüsü ────────────────────────────
void shell_run(void) {
    serial_print(
        "\r\n"
        "  ███╗   ███╗ █████╗ ███╗   ██╗██████╗ ██╗   ██╗ ██████╗ ███████╗\r\n"
        "  ████╗ ████║██╔══██╗████╗  ██║██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔════╝\r\n"
        "  ██╔████╔██║███████║██╔██╗ ██║██║  ██║ ╚████╔╝ ██║   ██║███████╗\r\n"
        "  ██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║  ╚██╔╝  ██║   ██║╚════██║\r\n"
        "  ██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝   ██║   ╚██████╔╝███████║\r\n"
        "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝    ╚═╝    ╚═════╝ ╚══════╝\r\n"
        "\r\n"
        "  MandyOs v0.8 - Server Kernel Shell\r\n"
        "  'help' yazin komutlari goruntuleyin.\r\n\r\n"
    );

    Command cmd;

    for (;;) {
        serial_print("mandyos# ");
        shell_readline(cmd.raw, MAX_LINE);

        if (cmd.raw[0] == '\0') continue;

        parse_command(&cmd);
        if (cmd.argc == 0) continue;

        const char *c = cmd.argv[0];

        if      (!kstrcmp(c, "help"))    cmd_help();
        else if (!kstrcmp(c, "uptime"))  cmd_uptime();
        else if (!kstrcmp(c, "mem"))     cmd_mem();
        else if (!kstrcmp(c, "ps"))      cmd_ps();
        else if (!kstrcmp(c, "pid"))     { serial_print("\r\nPID: "); kprint_num(current_pid); serial_print("\r\n"); }
        else if (!kstrcmp(c, "info"))    cmd_info();
        else if (!kstrcmp(c, "ticks"))   { serial_print("\r\nTicks: "); kprint_num(get_ticks()); serial_print("\r\n"); }
        else if (!kstrcmp(c, "memtest")) cmd_memtest();
        else if (!kstrcmp(c, "echo"))    cmd_echo(&cmd);
        else if (!kstrcmp(c, "clear"))   serial_print("\033[2J\033[H");
        else if (!kstrcmp(c, "reboot"))  cmd_reboot();
        else if (!kstrcmp(c, "halt"))    cmd_halt();
        else {
            serial_print("\r\nBilinmeyen komut: '");
            serial_print(c);
            serial_print("' - 'help' yazin.\r\n");
        }
    }
}