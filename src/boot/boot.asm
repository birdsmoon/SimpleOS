[org 0x7c00]
; 这里是指这段代码 在内存中的位置为0x7c00 在BIOS中常把启动扇区加载到内存中的0x7c00

mov ax, 3 
; 将数值3 赋值给ax  模式3 是指文本模式 80（列） * 25（行） 是VGA显示模式的经典文本 0x13 是图像模式
; 设置屏幕模式为文本模式 清除屏幕
int 0x10 ; 是一个bios中断 负责显示器和视频服务
; 初始化段寄存器
mov ax, 0 ; 初始化ax寄存器 把0赋值给ax寄存器
mov ds, ax ; 将ax的值（即 0）加载到 数据段寄存器ds
; 将 DS 指向内存中的 第 0 段
mov es, ax ; 将ax的值加载到额外段寄存器es
; ES 可能用于指向数据段或视频缓冲区等不同区域。
mov ss, ax ; 将ax的值加载到 堆栈段寄存器SS
; 堆栈段初始化为第 0 段，这是确保堆栈操作的必要准备。
mov sp, 0x7c00 
; sp 堆栈指针 SP 用于跟踪堆栈顶的位置。这里堆栈从 0x7C00 开始，意味着堆栈区域位于引导扇区的内存块中

mov si, booting
call print

mov edi, 0x1000; 读取目标内存
mov ecx, 2 ;起始扇区
mov bl, 4 ;扇区数量

call read_disk

cmp word [0x1000], 0x55aa
jnz error

jmp 0:0x1002

; 阻塞
jmp $
; 创建了一个无限循环，程序将在此指令处持续执行。
; 填充0
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
booting:
    db "Booting Onix...", 10, 13, 0 ; 10-\n 13-\r
error:
    mov si, .msg
    call print
    hlt ;让cpu停止
    .msg db "Error!", 10, 13, 0
times 510 - ($ - $$) db 0
; 主引导扇区512B最后两个字节必须是 0x55 0xaa
; dw 0xaa55
db 0x55, 0xaa
; 编译命令 nasm -f bin boot.asm -o boot.bin
; 创建硬盘镜像的命令 
; bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat master.img
; 将boot.bin 写入主引导扇区
; dd if=boot.bin of=master.img bs=512 count=1 conv=notrunc
; 配置bochs
; ata0-master: type=disk, path="master.img", mode=flat