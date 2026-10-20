`timescale 1ns/1ns

module tb_immgen;

reg [31:0] inst;
reg [2:0] imm_sel;
wire [31:0] imm;

integer checks;
integer errors;

`include "imm_codes.vh"

immgen dut (.inst(inst), .imm_sel(imm_sel), .imm(imm));

task check;
input [31:0] inst_in;
input [2:0] sel_in;
input [31:0] expected;
begin
inst = inst_in;
imm_sel = sel_in;
#1;
checks = checks + 1;
if (imm !== expected) begin
errors = errors + 1;
$display("FAIL: inst=%h sel=%0d expected=%h got=%h", inst_in, sel_in, expected, imm);
end
#9;
end
endtask

initial begin
$dumpfile("sim/immgen.vcd");
$dumpvars(0, tb_immgen);
checks = 0;
errors = 0;

// Group A: I-type
check(32'h00A08193, SEL_I, 32'h0000000A);
check(32'hFFF08193, SEL_I, 32'hFFFFFFFF);
check(32'hFFC08193, SEL_I, 32'hFFFFFFFC);
check(32'h7FF08193, SEL_I, 32'h000007FF);
check(32'h80008193, SEL_I, 32'hFFFFF800);

// Group B: S-type
check(32'h00512423, SEL_S, 32'h00000008);
check(32'hFE512E23, SEL_S, 32'hFFFFFFFC);
check(32'h7E512FA3, SEL_S, 32'h000007FF);
check(32'h80512023, SEL_S, 32'hFFFFF800);

// Group C: B-type
check(32'h00209663, SEL_B, 32'h0000000C);
check(32'h00208863, SEL_B, 32'h00000010);
check(32'hFE208CE3, SEL_B, 32'hFFFFFFF8);
check(32'h7E208FE3, SEL_B, 32'h00000FFE);

// Group D: J-type
check(32'hFF5FF06F, SEL_J, 32'hFFFFFFF4);
check(32'h0100006F, SEL_J, 32'h00000010);
check(32'h7FFFF06F, SEL_J, 32'h000FFFFE);

// Group E: U-type
check(32'h123452B7, SEL_U, 32'h12345000);
check(32'hFFFFF2B7, SEL_U, 32'hFFFFF000);
check(32'h000002B7, SEL_U, 32'h00000000);

// Group F: B-type, one bit at a time
check(32'd1 << 7,  SEL_B, 32'd1 << 11);
check(32'd1 << 8,  SEL_B, 32'd1 << 1);
check(32'd1 << 9,  SEL_B, 32'd1 << 2);
check(32'd1 << 10, SEL_B, 32'd1 << 3);
check(32'd1 << 11, SEL_B, 32'd1 << 4);
check(32'd1 << 25, SEL_B, 32'd1 << 5);
check(32'd1 << 26, SEL_B, 32'd1 << 6);
check(32'd1 << 27, SEL_B, 32'd1 << 7);
check(32'd1 << 28, SEL_B, 32'd1 << 8);
check(32'd1 << 29, SEL_B, 32'd1 << 9);
check(32'd1 << 30, SEL_B, 32'd1 << 10);
check(32'd1 << 31, SEL_B, 32'hFFFFF000);

// Group F: J-type, one bit at a time
check(32'd1 << 21, SEL_J, 32'd1 << 1);
check(32'd1 << 22, SEL_J, 32'd1 << 2);
check(32'd1 << 23, SEL_J, 32'd1 << 3);
check(32'd1 << 24, SEL_J, 32'd1 << 4);
check(32'd1 << 25, SEL_J, 32'd1 << 5);
check(32'd1 << 26, SEL_J, 32'd1 << 6);
check(32'd1 << 27, SEL_J, 32'd1 << 7);
check(32'd1 << 28, SEL_J, 32'd1 << 8);
check(32'd1 << 29, SEL_J, 32'd1 << 9);
check(32'd1 << 30, SEL_J, 32'd1 << 10);
check(32'd1 << 20, SEL_J, 32'd1 << 11);
check(32'd1 << 12, SEL_J, 32'd1 << 12);
check(32'd1 << 13, SEL_J, 32'd1 << 13);
check(32'd1 << 14, SEL_J, 32'd1 << 14);
check(32'd1 << 15, SEL_J, 32'd1 << 15);
check(32'd1 << 16, SEL_J, 32'd1 << 16);
check(32'd1 << 17, SEL_J, 32'd1 << 17);
check(32'd1 << 18, SEL_J, 32'd1 << 18);
check(32'd1 << 19, SEL_J, 32'd1 << 19);
check(32'd1 << 31, SEL_J, 32'hFFF00000);

// Group G: unused instruction bits must not leak into the immediate
check(32'h000FFFFF, SEL_I, 32'h00000000);
check(32'h01FFF07F, SEL_S, 32'h00000000);
check(32'h01FFF07F, SEL_B, 32'h00000000);
check(32'h00000FFF, SEL_U, 32'h00000000);
check(32'h00000FFF, SEL_J, 32'h00000000);

// Group G: undefined select gives 0
check(32'hFFFFFFFF, 3'd5, 32'h00000000);

// RARS-assembled vectors
check(32'h00310863, SEL_B, 32'h00000010);
check(32'hff5ff06f, SEL_J, 32'hFFFFFFF4);

if (errors == 0)
$display("PASS: immgen, %0d checks, 0 errors", checks);
else
$display("FAIL: immgen, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule

