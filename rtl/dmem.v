module dmem (
input clk,
input we,
input [31:0] addr,
input [31:0] wdata,
output [31:0] rdata
);

reg [31:0] mem [0:1023];

assign rdata = mem[addr[11:2]];

always @(posedge clk) begin
if (we)
mem[addr[11:2]] <= wdata;
end

endmodule
