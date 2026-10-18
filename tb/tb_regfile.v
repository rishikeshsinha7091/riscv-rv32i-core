`timescale 1ns/1ns

module tb_regfile;

reg clk;
reg we;
reg [4:0] waddr;
reg [31:0] wdata;
reg [4:0] raddr1;
reg [4:0] raddr2;
wire [31:0] rdata1;
wire [31:0] rdata2;

integer errors;
integer tests;
integer i;

regfile dut (
.clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
.raddr1(raddr1), .raddr2(raddr2),
.rdata1(rdata1), .rdata2(rdata2)
);

always #5 clk = ~clk;

function [31:0] pattern;
input [31:0] n;
begin
pattern = 32'hA500_0000 + n;
end
endfunction

task write_reg;
input [4:0] addr;
input [31:0] data;
begin
@(negedge clk);
we = 1;
waddr = addr;
wdata = data;
@(posedge clk);
#1;
end
endtask

task write_disabled;
input [4:0] addr;
input [31:0] data;
begin
@(negedge clk);
we = 0;
waddr = addr;
wdata = data;
@(posedge clk);
#1;
end
endtask

task check_read;
input [4:0] ra1;
input [4:0] ra2;
input [31:0] exp1;
input [31:0] exp2;
begin
@(negedge clk);
we = 0;
raddr1 = ra1;
raddr2 = ra2;
#1;
tests = tests + 1;
if (rdata1 !== exp1 || rdata2 !== exp2) begin
errors = errors + 1;
$display("FAIL: read x%0d,x%0d: rdata1=%h (expected %h) rdata2=%h (expected %h)", ra1, ra2, rdata1, exp1, rdata2, exp2);
end
end
endtask

task write_check;
input [4:0] addr;
input [31:0] data;
input [31:0] exp_old;
begin
@(negedge clk);
we = 1;
waddr = addr;
wdata = data;
raddr1 = addr;
#1;
tests = tests + 1;
if (rdata1 !== exp_old) begin
errors = errors + 1;
$display("FAIL: x%0d before the clock edge: rdata1=%h (expected old value %h)", addr, rdata1, exp_old);
end
@(posedge clk);
#1;
tests = tests + 1;
if (rdata1 !== data) begin
errors = errors + 1;
$display("FAIL: x%0d after the clock edge: rdata1=%h (expected new value %h)", addr, rdata1, data);
end
end
endtask

initial begin
clk = 0;
$dumpfile("sim/regfile.vcd");
$dumpvars(0, tb_regfile);
errors = 0;
tests = 0;
we = 0;
waddr = 5'd0;
wdata = 32'd0;
raddr1 = 5'd0;
raddr2 = 5'd0;

// 1. x0 reads 0 before anything has been written
check_read(5'd0, 5'd0, 32'd0, 32'd0);

// 2. write x1..x31, each with a different value
for (i = 1; i < 32; i = i + 1)
write_reg(i, pattern(i));

// 3. read every register back; the two ports read different registers
for (i = 1; i < 32; i = i + 1)
check_read(i, 32 - i, pattern(i), pattern(32 - i));

// 4. a write must not disturb the neighbours
write_reg(5'd5, 32'hDEAD_BEEF);
check_read(5'd4, 5'd6, pattern(4), pattern(6));
check_read(5'd5, 5'd5, 32'hDEAD_BEEF, 32'hDEAD_BEEF);

// 5. with we = 0 nothing is written
write_disabled(5'd7, 32'h1234_5678);
check_read(5'd7, 5'd7, pattern(7), pattern(7));

// 6. x0 ignores writes and still reads 0
write_reg(5'd0, 32'hFFFF_FFFF);
check_read(5'd0, 5'd0, 32'd0, 32'd0);

// 7. a read in the same cycle as a write sees the old value until the clock edge
write_check(5'd9, 32'h0BAD_F00D, pattern(9));

if (errors == 0) $display("PASS: tb_regfile - all %0d checks passed", tests);
else $display("FAIL: tb_regfile - %0d of %0d checks failed", errors, tests);
$finish;
end

endmodule