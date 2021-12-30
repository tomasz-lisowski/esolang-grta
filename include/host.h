#pragma once

#include "wasm-rt.h"
#include <stdint.h>
#include <stdio.h>

extern wasm_rt_memory_t host_mem;
void host_putc(uint32_t c);
uint32_t host_getc();
