`timescale 1ns/1ns

module tb_fwd_unit;

`include "fwd_codes.vh"

reg [4:0] ex_rs1;
reg [4:0] ex_rs2;
reg [4:0] mm_rd;
reg mm_reg_write;
reg [4:0] wb_rd;
reg wb_reg_write;
wire [1:0] fwd_a;
wire [1:0] fwd_b;
integer checks;
integer errors;
integer cases;
integer r;
integer b;

fwd_unit dut (.ex_rs1(ex_rs1), .ex_rs2(ex_rs2), .mm_rd(mm_rd), .mm_reg_write(mm_reg_write), .wb_rd(wb_rd), .wb_reg_write(wb_reg_write), .fwd_a(fwd_a), .fwd_b(fwd_b));

task apply;
input [4:0] rs1;
input [4:0] rs2;
input [4:0] m_rd;
input m_rw;
input [4:0] w_rd;
input w_rw;
input [1:0] exp_a;
input [1:0] exp_b;
begin
ex_rs1 = rs1;
ex_rs2 = rs2;
mm_rd = m_rd;
mm_reg_write = m_rw;
wb_rd = w_rd;
wb_reg_write = w_rw;
#1;
cases = cases + 1;
checks = checks + 1;
if (fwd_a !== exp_a) begin
errors = errors + 1;
$display("FAIL: case %0d fwd_a got=%0d expected=%0d", cases, fwd_a, exp_a);
end
checks = checks + 1;
if (fwd_b !== exp_b) begin
errors = errors + 1;
$display("FAIL: case %0d fwd_b got=%0d expected=%0d", cases, fwd_b, exp_b);
end
end
endtask

initial begin
$dumpfile("sim/fwd_unit.vcd");
$dumpvars(0, tb_fwd_unit);
checks = 0;
errors = 0;
cases = 0;

// directed cases
//    rs1 rs2 mm_rd mm_rw wb_rd wb_rw  exp_a    exp_b
apply(5,  6,  0,  0, 0,  0, FWD_REG, FWD_REG);
apply(5,  6,  5,  1, 9,  1, FWD_MEM, FWD_REG);
apply(5,  6,  6,  1, 9,  0, FWD_REG, FWD_MEM);
apply(5,  6,  9,  1, 5,  1, FWD_WB,  FWD_REG);
apply(5,  6,  9,  1, 6,  1, FWD_REG, FWD_WB);
apply(5,  6,  5,  1, 5,  1, FWD_MEM, FWD_REG);
apply(5,  6,  6,  1, 6,  1, FWD_REG, FWD_MEM);
apply(5,  5,  5,  1, 9,  1, FWD_MEM, FWD_MEM);
apply(5,  5,  9,  1, 5,  1, FWD_WB,  FWD_WB);
apply(5,  6,  5,  1, 6,  1, FWD_MEM, FWD_WB);
apply(5,  6,  6,  1, 5,  1, FWD_WB,  FWD_MEM);
apply(5,  6,  5,  0, 9,  0, FWD_REG, FWD_REG);
apply(5,  6,  9,  0, 5,  0, FWD_REG, FWD_REG);
apply(0,  0,  0,  1, 0,  1, FWD_REG, FWD_REG);
apply(0,  6,  0,  1, 9,  0, FWD_REG, FWD_REG);
apply(5,  0,  9,  0, 0,  1, FWD_REG, FWD_REG);
apply(5,  6,  5,  0, 5,  1, FWD_WB,  FWD_REG);
apply(31, 30, 31, 1, 30, 1, FWD_MEM, FWD_WB);
apply(5,  6,  21, 1, 22, 1, FWD_REG, FWD_REG);
apply(5,  6,  13, 1, 14, 1, FWD_REG, FWD_REG);

// sweeps
for (r = 0; r < 32; r = r + 1)
apply(r, r, r, 1, 0, 0, (r == 0) ? FWD_REG : FWD_MEM, (r == 0) ? FWD_REG : FWD_MEM);

for (r = 0; r < 32; r = r + 1)
apply(r, r, 0, 0, r, 1, (r == 0) ? FWD_REG : FWD_WB, (r == 0) ? FWD_REG : FWD_WB);

for (r = 1; r < 32; r = r + 1)
for (b = 0; b < 5; b = b + 1)
apply(r, r, r ^ (1 << b), 1, 0, 0, FWD_REG, FWD_REG);

for (r = 1; r < 32; r = r + 1)
for (b = 0; b < 5; b = b + 1)
apply(r, r, 0, 0, r ^ (1 << b), 1, FWD_REG, FWD_REG);

if (errors == 0)
$display("PASS: fwd_unit, %0d checks, 0 errors", checks);
else
$display("FAIL: fwd_unit, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
