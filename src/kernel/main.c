#include<onix/onix.h>
#include<onix/types.h>
#include<onix/io.h>
#include<onix/string.h>
#include<onix/console.h>

char message[] = "hello system!";

void kernel_init() {
    console_init();

    u32 count = 20;
    while (count --)
    {
        console_write(message, sizeof(message) - 1);
    }
    return;
} 