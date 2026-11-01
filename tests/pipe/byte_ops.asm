# byte_ops.asm for the pipeline: the same instructions as tests/byte_ops.asm plus padding.
# Data at 0x100 and 0x104. Three nops wherever a register is read too soon after it was written.
# nop is addi x0, x0, 0 and changes nothing.
addi x1, x0, 256
lui x2, 0x80FF8
nop
nop
nop
addi x2, x2, -255
nop
nop
nop
sw x2, 0(x1)
lb x3, 0(x1)
lb x4, 1(x1)
lb x5, 2(x1)
lb x6, 3(x1)
lbu x7, 2(x1)
lbu x8, 3(x1)
lh x9, 0(x1)
lh x10, 2(x1)
lhu x11, 2(x1)
lw x12, 0(x1)
lui x13, 0x11223
nop
nop
nop
addi x13, x13, 0x344
nop
nop
nop
sw x13, 4(x1)
addi x14, x0, -86
addi x15, x0, -69
addi x16, x0, -52
addi x17, x0, -35
sb x14, 5(x1)
lw x18, 4(x1)
sb x15, 4(x1)
sb x16, 6(x1)
sb x17, 7(x1)
lw x19, 4(x1)
addi x20, x0, 291
addi x22, x0, 1110
nop
nop
sh x20, 4(x1)
lw x21, 4(x1)
sh x22, 6(x1)
lw x23, 4(x1)
spin: jal x0, spin
nop
nop
