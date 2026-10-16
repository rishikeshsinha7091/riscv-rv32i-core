`timescale 1ns/1ps
module tb_dff_sync_reset;
reg clk, reset, d;
wire q;
integer errors;

dff_sync_reset dut (.clk(clk), .reset(reset), .d(d), .q(q));

initial clk = 0;
always #5 clk = ~clk;

task step(input t_reset, input t_d, input t_exp_q);
begin
@(negedge clk);
reset = t_reset;
d = t_d;
@(posedge clk);
#1;
if (q !== t_exp_q) begin
$display("FAIL: reset=%b d=%b q=%b expected %b", reset, d, q, t_exp_q);
errors = errors + 1;
end
end
endtask

initial begin
$dumpfile("sim/dff_sync_reset.vcd");
$dumpvars(0, tb_dff_sync_reset);
errors = 0;
reset = 1;
d = 0;
#1;

step(1, 0, 0);
step(0, 1, 1);
step(0, 0, 0);
step(0, 1, 1);
step(1, 1, 0);
step(0, 1, 1);

@(negedge clk);
reset = 1;
#1;
if (q !== 1'b1) begin
$display("FAIL: q changed before the clock edge");
errors = errors + 1;
end
@(posedge clk);
#1;
if (q !== 1'b0) begin
$display("FAIL: q not cleared at the clock edge");
errors = errors + 1;
end

if (errors == 0)
$display("PASS: dff_sync_reset, all checks correct");
else
$display("FAIL: dff_sync_reset, %0d errors", errors);
$finish;
end
endmodule