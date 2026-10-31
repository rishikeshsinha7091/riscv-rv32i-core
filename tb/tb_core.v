`timescale 1ns/1ns

module tb_core;

reg clk;
reg reset;
integer checks;
integer errors;

core #(.PROGRAM("tests/alu_ops.hex")) u_alu_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/mem_ops.hex")) u_mem_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/branch_ops.hex")) u_branch_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/jal_ops.hex")) u_jal_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/loop_sum.hex")) u_loop_sum (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/unsupported.hex")) u_unsupported (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/alu_full.hex")) u_alu_full (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/upper_jalr.hex")) u_upper_jalr (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/branch_all.hex")) u_branch_all (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/byte_ops.hex")) u_byte_ops (.clk(clk), .reset(reset));
core #(.PROGRAM("tests/checksum.hex")) u_checksum (.clk(clk), .reset(reset));
core #(.PROGRAM("sw/first.hex"), .DATA("sw/first.data.hex")) u_c_first (.clk(clk), .reset(reset));

always #5 clk = ~clk;

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

initial begin
$dumpfile("sim/core.vcd");
$dumpvars(0, tb_core);
clk = 0;
reset = 1;
checks = 0;
errors = 0;

@(negedge clk);
reset = 0;
repeat (100) @(posedge clk);
#1;

// alu_ops: values worked out by hand from tests/alu_ops.asm
check_value("alu_ops x1",  u_alu_ops.u_regfile.regs[1],  32'd12);
check_value("alu_ops x2",  u_alu_ops.u_regfile.regs[2],  32'd10);
check_value("alu_ops x3",  u_alu_ops.u_regfile.regs[3],  32'd22);
check_value("alu_ops x4",  u_alu_ops.u_regfile.regs[4],  32'd2);
check_value("alu_ops x5",  u_alu_ops.u_regfile.regs[5],  32'd8);
check_value("alu_ops x6",  u_alu_ops.u_regfile.regs[6],  32'd14);
check_value("alu_ops x7",  u_alu_ops.u_regfile.regs[7],  32'd0);
check_value("alu_ops x8",  u_alu_ops.u_regfile.regs[8],  32'd1);
check_value("alu_ops x9",  u_alu_ops.u_regfile.regs[9],  32'hFFFFFFFF);
check_value("alu_ops x10", u_alu_ops.u_regfile.regs[10], 32'd1);
check_value("alu_ops x11", u_alu_ops.u_regfile.regs[11], 32'hFFFFFFFE);
check_value("alu_ops x12", u_alu_ops.u_regfile.regs[12], 32'd6);
check_value("alu_ops x13", u_alu_ops.u_regfile.regs[13], 32'd112);
check_value("alu_ops pc",  u_alu_ops.pc,                 32'd52);

// mem_ops: values worked out by hand from tests/mem_ops.asm
check_value("mem_ops x1",  u_mem_ops.u_regfile.regs[1], 32'd123);
check_value("mem_ops x2",  u_mem_ops.u_regfile.regs[2], 32'd256);
check_value("mem_ops x3",  u_mem_ops.u_regfile.regs[3], 32'hFFFFFFFB);
check_value("mem_ops x4",  u_mem_ops.u_regfile.regs[4], 32'd77);
check_value("mem_ops x5",  u_mem_ops.u_regfile.regs[5], 32'hFFFFFFFB);
check_value("mem_ops x6",  u_mem_ops.u_regfile.regs[6], 32'd123);
check_value("mem_ops x7",  u_mem_ops.u_regfile.regs[7], 32'd77);
check_value("mem_ops x8",  u_mem_ops.u_regfile.regs[8], 32'hxxxxxxxx);
check_value("mem_ops x28", u_mem_ops.u_regfile.regs[28], 32'hxxxxxxxx);
check_value("mem_ops mem[63]", u_mem_ops.u_dmem.mem[63], 32'd77);
check_value("mem_ops mem[64]", u_mem_ops.u_dmem.mem[64], 32'd123);
check_value("mem_ops mem[66]", u_mem_ops.u_dmem.mem[66], 32'hFFFFFFFB);
check_value("mem_ops pc",  u_mem_ops.pc, 32'd40);

// branch_ops: values worked out by hand from tests/branch_ops.asm
check_value("branch_ops x1",  u_branch_ops.u_regfile.regs[1],  32'd7);
check_value("branch_ops x2",  u_branch_ops.u_regfile.regs[2],  32'd7);
check_value("branch_ops x3",  u_branch_ops.u_regfile.regs[3],  32'd5);
check_value("branch_ops x10", u_branch_ops.u_regfile.regs[10], 32'hxxxxxxxx);
check_value("branch_ops x11", u_branch_ops.u_regfile.regs[11], 32'd22);
check_value("branch_ops x12", u_branch_ops.u_regfile.regs[12], 32'd33);
check_value("branch_ops x14", u_branch_ops.u_regfile.regs[14], 32'd55);
check_value("branch_ops pc",  u_branch_ops.pc, 32'd48);

// jal_ops: values worked out by hand from tests/jal_ops.asm
check_value("jal_ops x1", u_jal_ops.u_regfile.regs[1], 32'd1);
check_value("jal_ops x2", u_jal_ops.u_regfile.regs[2], 32'd2);
check_value("jal_ops x3", u_jal_ops.u_regfile.regs[3], 32'hxxxxxxxx);
check_value("jal_ops x4", u_jal_ops.u_regfile.regs[4], 32'd4);
check_value("jal_ops x5", u_jal_ops.u_regfile.regs[5], 32'd8);
check_value("jal_ops x6", u_jal_ops.u_regfile.regs[6], 32'd36);
check_value("jal_ops pc", u_jal_ops.pc, 32'd36);

// loop_sum: values worked out by hand from tests/loop_sum.asm
check_value("loop_sum x1", u_loop_sum.u_regfile.regs[1], 32'd0);
check_value("loop_sum x2", u_loop_sum.u_regfile.regs[2], 32'd15);
check_value("loop_sum pc", u_loop_sum.pc, 32'd24);

// unsupported: values worked out by hand from tests/unsupported.asm
check_value("unsupported x1",  u_unsupported.u_regfile.regs[1],  32'd5);
check_value("unsupported x2",  u_unsupported.u_regfile.regs[2],  32'd7);
check_value("unsupported x14", u_unsupported.u_regfile.regs[14], 32'd77);
check_value("unsupported x15", u_unsupported.u_regfile.regs[15], 32'd99);
check_value("unsupported pc",  u_unsupported.pc, 32'd32);

// alu_full: values worked out by hand from tests/alu_full.asm
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
check_value("alu_full pc",  u_alu_full.pc, 32'd88);

// upper_jalr: values worked out by hand from tests/upper_jalr.asm
check_value("upper_jalr x1",  u_upper_jalr.u_regfile.regs[1],  32'h12345000);
check_value("upper_jalr x2",  u_upper_jalr.u_regfile.regs[2],  32'h00001800);
check_value("upper_jalr x3",  u_upper_jalr.u_regfile.regs[3],  32'h12345678);
check_value("upper_jalr x4",  u_upper_jalr.u_regfile.regs[4],  32'h80000000);
check_value("upper_jalr x5",  u_upper_jalr.u_regfile.regs[5],  32'hFFFFF000);
check_value("upper_jalr x6",  u_upper_jalr.u_regfile.regs[6],  32'h0000101C);
check_value("upper_jalr x7",  u_upper_jalr.u_regfile.regs[7],  32'h00000020);
check_value("upper_jalr x8",  u_upper_jalr.u_regfile.regs[8],  32'hFFFFF024);
check_value("upper_jalr x9",  u_upper_jalr.u_regfile.regs[9],  32'h0000002C);
check_value("upper_jalr x10", u_upper_jalr.u_regfile.regs[10], 32'd77);
check_value("upper_jalr x11", u_upper_jalr.u_regfile.regs[11], 32'd5);
check_value("upper_jalr x12", u_upper_jalr.u_regfile.regs[12], 32'h00000030);
check_value("upper_jalr x13", u_upper_jalr.u_regfile.regs[13], 32'h00000038);
check_value("upper_jalr x14", u_upper_jalr.u_regfile.regs[14], 32'hxxxxxxxx);
check_value("upper_jalr x15", u_upper_jalr.u_regfile.regs[15], 32'd7);
check_value("upper_jalr pc",  u_upper_jalr.pc, 32'd64);

// branch_all: 1 = branch taken, 0 = not taken. Values worked out by hand from tests/branch_all.asm
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
check_value("branch_all pc",  u_branch_all.pc, 32'd220);

// byte_ops: loads in registers, stores read back through lw and directly in memory. Values worked out by hand from tests/byte_ops.asm
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
check_value("byte_ops pc",  u_byte_ops.pc, 32'd132);

// checksum: values worked out by hand from tests/checksum.asm. Word 128 is address 0x200, 129 is 0x204, 130 is 0x208
check_value("checksum x1",  u_checksum.u_regfile.regs[1],  32'h00000200);
check_value("checksum x2",  u_checksum.u_regfile.regs[2],  32'd605);
check_value("checksum x6",  u_checksum.u_regfile.regs[6],  32'h00000030);
check_value("checksum x12", u_checksum.u_regfile.regs[12], 32'd438);
check_value("checksum x13", u_checksum.u_regfile.regs[13], 32'h00000048);
check_value("checksum x14", u_checksum.u_regfile.regs[14], 32'h01B60048);
check_value("checksum x15", u_checksum.u_regfile.regs[15], 32'hCAFEF00D);
check_value("checksum x16", u_checksum.u_regfile.regs[16], 32'hCB48F045);
check_value("checksum x17", u_checksum.u_regfile.regs[17], 32'h0000F045);
check_value("checksum x18", u_checksum.u_regfile.regs[18], 32'hFFFFCB48);
check_value("checksum x19", u_checksum.u_regfile.regs[19], 32'hFFFFFFCB);
check_value("checksum x20", u_checksum.u_regfile.regs[20], 32'hFFFFFFCB);
check_value("checksum x21", u_checksum.u_regfile.regs[21], 32'd0);
check_value("checksum x22", u_checksum.u_regfile.regs[22], 32'h00000070);
check_value("checksum x23", u_checksum.u_regfile.regs[23], 32'd0);
check_value("checksum x24", u_checksum.u_regfile.regs[24], 32'd1);
check_value("checksum x25", u_checksum.u_regfile.regs[25], 32'd1);
check_value("checksum mem128", u_checksum.u_dmem.mem[128], 32'hCA37A411);
check_value("checksum mem129", u_checksum.u_dmem.mem[129], 32'hxxxxxxxx);
check_value("checksum mem130", u_checksum.u_dmem.mem[130], 32'hCB48F045);
check_value("checksum pc",  u_checksum.pc, 32'd116);

// c_first: compiled from sw/first.c. 0 + 5 + 7 = 12. Layout from sw/link.ld: count at 0x1000 is dmem word 0, total at 0x1004 is word 1
check_value("c_first x1",   u_c_first.u_regfile.regs[1],  32'h0000002C);
check_value("c_first x2",   u_c_first.u_regfile.regs[2],  32'h00002000);
check_value("c_first x10",  u_c_first.u_regfile.regs[10], 32'd12);
check_value("c_first mem0", u_c_first.u_dmem.mem[0],      32'd5);
check_value("c_first mem1", u_c_first.u_dmem.mem[1],      32'd12);
check_value("c_first pc",   u_c_first.pc,                 32'd44);

if (errors == 0)
$display("PASS: core, %0d checks, 0 errors", checks);
else
$display("FAIL: core, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule

