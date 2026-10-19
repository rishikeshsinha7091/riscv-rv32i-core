module imem (
input [31:0] pc,
output [31:0] instr
);

parameter INIT_FILE = "tests/program.hex";

reg [31:0] mem [0:1023];

initial $readmemh(INIT_FILE, mem);

assign instr = mem[pc[11:2]];

endmodule
