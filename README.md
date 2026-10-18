# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. So far the repository contains the datapath building blocks, each with a self-checking testbench. They are not connected into a processor yet: there is no instruction memory, decoder or control logic, and no program runs.

| Module | Description |
|---|---|
| `mux2` | 1-bit 2:1 multiplexer |
| `dff_sync_reset` | D flip-flop with synchronous reset |
| `alu` | 32-bit ALU: add, sub, and, or, xor, sll, srl, sra, slt, sltu, plus a zero flag |
| `regfile` | 32 x 32-bit register file: two read ports, one write port, x0 always reads 0 |
| `pc_reg` | 32-bit program counter register with synchronous reset and a PC + 4 output |

## Repository layout

- `rtl/` : design files (synthesizable Verilog)
- `tb/` : self-checking testbenches, named `tb_<module>.v`
- `sim/` : run script
- `docs/` : design log and waveform screenshots

## Running a test

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH. On Windows, from the repository root, run `sim\run.cmd <module>` with a module name from the table above, for example `sim\run.cmd alu`. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Planned

- Single-cycle RV32I core
- 5-stage pipelined core
- Test programs run on the core
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Synthesis with Yosys (planned)