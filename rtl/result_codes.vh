// result_src codes: what the register file receives. This numbering is our own.
// Include inside a module body so every user shares one definition.
localparam RES_ALU    = 3'd0;
localparam RES_MEM    = 3'd1;
localparam RES_PC4    = 3'd2;
localparam RES_IMM    = 3'd3;
localparam RES_TARGET = 3'd4;