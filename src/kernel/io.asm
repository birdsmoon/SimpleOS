[bits 32]

section .text; 代码段

global inb ;将inb导出
inb:
    push ebp
    mov ebp, esp; 保存栈帧

    xor eax, eax ;自身异或 使eax归零

    mov edx, [ebp + 8]; 将port压入stack
    in al, dx; 将端口号dx 的8bit输入到ax
    jmp $+2
    jmp $+2
    jmp $+2; 一点延迟
    leave ;恢复栈帧
    ret
global inw ;将inw导出
inw:
    push ebp
    mov ebp, esp; 保存栈帧

    xor eax, eax ;自身异或 使eax归零

    mov edx, [ebp + 8]; 将port压入stack
    in al, dx; 将端口号dx 的8bit输入到ax
    jmp $+2
    jmp $+2
    jmp $+2; 一点延迟
    leave ;恢复栈帧
    ret
global outb ;将outb导出
outb:
    push ebp
    mov ebp, esp; 保存栈帧

    xor eax, eax ;自身异或 使eax归零

    mov edx, [ebp + 8]; 将port压入stack
    mov eax, [ebp + 12]; 从右往左压入 eax地址更低
    out dx, al; 将al中的8bit输出
    jmp $+2
    jmp $+2
    jmp $+2; 一点延迟
    leave ;恢复栈帧
    ret
global outw
outw:
    push ebp; 
    mov ebp, esp ; 保存帧

    mov edx, [ebp + 8]; port 
    mov eax, [ebp + 12]; value
    out dx, ax; 将 ax 中的 16 bit 输入出到 端口号 dx

    jmp $+2 ; 一点点延迟
    jmp $+2 ; 一点点延迟
    jmp $+2 ; 一点点延迟

    leave ; 恢复栈帧
    ret

