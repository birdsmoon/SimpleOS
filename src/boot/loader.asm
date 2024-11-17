[org 0x1000] ;指定代码的起始地址 打多数引导加载程序的起始地址

dw 0x55aa 
; 引导扇区的签名 标识该扇区为有效的引导扇区

mov si, loading
; 将字符串loading 赋值给si 
call print
; 检测内存
xchg bx, bx;断点
detect_memory:
    xor ebx, ebx
    ; 结构体缓存地址
    mov ax, 0
    mov es, ax; 若写成mov es, 0 硬件会不支持这种写法 设置段寄存为0 准备内存信息
    mov edi, ards_buffer ; 将ards_buffer的地址加载到edi寄存器
    ; edi是目标寄存器 
    mov edx, 0x534d4150 ; 固定签名
    ; edx 常被用来存储数据或者参与计算
    ; 0x53 -> S 0x4D -> M 0x41 -> A 0x50 -> P    
    ; 对应的ASCII 为 SMAP
.next:
    ; 子功能号 内存信息的系统调用号
    mov eax, 0xe820
    ; ards 结构的大小 
    mov ecx, 20

    int 0x15    ; 调用 BIOS中断0x15获取内存信息
    ; 如果cf置位 就跳转到error
    jc error
    ;将缓存指针指向下一个结构体
    add di, cx
    ; 将结构体数量加一
    inc word [ards_count]
    ; 判断是否已经检查完所有的内存块
    cmp ebx, 0
    jnz .next   ; 如果没有 继续检测下一个结构体

    mov si, detecting
    call print
    
; 该部分代码通过调用 BIOS 中断 0x15 来获取系统内存的信息。0xe820 是该中断的子功能号，表示请求内存布局。
; mov edx, 0x534d4150 是一个固定的签名，用来标识内存布局结构。
; 通过读取返回的内存数据并将其存储在 ards_buffer 中，接着更新结构体缓存指针 edi，直到获取到所有内存信息并更新 ards_count。

    ; xchg bx, bx
    ; mov byte [0xb8000], 'P'

    jmp prepare_protected_mode

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret
loading:
    db "Loading Onix...", 10, 13, 0 ; 10-\n 13-\r
detecting:
    db "Detecting Memory Success...", 10, 13, 0 ; 10-\n 13-\r
; 打印错误信息并停机
error:
    mov si, .msg
    call print
    hlt ;让cpu停止
    .msg db "Loading Error!", 10, 13, 0
; 如果在检测内存时发生错误（比如 BIOS 返回错误），会打印 "Loading Error!" 字符串，并通过 hlt 指令停止 CPU 执行。
prepare_protected_mode:

    cli ;关闭中断 确保在初始化保护模式时不会中断当前操作
    ;打开A20线
    in al, 0x92 ; 操作A20地址线
    or al, 0b10
    out 0x92, al

    lgdt [gdt_ptr]; 加载gdt（全局描述符表）

    ; 启动保护模式；
    mov eax, cr0
    or eax, 1 ; 读取控制寄存器 cr0，并设置其最低位为 1，启用保护模式。
    mov cr0, eax
    
    ; 用跳转来刷新缓存，启用保护模式
    jmp dword code_selector:protect_mode
; 准备进入保护模式
[bits 32]
; 这是一段汇编伪指令 旨在告诉编译器这里要视为32位寄存器 并运行在32位模式下
protect_mode:

    mov ax, data_selector ; data_selector 是段选择子 用于标识 数据段 的位置以及访问权限。用来确定数据段在内存中的位置和大小
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax; 初始化段寄存器

    mov esp, 0x10000; 修改栈顶
    mov edi, 0x10000; 读取目标内存
    mov ecx, 10 ;起始扇区
    mov bl, 200 ;扇区数量

    call read_disk
    jmp dword code_selector:0x10000

    ud2; 表示出错
; 保护模式初始化
jmp $
; GDT表和内存配置

read_disk:
    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx;0x1f3
    mov al, cl
    out dx, al

    inc dx;0x1f4
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx;0x1f5
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx; 0x1f6
    shr ecx, 8
    and cl, 0b1111 ;将高四位置0

    mov al, 0b1110_0000
    or al, cl
    out dx, al; 主盘-LBA模式

    inc dx; 0x1f7
    mov al, 0x20; 读硬盘
    out dx, al

    xor ecx, ecx;清空
    mov cl, bl; 得到读写扇区的数量

    .read:
        push cx ;保存cx
        call .waits ;等待数据准备完毕
        call .reads ;读取一个扇区
        pop cx
        loop .read

    ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2
            jmp $+2
            jmp $+2 ;增加一些延迟
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret
    
    .reads:
        mov dx, 0x1f0
        mov cx, 256 ; 一个扇区256字
        .readw:
            in ax, dx
            jmp $+2
            jmp $+2
            jmp $+2
            mov [edi], ax
            add edi, 2
            loop .readw
        ret
code_selector equ (1 << 3)  
data_selector equ (2 << 3) ; 段寄存器为16 2 << 3 等价于 2 * (2^3)，即 2 * 8 = 16

memory_base equ 0;内存开始的位置 基地址
; 内存界限 4G / 4k -1
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1
; gdt描述符
gdt_ptr: ; 定义位置和大小
    dw (gdt_end - gdt_base) - 1
    dd gdt_base
gdt_base:   ;起始位置
    dd 0, 0; NULL描述符 
gdt_code: ; 代码段描述符
    dw memory_limit & 0xffff; 段界限 0 - 15 位
    dw memory_base & 0xffff; 基地址 0 - 15位
    db (memory_base >> 16) & 0xff ;基地址 16 - 23 位
    db 0b_1_00_1_1_0_1_0 ; 存在 dlp 0 s 代码 非依从 可读 没有被访问过
    ; 4k -32- 不是64位  
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf 
    db (memory_base >> 24) & 0xff ; 基地址24-31
gdt_data: ; 数据段描述符
    dw memory_limit & 0xffff; 段界限 0 - 15 位
    dw memory_base & 0xffff; 基地址 0 - 15 位
    db (memory_base >> 16) & 0xff ;基地址 16 - 23 位
    db 0b_1_00_1_0_0_1_0 ; 存在 dlp 0 s 代码 非依从 可写 没有被访问过
    ; 4k -32- 不是64位  
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf 
    db (memory_base >> 24) & 0xff ; 基地址24-31
gdt_end:
ards_count:
    dw 0;
ards_buffer:
; dd、dw 和 db 是汇编语言中的 伪指令
; db 是定义一段字节 dw是定义一段字 dd是定义双字