; boot.asm - Stage 1 Bootloader (512 bytes, MBR)
[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Stage 2'yi 0x0500 adresine yükle (disk'ten)
    mov ah, 0x02        ; BIOS read sector
    mov al, 16          ; 16 sektör oku (Stage 2)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2'den başla
    mov dh, 0           ; Head 0
    mov bx, 0x0500      ; Yükleme adresi
    int 0x13
    jc disk_error

    jmp 0x0000:0x0500   ; Stage 2'ye atla

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

err_msg db "Disk Error!", 0

times 510-($-$$) db 0
dw 0xAA55               ; Boot imzası