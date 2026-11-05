`timescale 1ns/1ns

module tb_core_pipe;

reg clk;
reg reset;
integer checks;
integer errors;
integer e;
integer k;
reg [31:0] exp_pc;
reg [31:0] exp_next;
reg exp_src;

core_pipe #(.PROGRAM("tb/pipe_stage_test.hex"), .DATA("tb/pipe_data_test.hex")) dut (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/alu_full.hex")) u_alu_full (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/mem_ops.hex")) u_mem_ops (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/byte_ops.hex")) u_byte_ops (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/branch_all.hex")) u_branch_all (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/jal_ops.hex")) u_jal_ops (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/loop_sum.hex")) u_loop_sum (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/pipe/upper_jalr.hex")) u_upper_jalr (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/hazard/hazard_alu.hex")) u_hazard_alu (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/hazard/bypass_d3.hex")) u_bypass_d3 (.clk(clk), .reset(reset));
core_pipe #(.PROGRAM("tests/hazard/load_use.hex")) u_load_use (.clk(clk), .reset(reset));

integer lu_stalls;
initial lu_stalls = 0;
always @(posedge clk) if (u_load_use.stall === 1'b1) lu_stalls = lu_stalls + 1;

always #5 clk = ~clk;

// expected values for the 11 words of tb/pipe_stage_test.hex
reg [31:0] t_word [0:10];
reg [31:0] t_r1   [0:10];
reg [31:0] t_r2   [0:10];
reg [31:0] t_imm  [0:10];
reg [4:0]  t_rd   [0:10];
reg [17:0] t_ctrl [0:10];
reg [31:0] t_res  [0:10];
reg [4:0] t_rs1 [0:10];
reg [4:0] t_rs2 [0:10];

task set;
input [31:0] i;
input [31:0] w;
input [31:0] r1;
input [31:0] r2;
input [31:0] imm;
input [4:0] rd;
input [17:0] ctrl;
input [31:0] res;
begin
t_word[i] = w;
t_r1[i] = r1;
t_r2[i] = r2;
t_imm[i] = imm;
t_rd[i] = rd;
t_ctrl[i] = ctrl;
t_res[i] = res;
end
endtask

// ---- done detection: the spin jal in Execute jumps to itself, then wait for the pipeline to drain ----
localparam NP = 10;
localparam DRAIN = 4;
localparam TIMEOUT = 20000;
localparam [NP-1:0] ALL = {NP{1'b1}};

// index 0 = alu_full, 1 = mem_ops, 2 = byte_ops, 3 = branch_all, 4 = jal_ops, 5 = loop_sum, 6 = upper_jalr, 7 = hazard_alu, 8 = bypass_d3, 9 = load_use
wire [NP-1:0] srcs = {u_load_use.ex_pc_src, u_bypass_d3.ex_pc_src, u_hazard_alu.ex_pc_src, u_upper_jalr.ex_pc_src, u_loop_sum.ex_pc_src, u_jal_ops.ex_pc_src, u_branch_all.ex_pc_src, u_byte_ops.ex_pc_src, u_mem_ops.ex_pc_src, u_alu_full.ex_pc_src};
wire [32*NP-1:0] xpcs = {u_load_use.ex_pc, u_bypass_d3.ex_pc, u_hazard_alu.ex_pc, u_upper_jalr.ex_pc, u_loop_sum.ex_pc, u_jal_ops.ex_pc, u_branch_all.ex_pc, u_byte_ops.ex_pc, u_mem_ops.ex_pc, u_alu_full.ex_pc};
wire [32*NP-1:0] nexts = {u_load_use.next_pc, u_bypass_d3.next_pc, u_hazard_alu.next_pc, u_upper_jalr.next_pc, u_loop_sum.next_pc, u_jal_ops.next_pc, u_branch_all.next_pc, u_byte_ops.next_pc, u_mem_ops.next_pc, u_alu_full.next_pc};

integer edges;
integer j;
reg [NP-1:0] found;
reg [NP-1:0] done;
integer found_at [0:NP-1];
integer drain [0:NP-1];
reg [31:0] spin_pc [0:NP-1];

initial begin
edges = -1;
found = 0;
done = 0;
for (j = 0; j < NP; j = j + 1) begin
found_at[j] = 0;
drain[j] = 0;
spin_pc[j] = 32'hxxxxxxxx;
end
end

// the reset edge is edge 0; at edge n the detector sees the state of the cycle that ends at edge n
always @(posedge clk) begin
edges = edges + 1;
for (j = 0; j < NP; j = j + 1) begin
if (!found[j]) begin
if ((srcs[j] === 1'b1) && ((^xpcs[32*j +: 32]) !== 1'bx) && (nexts[32*j +: 32] === xpcs[32*j +: 32])) begin
found[j] = 1'b1;
found_at[j] = edges;
spin_pc[j] = xpcs[32*j +: 32];
end
end
else if (!done[j]) begin
drain[j] = drain[j] + 1;
if (drain[j] >= DRAIN) done[j] = 1'b1;
end
end
end

task check_value;
input [8*16-1:0] name;
input [31:0] actual;
input [31:0] expected;
begin
checks = checks + 1;
if (actual !== expected) begin
errors = errors + 1;
$display("FAIL: %0s got=%h expected=%h", name, actual, expected);
end
end
endtask

task check;
input [31:0] n;
input [8*12-1:0] what;
input [31:0] actual;
input [31:0] expected;
begin
checks = checks + 1;
if (actual !== expected) begin
errors = errors + 1;
$display("FAIL: edge %0d %0s got=%h expected=%h", n, what, actual, expected);
end
end
endtask

task check_ifid;
input [31:0] n;
input [31:0] e_pc;
input [31:0] e_pc4;
input [31:0] e_inst;
begin
check(n, "id_pc", dut.id_pc, e_pc);
check(n, "id_pc_plus4", dut.id_pc_plus4, e_pc4);
check(n, "id_inst", dut.id_inst, e_inst);
end
endtask

task check_idex;
input [31:0] n;
input [31:0] e_pc;
input [31:0] e_pc4;
input [31:0] e_r1;
input [31:0] e_r2;
input [31:0] e_imm;
input [4:0] e_rd;
input [17:0] e_ctrl;
begin
check(n, "ex_pc", dut.ex_pc, e_pc);
check(n, "ex_pc_plus4", dut.ex_pc_plus4, e_pc4);
check(n, "ex_rdata1", dut.ex_rdata1, e_r1);
check(n, "ex_rdata2", dut.ex_rdata2, e_r2);
check(n, "ex_imm", dut.ex_imm, e_imm);
check(n, "ex_rd", dut.ex_rd, e_rd);
check(n, "ex_ctrl", {dut.ex_reg_write, dut.ex_result_src, dut.ex_mem_write, dut.ex_mem_size, dut.ex_load_unsigned, dut.ex_branch, dut.ex_jump, dut.ex_jalr, dut.ex_br_lt, dut.ex_br_inv, dut.ex_alu_src, dut.ex_alu_op}, e_ctrl);
end
endtask

task check_exmem;
input [31:0] n;
input [31:0] e_res;
input [31:0] e_sd;
input [4:0] e_rd;
input [7:0] e_ctrl;
begin
check(n, "mm_result", dut.mm_result, e_res);
check(n, "mm_store_src", dut.mm_store_src, e_sd);
check(n, "mm_rd", dut.mm_rd, e_rd);
check(n, "mm_ctrl", {dut.mm_reg_write, dut.mm_result_src, dut.mm_mem_write, dut.mm_mem_size, dut.mm_load_unsigned}, e_ctrl);
end
endtask

task check_memwb;
input [31:0] n;
input [31:0] e_res;
input [4:0] e_rd;
input [3:0] e_ctrl;
begin
check(n, "wb_result", dut.wb_result, e_res);
check(n, "wb_rd", dut.wb_rd, e_rd);
check(n, "wb_ctrl", {dut.wb_reg_write, dut.wb_result_src}, e_ctrl);
end
endtask

initial begin
$dumpfile("sim/core_pipe.vcd");
$dumpvars(0, tb_core_pipe);
clk = 0;
reset = 1;
checks = 0;
errors = 0;

//  i  word          rdata1        rdata2        imm           rd     control   ex_result
set(0,  32'h00708293, 32'h01010101, 32'h07070707, 32'h00000007, 5'd5,  18'h20010, 32'h01010108);
set(1,  32'h00310333, 32'h02020202, 32'h03030303, 32'h00000003, 5'd6,  18'h20000, 32'h05050505);
set(2,  32'h00C22383, 32'h04040404, 32'h0C0C0C0C, 32'h0000000C, 5'd7,  18'h25010, 32'h04040410);
set(3,  32'h00942823, 32'h08080808, 32'h09090909, 32'h00000010, 5'd16, 18'h03010, 32'h08080818);
set(4,  32'h00B50463, 32'h0A0A0A0A, 32'h0B0B0B0B, 32'h00000008, 5'd8,  18'h00201, 32'hFEFEFEFF);
set(5,  32'h123456B7, 32'h08080808, 32'h03030303, 32'h12345000, 5'd13, 18'h2C000, 32'h12345000);
set(6,  32'h00010717, 32'h02020202, 32'h00000000, 32'h00010000, 5'd14, 18'h30000, 32'h00010018);
set(7,  32'hFFF00793, 32'h00000000, 32'h1F1F1F1F, 32'hFFFFFFFF, 5'd15, 18'h20010, 32'hFFFFFFFF);
set(8,  32'h0108E663, 32'h11111111, 32'h10101010, 32'h0000000C, 5'd12, 18'h00249, 32'h00000000);
set(9,  32'h0140066F, 32'h00000000, 32'h14141414, 32'h00000014, 5'd12, 18'h28100, 32'h00000028);
set(10, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 5'd0,  18'h00000, 32'h00000000);
t_rs1[0] = 5'd1;  t_rs2[0] = 5'd7;
t_rs1[1] = 5'd2;  t_rs2[1] = 5'd3;
t_rs1[2] = 5'd4;  t_rs2[2] = 5'd12;
t_rs1[3] = 5'd8;  t_rs2[3] = 5'd9;
t_rs1[4] = 5'd10; t_rs2[4] = 5'd11;
t_rs1[5] = 5'd8;  t_rs2[5] = 5'd3;
t_rs1[6] = 5'd2;  t_rs2[6] = 5'd0;
t_rs1[7] = 5'd0;  t_rs2[7] = 5'd31;
t_rs1[8] = 5'd17; t_rs2[8] = 5'd16;
t_rs1[9] = 5'd0;  t_rs2[9] = 5'd20;
t_rs1[10] = 5'd0; t_rs2[10] = 5'd0;

// write-back does not exist yet: give x1 to x31 known values, x(k) = k * 0x01010101
for (k = 1; k < 32; k = k + 1) dut.u_regfile.regs[k] = k * 32'h01010101;

// the first rising edge (5 ns) is the reset: everything must be zero (a bubble)
@(posedge clk);
#1;
check(0, "pc", dut.pc, 32'd0);
check_ifid(0, 32'd0, 32'd0, 32'd0);
check_idex(0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 5'd0, 18'd0);
check(0, "ex_rs1", dut.ex_rs1, 5'd0);
check(0, "ex_rs2", dut.ex_rs2, 5'd0);
check_exmem(0, 32'd0, 32'd0, 5'd0, 8'd0);
check_memwb(0, 32'd0, 5'd0, 4'd0);

@(negedge clk);
reset = 0;

// edge e: pc = 4e, IF/ID holds instruction e-1, ID/EX holds instruction e-2
for (e = 1; e <= 12; e = e + 1) begin
@(posedge clk);
#1;
exp_pc = (e == 12) ? 32'd56 : 4*e;
exp_next = (e == 11) ? 32'd56 : ((e == 12) ? 32'd60 : 4*e + 4);
exp_src = (e == 11);
check(e, "pc", dut.pc, exp_pc);
check(e, "next_pc", dut.next_pc, exp_next);
check(e, "ex_pc_src", dut.ex_pc_src, exp_src);
if (e <= 11) check_ifid(e, 4*(e-1), 4*e, t_word[e-1]);
if (e == 1) check_idex(e, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 5'd0, 18'd0);
else check_idex(e, 4*(e-2), 4*(e-1), t_r1[e-2], t_r2[e-2], t_imm[e-2], t_rd[e-2], t_ctrl[e-2]);
if (e == 1) begin
check(e, "ex_rs1", dut.ex_rs1, 5'd0);
check(e, "ex_rs2", dut.ex_rs2, 5'd0);
end else begin
check(e, "ex_rs1", dut.ex_rs1, t_rs1[e-2]);
check(e, "ex_rs2", dut.ex_rs2, t_rs2[e-2]);
end
if (e >= 3) check_exmem(e, t_res[e-3], t_r2[e-3], t_rd[e-3], t_ctrl[e-3] >> 10);
else check_exmem(e, 32'd0, 32'd0, 5'd0, 8'd0);
if (e >= 4) check_memwb(e, t_res[e-4], t_rd[e-4], t_ctrl[e-4] >> 14);
else check_memwb(e, 32'd0, 5'd0, 4'd0);
if (e == 5) check(e, "mm_load_val", dut.mm_load_value, 32'hA1B2C3D4);
if (e == 6) begin
check(e, "mm_be", dut.mm_be, 32'd15);
check(e, "mm_wdata", dut.mm_wdata, 32'h09090909);
check(e, "dmem[518]", dut.u_dmem.mem[518], 32'hxxxxxxxx);
check(e, "wb_load_val", dut.wb_load_value, 32'hA1B2C3D4);
end
if (e == 7) check(e, "dmem[518]", dut.u_dmem.mem[518], 32'h09090909);

// register file: a write lands one edge after its instruction is in MEM/WB, never earlier
if (e == 4) check(e, "x5 early", dut.u_regfile.regs[5], 32'h05050505);
if (e == 5) begin
check(e, "x5", dut.u_regfile.regs[5], 32'h01010108);
check(e, "x6 early", dut.u_regfile.regs[6], 32'h06060606);
end
if (e == 6) begin
check(e, "x6", dut.u_regfile.regs[6], 32'h05050505);
check(e, "x7 early", dut.u_regfile.regs[7], 32'h07070707);
end
if (e == 7) check(e, "x7", dut.u_regfile.regs[7], 32'hA1B2C3D4);
if (e == 8) check(e, "x16 unchg", dut.u_regfile.regs[16], 32'h10101010);
if (e == 9) begin
check(e, "x8 unchg", dut.u_regfile.regs[8], 32'h08080808);
check(e, "x13 early", dut.u_regfile.regs[13], 32'h0D0D0D0D);
end
if (e == 10) begin
check(e, "x13", dut.u_regfile.regs[13], 32'h12345000);
check(e, "x14 early", dut.u_regfile.regs[14], 32'h0E0E0E0E);
end
if (e == 11) begin
check(e, "x14", dut.u_regfile.regs[14], 32'h00010018);
check(e, "x15 early", dut.u_regfile.regs[15], 32'h0F0F0F0F);
end
if (e == 12) check(e, "x15", dut.u_regfile.regs[15], 32'hFFFFFFFF);
end

// two more edges: bltu must not write x12 (its rd field), then the jal writes its link value
@(posedge clk);
#1;
check(13, "x12 unchg", dut.u_regfile.regs[12], 32'h0C0C0C0C);
@(posedge clk);
#1;
check(14, "x12", dut.u_regfile.regs[12], 32'h00000028);

// wait until every program is done (spin found, then drained) or until the timeout; falling edges avoid a race with the detector
while ((done !== ALL) && (edges < TIMEOUT)) @(negedge clk);
#1;

$display("INFO: core_pipe: all programs done after %0d edges", edges);
$display("INFO: alu_full: spin found at edge %0d", found_at[0]);
$display("INFO: mem_ops: spin found at edge %0d", found_at[1]);
$display("INFO: byte_ops: spin found at edge %0d", found_at[2]);
$display("INFO: branch_all: spin found at edge %0d", found_at[3]);
$display("INFO: jal_ops: spin found at edge %0d", found_at[4]);
$display("INFO: loop_sum: spin found at edge %0d", found_at[5]);
$display("INFO: upper_jalr: spin found at edge %0d", found_at[6]);
$display("INFO: hazard_alu: spin found at edge %0d", found_at[7]);
$display("INFO: bypass_d3: spin found at edge %0d", found_at[8]);
$display("INFO: load_use: spin found at edge %0d", found_at[9]);

// alu_full: spin address 96
check_value("alu_full done", done[0], 1);
check_value("alu_full spin", spin_pc[0], 96);
check_value("alu_full edge", found_at[0], 27);
check_value("alu_full x1",  u_alu_full.u_regfile.regs[1],  32'd12);
check_value("alu_full x2",  u_alu_full.u_regfile.regs[2],  32'd10);
check_value("alu_full x3",  u_alu_full.u_regfile.regs[3],  32'hFFFFFFF0);
check_value("alu_full x4",  u_alu_full.u_regfile.regs[4],  32'd3);
check_value("alu_full x5",  u_alu_full.u_regfile.regs[5],  32'd6);
check_value("alu_full x6",  u_alu_full.u_regfile.regs[6],  32'd96);
check_value("alu_full x7",  u_alu_full.u_regfile.regs[7],  32'h1FFFFFFE);
check_value("alu_full x8",  u_alu_full.u_regfile.regs[8],  32'hFFFFFFFE);
check_value("alu_full x9",  u_alu_full.u_regfile.regs[9],  32'd0);
check_value("alu_full x10", u_alu_full.u_regfile.regs[10], 32'd1);
check_value("alu_full x11", u_alu_full.u_regfile.regs[11], 32'hFFFFFFF3);
check_value("alu_full x12", u_alu_full.u_regfile.regs[12], 32'd1034);
check_value("alu_full x13", u_alu_full.u_regfile.regs[13], 32'd1264);
check_value("alu_full x14", u_alu_full.u_regfile.regs[14], 32'd0);
check_value("alu_full x15", u_alu_full.u_regfile.regs[15], 32'd1);
check_value("alu_full x16", u_alu_full.u_regfile.regs[16], 32'd1);
check_value("alu_full x17", u_alu_full.u_regfile.regs[17], 32'd0);
check_value("alu_full x18", u_alu_full.u_regfile.regs[18], 32'd192);
check_value("alu_full x19", u_alu_full.u_regfile.regs[19], 32'h0FFFFFFF);
check_value("alu_full x20", u_alu_full.u_regfile.regs[20], 32'hFFFFFFFF);
check_value("alu_full x21", u_alu_full.u_regfile.regs[21], 32'd1);
check_value("alu_full x22", u_alu_full.u_regfile.regs[22], 32'h80000000);

// mem_ops: spin address 44; x8 and x28 are the rd fields of two stores and must stay unwritten
check_value("mem_ops done", done[1], 1);
check_value("mem_ops spin", spin_pc[1], 44);
check_value("mem_ops edge", found_at[1], 14);
check_value("mem_ops x1",  u_mem_ops.u_regfile.regs[1], 32'd123);
check_value("mem_ops x2",  u_mem_ops.u_regfile.regs[2], 32'd256);
check_value("mem_ops x3",  u_mem_ops.u_regfile.regs[3], 32'hFFFFFFFB);
check_value("mem_ops x4",  u_mem_ops.u_regfile.regs[4], 32'd77);
check_value("mem_ops x5",  u_mem_ops.u_regfile.regs[5], 32'hFFFFFFFB);
check_value("mem_ops x6",  u_mem_ops.u_regfile.regs[6], 32'd123);
check_value("mem_ops x7",  u_mem_ops.u_regfile.regs[7], 32'd77);
check_value("mem_ops x8",  u_mem_ops.u_regfile.regs[8], 32'hxxxxxxxx);
check_value("mem_ops x28", u_mem_ops.u_regfile.regs[28], 32'hxxxxxxxx);
check_value("mem_ops mem63", u_mem_ops.u_dmem.mem[63], 32'd77);
check_value("mem_ops mem64", u_mem_ops.u_dmem.mem[64], 32'd123);
check_value("mem_ops mem66", u_mem_ops.u_dmem.mem[66], 32'hFFFFFFFB);

// byte_ops: spin address 188
check_value("byte_ops done", done[2], 1);
check_value("byte_ops spin", spin_pc[2], 188);
check_value("byte_ops edge", found_at[2], 50);
check_value("byte_ops x3",  u_byte_ops.u_regfile.regs[3],  32'h00000001);
check_value("byte_ops x4",  u_byte_ops.u_regfile.regs[4],  32'h0000007F);
check_value("byte_ops x5",  u_byte_ops.u_regfile.regs[5],  32'hFFFFFFFF);
check_value("byte_ops x6",  u_byte_ops.u_regfile.regs[6],  32'hFFFFFF80);
check_value("byte_ops x7",  u_byte_ops.u_regfile.regs[7],  32'h000000FF);
check_value("byte_ops x8",  u_byte_ops.u_regfile.regs[8],  32'h00000080);
check_value("byte_ops x9",  u_byte_ops.u_regfile.regs[9],  32'h00007F01);
check_value("byte_ops x10", u_byte_ops.u_regfile.regs[10], 32'hFFFF80FF);
check_value("byte_ops x11", u_byte_ops.u_regfile.regs[11], 32'h000080FF);
check_value("byte_ops x12", u_byte_ops.u_regfile.regs[12], 32'h80FF7F01);
check_value("byte_ops x18", u_byte_ops.u_regfile.regs[18], 32'h1122AA44);
check_value("byte_ops x19", u_byte_ops.u_regfile.regs[19], 32'hDDCCAABB);
check_value("byte_ops x21", u_byte_ops.u_regfile.regs[21], 32'hDDCC0123);
check_value("byte_ops x23", u_byte_ops.u_regfile.regs[23], 32'h04560123);
check_value("byte_ops mem64", u_byte_ops.u_dmem.mem[64], 32'h80FF7F01);
check_value("byte_ops mem65", u_byte_ops.u_dmem.mem[65], 32'h04560123);
check_value("byte_ops mem66", u_byte_ops.u_dmem.mem[66], 32'hxxxxxxxx);

// branch_all: spin address 360; result is 1 where the branch was taken
check_value("branch_all done", done[3], 1);
check_value("branch_all spin", spin_pc[3], 360);
check_value("branch_all edge", found_at[3], 84);
check_value("branch_all x8",  u_branch_all.u_regfile.regs[8],  32'd0);
check_value("branch_all x9",  u_branch_all.u_regfile.regs[9],  32'd1);
check_value("branch_all x10", u_branch_all.u_regfile.regs[10], 32'd1);
check_value("branch_all x11", u_branch_all.u_regfile.regs[11], 32'd0);
check_value("branch_all x12", u_branch_all.u_regfile.regs[12], 32'd0);
check_value("branch_all x13", u_branch_all.u_regfile.regs[13], 32'd1);
check_value("branch_all x14", u_branch_all.u_regfile.regs[14], 32'd0);
check_value("branch_all x15", u_branch_all.u_regfile.regs[15], 32'd1);
check_value("branch_all x16", u_branch_all.u_regfile.regs[16], 32'd0);
check_value("branch_all x17", u_branch_all.u_regfile.regs[17], 32'd1);
check_value("branch_all x18", u_branch_all.u_regfile.regs[18], 32'd0);
check_value("branch_all x19", u_branch_all.u_regfile.regs[19], 32'd1);
check_value("branch_all x20", u_branch_all.u_regfile.regs[20], 32'd1);
check_value("branch_all x21", u_branch_all.u_regfile.regs[21], 32'd1);
check_value("branch_all x22", u_branch_all.u_regfile.regs[22], 32'd0);
check_value("branch_all x23", u_branch_all.u_regfile.regs[23], 32'd1);

// jal_ops: spin address 68; x3 is skipped and must stay unwritten
check_value("jal_ops done", done[4], 1);
check_value("jal_ops spin", spin_pc[4], 68);
check_value("jal_ops edge", found_at[4], 18);
check_value("jal_ops x1", u_jal_ops.u_regfile.regs[1], 32'd1);
check_value("jal_ops x2", u_jal_ops.u_regfile.regs[2], 32'd2);
check_value("jal_ops x3", u_jal_ops.u_regfile.regs[3], 32'hxxxxxxxx);
check_value("jal_ops x4", u_jal_ops.u_regfile.regs[4], 32'd4);
check_value("jal_ops x5", u_jal_ops.u_regfile.regs[5], 32'd8);
check_value("jal_ops x6", u_jal_ops.u_regfile.regs[6], 32'd60);

// loop_sum: spin address 48
check_value("loop_sum done", done[5], 1);
check_value("loop_sum spin", spin_pc[5], 48);
check_value("loop_sum edge", found_at[5], 50);
check_value("loop_sum x1", u_loop_sum.u_regfile.regs[1], 32'd0);
check_value("loop_sum x2", u_loop_sum.u_regfile.regs[2], 32'd15);

// upper_jalr: spin address 116; x14 is skipped by the jalr and must stay unwritten
check_value("upper_jalr done", done[6], 1);
check_value("upper_jalr spin", spin_pc[6], 116);
check_value("upper_jalr edge", found_at[6], 37);
check_value("upper_jalr x1",  u_upper_jalr.u_regfile.regs[1],  32'h12345000);
check_value("upper_jalr x2",  u_upper_jalr.u_regfile.regs[2],  32'h00001800);
check_value("upper_jalr x3",  u_upper_jalr.u_regfile.regs[3],  32'h12345678);
check_value("upper_jalr x4",  u_upper_jalr.u_regfile.regs[4],  32'h80000000);
check_value("upper_jalr x5",  u_upper_jalr.u_regfile.regs[5],  32'hFFFFF000);
check_value("upper_jalr x6",  u_upper_jalr.u_regfile.regs[6],  32'h00001034);
check_value("upper_jalr x7",  u_upper_jalr.u_regfile.regs[7],  32'h00000038);
check_value("upper_jalr x8",  u_upper_jalr.u_regfile.regs[8],  32'hFFFFF03C);
check_value("upper_jalr x9",  u_upper_jalr.u_regfile.regs[9],  32'h00000044);
check_value("upper_jalr x10", u_upper_jalr.u_regfile.regs[10], 32'd77);
check_value("upper_jalr x11", u_upper_jalr.u_regfile.regs[11], 32'd5);
check_value("upper_jalr x12", u_upper_jalr.u_regfile.regs[12], 32'h00000050);
check_value("upper_jalr x13", u_upper_jalr.u_regfile.regs[13], 32'h00000064);
check_value("upper_jalr x14", u_upper_jalr.u_regfile.regs[14], 32'hxxxxxxxx);
check_value("upper_jalr x15", u_upper_jalr.u_regfile.regs[15], 32'd7);

// hazard_alu: spin address 168; x18 and x22 are skipped by a taken bne and by the jalr and must stay unwritten
check_value("hazard_alu done", done[7], 1);
check_value("hazard_alu spin", spin_pc[7], 168);
check_value("hazard_alu edge", found_at[7], 43);
check_value("hazard_alu x1",  u_hazard_alu.u_regfile.regs[1],  32'd5);
check_value("hazard_alu x2",  u_hazard_alu.u_regfile.regs[2],  32'd10);
check_value("hazard_alu x3",  u_hazard_alu.u_regfile.regs[3],  32'd5);
check_value("hazard_alu x4",  u_hazard_alu.u_regfile.regs[4],  32'd7);
check_value("hazard_alu x5",  u_hazard_alu.u_regfile.regs[5],  32'd9);
check_value("hazard_alu x6",  u_hazard_alu.u_regfile.regs[6],  32'd16);
check_value("hazard_alu x7",  u_hazard_alu.u_regfile.regs[7],  32'd2);
check_value("hazard_alu x8",  u_hazard_alu.u_regfile.regs[8],  32'd4);
check_value("hazard_alu x9",  u_hazard_alu.u_regfile.regs[9],  32'd0);
check_value("hazard_alu x10", u_hazard_alu.u_regfile.regs[10], 32'h00002100);
check_value("hazard_alu x11", u_hazard_alu.u_regfile.regs[11], 32'd77);
check_value("hazard_alu x12", u_hazard_alu.u_regfile.regs[12], 32'd88);
check_value("hazard_alu x13", u_hazard_alu.u_regfile.regs[13], 32'd99);
check_value("hazard_alu x14", u_hazard_alu.u_regfile.regs[14], 32'd3);
check_value("hazard_alu x15", u_hazard_alu.u_regfile.regs[15], 32'd1);
check_value("hazard_alu x16", u_hazard_alu.u_regfile.regs[16], 32'd2);
check_value("hazard_alu x17", u_hazard_alu.u_regfile.regs[17], 32'd4);
check_value("hazard_alu x18", u_hazard_alu.u_regfile.regs[18], 32'hxxxxxxxx);
check_value("hazard_alu x19", u_hazard_alu.u_regfile.regs[19], 32'd3);
check_value("hazard_alu x20", u_hazard_alu.u_regfile.regs[20], 32'd144);
check_value("hazard_alu x21", u_hazard_alu.u_regfile.regs[21], 32'd152);
check_value("hazard_alu x22", u_hazard_alu.u_regfile.regs[22], 32'hxxxxxxxx);
check_value("hazard_alu x23", u_hazard_alu.u_regfile.regs[23], 32'd2);
check_value("hazard_alu x24", u_hazard_alu.u_regfile.regs[24], 32'h12345000);
check_value("hazard_alu x25", u_hazard_alu.u_regfile.regs[25], 32'h2468A000);
check_value("hazard_alu x28", u_hazard_alu.u_regfile.regs[28], 32'd1000);
check_value("hazard_alu x29", u_hazard_alu.u_regfile.regs[29], 32'd33);
check_value("hazard_alu mem64", u_hazard_alu.u_dmem.mem[64], 32'd77);
check_value("hazard_alu mem65", u_hazard_alu.u_dmem.mem[65], 32'd88);
check_value("hazard_alu mem66", u_hazard_alu.u_dmem.mem[66], 32'd99);

// bypass_d3: spin address 160
check_value("bypass_d3 done", done[8], 1);
check_value("bypass_d3 spin", spin_pc[8], 160);
check_value("bypass_d3 edge", found_at[8], 43);
check_value("bypass_d3 x1",  u_bypass_d3.u_regfile.regs[1],  32'd11);
check_value("bypass_d3 x4",  u_bypass_d3.u_regfile.regs[4],  32'd11);
check_value("bypass_d3 x5",  u_bypass_d3.u_regfile.regs[5],  32'd22);
check_value("bypass_d3 x8",  u_bypass_d3.u_regfile.regs[8],  32'd22);
check_value("bypass_d3 x9",  u_bypass_d3.u_regfile.regs[9],  32'd5);
check_value("bypass_d3 x12", u_bypass_d3.u_regfile.regs[12], 32'd10);
check_value("bypass_d3 x13", u_bypass_d3.u_regfile.regs[13], 32'd33);
check_value("bypass_d3 x15", u_bypass_d3.u_regfile.regs[15], 32'd3);
check_value("bypass_d3 x16", u_bypass_d3.u_regfile.regs[16], 32'd3);
check_value("bypass_d3 x17", u_bypass_d3.u_regfile.regs[17], 32'd0);
check_value("bypass_d3 x18", u_bypass_d3.u_regfile.regs[18], 32'd22);
check_value("bypass_d3 x19", u_bypass_d3.u_regfile.regs[19], 32'd33);
check_value("bypass_d3 x20", u_bypass_d3.u_regfile.regs[20], 32'h00002100);
check_value("bypass_d3 x21", u_bypass_d3.u_regfile.regs[21], 32'd33);
check_value("bypass_d3 x22", u_bypass_d3.u_regfile.regs[22], 32'd33);
check_value("bypass_d3 x23", u_bypass_d3.u_regfile.regs[23], 32'd33);
check_value("bypass_d3 x24", u_bypass_d3.u_regfile.regs[24], 32'd40);
check_value("bypass_d3 x27", u_bypass_d3.u_regfile.regs[27], 32'd43);
check_value("bypass_d3 mem66", u_bypass_d3.u_dmem.mem[66], 32'd33);

// load_use: spin address 112; 6 stall cycles; x15 is skipped by the taken bne and must stay unwritten
check_value("load_use done", done[9], 1);
check_value("load_use spin", spin_pc[9], 112);
check_value("load_use edge", found_at[9], 36);
check_value("load_use stalls", lu_stalls, 6);
check_value("load_use x1",  u_load_use.u_regfile.regs[1],  32'd100);
check_value("load_use x2",  u_load_use.u_regfile.regs[2],  32'd200);
check_value("load_use x3",  u_load_use.u_regfile.regs[3],  32'd100);
check_value("load_use x4",  u_load_use.u_regfile.regs[4],  32'd200);
check_value("load_use x5",  u_load_use.u_regfile.regs[5],  32'd200);
check_value("load_use x6",  u_load_use.u_regfile.regs[6],  32'hFFFFFF9C);
check_value("load_use x7",  u_load_use.u_regfile.regs[7],  32'd100);
check_value("load_use x8",  u_load_use.u_regfile.regs[8],  32'd5);
check_value("load_use x9",  u_load_use.u_regfile.regs[9],  32'd105);
check_value("load_use x10", u_load_use.u_regfile.regs[10], 32'd200);
check_value("load_use x11", u_load_use.u_regfile.regs[11], 32'd110);
check_value("load_use x12", u_load_use.u_regfile.regs[12], 32'd100);
check_value("load_use x13", u_load_use.u_regfile.regs[13], 32'd200);
check_value("load_use x15", u_load_use.u_regfile.regs[15], 32'hxxxxxxxx);
check_value("load_use x16", u_load_use.u_regfile.regs[16], 32'd2);
check_value("load_use x17", u_load_use.u_regfile.regs[17], 32'h00002108);
check_value("load_use x18", u_load_use.u_regfile.regs[18], 32'h00002108);
check_value("load_use x19", u_load_use.u_regfile.regs[19], 32'd100);
check_value("load_use x20", u_load_use.u_regfile.regs[20], 32'h00002100);
check_value("load_use x21", u_load_use.u_regfile.regs[21], 32'd200);
check_value("load_use mem64", u_load_use.u_dmem.mem[64], 32'd100);
check_value("load_use mem65", u_load_use.u_dmem.mem[65], 32'd200);
check_value("load_use mem66", u_load_use.u_dmem.mem[66], 32'd100);
check_value("load_use mem67", u_load_use.u_dmem.mem[67], 32'h00002108);

if (errors == 0)
$display("PASS: core_pipe, %0d checks, 0 errors", checks);
else
$display("FAIL: core_pipe, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
