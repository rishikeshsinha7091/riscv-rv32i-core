module store_align (
input mem_write,
input [1:0] mem_size,
input [1:0] addr_low,
input [31:0] rs2,
output [3:0] be,
output reg [31:0] wdata
);

`include "mem_codes.vh"

reg [3:0] lanes;

always @(*) begin
lanes = 4'b0000;
case (mem_size)
MEM_BYTE: lanes = 4'b0001 << addr_low;
MEM_HALF: lanes = addr_low[1] ? 4'b1100 : 4'b0011;
MEM_WORD: lanes = 4'b1111;
default:  lanes = 4'b0000;
endcase
end

assign be = mem_write ? lanes : 4'b0000;

always @(*) begin
case (mem_size)
MEM_BYTE: wdata = {4{rs2[7:0]}};
MEM_HALF: wdata = {2{rs2[15:0]}};
MEM_WORD: wdata = rs2;
default:  wdata = 32'b0;
endcase
end

endmodule
