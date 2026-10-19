module immgen (
input [31:0] inst,
input [2:0] imm_sel,
output reg [31:0] imm
);

localparam SEL_I = 3'd0;
localparam SEL_S = 3'd1;
localparam SEL_B = 3'd2;
localparam SEL_U = 3'd3;
localparam SEL_J = 3'd4;

always @(*) begin
case (imm_sel)
SEL_I: imm = { {20{inst[31]}}, inst[31:20] };
SEL_S: imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };
SEL_B: imm = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
SEL_U: imm = { inst[31:12], 12'b0 };
SEL_J: imm = { {11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };
default: imm = 32'd0;
endcase
end

endmodule