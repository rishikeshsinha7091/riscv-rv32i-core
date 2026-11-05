# flush_ctl.asm: control hazards with wrong-path poison. No nops after any branch, jump or the spin.
# After each taken branch or jump the next two instructions are harmful; they must never take effect.
lui  x20, 0x2
addi x20, x20, 256
addi x2, x0, 55
addi x3, x0, 99
sw   x2, 0(x20)
addi x1, x0, 1
bne  x1, x0, tgt_bne
addi x9, x0, 77
sw   x3, 4(x20)
addi x10, x0, 88
tgt_bne: addi x4, x0, 4
beq  x4, x0, tgt_beq
addi x5, x0, 5
addi x6, x0, 6
tgt_beq: jal x7, tgt_jal
addi x11, x0, 66
sw   x3, 8(x20)
addi x12, x0, 33
tgt_jal: auipc x13, 0
jalr x14, x13, 20
addi x15, x0, 1
sw   x3, 12(x20)
addi x16, x0, 2
addi x17, x0, 3
addi x1, x0, 3
addi x18, x0, 0
addi x19, x0, 0
loop: addi x1, x1, -1
bne  x1, x0, loop
addi x18, x18, 1
addi x19, x19, 1
addi x21, x0, 7
sw   x21, 16(x20)
lw   x22, 16(x20)
bne  x22, x0, tgt_ld
addi x23, x0, 9
sw   x3, 20(x20)
addi x24, x0, 8
tgt_ld: addi x25, x0, 25
spin: jal x0, spin
