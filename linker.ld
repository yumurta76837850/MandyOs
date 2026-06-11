OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

SECTIONS {
    . = 0x100000;

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(COMMON)
        *(.bss*)
    }

    /DISCARD/ : {
        *(.note*)
        *(.eh_frame*)
        *(.pdata*)
        *(.xdata*)
        *(.got*)
        *(.rdata*)
        *(.comment*)
        *(.debug*)
        *(.llvm*)
        *(.gnu*)
        *(SORT(.text$*))
    }
}
