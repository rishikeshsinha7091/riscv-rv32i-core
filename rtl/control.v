module control (
input [6:0] opcode,
input [2:0] funct3,
input [6:0] funct7,
output reg reg_write,
output reg [2:0] imm_sel,
output reg alu_src,
output reg [3:0] alu_op,
output reg mem_write,
output reg [1:0] result_src,
output reg branch,
output reg jump
);

`include "alu_codes.vh"
`include "imm_codes.vh"
`include "result_codes.vh"

localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_RTYPE  = 7'b0110011;
localparam OP_ITYPE  = 7'b0010011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JAL    = 7'b1101111;

localparam CLASS_ADD   = 2'b00;
localparam CLASS_SUB   = 2'b01;
localparam CLASS_FUNCT = 2'b10;

reg valid;
reg [1:0] alu_class;

always @(*) begin
valid = 1'b0;
case (opcode)
OP_LOAD:   valid = (funct3 == 3'b010);
OP_STORE:  valid = (funct3 == 3'b010);
OP_BRANCH: valid = (funct3 == 3'b000);
OP_JAL:    valid = 1'b1;
OP_ITYPE:  valid = (funct3 == 3'b000);
OP_RTYPE:  valid = ((funct7 == 7'b0000000) && (funct3 == 3'b000 || funct3 == 3'b010 || funct3 == 3'b110 || funct3 == 3'b111))
|| ((funct7 == 7'b0100000) && (funct3 == 3'b000));
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
alu_class  = CLASS_ADD;
if (valid) begin
case (opcode)
OP_LOAD: begin
reg_write  = 1'b1;
imm_sel    = SEL_I;
alu_src    = 1'b1;
result_src = RES_MEM;
end
OP_STORE: begin
imm_sel   = SEL_S;
alu_src   = 1'b1;
mem_write = 1'b1;
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
alu_class = CLASS_SUB;
end
OP_JAL: begin
reg_write  = 1'b1;
imm_sel    = SEL_J;
result_src = RES_PC4;
jump       = 1'b1;
end
default: begin
end
endcase
end
end

always @(*) begin
case (alu_class)
CLASS_ADD: alu_op = ALU_ADD;
CLASS_SUB: alu_op = ALU_SUB;
CLASS_FUNCT: begin
case (funct3)
3'b000:  alu_op = (opcode[5] && funct7[5]) ? ALU_SUB : ALU_ADD;
3'b010:  alu_op = ALU_SLT;
3'b110:  alu_op = ALU_OR;
3'b111:  alu_op = ALU_AND;
default: alu_op = ALU_ADD;
endcase
end
default: alu_op = ALU_ADD;
endcase
end

endmodule
