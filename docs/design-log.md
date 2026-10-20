# Design log

Engineering log: what was built, what broke, how it was found, how it was fixed. Newest entries at the bottom.

## Part 1: building blocks and self-checking tests

### 1. 2:1 mux with an exhaustive test

Built `rtl/mux2.v`, a 1-bit 2:1 mux using one continuous assignment, and `tb/tb_mux2.v`, a self-checking testbench. The testbench applies all 8 input combinations. Expected outputs are worked out from the mux rule, not copied from the design. Each output is compared with `!==`, failures are counted, and the last line prints PASS or FAIL.

Result: PASS, 8 of 8 cases, simulation ends at 80 ns. The mux is 1 bit wide for now and will be widened when the datapath needs 32-bit muxes.

### 2. Deliberately broken mux

To check that the test can fail, I swapped the inputs: `assign y = sel ? a : b;`. With the first 4-case version of the testbench, 2 of 4 cases failed (a=1 b=0 sel=0 and a=1 b=0 sel=1). The two cases where a equals b still passed, because a swapped mux gives the same output when both data inputs are equal.

Lesson: a bug can hide behind a badly chosen set of cases. The final testbench uses all 8 combinations. Restored the correct line and PASS returned.

### 3. An unknown output passed with `!=`

I set `assign y = 1'bx;` to simulate a dead design. With `!==` in the testbench, all 8 cases failed. After changing the comparison to `!=`, the testbench printed PASS. The reason: `x != 0` evaluates to x, not true, and an `if` only acts on true, so the FAIL message was skipped and the error counter stayed 0.

Fix: use `!==` for every comparison in testbenches. Restored both files and PASS returned.

### 4. D flip-flop with synchronous reset

Built `rtl/dff_sync_reset.v` and `tb/tb_dff_sync_reset.v`. The testbench changes inputs at the falling clock edge and reads `q` 1 ns after the rising edge, so it never changes an input at the instant the flip-flop samples it. Checks: a reset to remove the power-up `x`, six clocked steps (including reset winning over d=1), and a final block that raises reset and confirms `q` stays 1 until the next rising edge.

The clock starts as `x`, and `x` to 0 counts as a falling edge. A `#1` before the first step makes the first wait end at the real falling edge at 10 ns.

Result: PASS, simulation ends at 76 ns.

![D flip-flop waveform](dff_sync_reset_waveform.png)

`q` is `x` until the first rising edge. After that it changes only just after rising edges. Near 70 ns, `reset` rises while `q` stays 1, and `q` falls at the next rising edge.

### 5. Asynchronous reset: only one check caught it

I changed the sensitivity list to `always @(posedge clk or posedge reset)`, which makes the reset asynchronous. The testbench reported exactly 1 error, from the final block. The six `step` checks all passed.

Reason: `step` reads `q` 1 ns after a rising edge. At that moment the synchronous and asynchronous designs both show 0. They differ only between the moment reset rises (a falling edge) and the next rising edge, and only the final block looks there.

Lesson: a test catches only differences at the moments it looks. A behaviour that matters needs a check at a moment where a correct and a wrong design differ. Restored the line and PASS returned.

### 6. Run script

Added `sim/run.cmd`, which runs one module's test: `sim\run.cmd mux2`. It moves to the repo root first, so the waveform path always works. It stops if the compile fails, so an old compiled file from an earlier run is never executed by mistake. It is Windows-only for now. The all-tests runner comes in Part 6.

## Part 2: ALU, register file and program counter

### 7. ALU with ten operations and a zero flag

Built `rtl/alu.v` and `tb/tb_alu.v`. The ALU implements the ten RV32I integer operations (add, sub, and, or, xor, sll, srl, sra, slt, sltu) and a zero flag. All ten operations were built up front, because the 4-bit operation code is the interface the control logic will use later, and changing it would mean retesting both modules.

The testbench has 40 directed checks. The expected values were worked out by hand and never copied from the design's output. Edge cases: `7FFFFFFF + 1` (wraps), `0 - 1`, shifts by 31 and by 32 (only the low 5 bits of the shift amount count), slt and sltu on operands with different sign bits, and an unused operation code (must give 0).

### 8. ALU: bugs introduced on purpose, and which checks caught them

Four bugs were introduced one at a time to confirm the testbench can fail.

- slt written as `$signed(a) < b`. Verilog treats an expression as signed only if all its operands are signed, so this comparison became unsigned. 2 of 40 checks failed: only the two slt checks whose operands have different sign bits. The other four slt checks still passed. Fix: both operands `$signed`.
- sra written without `$signed`. The `>>>` operator then shifts in zeros. 3 of 40 checks failed. The check with a positive input passed, because sign fill and zero fill are the same for positive numbers.
- sll shifting by all of `b` instead of `b[4:0]`. 1 of 40 checks failed: the one with shift amount 32.
- zero flag written as `(a == b)` instead of `(y == 0)`. 6 of 40 checks failed, all of them cases where the result is zero but the inputs differ.

Lesson: a check is only worth something if it can tell a correct design from a wrong one. Several of these bugs were caught by exactly one check.

### 9. Testbench timing for clocked designs

Convention used by the register file and program counter testbenches: inputs change at the falling clock edge, combinational outputs are checked 1 ns after the inputs change, and clocked outputs are checked 1 ns after the next rising edge.

Changing an input at the rising edge would race with the design sampling that input (the order is undefined). Reading a clocked output at the exact rising edge could return the value from before the nonblocking update. Each testbench task lasts one clock period (10 ns).

### 10. Register file

Built `rtl/regfile.v` and `tb/tb_regfile.v`: 32 registers of 32 bits, two combinational read ports, one clocked write port with a write enable, and x0 that always reads 0 and ignores writes. Decision: no reset. x1 to x31 start as `x` in simulation, so a read before any write shows up in a test instead of being hidden by a zero.

The testbench has 38 checks: x0 reads 0 before anything is written; every register is written with a different value and read back with the two ports on different registers; a write does not disturb its neighbours; nothing is written when the enable is low; x0 ignores writes; and a read of a register in the same cycle as its write shows the old value until the clock edge, then the new value.

![Register file write: the read port shows the old value until the rising edge](regfile_write_waveform.png)

At 710 ns the inputs change on the falling edge, but `rdata1` still shows the old value `A5000009`. At 715 ns, on the rising edge, the write lands and `rdata1` shows `0BADF00D`.

### 11. Register file: bugs introduced on purpose

- Read guard removed on port 1: 2 of 38 checks failed (x0 read as `x`, because nothing ever writes it).
- Write enable ignored: 1 of 38 checks failed, the only one with the enable low and a different write value. In the other cycles the stale address and data just rewrote the same value, which is invisible.
- `rdata2` using `raddr1` (a copy-paste bug): 31 of 38 failed. It passes only when both ports read the same register, which is why the test reads different registers on the two ports.
- x0 write guard removed: all 38 checks still passed. While the read guard forces x0 to 0, a value stored in x0 cannot be seen from outside, so no test can fail on this guard. It stays in the design to state the intention clearly.

### 12. Program counter

Built `rtl/pc_reg.v` and `tb/tb_pc_reg.v`: a 32-bit register with synchronous reset to 0 and a `pc_plus4` output. No enable, because the single-cycle core loads a new value every cycle.

The testbench has 18 checks: `pc` is unknown before the first clock edge and 0 after reset (with a non-zero `next_pc`, so reset must win); `pc` follows `next_pc`, including a jump, a large address, and `FFFFFFFC + 4` wrapping to 0; reset in the middle of a run, held for two cycles, then released. Every step also checks that `pc` has not changed before the rising edge.

Bugs introduced on purpose:

- `PC + 1` instead of `PC + 4`: 8 of 18 checks failed, one in every step.
- Reset removed: 6 checks failed from one bug. The first failure (at 6 ns) pointed to the cause; the later ones followed from it.
- `next_pc` ignored (`pc <= pc_plus4`): 6 checks failed. The first two steps passed, because their `next_pc` happened to equal `pc + 4`. The first failure was the jump.

## Part 3: immediate generator and memories

### 13. Immediate generator

Built `rtl/immgen.v` and `tb/tb_immgen.v`. The module takes a 32-bit instruction and a 3-bit format select (I, S, B, U or J) and rebuilds the 32-bit immediate. It rearranges the scattered instruction bits, puts back the implied bit 0 of the B and J formats, and sign-extends from instruction bit 31. An unused select gives 0. It is combinational: an `always @(*)` with a `case` and a `default`.

The testbench has 59 checks, with expected values worked out by hand from the instruction format tables. They are: named instructions for each format (the `addi` and `bne` encoded by hand earlier, a `beq` and a `jal` assembled by RARS, and stores and `lui` instructions); the extreme offsets of each format; one-bit-at-a-time vectors for the scrambled B and J formats (a single 1 on each stored instruction bit must appear at the right immediate bit); vectors where every unused instruction bit is 1 (the output must be 0); and an undefined select. R-type instructions are not tested, because they have no immediate and so there is no defined correct output.

Result: PASS, 59 of 59 checks, simulation ends at 590 ns.

### 14. Immediate generator: bugs introduced on purpose

Three bugs were introduced one at a time into the version of the testbench that had 57 checks (before the two RARS vectors were added).

- Two bits swapped inside the B immediate (`imm[5]` and `imm[6]`): 2 of 57 checks failed, the two one-bit checks for those bits. Every named B instruction still passed, because in each of them the two swapped bits happen to be equal.
- Zero extension instead of sign extension in the I format: 3 of 57 failed, the three negative constants. All positive constants passed.
- One sign copy too few in the B format (`{18{inst[31]}}` instead of `{19{inst[31]}}`): the compiler accepted it, because a 31-bit value assigned to a 32-bit `reg` is silently zero-extended. 2 of 57 failed, the two B checks with a negative result.

Lesson: a swapped pair of bits is invisible when the two bits are equal in every test vector, so scattered fields need one-bit-at-a-time vectors, and sign extension needs negative test values. Each bug was undone with `git restore` and PASS returned.

### 15. Instruction memory

Built `rtl/imem.v`, `tb/tb_imem.v` and the test data file `tb/imem_test.hex`. The memory has 1024 words of 32 bits, is read-only, and has a combinational read: `instr = mem[pc[11:2]]`. The PC counts bytes and each instruction is 4 bytes, so the word index is the PC divided by 4, which means dropping the two low bits. Contents are loaded with `$readmemh` at the start of a simulation. The hex file name is a module parameter, so the testbench loads its own file with known contents instead of the program the core will run later. That test file lives in `tb/` next to the testbench, because the test cannot pass without it.

The testbench has 10 checks: the four words at byte addresses 0, 4, 8 and 12; a marker word in the last slot; the two low address bits ignored (addresses 1, 2 and 3 read the same word as address 0); a never-written slot reading `x`; and an address above 4 KiB wrapping around to slot 0.

Result: PASS, 10 of 10 checks, simulation ends at 100 ns. Known limitation: addresses above 4 KiB wrap around without a fault, and misaligned addresses are not checked.

### 16. Instruction memory: bugs introduced on purpose

- Index `pc[7:0]`, using the PC as if it counted words: 7 of 10 checks failed. The passes were address 0, the unfilled-slot check and the wrap-around check. The unfilled-slot check passed by coincidence: the broken design read a different unfilled slot, and `x` equals `x` under `!==`.
- Index `pc[12:2]`, one bit too wide: 1 of 10 failed, only the wrap-around check. Address 0x1000 reached slot 1024, outside the array, which reads `x`. That check exists for this bug, since every address below 4 KiB still worked.
- File load removed: 9 of 10 failed, every check against known contents. Again only the unfilled-slot check passed.

Lesson: a check that expects `x` only proves that an unwritten slot reads `x`. It cannot tell a correct design from one that reads the wrong slot or loads nothing. Checks on known contents catch those.

### 17. Data memory

Built `rtl/dmem.v` and `tb/tb_dmem.v`: 1024 words of 32 bits, a combinational read, and a write on the rising clock edge when the write enable is 1. There is no reset, so unwritten words read `x`, as in the register file. Access is by whole words only. Byte and half-word access (for `lb`, `lh`, `sb`, `sh`) is postponed to the full RV32I core: the first core needs only `lw` and `sw`, and the existing tests will protect the later change to a 4-bit byte enable.

The testbench follows the timing convention of entry 9 (each task lasts one clock period, inputs change at the falling edge). It has 15 checks: an unwritten word reads `x`; a write and a read back; a write attempt with the enable low changes nothing; two addresses do not disturb each other; an overwrite shows the old value before the clock edge and the new value after it; and the two low address bits are ignored.

Result: PASS, 15 of 15 checks, simulation ends at 130 ns.

### 18. Data memory: bugs introduced on purpose

- Write enable ignored: 4 of 15 checks failed. Without the enable the memory writes at every clock edge with whatever is on `wdata`, so even the first clock period, where nothing should be written, stored a 0. The failures were that stray write and three reads that saw leftover data from earlier cycles, including the check built for this bug (a write attempt with the enable low).
- Index `addr[7:0]`: 3 of 15 failed, only the three low-address-bit checks. Writes and reads through the same address still agree under the wrong numbering, so every round trip passed.
- Registered (clocked) read: 10 of 15 failed. Every read returned the data for the previous clock edge's address, one cycle late. In a single-cycle core this would hand `lw` the wrong word, which is why the read has to be combinational.

Not tried: a write on the falling edge. The testbench changes inputs at the falling edge, so the design and the testbench would change at the same instant (a race) and the result would depend on the simulator's event order, not on the design.