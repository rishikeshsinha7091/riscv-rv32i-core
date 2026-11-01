# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. The repository now contains a single-cycle core that runs 37 of the 40 instructions of the RV32I base set: everything except `fence`, `ecall` and `ebreak` (see Design notes for why). It is built from the modules in the table below, and every module has a self-checking testbench. The core test runs twelve small assembly programs from `tests/` and four C programs compiled with GCC from `sw/`, and checks their results automatically. One command runs all tests. The pipelined core and the synthesis results are not done yet.

| Module | Description |
|---|---|
| `mux2` | 1-bit 2:1 multiplexer |
| `dff_sync_reset` | D flip-flop with synchronous reset |
| `alu` | 32-bit ALU: add, sub, and, or, xor, sll, srl, sra, slt, sltu, plus a zero flag |
| `regfile` | 32 x 32-bit register file: two read ports, one write port, x0 always reads 0 |
| `pc_reg` | 32-bit program counter register with synchronous reset and a PC + 4 output |
| `immgen` | Immediate generator: rebuilds the 32-bit constant from the I, S, B, U or J instruction format, with sign extension |
| `imem` | Instruction memory: 1024 x 32-bit words, read-only, combinational read, loaded from a hex file |
| `dmem` | Data memory: 1024 x 32-bit words, combinational read, clocked write with a 4-bit byte enable (one bit per byte lane). The parameter `INIT_FILE` can preload it from a hex file; by default nothing is loaded |
| `store_align` | Store alignment: from the access size, the low address bits and rs2, makes the byte enable and the write data for sb, sh and sw |
| `load_align` | Load alignment: picks the byte or half-word out of the memory word and sign- or zero-extends it, for lb, lh, lw, lbu and lhu |
| `control` | Control unit: turns opcode, funct3 and funct7 into the 13 control outputs for the 37 supported instructions. Any other instruction gives all-zero outputs |
| `core` | Single-cycle core for the 37 supported instructions. Connects the modules above, adds a branch target adder, the branch decision, the jalr target and the next-PC logic. The parameter `PROGRAM` names the hex file loaded into the instruction memory, and `DATA` names an optional hex file loaded into the data memory |

## Repository layout

- `rtl/` : design files (synthesizable Verilog) and the shared code headers (`*.vh`)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`, `dmem_test.hex`)
- `tests/` : assembly test programs for the core: the source (`.asm`) and the assembled hex file (`.hex`) that the core loads
- `sw/` : C test programs for the core, the start-up code, the linker script, the build script and the generated hex files
- `sim/` : run scripts (`run.cmd` for one test, `run_all.ps1` for all of them)
- `docs/` : design log and waveform screenshots

## Running the tests

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH, and Windows PowerShell. From the repository root:

- `.\sim\run_all.ps1` runs every testbench in `tb\`, prints one line per test and a summary, and ends with exit code 0 only if everything passed. If the RISC-V toolchain described below is on the PATH, it also rebuilds each C program, checks that the committed hex files match what the source builds to, and checks that every instruction in the program is one of the 37 supported ones. Without the toolchain it prints a `SKIP` line and runs the testbenches only. `.\sim\run_all.ps1 -Strict` counts a missing toolchain as a failure.
- `sim\run.cmd <module>` runs one test with a module name from the table above, for example `sim\run.cmd alu`. `sim\run.cmd core` runs the core on all programs at once.

If PowerShell refuses to run the scripts, allow your own scripts for the current user with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Test programs

Eleven of the twelve programs end in a spin loop (`spin: jal x0, spin`). The twelfth, `xpc`, is the exception. The testbench watches the PC of every core. A program is done when its PC is known and has not changed for 4 clock edges, with a timeout of 20000 cycles. Then the testbench checks the registers, the memory and the final PC.

| Program | What it checks |
|---|---|
| `alu_ops` | add, sub, and, or, slt, addi, with operands chosen so every result differs |
| `alu_full` | the other ALU instructions: sll, srl, sra, sltu, xor and the immediate forms, with negative values and constants that set instruction bit 30 |
| `mem_ops` | sw and lw at three addresses, a negative offset and a negative value |
| `byte_ops` | lb, lbu, lh, lhu, sb and sh on every byte lane and half-word, with the neighbouring bytes checked |
| `branch_ops` | beq taken and not taken, forward and backward |
| `branch_all` | bne, blt, bge, bltu and bgeu, each taken and not taken, with equal values, different sign bits and the overflow pair |
| `jal_ops` | jal forward and backward, the return address, and jal x0 |
| `upper_jalr` | lui, auipc and jalr: a call and a return, a jalr target with bit 0 set, and lui plus addi with the sign gotcha |
| `loop_sum` | a loop that adds 5 + 4 + 3 + 2 + 1 |
| `checksum` | a loop that fills memory with bytes, a function that sums and xors them, and results combined with lui constants and read back as halves and bytes |
| `unsupported` | mul, fence, ecall and ebreak inside a program change nothing |
| `xpc` | one `jalr` through a register that was never written, so the PC becomes unknown. The testbench must not report this core as done |

## Compiled C programs

The `sw/` folder holds C programs that run on the core. They are compiled with the xPack GNU RISC-V Embedded GCC 15.2.0-1 (`riscv-none-elf-gcc`). Other versions may generate different code, in which case the runner reports that a hex file differs from a fresh build.

`.\sw\build.ps1 NAME` builds `sw\NAME.c` together with the start-up code `sw/start.S` and the linker script `sw/link.ld`. It writes `sw\NAME.hex` (the code, loaded into the instruction memory) and `sw\NAME.data.hex` (the starting values of the variables, loaded into the data memory). The compiler flags are `-march=rv32i -mabi=ilp32 -O1 -ffreestanding -mno-relax` plus two flags that remove unwind tables. The generated hex files are committed, so the tests run without the toolchain.

The expected results are worked out by hand, not taken from the core. The testbench checks the return value, the data memory, `sp`, `ra` and the final PC.

| Program | What it checks |
|---|---|
| `first` | The whole chain, end to end: a variable with a starting value (5) is preloaded, a variable without one is zeroed by the start-up code, and `main` returns 0 + 5 + 7 = 12 |
| `fib` | A loop and array stores: the first 10 Fibonacci numbers, and a check that nothing is written past the array |
| `sort` | A bubble sort of 5, -2, 9, 1, -7, 3, 8, 4 (with negative numbers, so a signed-compare bug cannot hide), and a count of 13 swaps |
| `bits` | Shifts and logic on fixed values: the one-bit count of 0x80F0A55A (13), sra, srl, sll, and, or and xor |

## Design notes

- The memories are behavioural models with a combinational read: the data is available in the same cycle as the address. Real SRAM usually has a clocked read, so this is a simplification that suits a single-cycle core.
- Both memories hold 1024 words (4 KiB). Addresses above 4 KiB wrap around and there is no access-fault checking. The instruction memory ignores the two low address bits.
- Misaligned accesses are not supported. A half-word access looks only at address bit 1 and a word access ignores the two low bits, so an unaligned data address is rounded down. Branch and jump targets are not checked for alignment either. A real core would raise an exception.
- The data memory is an array of words with a 4-bit byte enable. The byte and half-word work is done outside it: `store_align` repeats the byte or half-word on every lane and enables only the lanes to write, and `load_align` picks the lane and extends it.
- The core has two separate memories (a Harvard design), and no instruction can read the instruction memory as data. A compiled program needs its constants and its variables with starting values in the data memory, so `dmem` can be preloaded from a hex file (`INIT_FILE`, reached from `core` through `DATA`). This is a simulation shortcut: a real system copies the values from flash into RAM at boot.
- Both memories start at address 0 in the hardware, but a linker assumes one address space. The linker script places the instruction memory at 0 and tells the linker that the data memory starts at `0x1000`. The data memory looks only at address bits 11 to 2, so `0x1000` reaches its first word. The stack pointer starts at `0x2000`, the end of the data memory. The start-up code (`sw/start.S`) sets `sp`, zeroes the uninitialised variables, calls `main` and then spins.
- Compiled code is limited to the 37 supported instructions with `-march=rv32i`. A `*` or `/` in C would become a call to a library routine, and none of the programs use one. The runner checks every instruction of every program, and also rejects 16-bit instructions.
- The instruction memory and the data memory are loaded from hex files with `$readmemh` at the start of a simulation. Words the file does not write read as `x`. Because the files are shorter than the memory, Icarus prints a harmless warning for each; `sim\run.cmd` hides exactly that one message and nothing else.
- The control unit accepts only the 37 supported instructions, checking exactly the bits that are function codes in each format (for example `funct7` for register-register instructions and for the shift-immediates, but not for `addi`, where it holds bits of the constant). Anything else gives all-zero control signals: no register or memory changes and the PC moves to PC + 4. A real core would raise an illegal-instruction exception, and this one does not.
- Branches reuse the ALU: beq and bne subtract and use the zero flag, while blt, bge, bltu and bgeu run slt or sltu and read bit 0 of the result. Bit 0 of funct3 inverts the answer. A separate adder computes PC + immediate for branches, jal and auipc, and jalr uses the ALU for rs1 + immediate and clears bit 0 of the sum.
- `fence`, `ecall` and `ebreak` are not implemented, so the core has 37 of the 40 RV32I instructions. `ecall` and `ebreak` need a trap mechanism (control and status registers, a saved PC and cause, a handler address and a return instruction) and an environment to answer them, which this project does not have. In this core they do nothing, which is not what a complete core does. A `fence` orders memory accesses as seen by other agents. With one hart, in-order execution, no caches and no devices there is nothing to order, so doing nothing is allowed for a simple core.
- Only the PC has a reset. The registers and memories have no reset and start as unknown (`x`) in simulation, so every test program writes a register before it reads it (except `xpc`, which does so on purpose). The testbench holds reset for one clock edge.
- The runner passes a test only if it ended normally, printed exactly one line starting with `PASS:` and no line starting with `FAIL:`. A compile error, a crash or a silent test is therefore a failure. The oldest testbenches word their PASS line differently from the newer ones, and the runner accepts both.
- The assembly programs are assembled with RARS. The shared operation, select, result and size codes are in the `.vh` header files in `rtl/`.

## Planned

- 5-stage pipelined core
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Assembly test programs assembled with RARS
- C test programs compiled with the xPack GNU RISC-V Embedded GCC 15.2.0-1
- PowerShell scripts for the build and the test runner
- Synthesis with Yosys (planned)
