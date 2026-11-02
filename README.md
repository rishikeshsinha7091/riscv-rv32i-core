# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The repository holds a single-cycle core and a 5-stage pipelined core. The pipelined core does not handle hazards yet, so it runs only specially prepared programs.

## Status

Early development. The repository contains a single-cycle core that runs 37 of the 40 instructions of the RV32I base set: everything except `fence`, `ecall` and `ebreak` (see Design notes for why), and a 5-stage pipelined core for the same 37 instructions. Every module has a self-checking testbench. The single-cycle core test runs twelve small assembly programs from `tests/` and four C programs compiled with GCC from `sw/`, and checks their results automatically. The pipelined core has no forwarding, no stalls and no flushes yet. It runs seven hazard-free copies of the assembly programs (`tests/pipe/`) correctly, but it gives wrong results on programs that read a register right after it is written or that have no `nop`s behind a jump, so it does not run the C programs. One command runs all tests. Hazard handling, a cycle-count comparison between the two cores and the synthesis results are not done yet.

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
| `pipe_reg` | Pipeline register: a row of D flip-flops of any width with a synchronous reset, a flush input that clears it to zeros (a bubble) and an enable input that holds its value. The pipelined core ties the enable to 1 and the flush to 0 for now |
| `core_pipe` | 5-stage pipelined core for the same 37 instructions: Fetch, Decode, Execute, Memory and Write-back, separated by four `pipe_reg` registers. It reuses `pc_reg`, `imem`, `control`, `regfile`, `immgen`, `alu`, `store_align`, `dmem` and `load_align` unchanged and has the same parameters `PROGRAM` and `DATA` as `core`. No hazard handling |

## Repository layout

- `rtl/` : design files (synthesizable Verilog) and the shared code headers (`*.vh`)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`, `dmem_test.hex`, `pipe_stage_test.hex`, `pipe_data_test.hex`)
- `tests/` : assembly test programs for the core: the source (`.asm`) and the assembled hex file (`.hex`) that the core loads. `tests/pipe/` holds the hazard-free copies for the pipelined core
- `sw/` : C test programs for the core, the start-up code, the linker script, the build script and the generated hex files
- `sim/` : run scripts (`run.cmd` for one test, `run_all.ps1` for all of them)
- `docs/` : design log and waveform screenshots

## Running the tests

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH, and Windows PowerShell. From the repository root:

- `.\sim\run_all.ps1` runs every testbench in `tb\`, prints one line per test and a summary, and ends with exit code 0 only if everything passed. If the RISC-V toolchain described below is on the PATH, it also rebuilds each C program, checks that the committed hex files match what the source builds to, and checks that every instruction in the program is one of the 37 supported ones. Without the toolchain it prints a `SKIP` line and runs the testbenches only. `.\sim\run_all.ps1 -Strict` counts a missing toolchain as a failure.
- `sim\run.cmd <module>` runs one test with a module name from the table above, for example `sim\run.cmd alu`. `sim\run.cmd core` runs the single-cycle core on all programs at once, and `sim\run.cmd core_pipe` runs the pipelined core on its seven programs and its stage test.

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

## Pipelined core

`core_pipe` has five stages, with a pipeline register between each pair:

| Stage | What it contains |
|---|---|
| Fetch | `pc_reg`, `imem` and the next-PC mux (its select signals come from Execute) |
| Decode | `control`, the read ports of `regfile` and `immgen` |
| Execute | the ALU, the branch target adder, the branch and jump decision, the `jalr` target, and a mux that merges `pc + 4`, the immediate and `pc + imm` with the ALU result into one value |
| Memory | `store_align`, `dmem` and `load_align` |
| Write-back | a choice between the loaded value and the result, and the write port of `regfile` |

The four registers are IF/ID (96 bits), ID/EX (183), EX/MEM (77) and MEM/WB (73), 429 flip-flops in total, all instances of `pipe_reg`. The control signals are decoded once in Decode and travel through the registers with their instruction, each one only as far as the stage that uses it.

What it cannot do yet, and why:

- A register written by one instruction cannot be used by any of the next 3 instructions. The register file is written at the clock edge and read without a clock, so a read in the same cycle as a write gets the old value, and the new value is still travelling through the pipeline registers.
- A branch or jump is decided in Execute, two fetches after it. The two instructions behind a taken branch or jump have already been fetched, and nothing throws them away, so they run.
- A load followed directly by an instruction that uses its result has the same problem.

Forwarding, stalls and flushes (hazard handling) are planned. Until then, programs need padding.

### Test programs for the pipelined core

`tests/pipe/` holds copies of `alu_full`, `mem_ops`, `byte_ops`, `branch_all`, `jal_ops`, `loop_sum` and `upper_jalr`: the same instructions in the same order, with only `nop`s added, so that a register is read at least 4 instructions after it was written and two `nop`s follow every branch and jump. Padding moves instructions, so the values that depend on addresses differ from the single-cycle versions: the spin address, `x6` of `jal_ops`, the `auipc` and link values of `upper_jalr`, and the `jalr` offset there (33 instead of 13, still odd).

The testbench `tb_core_pipe` runs all seven on one clock and reset. A program is done when the instruction in Execute is a jump to its own address (the spin loop). The testbench then waits 4 more edges for the older instructions to finish, and checks the registers, the memory and the spin address. It also checks the clock edge at which the spin was found, a number worked out by hand: the number of instructions fetched before the spin (counting the two wrong-path `nop`s behind every taken jump) plus 3. The rule of the single-cycle testbench, a PC that has not changed for 4 edges, would never fire on a pipeline: the fetch PC runs on past the spin and is sent back, so it cycles through three addresses.

| Program | Spin address | Spin found at edge |
|---|---|---|
| `alu_full` | 96 | 27 |
| `mem_ops` | 44 | 14 |
| `byte_ops` | 188 | 50 |
| `branch_all` | 360 | 84 |
| `jal_ops` | 68 | 18 |
| `loop_sum` | 48 | 50 |
| `upper_jalr` | 116 | 37 |

`tb_core_pipe` also contains a stage test. It is a hand-encoded program of 11 instructions (`tb/pipe_stage_test.hex`) whose decoded fields, ALU results, memory accesses and register writes are checked in every pipeline register after every clock edge. The registers are preloaded by the testbench, because the stage test was written before Write-back existed.

## Design notes

- The memories are behavioural models with a combinational read: the data is available in the same cycle as the address. Real SRAM usually has a clocked read, so this is a simplification that suits a single-cycle core. The pipelined core keeps these memories. A real pipeline would use clocked memories and arrange its Fetch and Memory stages differently.
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
- Only the PC has a reset. The registers and memories have no reset and start as unknown (`x`) in simulation, so every test program writes a register before it reads it (except `xpc`, which does so on purpose). The testbench holds reset for one clock edge. In the pipelined core the pipeline registers are also reset, to all zeros: with all control signals at zero an instruction slot does nothing (a bubble).
- The runner passes a test only if it ended normally, printed exactly one line starting with `PASS:` and no line starting with `FAIL:`. A compile error, a crash or a silent test is therefore a failure. The oldest testbenches word their PASS line differently from the newer ones, and the runner accepts both.
- The assembly programs are assembled with RARS. The shared operation, select, result and size codes are in the `.vh` header files in `rtl/`.
- In the pipelined core the five-input result mux of the single-cycle core is split: Execute merges `pc + 4`, the immediate and `pc + imm` with the ALU result into one value, and Write-back only chooses between that value and the loaded one. This saves about 190 flip-flops in the registers and costs one mux delay in Execute. The branch decision and the `jalr` target use the ALU result directly. The data a store writes is the raw value of rs2, not the ALU's second input, which is the offset.
- `pipe_reg` has an enable input (a stall holds the value) and a flush input (it clears the register), both prepared for hazard handling and unused so far. If both are active the flush wins, so a thrown-away instruction cannot be held in place.
- In the pipelined core the loaded value that reaches Write-back is unknown (`x`) for every instruction that is not a load, because the Memory stage reads the data memory for every instruction. It is never used for them.
- Simulation shows that the pipelined core is correct on its programs and how many clock edges they take. It cannot show that the clock period is shorter than that of the single-cycle core, because every gate has zero delay in Icarus. That needs a timing estimate from synthesis, and the README will say so when it exists.

## Planned

- Hazard handling for the pipelined core: forwarding, stalls and flushes, so that the original programs and the C programs run on it
- Cycle counts of both cores compared on the same programs
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Assembly test programs assembled with RARS
- C test programs compiled with the xPack GNU RISC-V Embedded GCC 15.2.0-1
- PowerShell scripts for the build and the test runner
- Synthesis with Yosys (planned)
