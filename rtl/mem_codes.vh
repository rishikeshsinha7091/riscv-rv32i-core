// mem_size codes: size of a data memory access. They equal funct3[1:0] of the load and store instructions.
// Include inside a module body so every user shares one definition.
localparam MEM_BYTE = 2'd0;
localparam MEM_HALF = 2'd1;
localparam MEM_WORD = 2'd2;
