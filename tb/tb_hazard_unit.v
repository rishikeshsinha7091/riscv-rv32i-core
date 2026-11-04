`timescale 1ns/1ns

module tb_hazard_unit;

reg [6:0] id_opcode;
reg [4:0] id_rs1;
reg [4:0] id_rs2;
reg ex_is_load;
reg [4:0] ex_rd;
wire stall;
integer checks;
integer errors;
integer cases;
integer r;
integer b;
integer op;

// opcodes typed again from the RV32I opcode table, independent of the module under test
localparam T_LOAD = 7'b0000011;
localparam T_STORE = 7'b0100011;
localparam T_BRANCH = 7'b1100011;
localparam T_JALR = 7'b1100111;
localparam T_IMM = 7'b0010011;
localparam T_REG = 7'b0110011;
localparam T_LUI = 7'b0110111;
localparam T_AUIPC = 7'b0010111;
localparam T_JAL = 7'b1101111;

hazard_unit dut (.id_opcode(id_opcode), .id_rs1(id_rs1), .id_rs2(id_rs2), .ex_is_load(ex_is_load), .ex_rd(ex_rd), .stall(stall));

// which opcodes really read rs1 and rs2 (the table the sweeps compare against)
function uses1;
input [6:0] opc;
begin
uses1 = (opc == T_LOAD) || (opc == T_STORE) || (opc == T_BRANCH) || (opc == T_JALR) || (opc == T_IMM) || (opc == T_REG);
end
endfunction

function uses2;
input [6:0] opc;
begin
uses2 = (opc == T_STORE) || (opc == T_BRANCH) || (opc == T_REG);
end
endfunction

task apply;
input [6:0] opc;
input [4:0] rs1;
input [4:0] rs2;
input is_load;
input [4:0] rd;
input expected;
begin
id_opcode = opc;
id_rs1 = rs1;
id_rs2 = rs2;
ex_is_load = is_load;
ex_rd = rd;
#1;
cases = cases + 1;
checks = checks + 1;
if (stall !== expected) begin
errors = errors + 1;
$display("FAIL: case %0d stall got=%b expected=%b", cases, stall, expected);
end
end
endtask

initial begin
$dumpfile("sim/hazard_unit.vcd");
$dumpvars(0, tb_hazard_unit);
checks = 0;
errors = 0;
cases = 0;

// directed cases
// real users: a load in Execute with a matching rd stalls
apply(T_REG, 5, 6, 1, 5, 1);
apply(T_REG, 5, 6, 1, 6, 1);
apply(T_REG, 5, 6, 1, 7, 0);
apply(T_REG, 5, 5, 1, 5, 1);
apply(T_IMM, 5, 6, 1, 5, 1);
apply(T_IMM, 1, 6, 1, 6, 0);
apply(T_LOAD, 5, 6, 1, 5, 1);
apply(T_LOAD, 1, 6, 1, 6, 0);
apply(T_STORE, 1, 6, 1, 6, 1);
apply(T_STORE, 5, 6, 1, 5, 1);
apply(T_BRANCH, 5, 6, 1, 6, 1);
apply(T_BRANCH, 5, 6, 1, 5, 1);
apply(T_JALR, 5, 6, 1, 5, 1);
apply(T_JALR, 1, 6, 1, 6, 0);
// instructions that read no register
apply(T_LUI, 5, 6, 1, 5, 0);
apply(T_AUIPC, 5, 6, 1, 5, 0);
apply(T_JAL, 5, 6, 1, 6, 0);
apply(7'b0000000, 5, 6, 1, 5, 0);
apply(7'b0001111, 5, 6, 1, 5, 0);
apply(7'b1110011, 5, 6, 1, 5, 0);
// the producer is not a load: forwarding handles it, no stall
apply(T_REG, 5, 6, 0, 5, 0);
// x0 never stalls
apply(T_REG, 0, 0, 1, 0, 0);
apply(T_STORE, 0, 0, 1, 0, 0);
// highest numbers, and numbers that differ in one bit
apply(T_REG, 31, 30, 1, 31, 1);
apply(T_REG, 31, 30, 1, 30, 1);
apply(T_REG, 5, 6, 1, 21, 0);
apply(T_REG, 5, 6, 1, 22, 0);
apply(T_REG, 5, 6, 1, 13, 0);
apply(T_REG, 5, 6, 1, 14, 0);

// sweeps
for (op = 0; op < 128; op = op + 1)
apply(op, 5, 6, 1, 5, uses1(op));

for (op = 0; op < 128; op = op + 1)
apply(op, 5, 6, 1, 6, uses2(op));

for (r = 0; r < 32; r = r + 1)
apply(T_REG, r, r, 1, r, (r != 0));

for (r = 1; r < 32; r = r + 1)
for (b = 0; b < 5; b = b + 1)
apply(T_REG, r, r, 1, r ^ (1 << b), 0);

for (r = 0; r < 32; r = r + 1)
apply(T_REG, r, r, 0, r, 0);

if (errors == 0)
$display("PASS: hazard_unit, %0d checks, 0 errors", checks);
else
$display("FAIL: hazard_unit, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
