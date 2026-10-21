# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. The repository now contains a single-cycle core that runs a subset of RV32I: 10 instructions (add, sub, and, or, slt, addi, lw, sw, beq, jal). It is built from the modules in the table below and runs six small assembly programs from `tests/`, whose results are checked automatically by a self-checking testbench. The rest of RV32I (for example bne, lui, byte and half-word access, and the other branches), the pipelined core and the synthesis results are not done yet.

| Module | Description |
|---|---|
| `mux2` | 1-bit 2:1 multiplexer |
| `dff_sync_reset` | D flip-flop with synchronous reset |
| `alu` | 32-bit ALU: add, sub, and, or, xor, sll, srl, sra, slt, sltu, plus a zero flag |
| `regfile` | 32 x 32-bit register file: two read ports, one write port, x0 always reads 0 |
| `pc_reg` | 32-bit program counter register with synchronous reset and a PC + 4 output |
| `immgen` | Immediate generator: rebuilds the 32-bit constant from the I, S, B, U or J instruction format, with sign extension |
| `imem` | Instruction memory: 1024 x 32-bit words, read-only, combinational read, loaded from a hex file |
| `dmem` | Data memory: 1024 x 32-bit words, combinational read, clocked write with a write enable, whole-word access only |
| `control` | Control unit: turns opcode, funct3 and funct7 into the control signals for the 10 supported instructions. Any other instruction gives all-zero outputs |
| `core` | Single-cycle core for the 10 supported instructions. Connects the modules above, adds a branch target adder and the next-PC logic. The parameter `PROGRAM` names the hex file loaded into the instruction memory |

## Repository layout

- `rtl/` : design files (synthesizable Verilog) and the shared code headers (`*.vh`)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`)
- `tests/` : test programs for the core: the assembly source (`.asm`) and the assembled hex file (`.hex`) that the core loads
- `sim/` : run script
- `docs/` : design log and waveform screenshots

## Running a test

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH. On Windows, from the repository root, run `sim\run.cmd <module>` with a module name from the table above, for example `sim\run.cmd alu`. `sim\run.cmd core` runs the core on all six programs in `tests/` at once. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Test programs

All six end in a spin loop (`jal x0, 0`). The testbench runs each for a fixed number of cycles, then checks the registers, the memory and the final PC.

| Program | What it checks |
|---|---|
| `alu_ops` | add, sub, and, or, slt, addi, with operands chosen so every result differs |
| `mem_ops` | sw and lw at three addresses, a negative offset and a negative value |
| `branch_ops` | beq taken and not taken, forward and backward |
| `jal_ops` | jal forward and backward, the return address, and jal x0 |
| `loop_sum` | a loop that adds 5 + 4 + 3 + 2 + 1 |
| `unsupported` | xor and bne inside a program change nothing |

## Design notes

- The memories are behavioural models with a combinational read: the data is available in the same cycle as the address. Real SRAM usually has a clocked read, so this is a simplification that suits a single-cycle core.
- Both memories hold 1024 words (4 KiB). Addresses above 4 KiB wrap around, the two low address bits are ignored, and there is no alignment or access-fault checking.
- The data memory handles whole words only. Byte and half-word access is planned for the full RV32I core.
- The instruction memory is loaded from a hex file with `$readmemh` at the start of a simulation. Words the file does not write read as `x`. Because the programs are shorter than the memory, each run prints a harmless `$readmemh` warning.
- The control unit accepts only the 10 supported instructions, matching the opcode, funct3 and (for register-register instructions) funct7 exactly. Anything else, including instructions that share an opcode with a supported one such as bne and xor, gives all-zero control signals: no register or memory changes and the PC moves to PC + 4. A real core would raise an illegal-instruction exception, and this one does not.
- The branch and jump target (PC + immediate) has its own adder, because the ALU is busy comparing the two registers for beq.
- Only the PC has a reset. The registers and memories have no reset and start as unknown (`x`) in simulation, so every test program writes a register before it reads it. The testbench holds reset for one clock edge.
- The supported set has no lui, so constants are limited to 12 bits, and no bne, so loops use beq.
- The test programs are assembled with RARS. The shared operation and select codes are in the `.vh` header files in `rtl/`.

## Planned

- Full RV32I instruction set in the single-cycle core
- 5-stage pipelined core
- Test programs compiled with the RISC-V GCC toolchain, and one command that runs all tests
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Test programs assembled with RARS
- Synthesis with Yosys (planned)
