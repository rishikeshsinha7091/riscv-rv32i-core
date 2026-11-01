# mem_ops.asm for the pipeline: the same instructions as tests/mem_ops.asm plus padding.
# One nop after the four setup instructions: the first sw reads x1, written 4 slots before it.
# nop is addi x0, x0, 0 and changes nothing.
# Memory words: 0xFC = 77, 0x100 = 123, 0x108 = 0xFFFFFFFB. x8 and x28 must stay unwritten.
.text
addi x2, x0, 256
addi x1, x0, 123
addi x3, x0, -5
addi x4, x0, 77
nop
sw   x1, 0(x2)
sw   x3, 8(x2)
sw   x4, -4(x2)
lw   x5, 8(x2)
lw   x6, 0(x2)
lw   x7, -4(x2)
spin: jal x0, spin
nop
nop
