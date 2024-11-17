#ifndef ONIX_CONSOLE_F
#define ONIX_CONSOLE_F

#include <onix/types.h>

void console_init();
void console_clear();
void console_write(char *buf, u32 count);

#endif