`timescale 1ns/1ns

module tb_control;

reg [6:0] opcode;
reg [2:0] funct3;
reg [6:0] funct7;
wire reg_write;
wire [2:0] imm_sel;
wire alu_src;
wire [3:0] alu_op;
wire mem_write;
wire [1:0] result_src;
wire branch;
wire jump;

integer checks;
integer errors;

`include "alu_codes.vh"
`include "imm_codes.vh"
`include "result_codes.vh"

localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_RTYPE  = 7'b0110011;
localparam OP_ITYPE  = 7'b0010011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JAL    = 7'b1101111;

control dut (.opcode(opcode), .funct3(funct3), .funct7(funct7),
.reg_write(reg_write), .imm_sel(imm_sel), .alu_src(alu_src), .alu_op(alu_op),
.mem_write(mem_write), .result_src(result_src), .branch(branch), .jump(jump));

task check;
input [8*12-1:0] name;
input [6:0] op_in;
input [2:0] f3_in;
input [6:0] f7_in;
input e_reg_write;
input [2:0] e_imm_sel;
input e_alu_src;
input [3:0] e_alu_op;
input e_mem_write;
input [1:0] e_result_src;
input e_branch;
input e_jump;
begin
opcode = op_in;
funct3 = f3_in;
funct7 = f7_in;
#1;
checks = checks + 1;
if ({reg_write, imm_sel, alu_src, alu_op, mem_write, result_src, branch, jump} !==
{e_reg_write, e_imm_sel, e_alu_src, e_alu_op, e_mem_write, e_result_src, e_branch, e_jump}) begin
errors = errors + 1;
$display("FAIL: %0s op=%b f3=%b f7=%b | got rw=%b imm=%0d asrc=%b aop=%0d mw=%b rs=%0d br=%b jmp=%b | expected rw=%b imm=%0d asrc=%b aop=%0d mw=%b rs=%0d br=%b jmp=%b",
name, op_in, f3_in, f7_in,
reg_write, imm_sel, alu_src, alu_op, mem_write, result_src, branch, jump,
e_reg_write, e_imm_sel, e_alu_src, e_alu_op, e_mem_write, e_result_src, e_branch, e_jump);
end
#9;
end
endtask

task check_invalid;
input [8*12-1:0] name;
input [6:0] op_in;
input [2:0] f3_in;
input [6:0] f7_in;
begin
check(name, op_in, f3_in, f7_in, 1'b0, SEL_I, 1'b0, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0);
end
endtask

initial begin
$dumpfile("sim/control.vcd");
$dumpvars(0, tb_control);
checks = 0;
errors = 0;

// Group A: the 10 supported instructions (the Message 3 table)
//     name    opcode     funct3   funct7       reg_write  imm_sel  alu_src  alu_op   mem_write  result_src  branch  jump
check("lw",   OP_LOAD,   3'b010, 7'b0000000, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_MEM, 1'b0, 1'b0);
check("sw",   OP_STORE,  3'b010, 7'b0000000, 1'b0, SEL_S, 1'b1, ALU_ADD, 1'b1, RES_ALU, 1'b0, 1'b0);
check("add",  OP_RTYPE,  3'b000, 7'b0000000, 1'b1, SEL_I, 1'b0, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0);
check("sub",  OP_RTYPE,  3'b000, 7'b0100000, 1'b1, SEL_I, 1'b0, ALU_SUB, 1'b0, RES_ALU, 1'b0, 1'b0);
check("and",  OP_RTYPE,  3'b111, 7'b0000000, 1'b1, SEL_I, 1'b0, ALU_AND, 1'b0, RES_ALU, 1'b0, 1'b0);
check("or",   OP_RTYPE,  3'b110, 7'b0000000, 1'b1, SEL_I, 1'b0, ALU_OR,  1'b0, RES_ALU, 1'b0, 1'b0);
check("slt",  OP_RTYPE,  3'b010, 7'b0000000, 1'b1, SEL_I, 1'b0, ALU_SLT, 1'b0, RES_ALU, 1'b0, 1'b0);
check("addi", OP_ITYPE,  3'b000, 7'b0000000, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0);
check("beq",  OP_BRANCH, 3'b000, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SUB, 1'b0, RES_ALU, 1'b1, 1'b0);
check("jal",  OP_JAL,    3'b000, 7'b0000000, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1);

// Group B: addi trap. The funct7 position of addi holds immediate bits, so it must not choose sub.
check("addi f7=7F", OP_ITYPE, 3'b000, 7'h7F, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0);
check("addi f7=20", OP_ITYPE, 3'b000, 7'h20, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0);

// Group C: fields that hold immediate bits must be ignored
check("lw f7=7F",    OP_LOAD,   3'b010, 7'h7F, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_MEM, 1'b0, 1'b0);
check("sw f7=7F",    OP_STORE,  3'b010, 7'h7F, 1'b0, SEL_S, 1'b1, ALU_ADD, 1'b1, RES_ALU, 1'b0, 1'b0);
check("beq f7=7F",   OP_BRANCH, 3'b000, 7'h7F, 1'b0, SEL_B, 1'b0, ALU_SUB, 1'b0, RES_ALU, 1'b1, 1'b0);
check("jal f3=111",  OP_JAL,    3'b111, 7'h7F, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1);
check("jal f3=010",  OP_JAL,    3'b010, 7'h2A, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1);

// Group D: unsupported instructions must give all zeros
check_invalid("bne",        OP_BRANCH, 3'b001, 7'b0000000);
check_invalid("lb",         OP_LOAD,   3'b000, 7'b0000000);
check_invalid("sb",         OP_STORE,  3'b000, 7'b0000000);
check_invalid("xor",        OP_RTYPE,  3'b100, 7'b0000000);
check_invalid("mul",        OP_RTYPE,  3'b000, 7'b0000001);
check_invalid("andi",       OP_ITYPE,  3'b111, 7'b0000000);
check_invalid("lui",        7'b0110111, 3'b000, 7'b0000000);
check_invalid("and bad f7", OP_RTYPE,  3'b111, 7'b0100000);
check_invalid("sub bad f7", OP_RTYPE,  3'b000, 7'b0100001);
check_invalid("jalr",       7'b1100111, 3'b000, 7'b0000000);
check_invalid("ecall",      7'b1110011, 3'b000, 7'b0000000);
check_invalid("zero opcode", 7'b0000000, 3'b000, 7'b0000000);

// Group E: an unknown instruction (what imem gives after the program) must give definite zeros
check_invalid("all x", 7'bxxxxxxx, 3'bxxx, 7'bxxxxxxx);

if (errors == 0)
$display("PASS: control, %0d checks, 0 errors", checks);
else
$display("FAIL: control, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
