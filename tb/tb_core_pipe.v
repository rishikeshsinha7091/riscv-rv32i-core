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

always #5 clk = ~clk;

// expected values for the 11 words of tb/pipe_stage_test.hex
reg [31:0] t_word [0:10];
reg [31:0] t_r1   [0:10];
reg [31:0] t_r2   [0:10];
reg [31:0] t_imm  [0:10];
reg [4:0]  t_rd   [0:10];
reg [17:0] t_ctrl [0:10];
reg [31:0] t_res  [0:10];

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

// write-back does not exist yet: give x1 to x31 known values, x(k) = k * 0x01010101
for (k = 1; k < 32; k = k + 1) dut.u_regfile.regs[k] = k * 32'h01010101;

// the first rising edge (5 ns) is the reset: everything must be zero (a bubble)
@(posedge clk);
#1;
check(0, "pc", dut.pc, 32'd0);
check_ifid(0, 32'd0, 32'd0, 32'd0);
check_idex(0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 5'd0, 18'd0);
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
end

if (errors == 0)
$display("PASS: core_pipe, %0d checks, 0 errors", checks);
else
$display("FAIL: core_pipe, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
