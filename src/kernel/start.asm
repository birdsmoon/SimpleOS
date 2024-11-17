[bits 32]

extern kernel_init;引入外部函数
global _start
_start:
    ; mov byte [0xb8000], "K" ; 进入内核
    call kernel_init
    jmp $