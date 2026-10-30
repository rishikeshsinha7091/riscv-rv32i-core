module core #(
parameter PROGRAM = "tests/program.hex"
) (
input clk,
input reset
);

`include "result_codes.vh"

wire [31:0] pc;
wire [31:0] pc_plus4;
wire [31:0] pc_target;
wire [31:0] jalr_target;
wire [31:0] next_pc;
wire pc_src;
wire taken;

wire [31:0] inst;
wire [31:0] imm;
wire [31:0] rdata1;
wire [31:0] rdata2;
wire [31:0] alu_b;
wire [31:0] alu_y;
wire zero;
wire [31:0] mem_rdata;
reg  [31:0] result;

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

pc_reg u_pc (.clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4));

imem #(.INIT_FILE(PROGRAM)) u_imem (.pc(pc), .instr(inst));

control u_control (.opcode(inst[6:0]), .funct3(inst[14:12]), .funct7(inst[31:25]),
.reg_write(reg_write), .imm_sel(imm_sel), .alu_src(alu_src), .alu_op(alu_op),
.mem_write(mem_write), .result_src(result_src), .branch(branch), .jump(jump),
.jalr(jalr), .br_lt(br_lt), .br_inv(br_inv), .mem_size(mem_size), .load_unsigned(load_unsigned));

regfile u_regfile (.clk(clk), .we(reg_write), .waddr(inst[11:7]), .wdata(result),
.raddr1(inst[19:15]), .raddr2(inst[24:20]), .rdata1(rdata1), .rdata2(rdata2));

immgen u_immgen (.inst(inst), .imm_sel(imm_sel), .imm(imm));

assign alu_b = alu_src ? imm : rdata2;

alu u_alu (.a(rdata1), .b(alu_b), .alu_op(alu_op), .y(alu_y), .zero(zero));

dmem u_dmem (.clk(clk), .we(mem_write), .addr(alu_y), .wdata(rdata2), .rdata(mem_rdata));

always @(*) begin
case (result_src)
RES_ALU: result = alu_y;
RES_MEM: result = mem_rdata;
RES_PC4: result = pc_plus4;
RES_IMM: result = imm;
RES_TARGET: result = pc_target;
default: result = 32'b0;
endcase
end

assign pc_target = pc + imm;
assign taken     = (br_lt ? alu_y[0] : zero) ^ br_inv;
assign pc_src    = (branch & taken) | jump;
assign jalr_target = {alu_y[31:1], 1'b0};
assign next_pc   = jalr ? jalr_target : (pc_src ? pc_target : pc_plus4);

endmodule
