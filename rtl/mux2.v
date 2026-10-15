// 2:1 multiplexer: y = a when sel = 0, y = b when sel = 1
module mux2 (
input a,
input b,
input sel,
output y
);
assign y = sel ? b : a;
endmodule
