`timescale 1ns/1ps
module tb_mux2;
reg a, b, sel;
wire y;
integer errors;

mux2 dut (.a(a), .b(b), .sel(sel), .y(y));

task apply_and_check(input t_a, input t_b, input t_sel, input t_exp);
begin
a = t_a;
b = t_b;
sel = t_sel;
#10;
if (y !== t_exp) begin
$display("FAIL: a=%b b=%b sel=%b y=%b expected %b", a, b, sel, y, t_exp);
errors = errors + 1;
end
end
endtask

initial begin
$dumpfile("sim/mux2.vcd");
$dumpvars(0, tb_mux2);
errors = 0;
apply_and_check(0, 0, 0, 0);
apply_and_check(0, 0, 1, 0);
apply_and_check(0, 1, 0, 0);
apply_and_check(0, 1, 1, 1);
apply_and_check(1, 0, 0, 1);
apply_and_check(1, 0, 1, 0);
apply_and_check(1, 1, 0, 1);
apply_and_check(1, 1, 1, 1);
if (errors == 0)
$display("PASS: mux2, all 8 cases correct");
else
$display("FAIL: mux2, %0d errors", errors);
$finish;
end
endmodule