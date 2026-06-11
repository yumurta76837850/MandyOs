; syscall_entry.asm
; x86_64 SYSCALL komutu: rax=numara, rdi,rsi,rdx,r10,r8,r9=argumanlar
[SECTION .text]
[BITS 64]
[GLOBAL syscall_entry]
[EXTERN syscall_dispatch]

syscall_entry:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Kaynak: SYSCALL ABI (user) -> Hedef: C ABI (syscall_dispatch)
    ; User:  rax=num, rdi=a1, rsi=a2, rdx=a3, r10=a4, r8=a5, r9=a6
    ; C:     rdi=num, rsi=a1, rdx=a2, rcx=a3, r8=a4,  r9=a5
    ;
    ; Mapping:
    ;   C rdi = rax
    ;   C rsi = original rdi (arg1)
    ;   C rdx = original rsi (arg2)
    ;   C rcx = original rdx (arg3)
    ;   C r8  = original r10 (arg4)
    ;   C r9  = original r8  (arg5)

    mov r11, rdi        ; r11 = original arg1 (user rdi)
    mov r12, r8         ; r12 = original arg5 (user r8, C r9'a gidecek)

    mov rdi, rax        ; C arg1 = syscall num
    mov rsi, r11        ; C arg2 = original arg1
    mov rdx, rsi        ; C arg3 = original arg2
    mov rcx, rdx        ; C arg4 = original arg3
    mov r8,  r10        ; C arg5 = original arg4
    mov r9,  r12        ; C arg6 = original arg5

    call syscall_dispatch

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp

    sysretq
