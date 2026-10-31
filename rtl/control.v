module control (
input [6:0] opcode,
input [2:0] funct3,
input [6:0] funct7,
output reg reg_write,
output reg [2:0] imm_sel,
output reg alu_src,
output reg [3:0] alu_op,
output reg mem_write,
output reg [2:0] result_src,
output reg branch,
output reg jump,
output reg jalr,
output reg br_lt,
output reg br_inv,
output reg [1:0] mem_size,
output reg load_unsigned
);

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
localparam OP_JALR   = 7'b1100111;
localparam OP_LUI    = 7'b0110111;
localparam OP_AUIPC  = 7'b0010111;

localparam CLASS_ADD    = 2'b00;
localparam CLASS_FUNCT  = 2'b10;
localparam CLASS_BRANCH = 2'b11;

reg valid;
reg [1:0] alu_class;

always @(*) begin
valid = 1'b0;
case (opcode)
OP_LOAD:   valid = (funct3 != 3'b011) && (funct3 != 3'b110) && (funct3 != 3'b111);
OP_STORE:  valid = (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010);
OP_BRANCH: valid = (funct3 != 3'b010) && (funct3 != 3'b011);
OP_JAL:    valid = 1'b1;
OP_LUI:    valid = 1'b1;
OP_AUIPC:  valid = 1'b1;
OP_JALR:   valid = (funct3 == 3'b000);
OP_ITYPE: begin
case (funct3)
3'b001:  valid = (funct7 == 7'b0000000);
3'b101:  valid = (funct7 == 7'b0000000) || (funct7 == 7'b0100000);
default: valid = 1'b1;
endcase
end
OP_RTYPE:  valid = (funct7 == 7'b0000000)
|| ((funct7 == 7'b0100000) && (funct3 == 3'b000 || funct3 == 3'b101));
default:   valid = 1'b0;
endcase
end

always @(*) begin
reg_write  = 1'b0;
imm_sel    = SEL_I;
alu_src    = 1'b0;
mem_write  = 1'b0;
result_src = RES_ALU;
branch     = 1'b0;
jump       = 1'b0;
jalr       = 1'b0;
br_lt      = 1'b0;
br_inv     = 1'b0;
mem_size   = MEM_BYTE;
load_unsigned = 1'b0;
alu_class  = CLASS_ADD;
if (valid) begin
case (opcode)
OP_LOAD: begin
reg_write  = 1'b1;
imm_sel    = SEL_I;
alu_src    = 1'b1;
result_src = RES_MEM;
mem_size   = funct3[1:0];
load_unsigned = funct3[2];
end
OP_STORE: begin
imm_sel   = SEL_S;
alu_src   = 1'b1;
mem_write = 1'b1;
mem_size  = funct3[1:0];
end
OP_RTYPE: begin
reg_write = 1'b1;
alu_class = CLASS_FUNCT;
end
OP_ITYPE: begin
reg_write = 1'b1;
alu_src   = 1'b1;
alu_class = CLASS_FUNCT;
end
OP_BRANCH: begin
imm_sel   = SEL_B;
branch    = 1'b1;
br_lt     = funct3[2];
br_inv    = funct3[0];
alu_class = CLASS_BRANCH;
end
OP_JAL: begin
reg_write  = 1'b1;
imm_sel    = SEL_J;
result_src = RES_PC4;
jump       = 1'b1;
end
OP_JALR: begin
reg_write  = 1'b1;
imm_sel    = SEL_I;
alu_src    = 1'b1;
result_src = RES_PC4;
jalr       = 1'b1;
end
OP_LUI: begin
reg_write  = 1'b1;
imm_sel    = SEL_U;
result_src = RES_IMM;
end
OP_AUIPC: begin
reg_write  = 1'b1;
imm_sel    = SEL_U;
result_src = RES_TARGET;
end
default: begin
end
endcase
end
end

always @(*) begin
case (alu_class)
CLASS_ADD: alu_op = ALU_ADD;
CLASS_BRANCH: begin
if (!funct3[2])
alu_op = ALU_SUB;
else if (funct3[1])
alu_op = ALU_SLTU;
else
alu_op = ALU_SLT;
end
CLASS_FUNCT: begin
case (funct3)
3'b000:  alu_op = (opcode[5] && funct7[5]) ? ALU_SUB : ALU_ADD;
3'b001:  alu_op = ALU_SLL;
3'b010:  alu_op = ALU_SLT;
3'b011:  alu_op = ALU_SLTU;
3'b100:  alu_op = ALU_XOR;
3'b101:  alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
3'b110:  alu_op = ALU_OR;
3'b111:  alu_op = ALU_AND;
default: alu_op = ALU_ADD;
endcase
end
default: alu_op = ALU_ADD;
endcase
end

endmodule
