# RISC-V RV32I Core

A RISC-V RV32I processor core written in Verilog. RV32I is the base 32-bit integer instruction set. The plan is to build a single-cycle core first, then a 5-stage pipelined core.

## Status

Early development. No processor logic exists yet. The repository currently contains only the basic project setup.

## Planned

- Single-cycle RV32I core
- 5-stage pipelined core
- Self-checking testbenches and test programs
- Area results from synthesis with Yosys

## Tools

- Verilog, simulated with Icarus Verilog
- Waveforms viewed in GTKWave
- Synthesis with Yosys (planned)