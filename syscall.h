// syscall.h
#pragma once
#include <stdint.h>
#include <stddef.h>

// Sistem çağrısı numaraları (Linux uyumlu subset)
#define SYS_READ    0
#define SYS_WRITE   1
#define SYS_OPEN    2
#define SYS_CLOSE   3
#define SYS_EXIT    60
#define SYS_FORK    57
#define SYS_EXEC    59
#define SYS_GETPID  39
#define SYS_SLEEP   35
#define SYS_UPTIME  100   // özel: sistem uptime (tick)

// Hata kodları
#define ESUCCESS   0
#define EPERM     -1
#define ENOENT    -2
#define EBADF     -9
#define EINVAL   -22

// Dosya tanımlayıcıları (standart)
#define STDIN_FD   0
#define STDOUT_FD  1
#define STDERR_FD  2

// Syscall sonuç tipi
typedef int64_t syscall_ret_t;

// Syscall handler prototipi
syscall_ret_t syscall_dispatch(
    uint64_t num,
    uint64_t arg1,
    uint64_t arg2,
    uint64_t arg3,
    uint64_t arg4,
    uint64_t arg5
);