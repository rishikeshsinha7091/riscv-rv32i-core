module dmem (
input clk,
input [3:0] be,
input [31:0] addr,
input [31:0] wdata,
output [31:0] rdata
);

parameter INIT_FILE = "";

reg [31:0] mem [0:1023];

initial begin
if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
end

assign rdata = mem[addr[11:2]];

always @(posedge clk) begin
if (be[0]) mem[addr[11:2]][7:0]   <= wdata[7:0];
if (be[1]) mem[addr[11:2]][15:8]  <= wdata[15:8];
if (be[2]) mem[addr[11:2]][23:16] <= wdata[23:16];
if (be[3]) mem[addr[11:2]][31:24] <= wdata[31:24];
end

endmodule
