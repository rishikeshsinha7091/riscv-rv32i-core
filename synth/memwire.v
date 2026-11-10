// Zero-delay stand-ins for imem and dmem. Used ONLY by the logic-depth runs in run_synth.ps1.
// The memory time is modelled as zero, so a path through the memory is not cut.
// Keep the ports identical to rtl/imem.v and rtl/dmem.v.
module imem #(parameter INIT_FILE = "") (input [31:0] pc, output [31:0] instr);
assign instr = pc;
endmodule

module dmem #(parameter INIT_FILE = "") (input clk, input [3:0] be, input [31:0] addr, input [31:0] wdata, output [31:0] rdata);
assign rdata = addr;
endmodule
