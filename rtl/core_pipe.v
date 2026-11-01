module core_pipe #(
parameter PROGRAM = "tests/program.hex",
parameter DATA = ""
) (
input clk,
input reset
);

// ---- Fetch stage ----
wire [31:0] pc;
wire [31:0] pc_plus4;
wire [31:0] next_pc;
wire [31:0] if_inst;

assign next_pc = pc_plus4;

pc_reg u_pc (.clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4));

imem #(.INIT_FILE(PROGRAM)) u_imem (.pc(pc), .instr(if_inst));

// ---- IF/ID register: pc, pc_plus4, inst ----
wire [95:0] if_id_q;
wire [31:0] id_pc;
wire [31:0] id_pc_plus4;
wire [31:0] id_inst;

pipe_reg #(.WIDTH(96)) u_if_id (.clk(clk), .reset(reset), .en(1'b1), .flush(1'b0), .d({pc, pc_plus4, if_inst}), .q(if_id_q));

assign {id_pc, id_pc_plus4, id_inst} = if_id_q;

// ---- Decode stage ----
wire [31:0] id_rdata1;
wire [31:0] id_rdata2;
wire [31:0] id_imm;
wire id_reg_write;
wire [2:0] id_imm_sel;
wire id_alu_src;
wire [3:0] id_alu_op;
wire id_mem_write;
wire [2:0] id_result_src;
wire id_branch;
wire id_jump;
wire id_jalr;
wire id_br_lt;
wire id_br_inv;
wire [1:0] id_mem_size;
wire id_load_unsigned;

control u_control (.opcode(id_inst[6:0]), .funct3(id_inst[14:12]), .funct7(id_inst[31:25]),
.reg_write(id_reg_write), .imm_sel(id_imm_sel), .alu_src(id_alu_src), .alu_op(id_alu_op),
.mem_write(id_mem_write), .result_src(id_result_src), .branch(id_branch), .jump(id_jump),
.jalr(id_jalr), .br_lt(id_br_lt), .br_inv(id_br_inv), .mem_size(id_mem_size), .load_unsigned(id_load_unsigned));

regfile u_regfile (.clk(clk), .we(1'b0), .waddr(5'b00000), .wdata(32'b0),
.raddr1(id_inst[19:15]), .raddr2(id_inst[24:20]), .rdata1(id_rdata1), .rdata2(id_rdata2));

immgen u_immgen (.inst(id_inst), .imm_sel(id_imm_sel), .imm(id_imm));

// ---- ID/EX register ----
wire [182:0] id_ex_q;
wire [31:0] ex_pc;
wire [31:0] ex_pc_plus4;
wire [31:0] ex_rdata1;
wire [31:0] ex_rdata2;
wire [31:0] ex_imm;
wire [4:0] ex_rd;
wire ex_reg_write;
wire [2:0] ex_result_src;
wire ex_mem_write;
wire [1:0] ex_mem_size;
wire ex_load_unsigned;
wire ex_branch;
wire ex_jump;
wire ex_jalr;
wire ex_br_lt;
wire ex_br_inv;
wire ex_alu_src;
wire [3:0] ex_alu_op;

pipe_reg #(.WIDTH(183)) u_id_ex (.clk(clk), .reset(reset), .en(1'b1), .flush(1'b0),
.d({id_pc, id_pc_plus4, id_rdata1, id_rdata2, id_imm, id_inst[11:7], id_reg_write, id_result_src, id_mem_write, id_mem_size, id_load_unsigned, id_branch, id_jump, id_jalr, id_br_lt, id_br_inv, id_alu_src, id_alu_op}),
.q(id_ex_q));

assign {ex_pc, ex_pc_plus4, ex_rdata1, ex_rdata2, ex_imm, ex_rd, ex_reg_write, ex_result_src, ex_mem_write, ex_mem_size, ex_load_unsigned, ex_branch, ex_jump, ex_jalr, ex_br_lt, ex_br_inv, ex_alu_src, ex_alu_op} = id_ex_q;

endmodule
