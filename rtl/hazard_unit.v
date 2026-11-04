module hazard_unit (
input [6:0] id_opcode,
input [4:0] id_rs1,
input [4:0] id_rs2,
input ex_is_load,
input [4:0] ex_rd,
output stall
);

localparam OP_LOAD = 7'b0000011;
localparam OP_STORE = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_JALR = 7'b1100111;
localparam OP_IMM = 7'b0010011;
localparam OP_REG = 7'b0110011;

wire uses_rs1;
wire uses_rs2;
wire hit_rs1;
wire hit_rs2;

assign uses_rs1 = (id_opcode == OP_LOAD) || (id_opcode == OP_STORE) || (id_opcode == OP_BRANCH) || (id_opcode == OP_JALR) || (id_opcode == OP_IMM) || (id_opcode == OP_REG);
assign uses_rs2 = (id_opcode == OP_STORE) || (id_opcode == OP_BRANCH) || (id_opcode == OP_REG);

assign hit_rs1 = uses_rs1 && (id_rs1 == ex_rd);
assign hit_rs2 = uses_rs2 && (id_rs2 == ex_rd);

assign stall = ex_is_load && (ex_rd != 5'd0) && (hit_rs1 || hit_rs2);

endmodule
