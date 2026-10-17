`timescale 1ns/1ns

module tb_alu;

reg [31:0] a;
reg [31:0] b;
reg [3:0] alu_op;
wire [31:0] y;
wire zero;

integer errors;
integer tests;

localparam ALU_ADD  = 4'd0;
localparam ALU_SUB  = 4'd1;
localparam ALU_AND  = 4'd2;
localparam ALU_OR   = 4'd3;
localparam ALU_XOR  = 4'd4;
localparam ALU_SLL  = 4'd5;
localparam ALU_SRL  = 4'd6;
localparam ALU_SRA  = 4'd7;
localparam ALU_SLT  = 4'd8;
localparam ALU_SLTU = 4'd9;

alu dut (.a(a), .b(b), .alu_op(alu_op), .y(y), .zero(zero));

task check;
input [3:0] op;
input [31:0] in_a;
input [31:0] in_b;
input [31:0] exp_y;
input exp_zero;
begin
alu_op = op;
a = in_a;
b = in_b;
#1;
tests = tests + 1;
if (y !== exp_y || zero !== exp_zero) begin
errors = errors + 1;
$display("FAIL: op=%0d a=%h b=%h y=%h (expected %h) zero=%b (expected %b)", op, in_a, in_b, y, exp_y, zero, exp_zero);
end
#9;
end
endtask

initial begin
$dumpfile("sim/alu.vcd");
$dumpvars(0, tb_alu);
errors = 0;
tests = 0;
a = 32'd0;
b = 32'd0;
alu_op = 4'd0;

// add
check(ALU_ADD, 32'd5, 32'd3, 32'd8, 1'b0);
check(ALU_ADD, 32'd0, 32'd0, 32'd0, 1'b1);
check(ALU_ADD, 32'h7FFF_FFFF, 32'd1, 32'h8000_0000, 1'b0);
check(ALU_ADD, 32'hFFFF_FFFF, 32'd1, 32'd0, 1'b1);
check(ALU_ADD, 32'h1234_5678, 32'h1111_1111, 32'h2345_6789, 1'b0);

// sub
check(ALU_SUB, 32'd7, 32'd5, 32'd2, 1'b0);
check(ALU_SUB, 32'd5, 32'd5, 32'd0, 1'b1);
check(ALU_SUB, 32'd0, 32'd1, 32'hFFFF_FFFF, 1'b0);
check(ALU_SUB, 32'h8000_0000, 32'd1, 32'h7FFF_FFFF, 1'b0);
check(ALU_SUB, 32'h1234_5678, 32'h1111_1111, 32'h0123_4567, 1'b0);

// and
check(ALU_AND, 32'hAAAA_AAAA, 32'h5555_5555, 32'd0, 1'b1);
check(ALU_AND, 32'hF0F0_F0F0, 32'hFFFF_0000, 32'hF0F0_0000, 1'b0);

// or
check(ALU_OR, 32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF, 1'b0);
check(ALU_OR, 32'hF0F0_0000, 32'h0000_FF00, 32'hF0F0_FF00, 1'b0);

// xor
check(ALU_XOR, 32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF, 1'b0);
check(ALU_XOR, 32'h1234_5678, 32'h1234_5678, 32'd0, 1'b1);
check(ALU_XOR, 32'hFFFF_0000, 32'hFF00_FF00, 32'h00FF_FF00, 1'b0);

// sll (the b = 32 case: only the low 5 bits of b count, so no shift)
check(ALU_SLL, 32'd1, 32'd4, 32'h0000_0010, 1'b0);
check(ALU_SLL, 32'd1, 32'd31, 32'h8000_0000, 1'b0);
check(ALU_SLL, 32'd1, 32'd32, 32'd1, 1'b0);
check(ALU_SLL, 32'hFFFF_FFFF, 32'd4, 32'hFFFF_FFF0, 1'b0);

// srl
check(ALU_SRL, 32'h8000_0000, 32'd4, 32'h0800_0000, 1'b0);
check(ALU_SRL, 32'h8000_0000, 32'd31, 32'd1, 1'b0);
check(ALU_SRL, 32'h1234_5678, 32'd8, 32'h0012_3456, 1'b0);

// sra
check(ALU_SRA, 32'h8000_0000, 32'd4, 32'hF800_0000, 1'b0);
check(ALU_SRA, 32'h8000_0000, 32'd31, 32'hFFFF_FFFF, 1'b0);
check(ALU_SRA, 32'h7FFF_FFFF, 32'd4, 32'h07FF_FFFF, 1'b0);
check(ALU_SRA, 32'hFFFF_FFF0, 32'd2, 32'hFFFF_FFFC, 1'b0);

// slt (signed): the first two have different sign bits
check(ALU_SLT, 32'h8000_0000, 32'd1, 32'd1, 1'b0);
check(ALU_SLT, 32'd1, 32'hFFFF_FFFF, 32'd0, 1'b1);
check(ALU_SLT, 32'd3, 32'd5, 32'd1, 1'b0);
check(ALU_SLT, 32'd5, 32'd3, 32'd0, 1'b1);
check(ALU_SLT, 32'hFFFF_FFF9, 32'hFFFF_FFFC, 32'd1, 1'b0);
check(ALU_SLT, 32'd5, 32'd5, 32'd0, 1'b1);

// sltu (unsigned)
check(ALU_SLTU, 32'h8000_0000, 32'd1, 32'd0, 1'b1);
check(ALU_SLTU, 32'd1, 32'hFFFF_FFFF, 32'd1, 1'b0);
check(ALU_SLTU, 32'd3, 32'd5, 32'd1, 1'b0);
check(ALU_SLTU, 32'hFFFF_FFF9, 32'hFFFF_FFFC, 32'd1, 1'b0);
check(ALU_SLTU, 32'd5, 32'd5, 32'd0, 1'b1);

// unused operation code: the output must be 0
check(4'd15, 32'd5, 32'd3, 32'd0, 1'b1);

if (errors == 0) $display("PASS: tb_alu - all %0d checks passed", tests);
else $display("FAIL: tb_alu - %0d of %0d checks failed", errors, tests);
$finish;
end

endmodule