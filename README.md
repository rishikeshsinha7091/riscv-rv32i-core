# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. The repository now contains a single-cycle core that runs 37 of the 40 instructions of the RV32I base set: everything except `fence`, `ecall` and `ebreak` (see Design notes for why). It is built from the modules in the table below and runs eleven small assembly programs from `tests/`, whose results are checked automatically by a self-checking testbench. The pipelined core and the synthesis results are not done yet.

| Module | Description |
|---|---|
| `mux2` | 1-bit 2:1 multiplexer |
| `dff_sync_reset` | D flip-flop with synchronous reset |
| `alu` | 32-bit ALU: add, sub, and, or, xor, sll, srl, sra, slt, sltu, plus a zero flag |
| `regfile` | 32 x 32-bit register file: two read ports, one write port, x0 always reads 0 |
| `pc_reg` | 32-bit program counter register with synchronous reset and a PC + 4 output |
| `immgen` | Immediate generator: rebuilds the 32-bit constant from the I, S, B, U or J instruction format, with sign extension |
| `imem` | Instruction memory: 1024 x 32-bit words, read-only, combinational read, loaded from a hex file |
| `dmem` | Data memory: 1024 x 32-bit words, combinational read, clocked write with a 4-bit byte enable (one bit per byte lane) |
| `store_align` | Store alignment: from the access size, the low address bits and rs2, makes the byte enable and the write data for sb, sh and sw |
| `load_align` | Load alignment: picks the byte or half-word out of the memory word and sign- or zero-extends it, for lb, lh, lw, lbu and lhu |
| `control` | Control unit: turns opcode, funct3 and funct7 into the 13 control outputs for the 37 supported instructions. Any other instruction gives all-zero outputs |
| `core` | Single-cycle core for the 37 supported instructions. Connects the modules above, adds a branch target adder, the branch decision, the jalr target and the next-PC logic. The parameter `PROGRAM` names the hex file loaded into the instruction memory |

## Repository layout

- `rtl/` : design files (synthesizable Verilog) and the shared code headers (`*.vh`)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`)
- `tests/` : test programs for the core: the assembly source (`.asm`) and the assembled hex file (`.hex`) that the core loads
- `sim/` : run script
- `docs/` : design log and waveform screenshots

## Running a test

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH. On Windows, from the repository root, run `sim\run.cmd <module>` with a module name from the table above, for example `sim\run.cmd alu`. `sim\run.cmd core` runs the core on all eleven programs in `tests/` at once. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Test programs

All eleven end in a spin loop (`jal x0, spin`). The testbench runs each for 100 cycles, then checks the registers, the memory and the final PC.

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

## Design notes

- The memories are behavioural models with a combinational read: the data is available in the same cycle as the address. Real SRAM usually has a clocked read, so this is a simplification that suits a single-cycle core.
- Both memories hold 1024 words (4 KiB). Addresses above 4 KiB wrap around and there is no access-fault checking. The instruction memory ignores the two low address bits.
- Misaligned accesses are not supported. A half-word access looks only at address bit 1 and a word access ignores the two low bits, so an unaligned data address is rounded down. Branch and jump targets are not checked for alignment either. A real core would raise an exception.
- The data memory is an array of words with a 4-bit byte enable. The byte and half-word work is done outside it: `store_align` repeats the byte or half-word on every lane and enables only the lanes to write, and `load_align` picks the lane and extends it.
- The instruction memory is loaded from a hex file with `$readmemh` at the start of a simulation. Words the file does not write read as `x`. Because the programs are shorter than the memory, each run prints a harmless `$readmemh` warning per program.
- The control unit accepts only the 37 supported instructions, checking exactly the bits that are function codes in each format (for example `funct7` for register-register instructions and for the shift-immediates, but not for `addi`, where it holds bits of the constant). Anything else gives all-zero control signals: no register or memory changes and the PC moves to PC + 4. A real core would raise an illegal-instruction exception, and this one does not.
- Branches reuse the ALU: beq and bne subtract and use the zero flag, while blt, bge, bltu and bgeu run slt or sltu and read bit 0 of the result. Bit 0 of funct3 inverts the answer. A separate adder computes PC + immediate for branches, jal and auipc, and jalr uses the ALU for rs1 + immediate and clears bit 0 of the sum.
- `fence`, `ecall` and `ebreak` are not implemented, so the core has 37 of the 40 RV32I instructions. `ecall` and `ebreak` need a trap mechanism (control and status registers, a saved PC and cause, a handler address and a return instruction) and an environment to answer them, which this project does not have. In this core they do nothing, which is not what a complete core does. A `fence` orders memory accesses as seen by other agents. With one hart, in-order execution, no caches and no devices there is nothing to order, so doing nothing is allowed for a simple core.
- Only the PC has a reset. The registers and memories have no reset and start as unknown (`x`) in simulation, so every test program writes a register before it reads it. The testbench holds reset for one clock edge.
- The test programs are assembled with RARS. The shared operation, select, result and size codes are in the `.vh` header files in `rtl/`.

## Planned

- 5-stage pipelined core
- Test programs compiled with the RISC-V GCC toolchain, and one command that runs all tests
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Test programs assembled with RARS
- Synthesis with Yosys (planned)
