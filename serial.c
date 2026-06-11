#include <stdint.h>
#include "io.h"

#define COM1 0x3F8

void serial_init(void) {
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x80);
    outb(COM1 + 0, 0x03);
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03);
    outb(COM1 + 2, 0xC7);
    outb(COM1 + 4, 0x0B);
}

void serial_write(char c) {
    while (!(inb(COM1 + 5) & 0x20));
    outb(COM1, c);
}

void serial_print(const char *s) {
    while (*s) serial_write(*s++);
}

uint8_t serial_read_byte(void) {
    while (!(inb(COM1 + 5) & 0x01))
        __asm__ volatile ("pause");
    return inb(COM1);
}
