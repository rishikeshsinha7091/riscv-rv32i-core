module fwd_unit (
input [4:0] ex_rs1,
input [4:0] ex_rs2,
input [4:0] mm_rd,
input mm_reg_write,
input [4:0] wb_rd,
input wb_reg_write,
output [1:0] fwd_a,
output [1:0] fwd_b
);

`include "fwd_codes.vh"

wire mm_writes;
wire wb_writes;
wire mm_hit_a;
wire mm_hit_b;
wire wb_hit_a;
wire wb_hit_b;

assign mm_writes = mm_reg_write && (mm_rd != 5'd0);
assign wb_writes = wb_reg_write && (wb_rd != 5'd0);

assign mm_hit_a = mm_writes && (mm_rd == ex_rs1);
assign mm_hit_b = mm_writes && (mm_rd == ex_rs2);
assign wb_hit_a = wb_writes && (wb_rd == ex_rs1);
assign wb_hit_b = wb_writes && (wb_rd == ex_rs2);

assign fwd_a = mm_hit_a ? FWD_MEM : (wb_hit_a ? FWD_WB : FWD_REG);
assign fwd_b = mm_hit_b ? FWD_MEM : (wb_hit_b ? FWD_WB : FWD_REG);

endmodule
