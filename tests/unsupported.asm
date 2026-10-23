# unsupported.asm: instructions outside the 37 supported ones must change nothing.
# x14 gets a sentinel before mul, x15 gets one after ecall and ebreak.
# If any of the four unsupported instructions did something, a sentinel or the final PC would be wrong.
addi x1, x0, 5
addi x2, x0, 7
addi x14, x0, 77
mul x14, x1, x2
fence 15, 15
ecall
ebreak
addi x15, x0, 99
spin: jal x0, spin


