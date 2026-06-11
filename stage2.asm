; stage2.asm - Protected Mode'a gecis ve kernel yukleme
[BITS 16]
[ORG 0x0500]

stage2_start:
    mov [boot_drive], dl

    mov dx, 0x3F8
    mov al, 'S'
    out dx, al

    ; A20 ac
    in al, 0x92
    or al, 2
    out 0x92, al

    call load_kernel

    mov dx, 0x3F8
    mov al, 'K'
    out dx, al

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:protected_mode

[BITS 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov esp, 0x90000

    ; Debug: 'P' = entered protected mode
    mov dx, 0x3F8
    mov al, 'P'
    out dx, al

    ; Copy kernel from 0x10000 to 0x100000
    mov esi, 0x10000
    mov edi, 0x100000
    mov ecx, 16384
    cld
    rep movsd

    ; Debug: 'C' = copy done
    mov dx, 0x3F8
    mov al, 'C'
    out dx, al

    jmp 0x100000

[BITS 16]

boot_drive: db 0

; Load kernel to buffer at 0x10000 (ES=0x1000, BX=0)
; Kernel at LBA 17 (CHS 0,0,18), 97 sectors
; Read 1 sector at a time, 97 sectors total from CHS(0,0,18)
load_kernel:
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ch, 0
    mov cl, 18               ; start sector
    mov dh, 0
    mov dl, [boot_drive]

    mov si, 97               ; total sectors to read

.next:
    mov ah, 0x02
    mov al, 1
    int 0x13
    jc disk_error

    ; advance buffer by 512 bytes (segment += 0x20)
    mov ax, es
    add ax, 0x20
    mov es, ax
    xor bx, bx

    ; advance CHS: inc sector, handle head/cylinder wrap
    inc cl
    cmp cl, 19
    jb .cont
    mov cl, 1
    inc dh
    cmp dh, 2
    jb .cont
    mov dh, 0
    inc ch
.cont:
    dec si
    jnz .next

    ret

disk_error:
    mov si, err_msg
.print:
    lodsb
    or al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    hlt
    jmp .halt

err_msg db "Kernel Yukleme Hatasi!", 0

; ---- GDT ----
gdt_start:
gdt_null:
    dq 0x0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
