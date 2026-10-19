`timescale 1ns/1ns

module tb_imem;

reg [31:0] pc;
wire [31:0] instr;

integer checks;
integer errors;

imem #(.INIT_FILE("tb/imem_test.hex")) dut (.pc(pc), .instr(instr));

task check;
input [31:0] pc_in;
input [31:0] expected;
begin
pc = pc_in;
#1;
checks = checks + 1;
if (instr !== expected) begin
errors = errors + 1;
$display("FAIL: pc=%h expected=%h got=%h", pc_in, expected, instr);
end
#9;
end
endtask

initial begin
$dumpfile("sim/imem.vcd");
$dumpvars(0, tb_imem);
checks = 0;
errors = 0;

// slots 0 to 3: the Part 0 instructions at byte addresses 0, 4, 8, 12
check(32'h00000000, 32'h002081B3);
check(32'h00000004, 32'h40520333);
check(32'h00000008, 32'h00A08193);
check(32'h0000000C, 32'h00209663);

// last slot: byte address 1023 x 4 = 0xFFC
check(32'h00000FFC, 32'hA5A5A5A5);

// the two low bits of the address are ignored
check(32'h00000001, 32'h002081B3);
check(32'h00000002, 32'h002081B3);
check(32'h00000003, 32'h002081B3);

// a slot the file never wrote reads as x
check(32'h00000010, 32'hxxxxxxxx);

// above 4 KiB the address wraps around to slot 0
check(32'h00001000, 32'h002081B3);

if (errors == 0)
$display("PASS: imem, %0d checks, 0 errors", checks);
else
$display("FAIL: imem, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
