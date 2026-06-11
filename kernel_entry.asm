; kernel_entry.asm
[SECTION .text]
[BITS 32]
[GLOBAL _start]

_start:
    ; Debug: 'E' = entered kernel entry
    mov dx, 0x3F8
    mov al, 'E'
    out dx, al

    call setup_paging

    ; Debug: '1' = paging tables set up
    mov dx, 0x3F8
    mov al, '1'
    out dx, al

    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax

    ; Debug: '2' = PAE enabled
    mov dx, 0x3F8
    mov al, '2'
    out dx, al

    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; Debug: '3' = LME set
    mov dx, 0x3F8
    mov al, '3'
    out dx, al

    mov eax, cr0
    or eax, (1 << 31)
    mov cr0, eax

    ; Debug: '4' = paging enabled
    mov dx, 0x3F8
    mov al, '4'
    out dx, al

    lgdt [gdt64_descriptor]

    ; Debug: '5' = GDT loaded
    mov dx, 0x3F8
    mov al, '5'
    out dx, al

    jmp 0x08:long_mode_entry

[BITS 64]
long_mode_entry:
    ; Debug: 'L' = entered long mode
    mov dx, 0x3F8
    mov al, 'L'
    out dx, al

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    xor ax, ax
    mov fs, ax
    mov gs, ax

    ; Debug: 'K' = about to call kernel_main
    mov dx, 0x3F8
    mov al, 'K'
    out dx, al

    extern kernel_main
    call kernel_main

    cli
.halt:
    hlt
    jmp .halt

; Default interrupt handler
[GLOBAL isr_default]
isr_default:
    iretq

[BITS 32]
setup_paging:
    ; Debug: 's' = setup_paging entered
    mov dx, 0x3F8
    mov al, 's'
    out dx, al

    ; PML4 -> PDPT -> PD -> PT identity map: ilk 64MB
    ; PML4@0x1000, PDPT@0x2000, PD@0x3000, PTs@0x4000-0x5000
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd

    mov edi, cr3
    mov dword [edi], 0x2003      ; PML4[0] -> PDPT @ 0x2000
    mov dword [edi+4], 0

    mov edi, 0x2000
    mov dword [edi], 0x3003      ; PDPT[0] -> PD @ 0x3000
    mov dword [edi+4], 0

    ; 64MB icin 2 PT gerek (her PT 2MB map eder)
    mov edi, 0x3000
    mov dword [edi], 0x4003      ; PD[0] -> PT @ 0x4000  (0-2MB)
    mov dword [edi+4], 0
    mov dword [edi+8], 0x5003    ; PD[1] -> PT @ 0x5000  (2-4MB)
    mov dword [edi+12], 0
    mov dword [edi+16], 0x6003   ; PD[2] -> PT @ 0x6000  (4-6MB)
    mov dword [edi+20], 0
    mov dword [edi+24], 0x7003   ; PD[3] -> PT @ 0x7000  (6-8MB)
    mov dword [edi+28], 0
    ; 8-64MB icin buyuk sayfa (2MB) kullan, PS=1
    ; Her PDE = (fiziksel_adres & 0xFFE00000) | 0x83
    mov ecx, 4
    mov ebx, 0x00800083          ; 8MB, Present|Writable|PS
.next_huge:
    mov dword [edi+ecx*8], ebx
    mov dword [edi+ecx*8+4], 0
    add ebx, 0x200000            ; sonraki 2MB
    inc ecx
    cmp ecx, 32
    jb .next_huge

    ; PT@0x4000: 0-2MB
    mov edi, 0x4000
    mov ebx, 0x00000003
    mov ecx, 512
.map_pt0:
    mov dword [edi], ebx
    mov dword [edi+4], 0
    add ebx, 0x1000
    add edi, 8
    loop .map_pt0

    ; PT@0x5000: 2-4MB
    mov edi, 0x5000
    mov ebx, 0x00200003
    mov ecx, 512
.map_pt1:
    mov dword [edi], ebx
    mov dword [edi+4], 0
    add ebx, 0x1000
    add edi, 8
    loop .map_pt1

    ; PT@0x6000: 4-6MB
    mov edi, 0x6000
    mov ebx, 0x00400003
    mov ecx, 512
.map_pt2:
    mov dword [edi], ebx
    mov dword [edi+4], 0
    add ebx, 0x1000
    add edi, 8
    loop .map_pt2

    ; PT@0x7000: 6-8MB
    mov edi, 0x7000
    mov ebx, 0x00600003
    mov ecx, 512
.map_pt3:
    mov dword [edi], ebx
    mov dword [edi+4], 0
    add ebx, 0x1000
    add edi, 8
    loop .map_pt3

    ; Debug: 'S' = setup_paging done
    push dx
    push ax
    mov dx, 0x3F8
    mov al, 'S'
    out dx, al
    pop ax
    pop dx

    ret

; 64-bit GDT
gdt64:
    dq 0
    dq 0x00AF9A000000FFFF   ; Code segment
    dq 0x00AF92000000FFFF   ; Data segment
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1
    dq gdt64
