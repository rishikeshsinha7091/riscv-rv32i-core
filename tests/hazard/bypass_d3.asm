# bypass_d3.asm: the Write-back-to-Decode bypass (d = 3), no stalls, no branches before the spin.
# Fillers between a producer and its reader only read x0, so each reader has exactly the distance named.
lui  x20, 0x2
addi x20, x20, 256
addi x1, x0, 11
addi x2, x0, 1
addi x3, x0, 2
add  x4, x1, x0
addi x5, x0, 22
addi x6, x0, 3
addi x7, x0, 4
add  x8, x0, x5
addi x9, x0, 5
addi x10, x0, 6
addi x11, x0, 7
add  x12, x9, x9
addi x15, x0, 1
addi x15, x0, 2
addi x15, x0, 3
add  x16, x15, x0
addi x0, x1, 7
nop
nop
add  x17, x0, x0
addi x13, x0, 33
nop
nop
sw   x13, 8(x20)
nop
nop
add  x18, x8, x0
lw   x19, 8(x20)
nop
nop
add  x21, x19, x0
lw   x22, 8(x20)
nop
add  x23, x22, x0
addi x24, x0, 40
addi x25, x0, 2
addi x26, x0, 3
add  x27, x24, x26
spin: jal x0, spin
nop
nop
