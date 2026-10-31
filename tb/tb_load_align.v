`timescale 1ns/1ns

module tb_load_align;

reg [31:0] word;
reg [1:0] addr_low;
reg [1:0] mem_size;
reg load_unsigned;
wire [31:0] value;

integer checks;
integer errors;

`include "mem_codes.vh"

localparam W_TEST = 32'h80FF7F01;

load_align dut (.word(word), .addr_low(addr_low), .mem_size(mem_size), .load_unsigned(load_unsigned), .value(value));

task check;
input [8*12-1:0] name;
input [1:0] size;
input u;
input [1:0] a;
input [31:0] expected;
begin
word = W_TEST;
mem_size = size;
load_unsigned = u;
addr_low = a;
#1;
checks = checks + 1;
if (value !== expected) begin
errors = errors + 1;
$display("FAIL: %0s size=%0d unsigned=%b addr=%b word=%h | got=%h expected=%h", name, size, u, a, word, value, expected);
end
#9;
end
endtask

initial begin
$dumpfile("sim/load_align.vcd");
$dumpvars(0, tb_load_align);
checks = 0;
errors = 0;
word = 0;
addr_low = 0;
mem_size = 0;
load_unsigned = 0;

// lb: the byte, sign-extended. Lanes 3 to 0 of the test word hold 80 FF 7F 01
check("lb lane 0", MEM_BYTE, 1'b0, 2'b00, 32'h00000001);
check("lb lane 1", MEM_BYTE, 1'b0, 2'b01, 32'h0000007F);
check("lb lane 2", MEM_BYTE, 1'b0, 2'b10, 32'hFFFFFFFF);
check("lb lane 3", MEM_BYTE, 1'b0, 2'b11, 32'hFFFFFF80);

// lbu: the byte, zero-extended
check("lbu lane 0", MEM_BYTE, 1'b1, 2'b00, 32'h00000001);
check("lbu lane 1", MEM_BYTE, 1'b1, 2'b01, 32'h0000007F);
check("lbu lane 2", MEM_BYTE, 1'b1, 2'b10, 32'h000000FF);
check("lbu lane 3", MEM_BYTE, 1'b1, 2'b11, 32'h00000080);

// lh and lhu: the half, sign- or zero-extended. The low half is 7F01, the high half is 80FF
check("lh low",   MEM_HALF, 1'b0, 2'b00, 32'h00007F01);
check("lh high",  MEM_HALF, 1'b0, 2'b10, 32'hFFFF80FF);
check("lhu low",  MEM_HALF, 1'b1, 2'b00, 32'h00007F01);
check("lhu high", MEM_HALF, 1'b1, 2'b10, 32'h000080FF);

// lw: the whole word, unchanged
check("lw", MEM_WORD, 1'b0, 2'b00, 32'h80FF7F01);

// an unused size gives 0
check("size 3", 2'd3, 1'b0, 2'b00, 32'h00000000);

if (errors == 0)
$display("PASS: load_align, %0d checks, 0 errors", checks);
else
$display("FAIL: load_align, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
