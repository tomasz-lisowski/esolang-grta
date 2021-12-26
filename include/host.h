#pragma once

#include <stdint.h>
#include <stdio.h>
#include <wasm-rt.h>

extern wasm_rt_memory_t host_mem;
void host_putc(uint32_t c);
