module pc_reg (
input clk,
input reset,
input [31:0] next_pc,
output reg [31:0] pc,
output [31:0] pc_plus4
);

always @(posedge clk) begin
if (reset) pc <= 32'b0;
else pc <= next_pc;
end

assign pc_plus4 = pc + 32'd4;

endmodule