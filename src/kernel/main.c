#include <onix/onix.h>
#include <onix/types.h>
#include <onix/io.h>
#include <onix/string.h>
#include <onix/console.h>
#include <onix/stdarg.h>

void test_args(int cnt, ...) {
    va_list args;
    va_start(args,cnt);
}

void kernel_init() {
    console_init();
    
    return;
} 