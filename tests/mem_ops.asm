# mem_ops: sw and lw at three addresses with three different values.
# Base address x2 = 0x100. Memory words: 0xFC = 77, 0x100 = 123, 0x108 = 0xFFFFFFFB.
# Final registers: x1=123 x2=256 x3=0xFFFFFFFB x4=77 x5=0xFFFFFFFB x6=123 x7=77
# x8 and x28 must stay unwritten: the rd bits of the two stores with offsets 8 and -4 are offset bits.
.text
addi x2, x0, 256
addi x1, x0, 123
addi x3, x0, -5
addi x4, x0, 77
sw   x1, 0(x2)
sw   x3, 8(x2)
sw   x4, -4(x2)
lw   x5, 8(x2)
lw   x6, 0(x2)
lw   x7, -4(x2)
spin: jal x0, spin
