`timescale 1ns/1ns

module tb_store_align;

reg mem_write;
reg [1:0] mem_size;
reg [1:0] addr_low;
reg [31:0] rs2;
wire [3:0] be;
wire [31:0] wdata;

integer checks;
integer errors;

`include "mem_codes.vh"

store_align dut (.mem_write(mem_write), .mem_size(mem_size), .addr_low(addr_low), .rs2(rs2), .be(be), .wdata(wdata));

task check;
input [8*12-1:0] name;
input w;
input [1:0] size;
input [1:0] a;
input [31:0] r;
input [3:0] exp_be;
input [31:0] exp_wdata;
begin
mem_write = w;
mem_size = size;
addr_low = a;
rs2 = r;
#1;
checks = checks + 1;
if (be !== exp_be || (exp_be != 4'b0000 && wdata !== exp_wdata)) begin
errors = errors + 1;
$display("FAIL: %0s write=%b size=%0d addr=%b rs2=%h | got be=%b wdata=%h | expected be=%b wdata=%h", name, w, size, a, r, be, wdata, exp_be, exp_wdata);
end
#9;
end
endtask

initial begin
$dumpfile("sim/store_align.vcd");
$dumpvars(0, tb_store_align);
checks = 0;
errors = 0;
mem_write = 0;
mem_size = 0;
addr_low = 0;
rs2 = 0;

// sw: all four lanes, the data is rs2
check("sw", 1'b1, MEM_WORD, 2'b00, 32'h11223344, 4'b1111, 32'h11223344);

// sh: the low half of rs2 on both halves, the enable picks the half
check("sh low",  1'b1, MEM_HALF, 2'b00, 32'h56781234, 4'b0011, 32'h12341234);
check("sh high", 1'b1, MEM_HALF, 2'b10, 32'h56781234, 4'b1100, 32'h12341234);

// sb: the low byte of rs2 on all four lanes, the enable picks the lane
check("sb lane 0", 1'b1, MEM_BYTE, 2'b00, 32'hA1B2C3D4, 4'b0001, 32'hD4D4D4D4);
check("sb lane 1", 1'b1, MEM_BYTE, 2'b01, 32'hA1B2C3D4, 4'b0010, 32'hD4D4D4D4);
check("sb lane 2", 1'b1, MEM_BYTE, 2'b10, 32'hA1B2C3D4, 4'b0100, 32'hD4D4D4D4);
check("sb lane 3", 1'b1, MEM_BYTE, 2'b11, 32'hA1B2C3D4, 4'b1000, 32'hD4D4D4D4);

// no write: be must be 0000 whatever the instruction size (wdata does not matter then)
check("sw no write", 1'b0, MEM_WORD, 2'b00, 32'h11223344, 4'b0000, 32'h0);
check("sh no write", 1'b0, MEM_HALF, 2'b10, 32'h56781234, 4'b0000, 32'h0);
check("sb no write", 1'b0, MEM_BYTE, 2'b01, 32'hA1B2C3D4, 4'b0000, 32'h0);

// an unused size writes nothing
check("size 3", 1'b1, 2'd3, 2'b00, 32'hFFFFFFFF, 4'b0000, 32'h0);

if (errors == 0)
$display("PASS: store_align, %0d checks, 0 errors", checks);
else
$display("FAIL: store_align, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
