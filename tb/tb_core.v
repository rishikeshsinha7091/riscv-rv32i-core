`timescale 1ns/1ns

module tb_core;

reg clk;
reg reset;
integer checks;
integer errors;

core #(.PROGRAM("tests/alu_ops.hex")) u_alu_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/mem_ops.hex")) u_mem_ops (.clk(clk), .reset(reset));

always #5 clk = ~clk;

task check_value;
input [8*16-1:0] name;
input [31:0] actual;
input [31:0] expected;
begin
checks = checks + 1;
if (actual !== expected) begin
errors = errors + 1;
$display("FAIL: %0s got=%h expected=%h", name, actual, expected);
end
end
endtask

initial begin
$dumpfile("sim/core.vcd");
$dumpvars(0, tb_core);
clk = 0;
reset = 1;
checks = 0;
errors = 0;

@(negedge clk);
reset = 0;
repeat (60) @(posedge clk);
#1;

// alu_ops: values worked out by hand from tests/alu_ops.asm
check_value("alu_ops x1",  u_alu_ops.u_regfile.regs[1],  32'd12);
check_value("alu_ops x2",  u_alu_ops.u_regfile.regs[2],  32'd10);
check_value("alu_ops x3",  u_alu_ops.u_regfile.regs[3],  32'd22);
check_value("alu_ops x4",  u_alu_ops.u_regfile.regs[4],  32'd2);
check_value("alu_ops x5",  u_alu_ops.u_regfile.regs[5],  32'd8);
check_value("alu_ops x6",  u_alu_ops.u_regfile.regs[6],  32'd14);
check_value("alu_ops x7",  u_alu_ops.u_regfile.regs[7],  32'd0);
check_value("alu_ops x8",  u_alu_ops.u_regfile.regs[8],  32'd1);
check_value("alu_ops x9",  u_alu_ops.u_regfile.regs[9],  32'hFFFFFFFF);
check_value("alu_ops x10", u_alu_ops.u_regfile.regs[10], 32'd1);
check_value("alu_ops x11", u_alu_ops.u_regfile.regs[11], 32'hFFFFFFFE);
check_value("alu_ops x12", u_alu_ops.u_regfile.regs[12], 32'd6);
check_value("alu_ops x13", u_alu_ops.u_regfile.regs[13], 32'd112);
check_value("alu_ops pc",  u_alu_ops.pc,                 32'd52);

// mem_ops: values worked out by hand from tests/mem_ops.asm
check_value("mem_ops x1",  u_mem_ops.u_regfile.regs[1], 32'd123);
check_value("mem_ops x2",  u_mem_ops.u_regfile.regs[2], 32'd256);
check_value("mem_ops x3",  u_mem_ops.u_regfile.regs[3], 32'hFFFFFFFB);
check_value("mem_ops x4",  u_mem_ops.u_regfile.regs[4], 32'd77);
check_value("mem_ops x5",  u_mem_ops.u_regfile.regs[5], 32'hFFFFFFFB);
check_value("mem_ops x6",  u_mem_ops.u_regfile.regs[6], 32'd123);
check_value("mem_ops x7",  u_mem_ops.u_regfile.regs[7], 32'd77);
check_value("mem_ops x8",  u_mem_ops.u_regfile.regs[8], 32'hxxxxxxxx);
check_value("mem_ops x28", u_mem_ops.u_regfile.regs[28], 32'hxxxxxxxx);
check_value("mem_ops mem[63]", u_mem_ops.u_dmem.mem[63], 32'd77);
check_value("mem_ops mem[64]", u_mem_ops.u_dmem.mem[64], 32'd123);
check_value("mem_ops mem[66]", u_mem_ops.u_dmem.mem[66], 32'hFFFFFFFB);
check_value("mem_ops pc",  u_mem_ops.pc, 32'd40);

if (errors == 0)
$display("PASS: core, %0d checks, 0 errors", checks);
else
$display("FAIL: core, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
