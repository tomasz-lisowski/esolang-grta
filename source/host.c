#include "host.h"

#define HOST_MEM_SIZE (1 << 16)
uint8_t host_mem_buf[HOST_MEM_SIZE] = {0};
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
