// Black-box stand-ins for imem and dmem. Used ONLY by the area runs in run_synth.ps1.
// Keep the ports identical to rtl/imem.v and rtl/dmem.v.
(* blackbox *)
module imem #(parameter INIT_FILE = "") (input [31:0] pc, output [31:0] instr);
endmodule

(* blackbox *)
module dmem #(parameter INIT_FILE = "") (input clk, input [3:0] be, input [31:0] addr, input [31:0] wdata, output [31:0] rdata);
endmodule
