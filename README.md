# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. So far the repository contains two small building blocks with self-checking testbenches: a 1-bit 2:1 mux and a D flip-flop with synchronous reset. No processor logic exists yet.

## Repository layout

- `rtl/` : design files (synthesizable Verilog)
- `tb/` : self-checking testbenches, named `tb_<module>.v`
- `sim/` : run script
- `docs/` : design log and waveform screenshots

## Running a test

Requires Icarus Verilog (`iverilog` and `vvp`) on the PATH. On Windows, from the repository root, run `sim\run.cmd mux2` or `sim\run.cmd dff_sync_reset`. Each test prints PASS or FAIL. Waveforms are written to `sim/` and can be viewed with GTKWave.

## Planned

- Single-cycle RV32I core
- 5-stage pipelined core
- Test programs run on the core
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Synthesis with Yosys (planned)
