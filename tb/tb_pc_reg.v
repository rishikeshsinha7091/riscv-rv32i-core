`timescale 1ns/1ns

module tb_pc_reg;

reg clk;
reg reset;
reg [31:0] next_pc;
wire [31:0] pc;
wire [31:0] pc_plus4;

reg [31:0] last_pc;
integer errors;
integer tests;

pc_reg dut (.clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4));

always #5 clk = ~clk;

task check_pc;
input [31:0] expected;
begin
tests = tests + 1;
if (pc !== expected) begin
errors = errors + 1;
$display("FAIL: pc=%h (expected %h) at %0d ns", pc, expected, $time);
end
end
endtask

task step;
input rst;
input [31:0] npc;
input [31:0] exp_pc;
input [31:0] exp_plus4;
begin
@(negedge clk);
reset = rst;
next_pc = npc;
#1;
check_pc(last_pc);
@(posedge clk);
#1;
tests = tests + 1;
if (pc !== exp_pc || pc_plus4 !== exp_plus4) begin
errors = errors + 1;
$display("FAIL: after the edge: pc=%h (expected %h) pc_plus4=%h (expected %h) at %0d ns", pc, exp_pc, pc_plus4, exp_plus4, $time);
end
last_pc = exp_pc;
end
endtask

initial begin
clk = 0;
$dumpfile("sim/pc_reg.vcd");
$dumpvars(0, tb_pc_reg);
errors = 0;
tests = 0;
reset = 1;
next_pc = 32'h0000_0040;

// power-up: pc is unknown until the first clock edge, then reset makes it 0
// (next_pc is non-zero here, so this also shows that reset wins)
#1;
check_pc(32'bx);
@(posedge clk);
#1;
check_pc(32'd0);
last_pc = 32'd0;

// normal operation: pc follows next_pc
step(1'b0, 32'h0000_0004, 32'h0000_0004, 32'h0000_0008);
step(1'b0, 32'h0000_0008, 32'h0000_0008, 32'h0000_000C);

// a jump or taken branch: next_pc is not pc + 4
step(1'b0, 32'h0000_0100, 32'h0000_0100, 32'h0000_0104);

// a large address, and pc + 4 wrapping around to 0
step(1'b0, 32'h8000_0000, 32'h8000_0000, 32'h8000_0004);
step(1'b0, 32'hFFFF_FFFC, 32'hFFFF_FFFC, 32'h0000_0000);

// reset in the middle of a run, held for two cycles, then released
step(1'b1, 32'h0000_0200, 32'h0000_0000, 32'h0000_0004);
step(1'b1, 32'h0000_0200, 32'h0000_0000, 32'h0000_0004);
step(1'b0, 32'h0000_0004, 32'h0000_0004, 32'h0000_0008);

if (errors == 0) $display("PASS: tb_pc_reg - all %0d checks passed", tests);
else $display("FAIL: tb_pc_reg - %0d of %0d checks failed", errors, tests);
$finish;
end

endmodule