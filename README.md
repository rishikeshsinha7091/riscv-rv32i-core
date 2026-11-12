# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The repository holds a single-cycle core and a 5-stage pipelined core. The pipelined core handles data hazards with forwarding, load-use hazards with a one-cycle stall and control hazards with a flush, and it is tested on programs written for those hazards. A second test runs it side by side with the single-cycle core on 20 programs and compares the final state and the cycle counts. Both cores are synthesized with Yosys (generic gates, memories as black boxes) to compare their size and logic depth.

## Status

Early development. The repository contains a single-cycle core that runs 37 of the 40 instructions of the RV32I base set: everything except `fence`, `ecall` and `ebreak` (see Design notes for why), and a 5-stage pipelined core for the same 37 instructions. Every module has a self-checking testbench. The single-cycle core test runs twelve small assembly programs from `tests/` and four C programs compiled with GCC from `sw/`, and checks their results automatically. The pipelined core has forwarding, a Write-back bypass into Decode, a one-cycle stall for a load followed by its user, and a flush on every taken branch and jump. Its testbench runs a stage test, seven padded copies of the assembly programs and four programs written for hazards (`tests/hazard/`). The results of those programs, and the clock edge at which each one ends, are worked out by hand, and a monitor checks that a stall and a flush never happen in the same cycle. A third testbench, `tb_pipe_vs_single`, runs the twelve assembly programs, the four C programs and the four hazard programs on the pipelined core and on the single-cycle core side by side and compares the final registers, the data memory and the final PC. It also counts the instructions, the stall cycles and the taken jumps of every program, and the cycle counts of both cores are in the section Cycle counts. One command runs all tests. A second script synthesizes both cores with Yosys and reports their size and logic depth (see Synthesis); it gives no clock period, so the README makes no claim about which core is faster.

| Module | Description |
|---|---|
| `mux2` | 1-bit 2:1 multiplexer |
| `dff_sync_reset` | D flip-flop with synchronous reset |
| `alu` | 32-bit ALU: add, sub, and, or, xor, sll, srl, sra, slt, sltu, plus a zero flag |
| `regfile` | 32 x 32-bit register file: two read ports, one write port, x0 always reads 0 |
| `pc_reg` | 32-bit program counter register with synchronous reset, an enable input (low holds the value, reset wins) and a PC + 4 output |
| `immgen` | Immediate generator: rebuilds the 32-bit constant from the I, S, B, U or J instruction format, with sign extension |
| `imem` | Instruction memory: 1024 x 32-bit words, read-only, combinational read, loaded from a hex file |
| `dmem` | Data memory: 1024 x 32-bit words, combinational read, clocked write with a 4-bit byte enable (one bit per byte lane). The parameter `INIT_FILE` can preload it from a hex file; by default nothing is loaded |
| `store_align` | Store alignment: from the access size, the low address bits and rs2, makes the byte enable and the write data for sb, sh and sw |
| `load_align` | Load alignment: picks the byte or half-word out of the memory word and sign- or zero-extends it, for lb, lh, lw, lbu and lhu |
| `control` | Control unit: turns opcode, funct3 and funct7 into the 13 control outputs for the 37 supported instructions. Any other instruction gives all-zero outputs |
| `core` | Single-cycle core for the 37 supported instructions. Connects the modules above, adds a branch target adder, the branch decision, the jalr target and the next-PC logic. The parameter `PROGRAM` names the hex file loaded into the instruction memory, and `DATA` names an optional hex file loaded into the data memory |
| `pipe_reg` | Pipeline register: a row of D flip-flops of any width with a synchronous reset, a flush input that clears it to zeros (a bubble) and an enable input that holds its value. If flush and enable are both active, the flush wins |
| `fwd_unit` | Forwarding unit: for the two source registers of the instruction in Execute, decides whether the value comes from the register read in Decode, from the EX/MEM result or from the MEM/WB data. A source qualifies only if that instruction writes a register other than x0 and its destination equals the source number. EX/MEM, the newer instruction, has priority |
| `hazard_unit` | Load-use detector: asks for a one-cycle stall when the instruction in Execute is a load whose destination is a register that the instruction in Decode really reads. Which registers an instruction reads is decided from its opcode, so an instruction whose immediate bits look like a register number does not stall |
| `core_pipe` | 5-stage pipelined core for the same 37 instructions: Fetch, Decode, Execute, Memory and Write-back, separated by four `pipe_reg` registers. It reuses `imem`, `control`, `regfile`, `immgen`, `alu`, `store_align`, `dmem` and `load_align` unchanged and `pc_reg` with its enable input, and has the same parameters `PROGRAM` and `DATA` as `core`. It adds `fwd_unit` and `hazard_unit` and handles data, load-use and control hazards |

## Repository layout

- `rtl/` : design files (synthesizable Verilog) and the shared code headers (`*.vh`)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`, `dmem_test.hex`, `pipe_stage_test.hex`, `pipe_data_test.hex`)
- `tests/` : assembly test programs for the core: the source (`.asm`) and the assembled hex file (`.hex`) that the core loads. `tests/pipe/` holds the padded copies for the pipelined core and `tests/hazard/` holds programs written to cause hazards
- `sw/` : C test programs for the core, the start-up code, the linker script, the build script and the generated hex files
- `sim/` : run scripts (`run.cmd` for one test, `run_all.ps1` for all of them, `cpi_table.ps1` for the cycle-count table)
- `synth/` : the synthesis script (`run_synth.ps1`), two stub files that stand in for the memories, and its committed result (`results.txt`)
- `docs/` : design log and waveform screenshots

## Running the tests

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH, and Windows PowerShell. From the repository root:

- `.\sim\run_all.ps1` runs every testbench in `tb\`, prints one line per test and a summary, and ends with exit code 0 only if everything passed. If the RISC-V toolchain described below is on the PATH, it also rebuilds each C program, checks that the committed hex files match what the source builds to, and checks that every instruction in the program is one of the 37 supported ones. Without the toolchain it prints a `SKIP` line and runs the testbenches only. `.\sim\run_all.ps1 -Strict` counts a missing toolchain as a failure.
- `sim\run.cmd <module>` runs one test with a module name from the table above, for example `sim\run.cmd alu`. `sim\run.cmd core` runs the single-cycle core on all programs at once, and `sim\run.cmd core_pipe` runs the pipelined core on its stage test and its eleven programs.
- `sim\run.cmd pipe_vs_single` runs the two cores side by side. A comparison of two cores has no single module under test, so when there is no `rtl\NAME.v` for a testbench `run.cmd` compiles only the testbench. `.\sim\cpi_table.ps1` runs it and prints the cycle-count table (see Cycle counts).

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
| Decode | `control`, the read ports of `regfile`, `immgen`, the Write-back bypass and `hazard_unit` |
| Execute | the ALU, the two forwarding muxes (selected by `fwd_unit`), the branch target adder, the branch and jump decision, the `jalr` target, and a mux that merges `pc + 4`, the immediate and `pc + imm` with the ALU result into one value |
| Memory | `store_align`, `dmem` and `load_align` |
| Write-back | a choice between the loaded value and the result, and the write port of `regfile` |

The four registers are IF/ID (96 bits), ID/EX (193), EX/MEM (77) and MEM/WB (73), 439 flip-flops in total, all instances of `pipe_reg`. The control signals are decoded once in Decode and travel through the registers with their instruction, each one only as far as the stage that uses it. ID/EX also carries the two source register numbers of its instruction, because the forwarding comparison happens in Execute.

### Hazard handling

**Data hazards.** An instruction that reads a register written by an instruction just ahead of it would read the old value, because the register file is written at the clock edge and read without a clock. The value is already inside the pipeline, so it is taken from there:

- One instruction ahead, the result is in EX/MEM. Two ahead, it is in MEM/WB. `fwd_unit` compares the two source register numbers of the instruction in Execute with the destinations of those two, and two 3-input muxes right after ID/EX pick the value. The same two values feed the ALU, the data of a store, the branch comparison and the `jalr` base. When both instructions match, EX/MEM wins, because it is the newer one. A write to x0, and an instruction that writes no register, is never forwarded.
- Three instructions ahead, the value is being written to the register file in the same cycle in which the reader is in Decode, and the read still gets the old value. The pipeline passes the Write-back value into Decode in that case. This is done in `core_pipe`: `regfile` is unchanged, because a bypass inside `regfile` would make an instruction that reads and writes the same register read its own result in the single-cycle core.

**Load-use hazard.** The data of a load comes out of the data memory in the Memory stage, one stage too late to be forwarded to the next instruction. When the instruction in Execute is a load and the instruction in Decode really reads its destination register (including a store of the loaded value), `hazard_unit` asks for a stall: the PC and IF/ID hold for one cycle and a bubble enters ID/EX. After that cycle the load is in Write-back and its data is forwarded. The cost is one cycle, only for a load whose very next instruction uses it.

**Control hazards.** A branch or jump is decided in Execute, and the core always fetches ahead as if the branch were not taken. When a branch is taken, and for every `jal` and `jalr`, the two instructions behind it (one in Fetch, one in Decode) are turned into bubbles by flushing IF/ID and ID/EX. The branch or jump itself is not flushed, so the link register of `jal` and `jalr` is still written. The cost is 2 cycles for every taken branch and jump. A stall and a flush cannot happen in the same cycle, because a load and a branch cannot both be in Execute; the testbench monitors this.

What it does not do:

- There is no branch prediction, so every taken branch and jump costs 2 cycles.
- A load followed directly by an instruction that reads it costs 1 cycle, including a load followed by a store of the loaded value.
- The memories read combinationally. Real clocked memories would change the Memory stage and the load latency.
- Simulation cannot show the clock period. The forwarding muxes lengthen the Execute path; the Synthesis section gives a logic depth, which is not a clock period.

### Test programs for the pipelined core

The testbench `tb_core_pipe` runs the stage test and eleven programs on one clock and reset. A program is done when the instruction in Execute is a jump to its own address (the spin loop). The testbench then waits 4 more edges for the older instructions to finish, and checks the registers, the memory and the spin address. It also checks the clock edge at which the spin was found, a number worked out by hand: the number of instructions fetched before the spin (counting the two wrong-path instructions behind every taken jump) plus 3, plus one for every stall cycle. The rule of the single-cycle testbench, a PC that has not changed for 4 edges, would never fire on a pipeline: the fetch PC runs on past the spin and is sent back, so it cycles through three addresses. Registers that a program must never write (because the instruction that writes them is wrong-path or skipped) are checked to be still unknown.

`tests/pipe/` holds copies of `alu_full`, `mem_ops`, `byte_ops`, `branch_all`, `jal_ops`, `loop_sum` and `upper_jalr`: the same instructions in the same order, with only `nop`s added, so that a register is read at least 4 instructions after it was written and two `nop`s follow every branch and jump. They were written for the first pipeline, which had no hazard handling. They still pass, with the same results and the same ending edges, which shows that the hazard logic changes nothing for programs without hazards. Padding moves instructions, so the values that depend on addresses differ from the single-cycle versions: the spin address, `x6` of `jal_ops`, the `auipc` and link values of `upper_jalr`, and the `jalr` offset there (33 instead of 13, still odd).

| Program | Spin address | Spin found at edge |
|---|---|---|
| `alu_full` | 96 | 27 |
| `mem_ops` | 44 | 14 |
| `byte_ops` | 188 | 50 |
| `branch_all` | 360 | 84 |
| `jal_ops` | 68 | 18 |
| `loop_sum` | 48 | 50 |
| `upper_jalr` | 116 | 37 |

`tests/hazard/` holds four programs written to cause hazards, with no `nop`s for data hazards:

| Program | What it checks | Spin address | Spin found at edge | Stall cycles |
|---|---|---|---|---|
| `hazard_alu` | forwarding at distances 1 and 2 on both operands, two writers of one register (the newer wins), a write to x0, the data of a store, an `addi` whose immediate bits look like the register written just before, branches and a `jalr` on a register written one instruction earlier | 168 | 43 | 0 |
| `bypass_d3` | reads three instructions after the write (`rs1`, `rs2`, store data, a load result), x0 after a write to x0, a store whose `rd` bits look like a register, and one instruction that needs the bypass on one operand and forwarding on the other | 160 | 43 | 0 |
| `load_use` | a load followed by its user on `rs1`, on `rs2`, as store data, in a branch and in a pointer chase; and two pairs that must not stall (one instruction in between, and an `addi` whose immediate looks like the load's destination) | 112 | 36 | 6 |
| `flush_ctl` | taken and not-taken branches, `jal`, `jalr`, a loop and a load followed by a branch, with a register write and a memory write right behind every taken jump that must have no effect; nothing is padded and no instruction follows the spin | 156 | 47 | 1 |

The stall cycles are counted by the testbench as well. A pipeline that stalled too often, or not at all in the right place, can give correct values with a wrong cycle count, or the other way round.

`tb_core_pipe` also contains a stage test. It is a hand-encoded program of 11 instructions (`tb/pipe_stage_test.hex`) whose decoded fields, ALU results, memory accesses and register writes are checked in every pipeline register after every clock edge. The registers are preloaded by the testbench, because the stage test was written before Write-back existed. It contains a taken `jal` near the end, and the test expects the bubble that the flush puts into ID/EX behind it.

## Verification of the pipelined core against the single-cycle core

`tb/tb_pipe_vs_single.v` runs 20 programs on two cores at once: the single-cycle `core`, used as the reference, and `core_pipe`. The programs are the twelve assembly programs, the four C programs and the four hazard programs. For 19 of them (all except `xpc`) the test waits until both cores are done (the single-cycle PC unchanged for 4 edges, the pipeline's spin found in Execute plus 4 edges) and then makes six checks:

- the single-cycle core is done and the pipelined core is done (a core that is not done after 2000 edges is a failure, never a silent pass),
- at least one of the registers x1 to x31 of the reference is known (a run in which nothing happened cannot pass),
- both cores ended at the same spin address,
- registers x1 to x31 are identical,
- all 1024 data memory words are identical.

Every comparison uses `!==`, so an unknown value is different from a known one. Two programs get more:

- `unsupported` (`mul`, `fence`, `ecall` and `ebreak` inside a program) also has hand-worked values on both cores: x1 = 5, x2 = 7, x14 = 77 (so `mul` changed nothing), x15 = 99, the final PC, and no other register written.
- `xpc` (a `jalr` through a register that was never written) is not compared. Neither core may be done, the PC must stay unknown on both, and no register or data word may become known.

The whole testbench makes 209 checks, including the cycle checks of the next section.

What this shows, and what it does not:

- For these 20 programs the pipelined core ends in the same state as the single-cycle core. It does not look at the values in between and it does not look at time (the cycle counts below do).
- Both cores are built from the same `alu`, `regfile`, `control`, `immgen`, `imem`, `dmem`, `store_align`, `load_align` and `pc_reg`. A bug in one of those is in both cores, and the comparison cannot see it. Those modules are checked by their own testbenches and by the hand-worked expected values in `tb_core`. The comparison finds bugs that exist only in the pipeline: the pipeline registers, forwarding, the bypass, the stall, the flush and the wiring.
- A bug is found only if a program makes its effect last until the end.
- To check that the test can fail, the design was broken on purpose. Removing the load-use stall made three programs differ (`checksum`, `c_first`, `c_sort`). Removing the forwarding from Write-back for the first ALU operand made six programs fail, and three of them (`loop_sum`, `c_sort`, `c_bits`) never reached their spin, which only the done check reports. Breaking `sra` in the shared ALU did not fail the comparison at all; only `tb_alu` and `tb_core` failed.
- Random or constrained-random programs have not been run.

## Cycle counts

Cycles are counted from the reset edge (edge 0) to the edge that ends the first cycle in which the spin executes. For the single-cycle core that is N + 1, where N is the number of instructions executed before the spin. For the pipelined core it is N + 3 + S + 2R: 3 for filling the pipeline, S load-use stall cycles and R taken branches and jumps at 2 cycles each. N is measured on the single-cycle core, where one cycle is one instruction. S and R are counted by monitors in the testbench. The testbench checks this equation for every program, and for 14 of the 19 programs it also checks N, S, R and the cycle count against numbers worked out by hand from the assembly (the hand-traced values of the four hazard programs agree with the ending edges in the table of hazard programs above). For the other five (`checksum` and the four C programs) only the equation is checked. CPI is cycles divided by N. The extra cycles of the pipeline over N are split into fill, stalls and flushes.

The four C programs (built with `-O1`):

| Program | N | Single-cycle cycles | Pipeline cycles | CPI single | CPI pipeline | Extra cycles (fill + stalls + flushes) |
|---|---|---|---|---|---|---|
| `first` | 20 | 21 | 32 | 1.050 | 1.600 | 3 + 1 + 8 |
| `fib` | 124 | 125 | 172 | 1.008 | 1.387 | 3 + 1 + 44 |
| `sort` | 259 | 260 | 386 | 1.004 | 1.490 | 3 + 28 + 96 |
| `bits` | 188 | 189 | 273 | 1.005 | 1.452 | 3 + 0 + 82 |
| Total | 591 | 595 | 863 | 1.007 | 1.460 | 12 + 30 + 230 |

`.\sim\cpi_table.ps1` runs the testbench and prints this table for all 19 programs, grouped as C programs, assembly programs and hazard programs. It refuses to print if the testbench did not pass or if a row breaks the equation. The eleven assembly programs together take 272 cycles on the single-cycle core and 368 on the pipelined core for 261 instructions, and the four hazard programs 136 and 169 for 132 instructions.

Reading the numbers:

- On the C programs the pipelined core needs about 1.45 times as many cycles as the single-cycle core.
- 230 of its 272 extra cycles (about 85 percent) are the flushes after taken branches and jumps: 115 of the 591 instructions are taken jumps and each costs 2 cycles, because there is no branch prediction. Load-use stalls cost 30 cycles, almost all of them in `sort`, and the fill costs 12. Forwarding and the Write-back bypass cost no cycles.
- Small programs overstate the fill: the 7-instruction `jal_ops` has a pipeline CPI of 2.571.

What the table does not say:

- CPI counts cycles, not time. Time is instructions x CPI x clock period, and the clock periods are not known: simulation has no gate delays. With these totals the pipelined core is faster only if its clock period is below about 0.69 of the single-cycle core's (595 / 863). That is not measured here, so the table does not say which core is faster. The Synthesis section gives a logic depth for both cores and says what it does not show.
- The programs are small, and the C programs were built at `-O1` only; other optimisation levels give other code and other stall counts. The assembly programs were written to test one thing each and the hazard programs to stress the hazard logic, so they are not typical code.
- Both memories read combinationally, so loads and stores cost no extra time. A real clocked memory would raise the CPI of both cores.

## Synthesis

`.\synth\run_synth.ps1` synthesizes `core` and `core_pipe` with Yosys and prints their size and logic depth. It checks itself (20 checks, one of them that the longest path of the pipelined core is shorter than that of the single-cycle core), prints `PASS: SYNTH, 20 checks, 0 errors` and writes `synth/results.txt`, which is committed. It runs from the repository root and needs WSL with Ubuntu and `yosys` (`sudo apt install yosys`; the numbers below are from Yosys 0.52). It is not part of `run_all.ps1`, which must work without them. Yosys runs inside WSL because the Windows build of its ABC program was blocked on the development machine by Windows Smart App Control.

No technology library is used. The cells are the generic gates and flip-flops of Yosys, so an area is a number of cells, not square micrometres, and the cells are not equal in size (a flip-flop is larger than a NAND gate). Cell counts exclude the bookkeeping cells that Yosys adds and the two black-box cells below.

How the cores are synthesized:

- `imem` and `dmem` are black boxes. `synth/memstubs.v` declares only their ports. As flip-flops, `dmem` alone is 70,722 cells (32,768 flip-flops and 32,736 multiplexers), more than ten times the size of `core`, and a real chip uses a memory block for this. The area of the memories is in no number below. The stub files repeat the ports of `imem` and `dmem`, so they must be changed together with those modules.
- The cores have no output ports, so Yosys would delete everything. The two memory instances are marked `keep`; their input pins make everything that drives them observable. Without `keep`, `core` shrank to nothing.
- The flow is `synth -flatten -nordff`. `-nordff` stops Yosys from merging the flip-flops in front of the register file's read addresses into its read ports, which added 10 duplicate flip-flops to `core_pipe` (1,501 instead of 1,491).

Results (`synth/results.txt`):

| | Flip-flops | Logic cells | Total cells | Logic depth (cells) |
|---|---|---|---|---|
| `core` | 1,056 | 5,269 | 6,325 | 56 |
| `core_pipe` | 1,491 | 5,488 | 6,979 | 44 |

- Flip-flops can be counted from the code before the run: PC 32 + register file 32 x 32 = 1,056, and 439 pipeline-register bits more for the pipelined core, 1,495. Run module by module, Yosys gives exactly these numbers. Run as a whole, it gives 1,056 and 1,491: it removes four pipeline bits that nothing reads (which four was not identified). The register file keeps 1,024 flip-flops, not 992: Yosys does not remove the word for x0, although it is never written.
- Pipelining costs 435 more flip-flops (41 percent) and 219 more logic cells (4 percent): the pipeline registers, and the forwarding, hazard and flush logic.
- The ALU alone is 1,461 cells and has no flip-flops. Without its three shifters it is 888, so the shifters are 573 cells (39 percent). The register file is 3,167 cells: 1,024 flip-flops and 1,984 multiplexers.
- The script fails if the ALU's `default` case is removed (a latch appears in both cores).

Logic depth is the longest chain of cells between two flip-flops (Yosys `ltp -noff`). For this measurement the memories are zero-delay wires (`synth/memwire.v`), so a path through a memory is not cut and the memory time counts as zero.

- `core`, 56 cells: from the instruction bits through decode, the ALU and the data-memory path to a register write. With the data-memory path cut it is 54.
- `core_pipe`, 44 cells: as far as the end points show, the branch loop in Execute: forwarding comparison, ALU compare, redirect decision and the flush of ID/EX.
- The ratio is 44 / 56 = 0.79. The cycle counts say the pipelined core wins on the C programs only if its clock period is below 0.69 of the single-cycle core's (595 / 863). The depth ratio is above that, but it leaves out the memories.

What this does not show:

- Depth is not time. Gates have different delays, wires and placement are not modelled, the path search also counts paths that can never be active, and the clock-to-output and setup times of the flip-flops are left out. They hurt the pipeline most, because each of its stages pays them again, so the real period ratio is closer to 1 than the depth ratio.
- The memory access time is left out, and the single-cycle core has to fit two memory accesses in series (the instruction, then the data) into one cycle. The pipeline has one per stage. This is the main reason why the real period ratio can be much lower than the depth ratio.
- A model, not a measurement. Let $M$ be the time of one memory access and $o$ the flip-flop overhead, both in gate levels. Then $T_\text{single} = o + 56 + 2M$ and $T_\text{pipe} = o + 44$ (valid while $M$ is below about 40). With $o = 3$ the pipelined core wins on the C programs when $M$ is above about 4.6; with $o = 10$, above about 6.2. Whether a real memory is slower than that is not known here.
- No megahertz, nanoseconds, square millimetres or power, and no claim about which core is faster. Placement, routing and an FPGA run are not part of this project yet.

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
- `pipe_reg` has an enable input (a stall holds the value) and a flush input (it clears the register). If both are active the flush wins, so a thrown-away instruction cannot be held in place, and reset wins over both. In `core_pipe` a stall holds the PC and IF/ID and flushes ID/EX, and a taken jump flushes IF/ID and ID/EX. `pc_reg` has an enable for the same reason; the single-cycle core ties it to 1.
- In the pipelined core the loaded value that reaches Write-back is unknown (`x`) for every instruction that is not a load, because the Memory stage reads the data memory for every instruction. It is never used for them, and a forwarded value always comes from `wb_data`, which chooses the loaded value only for a load. For a load in EX/MEM the result register holds the address, not the data, which is why a load followed by its user is stalled and never forwarded from EX/MEM.
- The forwarding unit only compares register numbers. It does not check whether the instruction really reads them, so an `addi` whose immediate bits equal the register written just before gets a forwarded value on an operand it ignores. That is harmless because the forwarding muxes sit before the ALU's `alu_src` mux and the immediate wins. The stall logic is precise: it decides from the opcode which registers an instruction reads, because a false stall would cost a cycle. The six opcode values it uses are also in `control`, so they exist in two places.
- Simulation shows that the pipelined core is correct on its programs and how many clock edges they take. It cannot show that the clock period is shorter than that of the single-cycle core, because every gate has zero delay in Icarus. A clock period needs a technology library and a physical design flow, which this project does not have. The Synthesis section gives a logic depth and a model, and says what they do not show.

## Planned

- A diagram of the pipeline and a waveform of the pipeline filling
- Possible later work, not started: an FPGA run, and branch prediction to cut the flush cycles

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Assembly test programs assembled with RARS
- C test programs compiled with the xPack GNU RISC-V Embedded GCC 15.2.0-1
- PowerShell scripts for the build and the test runner
- Synthesis with Yosys 0.52, run in WSL (Ubuntu) from a PowerShell script
