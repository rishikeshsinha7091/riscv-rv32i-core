# unsupported: xor and bne are not in our instruction set. They must change nothing.
# x1 = x2 = 5 on purpose: a bne misdecoded as beq would then BRANCH and skip addi x15.
# Final registers: x1=5 x2=5 x14=77 (xor must not touch it) x15=99 (bne must fall through).
.text
addi x1, x0, 5
addi x2, x0, 5
addi x14, x0, 77
xor  x14, x1, x2
bne  x1, x2, spin
addi x15, x0, 99
spin: jal x0, spin
