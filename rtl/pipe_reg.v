module pipe_reg #(
parameter WIDTH = 32
) (
input clk,
input reset,
input en,
input flush,
input [WIDTH-1:0] d,
output reg [WIDTH-1:0] q
);

always @(posedge clk) begin
if (reset || flush) q <= {WIDTH{1'b0}};
else if (en) q <= d;
end

endmodule
