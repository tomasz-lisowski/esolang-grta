# G.R.T.A. Esolang
An esoteric MISC instruction set without jumps/skips yet still capable due to a twist. It's close to impossible to create useful loops so any implementation of a *safety net* will likely fail at runtime.

## Architecture
- Memory is shared between data and code.
- Address map:
  - Code starts at 0x00000000 and grows into higher addresses upto and excluding 0x00003fff.
  - Data starts at 0xffffffff and grows into lower addresses upto and including 0x00003fff.
- CPU internal state:
  - `dp` data pointer
  - `ip` instruction pointer
  - `ln` 2-bit indicating lane-of-execution (LOE) which selects the lane of instructions that will be executed.
  - `dr` 1-bit indicating direction-of-execution (DOE) which determines if IP gets incremented (if 0) or decremented (if 1) after execution of the current instruction is completed. Note that a change in direction caused by an instruction leads to an immediate effect i.e. the next change of IP is affected by the direction.
- If IP moves out of bounds of the memory or if an invalid instruction gets loaded for execution, the execution halts. Note that loading an invalid instruction on a lane that is not executed does not lead to a halt.
- All memory cells are initialized to 0x01.

## Code
- Arranged such that every 4 instructions form a single line and each instruction in the line belongs to one lane indexed from left to right starting at 0.
- None of the instructions provide arguments in code, all are taken from data.
- All instructions are 1 byte long so every line consists of 1 word (plus 1 newline byte).

|Init ID |OP Code |Init Encoding  |Function                                                |
|:------:|:------:|:-------------:|--------------------------------------------------------|
|   00   | `INVB` |       a       |`cell_set(0, ~cell_get_u(0))`                           |
|   01   | `ANDB` |       b       |`cell_set(0, cell_get_u(0) & cell_get_u(1))`            |
|   02   | `ADDB` |       c       |`cell_set(0, cell_get_s(0) + cell_get_s(1))`            |
|   04   | `GETC` |       1       |`cell_set(0, getc(stdin))`                              |
|   03   | `PUTC` |       9       |`putc(cell_get_u(0), stdout)`                           |
|   05   | `FRNT` |       3       |`dp = dp - 1`                                           |
|   06   | `BACK` |       5       |`dp = dp + 1`                                           |
|   07   | `CPUC` |       7       |`dr = cell_get_u(0) % 2; ln = floor((cell_get_u(0) % 8) / 2)`|
