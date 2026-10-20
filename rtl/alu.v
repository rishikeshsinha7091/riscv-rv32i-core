module alu (
input [31:0] a,
input [31:0] b,
input [3:0] alu_op,
output reg [31:0] y,
output zero
);

`include "alu_codes.vh"

always @(*) begin
case (alu_op)
ALU_ADD:  y = a + b;
ALU_SUB:  y = a - b;
ALU_AND:  y = a & b;
ALU_OR:   y = a | b;
ALU_XOR:  y = a ^ b;
ALU_SLL:  y = a << b[4:0];
ALU_SRL:  y = a >> b[4:0];
ALU_SRA:  y = $signed(a) >>> b[4:0];
ALU_SLT:  y = {31'b0, $signed(a) < $signed(b)};
ALU_SLTU: y = {31'b0, a < b};
default:  y = 32'b0;
endcase
end

assign zero = (y == 32'b0);

endmodule

