# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. So far the repository contains the datapath building blocks and the instruction and data memories, each with a self-checking testbench. They are not connected into a processor yet: there is no decoder or control logic, and no program runs.

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

## Repository layout

- `rtl/` : design files (synthesizable Verilog)
- `tb/` : self-checking testbenches, named `tb_<module>.v`, and the test data they read (`imem_test.hex`)
- `sim/` : run script
- `docs/` : design log and waveform screenshots

## Running a test

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH. On Windows, from the repository root, run `sim\run.cmd <module>` with a module name from the table above, for example `sim\run.cmd alu`. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Design notes

- The memories are behavioural models with a combinational read: the data is available in the same cycle as the address. Real SRAM usually has a clocked read, so this is a simplification that suits a single-cycle core.
- Both memories hold 1024 words (4 KiB). Addresses above 4 KiB wrap around, the two low address bits are ignored, and there is no alignment or access-fault checking.
- The data memory handles whole words only. Byte and half-word access is planned for the full RV32I core.
- The instruction memory is loaded from a hex file with `$readmemh` at the start of a simulation. Words the file does not write read as `x`.

## Planned

- Single-cycle RV32I core
- 5-stage pipelined core
- Test programs run on the core
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Synthesis with Yosys (planned)