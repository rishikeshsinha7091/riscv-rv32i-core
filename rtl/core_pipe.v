module core_pipe #(
parameter PROGRAM = "tests/program.hex",
parameter DATA = ""
) (
input clk,
input reset
);

`include "result_codes.vh"
`include "fwd_codes.vh"
wire stall;
wire redirect;

// ---- Fetch stage ----
wire [31:0] pc;
wire [31:0] pc_plus4;
wire [31:0] next_pc;
wire [31:0] if_inst;

// next_pc is assigned in the Execute stage (branch and jump mux)

pc_reg u_pc (.clk(clk), .reset(reset), .en(~stall), .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4));

imem #(.INIT_FILE(PROGRAM)) u_imem (.pc(pc), .instr(if_inst));

// ---- IF/ID register: pc, pc_plus4, inst ----
wire [95:0] if_id_q;
wire [31:0] id_pc;
wire [31:0] id_pc_plus4;
wire [31:0] id_inst;

pipe_reg #(.WIDTH(96)) u_if_id (.clk(clk), .reset(reset), .en(~stall), .flush(redirect), .d({pc, pc_plus4, if_inst}), .q(if_id_q));

assign {id_pc, id_pc_plus4, id_inst} = if_id_q;

// ---- Decode stage ----
wire [31:0] wb_data;
wire [4:0] wb_rd;
wire wb_reg_write;
wire [31:0] id_rdata1;
wire [31:0] id_rdata2;
wire [31:0] id_src1;
wire [31:0] id_src2;
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

regfile u_regfile (.clk(clk), .we(wb_reg_write), .waddr(wb_rd), .wdata(wb_data),
.raddr1(id_inst[19:15]), .raddr2(id_inst[24:20]), .rdata1(id_rdata1), .rdata2(id_rdata2));

// ---- Write-back bypass: a value being written this cycle reaches a reader in Decode (the d = 3 case) ----
assign id_src1 = (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_inst[19:15])) ? wb_data : id_rdata1;
assign id_src2 = (wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_inst[24:20])) ? wb_data : id_rdata2;

immgen u_immgen (.inst(id_inst), .imm_sel(id_imm_sel), .imm(id_imm));

// ---- ID/EX register ----
wire [192:0] id_ex_q;
wire [31:0] ex_pc;
wire [31:0] ex_pc_plus4;
wire [31:0] ex_rdata1;
wire [31:0] ex_rdata2;
wire [31:0] ex_imm;
wire [4:0] ex_rd;
wire [4:0] ex_rs1;
wire [4:0] ex_rs2;
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

pipe_reg #(.WIDTH(193)) u_id_ex (.clk(clk), .reset(reset), .en(1'b1), .flush(stall | redirect),
.d({id_pc, id_pc_plus4, id_src1, id_src2, id_imm, id_inst[11:7], id_inst[19:15], id_inst[24:20], id_reg_write, id_result_src, id_mem_write, id_mem_size, id_load_unsigned, id_branch, id_jump, id_jalr, id_br_lt, id_br_inv, id_alu_src, id_alu_op}),
.q(id_ex_q));

assign {ex_pc, ex_pc_plus4, ex_rdata1, ex_rdata2, ex_imm, ex_rd, ex_rs1, ex_rs2, ex_reg_write, ex_result_src, ex_mem_write, ex_mem_size, ex_load_unsigned, ex_branch, ex_jump, ex_jalr, ex_br_lt, ex_br_inv, ex_alu_src, ex_alu_op} = id_ex_q;

// ---- Load-use hazard: stall one cycle (hold PC and IF/ID, bubble into ID/EX) ----
wire ex_is_load;
assign ex_is_load = (ex_result_src == RES_MEM);

hazard_unit u_hazard (.id_opcode(id_inst[6:0]), .id_rs1(id_inst[19:15]), .id_rs2(id_inst[24:20]), .ex_is_load(ex_is_load), .ex_rd(ex_rd), .stall(stall));

// ---- Execute stage ----
wire [31:0] ex_alu_b;
wire [31:0] ex_alu_y;
wire ex_zero;
wire [31:0] ex_pc_target;
wire ex_taken;
wire ex_pc_src;
wire [31:0] ex_jalr_target;
reg [31:0] ex_result;
wire [1:0] ex_fwd_a;
wire [1:0] ex_fwd_b;
wire [31:0] ex_src1;
wire [31:0] ex_src2;

assign ex_alu_b = ex_alu_src ? ex_imm : ex_src2;

alu u_alu (.a(ex_src1), .b(ex_alu_b), .alu_op(ex_alu_op), .y(ex_alu_y), .zero(ex_zero));

assign ex_pc_target = ex_pc + ex_imm;
assign ex_taken = (ex_br_lt ? ex_alu_y[0] : ex_zero) ^ ex_br_inv;
assign ex_pc_src = (ex_branch & ex_taken) | ex_jump;
assign ex_jalr_target = {ex_alu_y[31:1], 1'b0};
assign next_pc = ex_jalr ? ex_jalr_target : (ex_pc_src ? ex_pc_target : pc_plus4);
assign redirect = ex_pc_src | ex_jalr;

always @(*) begin
case (ex_result_src)
RES_PC4: ex_result = ex_pc_plus4;
RES_IMM: ex_result = ex_imm;
RES_TARGET: ex_result = ex_pc_target;
default: ex_result = ex_alu_y;
endcase
end

// ---- EX/MEM register: result, store data (rs2), rd, reg_write, result_src, mem_write, mem_size, load_unsigned ----
wire [76:0] ex_mem_q;
wire [31:0] mm_result;
wire [31:0] mm_store_src;
wire [4:0] mm_rd;
wire mm_reg_write;
wire [2:0] mm_result_src;
wire mm_mem_write;
wire [1:0] mm_mem_size;
wire mm_load_unsigned;

pipe_reg #(.WIDTH(77)) u_ex_mem (.clk(clk), .reset(reset), .en(1'b1), .flush(1'b0),
.d({ex_result, ex_src2, ex_rd, ex_reg_write, ex_result_src, ex_mem_write, ex_mem_size, ex_load_unsigned}),
.q(ex_mem_q));

assign {mm_result, mm_store_src, mm_rd, mm_reg_write, mm_result_src, mm_mem_write, mm_mem_size, mm_load_unsigned} = ex_mem_q;

// ---- Forwarding: the two Execute operands (ALU a and b, store data, branch and jalr operands all use these) ----
// A load in EX/MEM has its address in mm_result, so a load followed by its user needs the stall (u_hazard).
fwd_unit u_fwd (.ex_rs1(ex_rs1), .ex_rs2(ex_rs2), .mm_rd(mm_rd), .mm_reg_write(mm_reg_write), .wb_rd(wb_rd), .wb_reg_write(wb_reg_write), .fwd_a(ex_fwd_a), .fwd_b(ex_fwd_b));

assign ex_src1 = (ex_fwd_a == FWD_MEM) ? mm_result : ((ex_fwd_a == FWD_WB) ? wb_data : ex_rdata1);
assign ex_src2 = (ex_fwd_b == FWD_MEM) ? mm_result : ((ex_fwd_b == FWD_WB) ? wb_data : ex_rdata2);

// ---- Memory stage ----
wire [3:0] mm_be;
wire [31:0] mm_wdata;
wire [31:0] mm_rdata;
wire [31:0] mm_load_value;

store_align u_store_align (.mem_write(mm_mem_write), .mem_size(mm_mem_size), .addr_low(mm_result[1:0]), .rs2(mm_store_src), .be(mm_be), .wdata(mm_wdata));
dmem #(.INIT_FILE(DATA)) u_dmem (.clk(clk), .be(mm_be), .addr(mm_result), .wdata(mm_wdata), .rdata(mm_rdata));
load_align u_load_align (.word(mm_rdata), .addr_low(mm_result[1:0]), .mem_size(mm_mem_size), .load_unsigned(mm_load_unsigned), .value(mm_load_value));

// ---- MEM/WB register: result, load value, rd, reg_write, result_src ----
wire [72:0] mem_wb_q;
wire [31:0] wb_result;
wire [31:0] wb_load_value;
wire [2:0] wb_result_src;

pipe_reg #(.WIDTH(73)) u_mem_wb (.clk(clk), .reset(reset), .en(1'b1), .flush(1'b0),
.d({mm_result, mm_load_value, mm_rd, mm_reg_write, mm_result_src}),
.q(mem_wb_q));

assign {wb_result, wb_load_value, wb_rd, wb_reg_write, wb_result_src} = mem_wb_q;

// ---- Write-back stage ----
assign wb_data = (wb_result_src == RES_MEM) ? wb_load_value : wb_result;

endmodule
