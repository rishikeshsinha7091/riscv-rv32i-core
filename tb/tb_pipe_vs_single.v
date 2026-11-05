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
integer ec;
integer ref_last;
integer found_at;
integer s_cnt;
integer r_cnt;

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
ec = -1;
ref_last = 0;
found_at = 0;
s_cnt = 0;
r_cnt = 0;
end

// single-cycle core: done when the PC is known and unchanged for STABLE edges
// pipelined core: done DRAIN edges after the spin was found in Execute
always @(posedge clk) begin
ec = ec + 1;
if (!reset) begin
if ((^u_ref.pc) === 1'bx) ref_stable = 0;
else if (u_ref.pc === prev_pc) ref_stable = ref_stable + 1;
else begin ref_stable = 0; ref_last = ec; end
prev_pc = u_ref.pc;
if (ref_stable >= STABLE) ref_done = 1'b1;
if (!dut_found) begin
if ((u_dut.ex_pc_src === 1'b1) && ((^u_dut.ex_pc) !== 1'bx) && (u_dut.next_pc === u_dut.ex_pc)) begin
dut_found = 1'b1;
dut_spin = u_dut.ex_pc;
found_at = ec;
end
else begin
if (u_dut.stall === 1'b1) s_cnt = s_cnt + 1;
if (u_dut.redirect === 1'b1) r_cnt = r_cnt + 1;
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

localparam NPAIR = 19;
localparam TIMEOUT = 2000;

reg clk;
reg reset;
integer edges;
integer k;
integer total_checks;
integer total_errors;

integer top_checks;
integer top_errors;
integer r;
integer kr;
integer kd;
integer mr;
integer md;

task show;
input [8*12-1:0] name;
input [31:0] cyc_s;
input [31:0] cyc_p;
input [31:0] stalls;
input [31:0] redirs;
input [31:0] e_n;
input [31:0] e_s;
input [31:0] e_r;
input [31:0] e_f;
reg [31:0] n;
begin
n = cyc_s - 1;
$display("INFO: %0s N=%0d cycles single=%0d pipe=%0d stalls=%0d redirects=%0d", name, n, cyc_s, cyc_p, stalls, redirs);
top_checks = top_checks + 1;
if (cyc_p !== n + 3 + stalls + 2 * redirs) begin
top_errors = top_errors + 1;
$display("FAIL: %0s found edge %0d but N + 3 + S + 2R = %0d", name, cyc_p, n + 3 + stalls + 2 * redirs);
end
if (e_f !== 32'hx) begin
check_value({name, " N"}, n, e_n);
check_value({name, " S"}, stalls, e_s);
check_value({name, " R"}, redirs, e_r);
check_value({name, " found"}, cyc_p, e_f);
end
end
endtask
task check_value;
input [8*24-1:0] name;
input [31:0] actual;
input [31:0] expected;
begin
top_checks = top_checks + 1;
if (actual !== expected) begin
top_errors = top_errors + 1;
$display("FAIL: %0s got=%h expected=%h", name, actual, expected);
end
end
endtask
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
pair #(.PROGRAM("tests/unsupported.hex"), .NAME("unsupported")) p14 (.clk(clk), .reset(reset), .both_done(done[14]), .checks(chk[32*14 +: 32]), .errors(err[32*14 +: 32]));
pair #(.PROGRAM("tests/hazard/hazard_alu.hex"), .NAME("hazard_alu")) p15 (.clk(clk), .reset(reset), .both_done(done[15]), .checks(chk[32*15 +: 32]), .errors(err[32*15 +: 32]));
pair #(.PROGRAM("tests/hazard/bypass_d3.hex"), .NAME("bypass_d3")) p16 (.clk(clk), .reset(reset), .both_done(done[16]), .checks(chk[32*16 +: 32]), .errors(err[32*16 +: 32]));
pair #(.PROGRAM("tests/hazard/load_use.hex"), .NAME("load_use")) p17 (.clk(clk), .reset(reset), .both_done(done[17]), .checks(chk[32*17 +: 32]), .errors(err[32*17 +: 32]));
pair #(.PROGRAM("tests/hazard/flush_ctl.hex"), .NAME("flush_ctl")) p18 (.clk(clk), .reset(reset), .both_done(done[18]), .checks(chk[32*18 +: 32]), .errors(err[32*18 +: 32]));
pair #(.PROGRAM("tests/xpc.hex"), .NAME("xpc")) px (.clk(clk), .reset(reset), .both_done(), .checks(), .errors());

always #5 clk = ~clk;

always @(posedge clk) edges = edges + 1;

initial begin
clk = 0;
reset = 1;
edges = -1;
top_checks = 0;
top_errors = 0;
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
p14.evaluate;
p15.evaluate;
p16.evaluate;
p17.evaluate;
p18.evaluate;
// unsupported: the sentinels, worked out by hand, must hold on both cores
check_value("unsupported ref x1", p14.u_ref.u_regfile.regs[1], 32'd5);
check_value("unsupported dut x1", p14.u_dut.u_regfile.regs[1], 32'd5);
check_value("unsupported ref x2", p14.u_ref.u_regfile.regs[2], 32'd7);
check_value("unsupported dut x2", p14.u_dut.u_regfile.regs[2], 32'd7);
check_value("unsupported ref x14", p14.u_ref.u_regfile.regs[14], 32'd77);
check_value("unsupported dut x14", p14.u_dut.u_regfile.regs[14], 32'd77);
check_value("unsupported ref x15", p14.u_ref.u_regfile.regs[15], 32'd99);
check_value("unsupported dut x15", p14.u_dut.u_regfile.regs[15], 32'd99);
check_value("unsupported ref pc", p14.u_ref.pc, 32'h20);
check_value("unsupported dut pc", p14.dut_spin, 32'h20);
kr = 0;
kd = 0;
for (r = 1; r < 32; r = r + 1)
if (r != 1 && r != 2 && r != 14 && r != 15) begin
if ((^p14.u_ref.u_regfile.regs[r]) !== 1'bx) kr = kr + 1;
if ((^p14.u_dut.u_regfile.regs[r]) !== 1'bx) kd = kd + 1;
end
check_value("unsupported ref extra", kr, 0);
check_value("unsupported dut extra", kd, 0);
// xpc: the PC is unknown for ever. Neither core may be done, and nothing may be written.
kr = 0;
kd = 0;
mr = 0;
md = 0;
for (r = 1; r < 32; r = r + 1) begin
if ((^px.u_ref.u_regfile.regs[r]) !== 1'bx) kr = kr + 1;
if ((^px.u_dut.u_regfile.regs[r]) !== 1'bx) kd = kd + 1;
end
for (r = 0; r < 1024; r = r + 1) begin
if ((^px.u_ref.u_dmem.mem[r]) !== 1'bx) mr = mr + 1;
if ((^px.u_dut.u_dmem.mem[r]) !== 1'bx) md = md + 1;
end
check_value("xpc ref not done", px.ref_done, 0);
check_value("xpc dut not found", px.dut_found, 0);
check_value("xpc ref pc unknown", (^px.u_ref.pc) === 1'bx, 1);
check_value("xpc dut pc unknown", (^px.u_dut.pc) === 1'bx, 1);
check_value("xpc ref regs known", kr, 0);
check_value("xpc dut regs known", kd, 0);
check_value("xpc ref words known", mr, 0);
check_value("xpc dut words known", md, 0);
show("alu_ops", p0.ref_last, p0.found_at, p0.s_cnt, p0.r_cnt, 13, 0, 0, 16);
show("mem_ops", p1.ref_last, p1.found_at, p1.s_cnt, p1.r_cnt, 10, 0, 0, 13);
show("branch_ops", p2.ref_last, p2.found_at, p2.s_cnt, p2.r_cnt, 11, 0, 4, 22);
show("jal_ops", p3.ref_last, p3.found_at, p3.s_cnt, p3.r_cnt, 7, 0, 4, 18);
show("loop_sum", p4.ref_last, p4.found_at, p4.s_cnt, p4.r_cnt, 23, 0, 6, 38);
show("alu_full", p5.ref_last, p5.found_at, p5.s_cnt, p5.r_cnt, 22, 0, 0, 25);
show("upper_jalr", p6.ref_last, p6.found_at, p6.s_cnt, p6.r_cnt, 17, 0, 3, 26);
show("branch_all", p7.ref_last, p7.found_at, p7.s_cnt, p7.r_cnt, 46, 0, 9, 67);
show("byte_ops", p8.ref_last, p8.found_at, p8.s_cnt, p8.r_cnt, 33, 0, 0, 36);
show("checksum", p9.ref_last, p9.found_at, p9.s_cnt, p9.r_cnt, 32'hx, 32'hx, 32'hx, 32'hx);
show("c_first", p10.ref_last, p10.found_at, p10.s_cnt, p10.r_cnt, 32'hx, 32'hx, 32'hx, 32'hx);
show("c_fib", p11.ref_last, p11.found_at, p11.s_cnt, p11.r_cnt, 32'hx, 32'hx, 32'hx, 32'hx);
show("c_sort", p12.ref_last, p12.found_at, p12.s_cnt, p12.r_cnt, 32'hx, 32'hx, 32'hx, 32'hx);
show("c_bits", p13.ref_last, p13.found_at, p13.s_cnt, p13.r_cnt, 32'hx, 32'hx, 32'hx, 32'hx);
show("unsupported", p14.ref_last, p14.found_at, p14.s_cnt, p14.r_cnt, 8, 0, 0, 11);
show("hazard_alu", p15.ref_last, p15.found_at, p15.s_cnt, p15.r_cnt, 36, 0, 2, 43);
show("bypass_d3", p16.ref_last, p16.found_at, p16.s_cnt, p16.r_cnt, 40, 0, 0, 43);
show("load_use", p17.ref_last, p17.found_at, p17.s_cnt, p17.r_cnt, 25, 6, 1, 36);
show("flush_ctl", p18.ref_last, p18.found_at, p18.s_cnt, p18.r_cnt, 31, 1, 6, 47);
#1;
total_checks = 0;
total_errors = 0;
for (k = 0; k < NPAIR; k = k + 1) begin
total_checks = total_checks + chk[32*k +: 32];
total_errors = total_errors + err[32*k +: 32];
end
total_checks = total_checks + top_checks;
total_errors = total_errors + top_errors;
$display("INFO: pipe_vs_single: stopped after %0d edges", edges);
if (total_errors == 0) $display("PASS: pipe_vs_single, %0d checks, 0 errors", total_checks);
else $display("FAIL: pipe_vs_single, %0d checks, %0d errors", total_checks, total_errors);
$finish;
end

endmodule