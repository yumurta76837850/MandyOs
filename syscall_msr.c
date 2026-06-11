// syscall_msr.c
#include <stdint.h>

// MSR adresleri
#define MSR_EFER   0xC0000080
#define MSR_STAR   0xC0000081
#define MSR_LSTAR  0xC0000082
#define MSR_SFMASK 0xC0000084

static inline void wrmsr(uint32_t msr, uint64_t val) {
    uint32_t lo = val & 0xFFFFFFFF;
    uint32_t hi = val >> 32;
    __asm__ volatile ("wrmsr" :: "c"(msr), "a"(lo), "d"(hi));
}

static inline uint64_t rdmsr(uint32_t msr) {
    uint32_t lo, hi;
    __asm__ volatile ("rdmsr" : "=a"(lo), "=d"(hi) : "c"(msr));
    return ((uint64_t)hi << 32) | lo;
}

extern void syscall_entry(void);  // assembly stub

void syscall_init(void) {
    // EFER'de SCE (Syscall Enable) bitini aç
    uint64_t efer = rdmsr(MSR_EFER);
    efer |= (1 << 0);
    wrmsr(MSR_EFER, efer);

    // STAR: Kernel CS = 0x08, User CS = 0x1B (ring 3)
    // [63:48]=user_cs-16 [47:32]=kernel_cs
    uint64_t star = ((uint64_t)0x1B << 48) | ((uint64_t)0x08 << 32);
    wrmsr(MSR_STAR, star);

    // LSTAR: SYSCALL gelince atlayacağı adres
    wrmsr(MSR_LSTAR, (uint64_t)syscall_entry);

    // SFMASK: SYSCALL anında kapatılacak flag'ler (IF dahil)
    wrmsr(MSR_SFMASK, 0x200);  // IF flag'i kapat
}