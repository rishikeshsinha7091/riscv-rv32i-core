# load_use.asm: the load-use stall. 6 stall cycles in total; two load-user pairs that must NOT stall.
# Memory words 64 and 65 (0x2100 and 0x2104) are filled first. Two nops after the taken bne and the spin (flush comes later).
lui  x20, 0x2
addi x20, x20, 256
addi x1, x0, 100
addi x2, x0, 200
sw   x1, 0(x20)
sw   x2, 4(x20)
lw   x3, 0(x20)
add  x4, x3, x3
lw   x5, 4(x20)
sub  x6, x1, x5
lw   x7, 0(x20)
addi x8, x0, 5
add  x9, x7, x8
lw   x10, 4(x20)
addi x11, x1, 10
lw   x12, 0(x20)
sw   x12, 8(x20)
lw   x13, 4(x20)
bne  x13, x0, taken
nop
nop
addi x15, x0, 1
taken: addi x16, x0, 2
addi x17, x20, 8
sw   x17, 12(x20)
lw   x18, 12(x20)
lw   x19, 0(x18)
add  x21, x19, x19
spin: jal x0, spin
nop
nop
