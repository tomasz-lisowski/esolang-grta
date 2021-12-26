#include "grta.h"
#include "host.h"
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Provide definitions for functions imported in WASM. */
void (*Z_hostZ_putcZ_vi)(u32) = host_putc;
wasm_rt_memory_t(*Z_hostZ_code) = &host_mem;

int main(int argc, char **argv)
{
    // Copy code into host memory.
    {
        // Check arguments.
        if (argc != 2)
        {
            printf("Usage: grta <path/to/code>\n");
            return EXIT_FAILURE;
        }
        FILE *file_code = fopen(argv[1], "r");
        if (file_code == NULL)
        {
            printf("Failed to open code file: %s\n", strerror(errno));
            return EXIT_FAILURE;
        }

        /* Get code file length to be able to check if it fits in the host
         * memory. */
        if (fseek(file_code, 0, SEEK_END) != 0)
        {
            printf("Failed to seek code file: %s\n", strerror(errno));
            return EXIT_FAILURE;
        }
        const int64_t file_code_len_64 = ftell(file_code);
        if (file_code_len_64 < 0 || file_code_len_64 > (int64_t)UINT32_MAX)
        {
            printf("Code file length invalid or too large\n");
            return EXIT_FAILURE;
        }
        // Safely cast the 64-bit length to 32-bits for further use.
        const uint32_t file_code_len = (uint32_t)file_code_len_64;
        // Return to start of file.
        if (fseek(file_code, 0, 0) != 0)
        {
            printf("Failed to seek code file: %s\n", strerror(errno));
            return EXIT_FAILURE;
        }

        // Read the file into host memory.
        if (file_code_len > host_mem.size)
        {
            printf("Code file does not fit in host memory\n");
            return EXIT_FAILURE;
        }
        size_t file_code_read =
            fread(host_mem.data, sizeof(uint8_t), file_code_len, file_code);
        if (file_code_read != file_code_len)
        {
            printf("Failed to read the entire code file into host memory: %u\n",
                   file_code_len);
            return EXIT_FAILURE;
        }
        if (fclose(file_code) != 0)
        {
            printf("Failed to close code file: %s\n", strerror(errno));
            return EXIT_FAILURE;
        }
    }

    init();
    const uint32_t ret = Z_mainZ_iv();
    return (int32_t)ret; // Unsafe cast.
}
