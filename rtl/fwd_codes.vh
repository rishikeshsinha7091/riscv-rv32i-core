// forwarding select codes: where an Execute-stage operand comes from. This numbering is our own.
// FWD_REG: the value read in Decode (carried in ID/EX). FWD_MEM: the EX/MEM result. FWD_WB: the MEM/WB data.
// Include inside a module body so every user shares one definition.
localparam FWD_REG = 2'd0;
localparam FWD_MEM = 2'd1;
localparam FWD_WB  = 2'd2;
