	.file	"kernel.c"
	.text
	.p2align 4
	.globl	kprint
	.def	kprint;	.scl	2;	.type	32;	.endef
	.seh_proc	kprint
kprint:
	.seh_endprologue
	movzbl	(%rcx), %eax
	testb	%al, %al
	je	.L1
	movl	cursor_y(%rip), %r8d
	addq	$1, %rcx
	cmpb	$10, %al
	je	.L5
	movl	cursor_x(%rip), %edx
	cmpl	$79, %edx
	jg	.L7
	xorl	%r11d, %r11d
	jmp	.L6
	.p2align 5
	.p2align 4,,10
	.p2align 3
.L5:
	movzbl	(%rcx), %eax
	addl	$1, %r8d
	testb	%al, %al
	je	.L14
	addq	$1, %rcx
	cmpb	$10, %al
	je	.L5
	movl	$1, %r11d
	xorl	%edx, %edx
.L6:
	leal	1(%rdx), %r9d
	cmpl	$24, %r8d
	jle	.L12
.L15:
	movl	$1, %r11d
	xorl	%r8d, %r8d
.L9:
	movslq	%edx, %rdx
	orb	$15, %ah
	addq	%rdx, %rdx
	movw	%ax, 753664(%rdx)
	movzbl	(%rcx), %eax
	testb	%al, %al
	je	.L10
	addq	$1, %rcx
	cmpb	$10, %al
	je	.L5
	cmpl	$80, %r9d
	jne	.L31
.L7:
	addl	$1, %r8d
	movl	$1, %r9d
	movl	$1, %r11d
	xorl	%edx, %edx
	cmpl	$24, %r8d
	jg	.L15
.L12:
	leal	(%r8,%r8,4), %r10d
	sall	$4, %r10d
	addl	%r10d, %edx
	jmp	.L9
	.p2align 4,,10
	.p2align 3
.L31:
	leal	(%r8,%r8,4), %r10d
	movl	%r9d, %edx
	addl	$1, %r9d
	sall	$4, %r10d
	addl	%r10d, %edx
	jmp	.L9
	.p2align 4,,10
	.p2align 3
.L10:
	testb	%r11b, %r11b
	je	.L13
.L4:
	movl	%r8d, cursor_y(%rip)
.L13:
	movl	%r9d, cursor_x(%rip)
.L1:
	ret
	.p2align 4,,10
	.p2align 3
.L14:
	xorl	%r9d, %r9d
	jmp	.L4
	.seh_endproc
	.p2align 4
	.globl	idt_set_gate
	.def	idt_set_gate;	.scl	2;	.type	32;	.endef
	.seh_proc	idt_set_gate
idt_set_gate:
	pushq	%rbx
	.seh_pushreg	%rbx
	.seh_endprologue
	leaq	idt(%rip), %r9
	movl	$8, %eax
	xorl	%ebx, %ebx
	movslq	%ecx, %rcx
	salq	$4, %rcx
	movq	%rcx, %r10
	movw	%dx, (%r9,%rcx)
	movw	%ax, 2(%r9,%rcx)
	movl	%r8d, %ecx
	movl	$0, 12(%r9,%r10)
	movb	%cl, %bh
	movq	%rdx, %rcx
	shrq	$32, %rdx
	shrq	$16, %rcx
	movw	%bx, 4(%r9,%r10)
	movw	%cx, 6(%r9,%r10)
	movl	%edx, 8(%r9,%r10)
	popq	%rbx
	ret
	.seh_endproc
	.p2align 4
	.globl	idt_init
	.def	idt_init;	.scl	2;	.type	32;	.endef
	.seh_proc	idt_init
idt_init:
	pushq	%rbx
	.seh_pushreg	%rbx
	.seh_endprologue
	leaq	isr_default(%rip), %rcx
	movq	%rcx, %rdx
	movq	%rcx, %rax
	movd	%ecx, %xmm1
	movl	$8, %ecx
	shrq	$32, %rax
	pinsrw	$1, %ecx, %xmm1
	shrq	$16, %rdx
	punpckldq	%xmm1, %xmm1
	movd	%eax, %xmm0
	leaq	4+idt(%rip), %rax
	punpcklqdq	%xmm1, %xmm1
	punpcklqdq	%xmm0, %xmm0
	leaq	4096(%rax), %rbx
	movdqa	%xmm1, %xmm2
	movd	%xmm1, %r11d
	pshufd	$85, %xmm1, %xmm3
	punpckhdq	%xmm1, %xmm2
	pshufd	$255, %xmm1, %xmm1
	movq	%xmm0, %rcx
	movd	%xmm2, %r9d
	movd	%xmm1, %r8d
	.p2align 4
	.p2align 3
.L34:
	movl	$-29184, %r10d
	movl	%r11d, -4(%rax)
	subq	$-128, %rax
	movw	%r10w, -128(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -112(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -96(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -80(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -64(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -48(%rax)
	movl	$-29184, %r10d
	movw	%r10w, -32(%rax)
	movl	$-29184, %r10d
	movd	%xmm3, -116(%rax)
	movl	%r9d, -100(%rax)
	movl	%r8d, -84(%rax)
	movl	%r11d, -68(%rax)
	movd	%xmm3, -52(%rax)
	movl	%r9d, -36(%rax)
	movl	%r8d, -20(%rax)
	movw	%r10w, -16(%rax)
	movw	%dx, -126(%rax)
	movw	%dx, -110(%rax)
	movw	%dx, -94(%rax)
	movw	%dx, -78(%rax)
	movw	%dx, -62(%rax)
	movw	%dx, -46(%rax)
	movw	%dx, -30(%rax)
	movw	%dx, -14(%rax)
	movq	%rcx, -124(%rax)
	movhps	%xmm0, -108(%rax)
	movq	%rcx, -92(%rax)
	movhps	%xmm0, -76(%rax)
	movq	%rcx, -60(%rax)
	movhps	%xmm0, -44(%rax)
	movq	%rcx, -28(%rax)
	movhps	%xmm0, -12(%rax)
	cmpq	%rbx, %rax
	jne	.L34
	movl	$4095, %eax
	movw	%ax, idt_desc(%rip)
	leaq	idt(%rip), %rax
	movq	%rax, 2+idt_desc(%rip)
/APP
 # 65 "kernel.c" 1
	lidt idt_desc(%rip)
 # 0 "" 2
/NO_APP
	popq	%rbx
	ret
	.seh_endproc
	.p2align 4
	.globl	pic_init
	.def	pic_init;	.scl	2;	.type	32;	.endef
	.seh_proc	pic_init
pic_init:
	.seh_endprologue
	movl	$17, %eax
/APP
 # 5 "io.h" 1
	outb %al, $32
 # 0 "" 2
 # 5 "io.h" 1
	outb %al, $160
 # 0 "" 2
/NO_APP
	movl	$32, %eax
/APP
 # 5 "io.h" 1
	outb %al, $33
 # 0 "" 2
/NO_APP
	movl	$40, %eax
/APP
 # 5 "io.h" 1
	outb %al, $161
 # 0 "" 2
/NO_APP
	movl	$4, %eax
/APP
 # 5 "io.h" 1
	outb %al, $33
 # 0 "" 2
/NO_APP
	movl	$2, %eax
/APP
 # 5 "io.h" 1
	outb %al, $161
 # 0 "" 2
/NO_APP
	movl	$1, %eax
/APP
 # 5 "io.h" 1
	outb %al, $33
 # 0 "" 2
 # 5 "io.h" 1
	outb %al, $161
 # 0 "" 2
/NO_APP
	movl	$-1, %eax
/APP
 # 5 "io.h" 1
	outb %al, $33
 # 0 "" 2
 # 5 "io.h" 1
	outb %al, $161
 # 0 "" 2
/NO_APP
	ret
	.seh_endproc
	.p2align 4
	.globl	timer_handler
	.def	timer_handler;	.scl	2;	.type	32;	.endef
	.seh_proc	timer_handler
timer_handler:
	.seh_endprologue
	movq	tick_count(%rip), %rax
	addq	$1, %rax
	movq	%rax, tick_count(%rip)
	movl	$32, %eax
/APP
 # 5 "io.h" 1
	outb %al, $32
 # 0 "" 2
/NO_APP
	ret
	.seh_endproc
	.p2align 4
	.globl	pit_init
	.def	pit_init;	.scl	2;	.type	32;	.endef
	.seh_proc	pit_init
pit_init:
	.seh_endprologue
	movl	$54, %eax
/APP
 # 5 "io.h" 1
	outb %al, $67
 # 0 "" 2
/NO_APP
	movl	$-87, %eax
/APP
 # 5 "io.h" 1
	outb %al, $64
 # 0 "" 2
/NO_APP
	movl	$4, %eax
/APP
 # 5 "io.h" 1
	outb %al, $64
 # 0 "" 2
/NO_APP
	ret
	.seh_endproc
	.p2align 4
	.globl	get_ticks
	.def	get_ticks;	.scl	2;	.type	32;	.endef
	.seh_proc	get_ticks
get_ticks:
	.seh_endprologue
	movq	tick_count(%rip), %rax
	ret
	.seh_endproc
	.p2align 4
	.globl	pmm_init
	.def	pmm_init;	.scl	2;	.type	32;	.endef
	.seh_proc	pmm_init
pmm_init:
	.seh_endprologue
	leaq	page_bitmap(%rip), %r8
	pxor	%xmm0, %xmm0
	movq	%r8, %rax
	leaq	8192(%r8), %rdx
	.p2align 4
	.p2align 4
	.p2align 3
.L41:
	movups	%xmm0, (%rax)
	addq	$32, %rax
	movups	%xmm0, -16(%rax)
	cmpq	%rdx, %rax
	jne	.L41
	xorl	%eax, %eax
	.p2align 6
	.p2align 4
	.p2align 3
.L42:
	movl	%eax, %edx
	movl	%eax, %ecx
	movl	$1, %r10d
	addl	$1, %eax
	shrl	$3, %edx
	andl	$7, %ecx
	sall	%cl, %r10d
	orb	%r10b, (%r8,%rdx)
	cmpl	$512, %eax
	jne	.L42
	ret
	.seh_endproc
	.p2align 4
	.globl	pmm_alloc
	.def	pmm_alloc;	.scl	2;	.type	32;	.endef
	.seh_proc	pmm_alloc
pmm_alloc:
	.seh_endprologue
	xorl	%eax, %eax
	leaq	page_bitmap(%rip), %r10
	jmp	.L49
	.p2align 6
	.p2align 4,,10
	.p2align 3
.L47:
	addl	$1, %eax
	cmpl	$65536, %eax
	je	.L51
.L49:
	movl	%eax, %r8d
	movl	%eax, %ecx
	movl	$1, %r9d
	shrl	$3, %r8d
	andl	$7, %ecx
	movzbl	(%r10,%r8), %edx
	sall	%cl, %r9d
	movl	%r9d, %ecx
	movzbl	%dl, %r9d
	testl	%ecx, %r9d
	jne	.L47
	addl	$512, %eax
	orl	%ecx, %edx
	sall	$12, %eax
	movb	%dl, (%r10,%r8)
	cltq
	ret
	.p2align 4,,10
	.p2align 3
.L51:
	xorl	%eax, %eax
	ret
	.seh_endproc
	.p2align 4
	.globl	pmm_free
	.def	pmm_free;	.scl	2;	.type	32;	.endef
	.seh_proc	pmm_free
pmm_free:
	.seh_endprologue
	cmpq	$2097151, %rcx
	ja	.L54
	ret
	.p2align 4,,10
	.p2align 3
.L54:
	shrq	$12, %rcx
	leaq	page_bitmap(%rip), %r8
	leal	-512(%rcx), %edx
	andl	$7, %ecx
	shrl	$3, %edx
	movzbl	(%r8,%rdx), %eax
	btrl	%ecx, %eax
	movb	%al, (%r8,%rdx)
	ret
	.seh_endproc
	.p2align 4
	.globl	kmalloc
	.def	kmalloc;	.scl	2;	.type	32;	.endef
	.seh_proc	kmalloc
kmalloc:
	.seh_endprologue
	movq	heap_ptr(%rip), %rax
	addq	$7, %rcx
	andq	$-8, %rcx
	addq	%rax, %rcx
	movq	%rcx, heap_ptr(%rip)
	ret
	.seh_endproc
	.p2align 4
	.globl	scheduler_init
	.def	scheduler_init;	.scl	2;	.type	32;	.endef
	.seh_proc	scheduler_init
scheduler_init:
	.seh_endprologue
	leaq	16+proc_table(%rip), %rax
	leaq	4096(%rax), %rdx
	.p2align 5
	.p2align 4
	.p2align 3
.L57:
	movl	$0, (%rax)
	subq	$-128, %rax
	movl	$0, -64(%rax)
	cmpq	%rdx, %rax
	jne	.L57
	ret
	.seh_endproc
	.p2align 4
	.globl	proc_create
	.def	proc_create;	.scl	2;	.type	32;	.endef
	.seh_proc	proc_create
proc_create:
	.seh_endprologue
	leaq	proc_table(%rip), %r9
	xorl	%r8d, %r8d
	movq	%r9, %rax
	jmp	.L66
	.p2align 5
	.p2align 4,,10
	.p2align 3
.L61:
	addl	$1, %r8d
	addq	$64, %rax
	cmpl	$64, %r8d
	je	.L69
.L66:
	movl	16(%rax), %r10d
	testl	%r10d, %r10d
	jne	.L61
	movslq	%r8d, %rax
	salq	$6, %rax
	addq	%rax, %r9
	movq	heap_ptr(%rip), %rax
	movl	%r8d, 20(%r9)
	leaq	16384(%rax), %r10
	movq	%rax, 56(%r9)
	movq	%r10, heap_ptr(%rip)
	leaq	16376(%rax), %r10
	movl	$1, 16(%r9)
	movq	%r10, (%r9)
	movq	%rdx, 8(%r9)
	movq	%rdx, 16376(%rax)
	xorl	%eax, %eax
	jmp	.L62
	.p2align 5
	.p2align 4,,10
	.p2align 3
.L64:
	movb	%dl, 24(%r9,%rax)
	addq	$1, %rax
	cmpq	$32, %rax
	je	.L65
.L62:
	movzbl	(%rcx,%rax), %edx
	testb	%dl, %dl
	jne	.L64
.L65:
	addl	$1, proc_count(%rip)
	movl	%r8d, %eax
	ret
	.p2align 4,,10
	.p2align 3
.L69:
	movl	$-1, %r8d
	movl	%r8d, %eax
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC0:
	.ascii "MandyOs v0.1 - Server Kernel\12\0"
	.align 8
.LC1:
	.ascii "================================\12\0"
.LC2:
	.ascii "[SERIAL] COM1 hazir\12\0"
.LC3:
	.ascii "[OK] Serial port COM1\12\0"
.LC4:
	.ascii "[OK] Physical Memory Manager\12\0"
	.align 8
.LC5:
	.ascii "[OK] PIC 8259 yeniden eslestirildi\12\0"
.LC6:
	.ascii "[OK] IDT yuklendi\12\0"
.LC7:
	.ascii "[OK] PIT Timer 1000Hz\12\0"
	.align 8
.LC8:
	.ascii "[OK] Zamanlayici (Round-Robin)\12\0"
	.align 8
.LC9:
	.ascii "[OK] Syscall MSR kuruldu (LSTAR)\12\0"
	.align 8
.LC10:
	.ascii "[OK] Dosya tanimlayicilar (stdin/stdout/stderr)\12\0"
.LC11:
	.ascii "[OK] Interruptlar aktif\12\0"
	.align 8
.LC12:
	.ascii "\12MandyOs hazir. Shell baslatiliyor...\12\0"
.LC13:
	.ascii "[KERNEL] Boot tamamlandi.\12\0"
	.text
	.p2align 4
	.globl	kernel_main
	.def	kernel_main;	.scl	2;	.type	32;	.endef
	.seh_proc	kernel_main
kernel_main:
	subq	$40, %rsp
	.seh_stackalloc	40
	.seh_endprologue
	movl	$753664, %eax
	.p2align 5
	.p2align 4
	.p2align 3
.L71:
	movl	$3872, %edx
	movl	$3872, %ecx
	addq	$4, %rax
	movw	%dx, -4(%rax)
	movw	%cx, -2(%rax)
	cmpq	$757664, %rax
	jne	.L71
	leaq	.LC0(%rip), %rcx
	call	kprint
	leaq	.LC1(%rip), %rcx
	call	kprint
	call	serial_init
	leaq	.LC2(%rip), %rcx
	call	serial_print
	leaq	.LC3(%rip), %rcx
	call	kprint
	call	pmm_init
	leaq	.LC4(%rip), %rcx
	call	kprint
	leaq	.LC5(%rip), %rcx
	call	pic_init
	call	kprint
	call	idt_init
	leaq	.LC6(%rip), %rcx
	call	kprint
	movl	$54, %eax
/APP
 # 5 "io.h" 1
	outb %al, $67
 # 0 "" 2
/NO_APP
	movl	$-87, %eax
/APP
 # 5 "io.h" 1
	outb %al, $64
 # 0 "" 2
/NO_APP
	movl	$4, %eax
/APP
 # 5 "io.h" 1
	outb %al, $64
 # 0 "" 2
/NO_APP
	leaq	.LC7(%rip), %rcx
	call	kprint
	leaq	16+proc_table(%rip), %rax
	leaq	4096(%rax), %rdx
	.p2align 5
	.p2align 4
	.p2align 3
.L72:
	movl	$0, (%rax)
	subq	$-128, %rax
	movl	$0, -64(%rax)
	cmpq	%rdx, %rax
	jne	.L72
	leaq	.LC8(%rip), %rcx
	call	kprint
	call	syscall_init
	leaq	.LC9(%rip), %rcx
	call	kprint
	call	fd_init
	leaq	.LC10(%rip), %rcx
	call	kprint
/APP
 # 236 "kernel.c" 1
	sti
 # 0 "" 2
/NO_APP
	leaq	.LC11(%rip), %rcx
	call	kprint
	leaq	.LC12(%rip), %rcx
	call	kprint
	leaq	.LC13(%rip), %rcx
	call	serial_print
	call	shell_run
	.p2align 4
	.p2align 3
.L73:
/APP
 # 244 "kernel.c" 1
	hlt
 # 0 "" 2
/NO_APP
	jmp	.L73
	.seh_endproc
	.globl	proc_count
	.bss
	.align 4
proc_count:
	.space 4
	.globl	current_pid
	.align 4
current_pid:
	.space 4
	.globl	proc_table
	.align 32
proc_table:
	.space 4096
	.data
	.align 8
heap_ptr:
	.quad	4194304
	.globl	page_bitmap
	.bss
	.align 32
page_bitmap:
	.space 8192
.lcomm tick_count,8,8
.lcomm idt_desc,10,8
.lcomm idt,4096,32
.lcomm cursor_y,4,4
.lcomm cursor_x,4,4
	.ident	"GCC: (Rev8, Built by MSYS2 project) 15.2.0"
	.def	isr_default;	.scl	2;	.type	32;	.endef
	.def	serial_init;	.scl	2;	.type	32;	.endef
	.def	serial_print;	.scl	2;	.type	32;	.endef
	.def	syscall_init;	.scl	2;	.type	32;	.endef
	.def	fd_init;	.scl	2;	.type	32;	.endef
	.def	shell_run;	.scl	2;	.type	32;	.endef
	.section	.rdata$.refptr.isr_default, "dr"
	.p2align	3, 0
	.globl	.refptr.isr_default
	.linkonce	discard
.refptr.isr_default:
	.quad	isr_default
