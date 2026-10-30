`timescale 1ns/1ns

module tb_dmem;

reg clk;
reg [3:0] be;
reg [31:0] addr;
reg [31:0] wdata;
wire [31:0] rdata;

integer checks;
integer errors;

dmem dut (.clk(clk), .be(be), .addr(addr), .wdata(wdata), .rdata(rdata));

always #5 clk = ~clk;

task compare;
input [31:0] expected;
begin
checks = checks + 1;
if (rdata !== expected) begin
errors = errors + 1;
$display("FAIL: addr=%h expected=%h got=%h time=%0d", addr, expected, rdata, $time);
end
end
endtask

task read_check;
input [31:0] a;
input [31:0] expected;
begin
be = 4'b0000;
addr = a;
#1;
compare(expected);
#9;
end
endtask

task write_and_check;
input [31:0] a;
input [31:0] d;
input [31:0] old_value;
begin
be = 4'b1111;
addr = a;
wdata = d;
#4;
compare(old_value);
#2;
compare(d);
#4;
end
endtask

task write_disabled;
input [31:0] a;
input [31:0] d;
begin
be = 4'b0000;
addr = a;
wdata = d;
#10;
end
endtask

task write_bytes;
input [31:0] a;
input [31:0] d;
input [3:0] b;
input [31:0] expected;
begin
be = b;
addr = a;
wdata = d;
#6;
compare(expected);
#4;
end
endtask

initial begin
clk = 0;
$dumpfile("sim/dmem.vcd");
$dumpvars(0, tb_dmem);
checks = 0;
errors = 0;
be = 4'b0000;
addr = 0;
wdata = 0;

// nothing written yet: reads as x
read_check(32'h00000010, 32'hxxxxxxxx);

// write A, then read it back
write_and_check(32'h00000010, 32'hDEADBEEF, 32'hxxxxxxxx);
read_check(32'h00000010, 32'hDEADBEEF);

// write attempt with be = 0000 changes nothing
write_disabled(32'h00000010, 32'h12345678);
read_check(32'h00000010, 32'hDEADBEEF);

// write B, then check A and B are independent
write_and_check(32'h00000014, 32'hCAFEF00D, 32'hxxxxxxxx);
read_check(32'h00000010, 32'hDEADBEEF);
read_check(32'h00000014, 32'hCAFEF00D);

// overwrite A: old value before the edge, new value after
write_and_check(32'h00000010, 32'h0000002A, 32'hDEADBEEF);
read_check(32'h00000014, 32'hCAFEF00D);

// the two low address bits are ignored
read_check(32'h00000011, 32'h0000002A);
read_check(32'h00000012, 32'h0000002A);
read_check(32'h00000013, 32'h0000002A);

// byte lanes: a full-word write first, then change one lane or half at a time
write_and_check(32'h00000020, 32'h11223344, 32'hxxxxxxxx);
write_bytes(32'h00000020, 32'hAAAAAAAA, 4'b0001, 32'h112233AA);
write_bytes(32'h00000020, 32'hBBBBBBBB, 4'b0010, 32'h1122BBAA);
write_bytes(32'h00000020, 32'hCCCCCCCC, 4'b0100, 32'h11CCBBAA);
write_bytes(32'h00000020, 32'hDDDDDDDD, 4'b1000, 32'hDDCCBBAA);

// half-words: the data bytes differ, so a lane that takes the wrong byte shows up
write_bytes(32'h00000020, 32'h56781234, 4'b0011, 32'hDDCC1234);
write_bytes(32'h00000020, 32'h9ABC5555, 4'b1100, 32'h9ABC1234);

// two lanes that are not next to each other, and no lane at all
write_bytes(32'h00000020, 32'hEE0000FF, 4'b1001, 32'hEEBC12FF);
write_bytes(32'h00000020, 32'hFFFFFFFF, 4'b0000, 32'hEEBC12FF);

// the neighbouring words were never written
read_check(32'h00000024, 32'hxxxxxxxx);
read_check(32'h0000001C, 32'hxxxxxxxx);

// a lane write into a word that was never written leaves the other lanes unknown
write_bytes(32'h00000030, 32'h000000A5, 4'b0001, 32'hxxxxxxA5);

if (errors == 0)
$display("PASS: dmem, %0d checks, 0 errors", checks);
else
$display("FAIL: dmem, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
