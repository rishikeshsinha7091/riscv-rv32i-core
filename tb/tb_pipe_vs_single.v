`timescale 1ns/1ns

// pair: one program on the single-cycle core (the reference) and on the pipelined core.
// evaluate compares them once both cores are done.
module pair #(
parameter PROGRAM = "",
parameter DATA = "",
parameter NAME = ""
) (
input clk,
input reset,
output both_done,
output reg [31:0] checks,
output reg [31:0] errors
);

localparam STABLE = 4;
localparam DRAIN = 4;

core #(.PROGRAM(PROGRAM), .DATA(DATA)) u_ref (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM(PROGRAM), .DATA(DATA)) u_dut (.clk(clk), .reset(reset));

reg ref_done;
reg dut_found;
reg dut_done;
integer ref_stable;
integer drain;
reg [31:0] prev_pc;
reg [31:0] dut_spin;

assign both_done = ref_done & dut_done;

initial begin
checks = 0;
errors = 0;
ref_done = 1'b0;
dut_found = 1'b0;
dut_done = 1'b0;
ref_stable = 0;
drain = 0;
prev_pc = 32'hxxxxxxxx;
dut_spin = 32'hxxxxxxxx;
end

// single-cycle core: done when the PC is known and unchanged for STABLE edges
// pipelined core: done DRAIN edges after the spin was found in Execute
always @(posedge clk) begin
if (!reset) begin
if ((^u_ref.pc) === 1'bx) ref_stable = 0;
else if (u_ref.pc === prev_pc) ref_stable = ref_stable + 1;
else ref_stable = 0;
prev_pc = u_ref.pc;
if (ref_stable >= STABLE) ref_done = 1'b1;
if (!dut_found) begin
if ((u_dut.ex_pc_src === 1'b1) && ((^u_dut.ex_pc) !== 1'bx) && (u_dut.next_pc === u_dut.ex_pc)) begin
dut_found = 1'b1;
dut_spin = u_dut.ex_pc;
end
end
else if (!dut_done) begin
drain = drain + 1;
if (drain >= DRAIN) dut_done = 1'b1;
end
end
end

integer i;
integer known;
integer reg_bad;
integer mem_bad;
integer first_reg;
integer first_mem;

task check_flag;
input [8*24-1:0] what;
input ok;
begin
checks = checks + 1;
if (ok !== 1'b1) begin
errors = errors + 1;
$display("FAIL: %0s %0s", NAME, what);
end
end
endtask

task evaluate;
begin
check_flag("single-cycle core done", ref_done);
check_flag("pipelined core done", dut_done);
known = 0;
for (i = 1; i < 32; i = i + 1)
if ((^u_ref.u_regfile.regs[i]) !== 1'bx) known = known + 1;
check_flag("some register known", known > 0);
check_flag("same final pc", u_ref.pc === dut_spin);
reg_bad = 0;
first_reg = -1;
for (i = 1; i < 32; i = i + 1)
if (u_ref.u_regfile.regs[i] !== u_dut.u_regfile.regs[i]) begin
reg_bad = reg_bad + 1;
if (first_reg < 0) first_reg = i;
end
checks = checks + 1;
if (reg_bad != 0) begin
errors = errors + 1;
$display("FAIL: %0s registers differ: %0d (first x%0d)", NAME, reg_bad, first_reg);
end
mem_bad = 0;
first_mem = -1;
for (i = 0; i < 1024; i = i + 1)
if (u_ref.u_dmem.mem[i] !== u_dut.u_dmem.mem[i]) begin
mem_bad = mem_bad + 1;
if (first_mem < 0) first_mem = i;
end
checks = checks + 1;
if (mem_bad != 0) begin
errors = errors + 1;
$display("FAIL: %0s memory words differ: %0d (first word %0d)", NAME, mem_bad, first_mem);
end
end
endtask

endmodule

module tb_pipe_vs_single;

localparam NPAIR = 14;
localparam TIMEOUT = 2000;

reg clk;
reg reset;
integer edges;
integer k;
integer total_checks;
integer total_errors;
wire [NPAIR-1:0] done;
wire [32*NPAIR-1:0] chk;
wire [32*NPAIR-1:0] err;

pair #(.PROGRAM("tests/alu_ops.hex"), .NAME("alu_ops")) p0 (.clk(clk), .reset(reset), .both_done(done[0]), .checks(chk[32*0 +: 32]), .errors(err[32*0 +: 32]));
pair #(.PROGRAM("tests/mem_ops.hex"), .NAME("mem_ops")) p1 (.clk(clk), .reset(reset), .both_done(done[1]), .checks(chk[32*1 +: 32]), .errors(err[32*1 +: 32]));
pair #(.PROGRAM("tests/branch_ops.hex"), .NAME("branch_ops")) p2 (.clk(clk), .reset(reset), .both_done(done[2]), .checks(chk[32*2 +: 32]), .errors(err[32*2 +: 32]));
pair #(.PROGRAM("tests/jal_ops.hex"), .NAME("jal_ops")) p3 (.clk(clk), .reset(reset), .both_done(done[3]), .checks(chk[32*3 +: 32]), .errors(err[32*3 +: 32]));
pair #(.PROGRAM("tests/loop_sum.hex"), .NAME("loop_sum")) p4 (.clk(clk), .reset(reset), .both_done(done[4]), .checks(chk[32*4 +: 32]), .errors(err[32*4 +: 32]));
pair #(.PROGRAM("tests/alu_full.hex"), .NAME("alu_full")) p5 (.clk(clk), .reset(reset), .both_done(done[5]), .checks(chk[32*5 +: 32]), .errors(err[32*5 +: 32]));
pair #(.PROGRAM("tests/upper_jalr.hex"), .NAME("upper_jalr")) p6 (.clk(clk), .reset(reset), .both_done(done[6]), .checks(chk[32*6 +: 32]), .errors(err[32*6 +: 32]));
pair #(.PROGRAM("tests/branch_all.hex"), .NAME("branch_all")) p7 (.clk(clk), .reset(reset), .both_done(done[7]), .checks(chk[32*7 +: 32]), .errors(err[32*7 +: 32]));
pair #(.PROGRAM("tests/byte_ops.hex"), .NAME("byte_ops")) p8 (.clk(clk), .reset(reset), .both_done(done[8]), .checks(chk[32*8 +: 32]), .errors(err[32*8 +: 32]));
pair #(.PROGRAM("tests/checksum.hex"), .NAME("checksum")) p9 (.clk(clk), .reset(reset), .both_done(done[9]), .checks(chk[32*9 +: 32]), .errors(err[32*9 +: 32]));
pair #(.PROGRAM("sw/first.hex"), .DATA("sw/first.data.hex"), .NAME("c_first")) p10 (.clk(clk), .reset(reset), .both_done(done[10]), .checks(chk[32*10 +: 32]), .errors(err[32*10 +: 32]));
pair #(.PROGRAM("sw/fib.hex"), .DATA("sw/fib.data.hex"), .NAME("c_fib")) p11 (.clk(clk), .reset(reset), .both_done(done[11]), .checks(chk[32*11 +: 32]), .errors(err[32*11 +: 32]));
pair #(.PROGRAM("sw/sort.hex"), .DATA("sw/sort.data.hex"), .NAME("c_sort")) p12 (.clk(clk), .reset(reset), .both_done(done[12]), .checks(chk[32*12 +: 32]), .errors(err[32*12 +: 32]));
pair #(.PROGRAM("sw/bits.hex"), .DATA("sw/bits.data.hex"), .NAME("c_bits")) p13 (.clk(clk), .reset(reset), .both_done(done[13]), .checks(chk[32*13 +: 32]), .errors(err[32*13 +: 32]));

always #5 clk = ~clk;

always @(posedge clk) edges = edges + 1;

initial begin
clk = 0;
reset = 1;
edges = -1;
@(posedge clk);
#1 reset = 0;
// wait until every pair is done, or until the timeout; looking at falling edges avoids a race with the detectors
while (((&done) !== 1'b1) && (edges < TIMEOUT)) @(negedge clk);
p0.evaluate;
p1.evaluate;
p2.evaluate;
p3.evaluate;
p4.evaluate;
p5.evaluate;
p6.evaluate;
p7.evaluate;
p8.evaluate;
p9.evaluate;
p10.evaluate;
p11.evaluate;
p12.evaluate;
p13.evaluate;
#1;
total_checks = 0;
total_errors = 0;
for (k = 0; k < NPAIR; k = k + 1) begin
total_checks = total_checks + chk[32*k +: 32];
total_errors = total_errors + err[32*k +: 32];
end
$display("INFO: pipe_vs_single: stopped after %0d edges", edges);
if (total_errors == 0) $display("PASS: pipe_vs_single, %0d checks, 0 errors", total_checks);
else $display("FAIL: pipe_vs_single, %0d checks, %0d errors", total_checks, total_errors);
$finish;
end

endmodule