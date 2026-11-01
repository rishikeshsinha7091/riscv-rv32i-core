`timescale 1ns/1ns

module tb_pipe_reg;

localparam W = 40;
localparam [W-1:0] ZERO  = 40'h0000000000;
localparam [W-1:0] VAL_A = 40'h123456789A;
localparam [W-1:0] VAL_B = 40'hFEDCBA9876;
localparam [W-1:0] VAL_C = 40'hA55A5A5AA5;
localparam [W-1:0] VAL_D = 40'h8000000001;

reg clk;
reg reset;
reg en;
reg flush;
reg [W-1:0] d;
wire [W-1:0] q;
reg [W-1:0] prev;
integer checks;
integer errors;

pipe_reg #(.WIDTH(W)) dut (.clk(clk), .reset(reset), .en(en), .flush(flush), .d(d), .q(q));

always #5 clk = ~clk;

task check;
input [31:0] step_no;
input [8*12-1:0] when;
input [W-1:0] actual;
input [W-1:0] expected;
begin
checks = checks + 1;
if (actual !== expected) begin
errors = errors + 1;
$display("FAIL: step %0d %0s got=%h expected=%h", step_no, when, actual, expected);
end
end
endtask

task step;
input [31:0] n;
input r;
input e;
input f;
input [W-1:0] data;
input [W-1:0] expected;
begin
@(negedge clk);
reset = r;
en = e;
flush = f;
d = data;
#1;
check(n, "before-edge", q, prev);
@(posedge clk);
#1;
check(n, "after-edge", q, expected);
prev = expected;
end
endtask

initial begin
$dumpfile("sim/pipe_reg.vcd");
$dumpvars(0, tb_pipe_reg);
clk = 0;
reset = 1;
en = 0;
flush = 0;
d = ZERO;
checks = 0;
errors = 0;

// before the first clock edge nothing has been stored: q is unknown
#2;
check(0, "power-up", q, {W{1'bx}});

// the first rising edge (5 ns) is a reset
#4;
check(0, "first reset", q, ZERO);
prev = ZERO;

//   n  reset en flush data   expected
step(1,  1, 1, 0, VAL_A, ZERO);
step(2,  0, 1, 0, VAL_A, VAL_A);
step(3,  0, 1, 0, VAL_B, VAL_B);
step(4,  0, 0, 0, VAL_C, VAL_B);
step(5,  0, 0, 0, VAL_D, VAL_B);
step(6,  0, 1, 0, VAL_C, VAL_C);
step(7,  0, 1, 0, VAL_D, VAL_D);
step(8,  0, 0, 1, VAL_A, ZERO);
step(9,  0, 1, 0, VAL_B, VAL_B);
step(10, 0, 1, 1, VAL_C, ZERO);
step(11, 0, 1, 0, VAL_A, VAL_A);
step(12, 1, 0, 0, VAL_B, ZERO);
step(13, 0, 1, 0, VAL_D, VAL_D);
step(14, 1, 1, 1, VAL_C, ZERO);

if (errors == 0)
$display("PASS: pipe_reg, %0d checks, 0 errors", checks);
else
$display("FAIL: pipe_reg, %0d errors in %0d checks", errors, checks);
$finish;
end

endmodule
