# hazard_alu.asm: data hazards in the ALU, stores, branches and jalr, with no nops for data hazards.
# Only distances 1 and 2 are used (and far apart reads). No loads. Two nops after every taken branch, jalr and the spin.
addi x1, x0, 5
add  x2, x1, x1
sub  x3, x2, x1
addi x4, x0, 7
addi x5, x0, 9
add  x6, x4, x5
addi x7, x0, 1
addi x7, x0, 2
add  x8, x7, x7
addi x0, x6, 5
add  x9, x0, x0
lui  x10, 0x2
addi x10, x10, 256
addi x11, x0, 77
sw   x11, 0(x10)
addi x12, x0, 88
sw   x12, 4(x10)
addi x13, x0, 99
nop
sw   x13, 8(x10)
lui  x24, 0x12345
add  x25, x24, x24
addi x28, x0, 1000
addi x29, x1, 28
addi x14, x0, 3
beq  x14, x0, after1
nop
nop
addi x15, x0, 1
after1: addi x16, x0, 2
addi x17, x0, 4
bne  x17, x0, after2
nop
nop
addi x18, x0, 111
after2: addi x19, x0, 3
auipc x20, 0
jalr x21, x20, 20
nop
nop
addi x22, x0, 1
landing: addi x23, x0, 2
spin: jal x0, spin
nop
nop
