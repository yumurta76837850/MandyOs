// syscall.c
#include "syscall.h"
#include <stdint.h>
#include <stddef.h>

// ─── Harici bağımlılıklar ─────────────────────────
extern void serial_write(char c);
extern void serial_print(const char *s);
extern uint64_t get_ticks(void);

// Aktif process PID (scheduler'dan)
extern int current_pid;
extern int proc_count;
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

// ─── Dosya Sistemi (Basit In-Memory VFS stub) ─────
#define MAX_FD   32
#define BUF_SIZE 4096

typedef enum { FD_NONE, FD_SERIAL, FD_PIPE, FD_FILE } FDType;

typedef struct {
    FDType type;
    int    flags;
    size_t pos;
} FileDescriptor;

static FileDescriptor fd_table[MAX_FD];

void fd_init(void) {
    for (int i = 0; i < MAX_FD; i++)
        fd_table[i].type = FD_NONE;
    // Standart fd'ler
    fd_table[STDIN_FD ].type = FD_SERIAL;
    fd_table[STDOUT_FD].type = FD_SERIAL;
    fd_table[STDERR_FD].type = FD_SERIAL;
}

// ─── sys_write ────────────────────────────────────
static syscall_ret_t sys_write(int fd, const char *buf, size_t count) {
    if (fd < 0 || fd >= MAX_FD)         return EBADF;
    if (fd_table[fd].type == FD_NONE)   return EBADF;
    if (!buf)                            return EINVAL;

    // Şimdilik tüm yazma → serial
    for (size_t i = 0; i < count; i++)
        serial_write(buf[i]);

    return (syscall_ret_t)count;
}

// ─── sys_read ─────────────────────────────────────
// Serial porttan 1 byte okur (blocking)
extern uint8_t serial_read_byte(void);  // serial.c'de tanımlı

static syscall_ret_t sys_read(int fd, char *buf, size_t count) {
    if (fd < 0 || fd >= MAX_FD)       return EBADF;
    if (fd_table[fd].type == FD_NONE) return EBADF;
    if (!buf || count == 0)           return EINVAL;

    size_t i = 0;
    while (i < count) {
        buf[i] = (char)serial_read_byte();
        if (buf[i] == '\n' || buf[i] == '\r') {
            buf[i] = '\0';
            break;
        }
        i++;
    }
    return (syscall_ret_t)i;
}

// ─── sys_exit ─────────────────────────────────────
#define MAX_PROCS 64

void proc_exit(int pid, int code) {
    (void)code;
    if (pid >= 0 && pid < MAX_PROCS) {
        proc_table[pid].state = PROC_EMPTY;
        proc_count--;
    }
}

static syscall_ret_t sys_exit(int code) {
    proc_exit(current_pid, code);
    __builtin_unreachable();
}

// ─── sys_getpid ───────────────────────────────────
static syscall_ret_t sys_getpid(void) {
    return (syscall_ret_t)current_pid;
}

// ─── sys_sleep ────────────────────────────────────
static syscall_ret_t sys_sleep(uint64_t ms) {
    uint64_t target = get_ticks() + ms;
    while (get_ticks() < target)
        __asm__ volatile ("pause");
    return ESUCCESS;
}

// ─── sys_uptime ───────────────────────────────────
static syscall_ret_t sys_uptime(void) {
    return (syscall_ret_t)(get_ticks() / 1000);  // saniye cinsinden
}

// ─── Dispatch Tablosu ─────────────────────────────
syscall_ret_t syscall_dispatch(
    uint64_t num,
    uint64_t arg1, uint64_t arg2, uint64_t arg3,
    uint64_t arg4, uint64_t arg5)
{
    (void)arg4; (void)arg5;

    switch (num) {
        case SYS_READ:    return sys_read((int)arg1, (char *)arg2, (size_t)arg3);
        case SYS_WRITE:   return sys_write((int)arg1, (const char *)arg2, (size_t)arg3);
        case SYS_EXIT:    return sys_exit((int)arg1);
        case SYS_GETPID:  return sys_getpid();
        case SYS_SLEEP:   return sys_sleep(arg1);
        case SYS_UPTIME:  return sys_uptime();
        default:
            serial_print("[SYSCALL] Bilinmeyen: ");
            return EINVAL;
    }
}