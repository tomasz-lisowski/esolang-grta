#include "host.h"
#include <stdio.h>
#include <stdlib.h>

#define HOST_MEM_SIZE (1 << 16)
uint8_t host_mem_buf[HOST_MEM_SIZE] = {[0 ... HOST_MEM_SIZE - 1] = 1};
wasm_rt_memory_t host_mem = {
    .pages = 1,
    .size = HOST_MEM_SIZE,
    .max_pages = 1,
    .data = host_mem_buf,
};

void host_putc(uint32_t c)
{
    putc((char)c, stdout);
}

uint32_t host_getc()
{
    const int32_t c = getc(stdin);
    if (c < 0)
    {
        printf("Failed to get char\n");
        exit(EXIT_FAILURE);
    }
    return (uint8_t)c; // Safe cast
}
