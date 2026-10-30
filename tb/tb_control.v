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
wire [2:0] result_src;
wire branch;
wire jump;
wire jalr;
wire br_lt;
wire br_inv;
wire [1:0] mem_size;
wire load_unsigned;

integer checks;
integer errors;

`include "alu_codes.vh"
`include "imm_codes.vh"
`include "result_codes.vh"
`include "mem_codes.vh"

localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_RTYPE  = 7'b0110011;
localparam OP_ITYPE  = 7'b0010011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JAL    = 7'b1101111;
localparam OP_LUI    = 7'b0110111;
localparam OP_JALR   = 7'b1100111;
localparam OP_SYSTEM = 7'b1110011;
localparam OP_FENCE  = 7'b0001111;
localparam OP_AUIPC  = 7'b0010111;

control dut (.opcode(opcode), .funct3(funct3), .funct7(funct7),
.reg_write(reg_write), .imm_sel(imm_sel), .alu_src(alu_src), .alu_op(alu_op),
.mem_write(mem_write), .result_src(result_src), .branch(branch), .jump(jump),
.jalr(jalr), .br_lt(br_lt), .br_inv(br_inv), .mem_size(mem_size), .load_unsigned(load_unsigned));

task check;
input [8*16-1:0] name;
input [6:0] op_in;
input [2:0] f3_in;
input [6:0] f7_in;
input e_reg_write;
input [2:0] e_imm_sel;
input e_alu_src;
input [3:0] e_alu_op;
input e_mem_write;
input [2:0] e_result_src;
input e_branch;
input e_jump;
input e_jalr;
input e_br_lt;
input e_br_inv;
input [1:0] e_mem_size;
input e_load_unsigned;
begin
opcode = op_in;
funct3 = f3_in;
funct7 = f7_in;
#1;
checks = checks + 1;
if ({reg_write, imm_sel, alu_src, alu_op, mem_write, result_src, branch, jump, jalr, br_lt, br_inv, mem_size, load_unsigned} !==
{e_reg_write, e_imm_sel, e_alu_src, e_alu_op, e_mem_write, e_result_src, e_branch, e_jump, e_jalr, e_br_lt, e_br_inv, e_mem_size, e_load_unsigned}) begin
errors = errors + 1;
$display("FAIL: %0s op=%b f3=%b f7=%b | got rw=%b imm=%0d asrc=%b aop=%0d mw=%b rs=%0d br=%b jmp=%b jalr=%b lt=%b inv=%b sz=%0d uns=%b | expected rw=%b imm=%0d asrc=%b aop=%0d mw=%b rs=%0d br=%b jmp=%b jalr=%b lt=%b inv=%b sz=%0d uns=%b",
name, op_in, f3_in, f7_in,
reg_write, imm_sel, alu_src, alu_op, mem_write, result_src, branch, jump, jalr, br_lt, br_inv, mem_size, load_unsigned,
e_reg_write, e_imm_sel, e_alu_src, e_alu_op, e_mem_write, e_result_src, e_branch, e_jump, e_jalr, e_br_lt, e_br_inv, e_mem_size, e_load_unsigned);
end
#9;
end
endtask

task check_invalid;
input [8*16-1:0] name;
input [6:0] op_in;
input [2:0] f3_in;
input [6:0] f7_in;
begin
check(name, op_in, f3_in, f7_in, 1'b0, SEL_I, 1'b0, ALU_ADD, 1'b0, RES_ALU, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
end
endtask

task check_rtype;
input [8*16-1:0] name;
input [2:0] f3_in;
input [6:0] f7_in;
input [3:0] e_alu_op;
begin
check(name, OP_RTYPE, f3_in, f7_in, 1'b1, SEL_I, 1'b0, e_alu_op, 1'b0, RES_ALU, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
end
endtask

task check_itype;
input [8*16-1:0] name;
input [2:0] f3_in;
input [6:0] f7_in;
input [3:0] e_alu_op;
begin
check(name, OP_ITYPE, f3_in, f7_in, 1'b1, SEL_I, 1'b1, e_alu_op, 1'b0, RES_ALU, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
end
endtask

initial begin
$dumpfile("sim/control.vcd");
$dumpvars(0, tb_control);
checks = 0;
errors = 0;

// Group A: the 23 supported instructions (the Message 5 table)
//     name    opcode     funct3   funct7       reg_write  imm_sel  alu_src  alu_op   mem_write  result_src  branch  jump  jalr  br_lt  br_inv  mem_size  load_unsigned
check("lw",   OP_LOAD,   3'b010, 7'b0000000, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_MEM, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_WORD, 1'b0);
check("sw",   OP_STORE,  3'b010, 7'b0000000, 1'b0, SEL_S, 1'b1, ALU_ADD, 1'b1, RES_ALU, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_WORD, 1'b0);
check("beq",  OP_BRANCH, 3'b000, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SUB, 1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("jal",  OP_JAL,    3'b000, 7'b0000000, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("jalr",  OP_JALR,  3'b000, 7'b0000000, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_PC4,    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("lui",   OP_LUI,   3'b000, 7'b0000000, 1'b1, SEL_U, 1'b0, ALU_ADD, 1'b0, RES_IMM,    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("auipc", OP_AUIPC, 3'b000, 7'b0000000, 1'b1, SEL_U, 1'b0, ALU_ADD, 1'b0, RES_TARGET, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("bne",  OP_BRANCH, 3'b001, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SUB,  1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, MEM_BYTE, 1'b0);
check("blt",  OP_BRANCH, 3'b100, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SLT,  1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, MEM_BYTE, 1'b0);
check("bge",  OP_BRANCH, 3'b101, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SLT,  1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, MEM_BYTE, 1'b0);
check("bltu", OP_BRANCH, 3'b110, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SLTU, 1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, MEM_BYTE, 1'b0);
check("bgeu", OP_BRANCH, 3'b111, 7'b0000000, 1'b0, SEL_B, 1'b0, ALU_SLTU, 1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, MEM_BYTE, 1'b0);

//          name    funct3   funct7       alu_op
check_rtype("add",  3'b000, 7'b0000000, ALU_ADD);
check_rtype("sub",  3'b000, 7'b0100000, ALU_SUB);
check_rtype("sll",  3'b001, 7'b0000000, ALU_SLL);
check_rtype("slt",  3'b010, 7'b0000000, ALU_SLT);
check_rtype("sltu", 3'b011, 7'b0000000, ALU_SLTU);
check_rtype("xor",  3'b100, 7'b0000000, ALU_XOR);
check_rtype("srl",  3'b101, 7'b0000000, ALU_SRL);
check_rtype("sra",  3'b101, 7'b0100000, ALU_SRA);
check_rtype("or",   3'b110, 7'b0000000, ALU_OR);
check_rtype("and",  3'b111, 7'b0000000, ALU_AND);

check_itype("addi",  3'b000, 7'b0000000, ALU_ADD);
check_itype("slli",  3'b001, 7'b0000000, ALU_SLL);
check_itype("slti",  3'b010, 7'b0000000, ALU_SLT);
check_itype("sltiu", 3'b011, 7'b0000000, ALU_SLTU);
check_itype("xori",  3'b100, 7'b0000000, ALU_XOR);
check_itype("srli",  3'b101, 7'b0000000, ALU_SRL);
check_itype("srai",  3'b101, 7'b0100000, ALU_SRA);
check_itype("ori",   3'b110, 7'b0000000, ALU_OR);
check_itype("andi",  3'b111, 7'b0000000, ALU_AND);

// Group B: in an ALU-immediate instruction the funct7 position holds bits of the number, so bit 30 must not choose sub or sra
check_itype("addi f7=7F",  3'b000, 7'h7F, ALU_ADD);
check_itype("addi f7=20",  3'b000, 7'h20, ALU_ADD);
check_itype("slti f7=20",  3'b010, 7'h20, ALU_SLT);
check_itype("sltiu f7=20", 3'b011, 7'h20, ALU_SLTU);
check_itype("xori f7=20",  3'b100, 7'h20, ALU_XOR);
check_itype("ori f7=20",   3'b110, 7'h20, ALU_OR);
check_itype("andi f7=20",  3'b111, 7'h20, ALU_AND);

// Group C: fields that hold immediate bits must be ignored
check("lw f7=7F",   OP_LOAD,   3'b010, 7'h7F, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_MEM, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_WORD, 1'b0);
check("sw f7=7F",   OP_STORE,  3'b010, 7'h7F, 1'b0, SEL_S, 1'b1, ALU_ADD, 1'b1, RES_ALU, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_WORD, 1'b0);
check("beq f7=7F",  OP_BRANCH, 3'b000, 7'h7F, 1'b0, SEL_B, 1'b0, ALU_SUB, 1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("jal f3=111", OP_JAL,    3'b111, 7'h7F, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("jal f3=010", OP_JAL,    3'b010, 7'h2A, 1'b1, SEL_J, 1'b0, ALU_ADD, 1'b0, RES_PC4, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("lui f3=111",   OP_LUI,   3'b111, 7'h7F, 1'b1, SEL_U, 1'b0, ALU_ADD, 1'b0, RES_IMM,    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("auipc f3=101", OP_AUIPC, 3'b101, 7'h2A, 1'b1, SEL_U, 1'b0, ALU_ADD, 1'b0, RES_TARGET, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("jalr f7=7F",   OP_JALR,  3'b000, 7'h7F, 1'b1, SEL_I, 1'b1, ALU_ADD, 1'b0, RES_PC4,    1'b0, 1'b0, 1'b1, 1'b0, 1'b0, MEM_BYTE, 1'b0);
check("bne f7=7F",  OP_BRANCH, 3'b001, 7'h7F, 1'b0, SEL_B, 1'b0, ALU_SUB,  1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, MEM_BYTE, 1'b0);
check("bgeu f7=7F", OP_BRANCH, 3'b111, 7'h7F, 1'b0, SEL_B, 1'b0, ALU_SLTU, 1'b0, RES_ALU, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, MEM_BYTE, 1'b0);

// Group D: shift-immediates, where funct7 is a real function code: wrong values must give all zeros
check_invalid("slli f7=01", OP_ITYPE, 3'b001, 7'b0000001);
check_invalid("slli f7=20", OP_ITYPE, 3'b001, 7'b0100000);
check_invalid("srli f7=01", OP_ITYPE, 3'b101, 7'b0000001);
check_invalid("srai f7=21", OP_ITYPE, 3'b101, 7'b0100001);
check_invalid("srai f7=7F", OP_ITYPE, 3'b101, 7'b1111111);

// Group E: register-register with a wrong funct7. The alternate value 0100000 exists only for sub (000) and sra (101)
check_invalid("sll f7=20",  OP_RTYPE, 3'b001, 7'b0100000);
check_invalid("slt f7=20",  OP_RTYPE, 3'b010, 7'b0100000);
check_invalid("sltu f7=20", OP_RTYPE, 3'b011, 7'b0100000);
check_invalid("xor f7=20",  OP_RTYPE, 3'b100, 7'b0100000);
check_invalid("or f7=20",   OP_RTYPE, 3'b110, 7'b0100000);
check_invalid("and f7=20",  OP_RTYPE, 3'b111, 7'b0100000);
check_invalid("srl f7=01",  OP_RTYPE, 3'b101, 7'b0000001);
check_invalid("sra f7=21",  OP_RTYPE, 3'b101, 7'b0100001);
check_invalid("sub f7=21",  OP_RTYPE, 3'b000, 7'b0100001);
check_invalid("mul",        OP_RTYPE, 3'b000, 7'b0000001);

// Group F: instructions that stay unsupported (Message 6)
check_invalid("ecall",      OP_SYSTEM, 3'b000, 7'b0000000);
check_invalid("csrrw",      OP_SYSTEM, 3'b001, 7'b0000000);
check_invalid("fence",      OP_FENCE,  3'b000, 7'b0000000);
check_invalid("zero opcode", 7'b0000000, 3'b000, 7'b0000000);
check_invalid("jalr f3=001", OP_JALR, 3'b001, 7'b0000000);
check_invalid("jalr f3=111", OP_JALR, 3'b111, 7'b0000000);
check_invalid("branch f3=010", OP_BRANCH, 3'b010, 7'b0000000);
check_invalid("branch f3=011", OP_BRANCH, 3'b011, 7'b0000000);

// Group G: not supported yet. A later build moves each row to Group A
check_invalid("lb",    OP_LOAD,   3'b000, 7'b0000000);
check_invalid("sb",    OP_STORE,  3'b000, 7'b0000000);

// Group H: an unknown instruction (what imem gives after the program) must give definite zeros
check_invalid("all x", 7'bxxxxxxx, 3'bxxx, 7'bxxxxxxx);

if (errors == 0)
$display("PASS: control, %0d checks, 0 errors", checks);
else
$display("FAIL: control, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule


