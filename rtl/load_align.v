module load_align (
input [31:0] word,
input [1:0] addr_low,
input [1:0] mem_size,
input load_unsigned,
output reg [31:0] value
);

`include "mem_codes.vh"

reg [7:0] byte_val;
wire [15:0] half_val = addr_low[1] ? word[31:16] : word[15:0];

always @(*) begin
case (addr_low)
2'b00:   byte_val = word[7:0];
2'b01:   byte_val = word[15:8];
2'b10:   byte_val = word[23:16];
2'b11:   byte_val = word[31:24];
default: byte_val = 8'b0;
endcase
end

always @(*) begin
case (mem_size)
MEM_BYTE: value = {{24{byte_val[7] & ~load_unsigned}}, byte_val};
MEM_HALF: value = {{16{half_val[15] & ~load_unsigned}}, half_val};
MEM_WORD: value = word;
default:  value = 32'b0;
endcase
end

endmodule
