# jal_ops: jal forward and backward, the return address, and jal x0 (no link).
# Flow: 0, jal(x5) to first, first, jal x0 to second, second: jal(x6) backward to back, back, jal x0 to spin.
# Final registers: x1=1 x2=2 x4=4 x5=8 x6=36. x3 must stay unwritten (skipped).
.text
addi x1, x0, 1
jal  x5, first
addi x1, x0, 99
first: addi x2, x0, 2
jal  x0, second
addi x3, x0, 98
back: addi x4, x0, 4
jal  x0, spin
second: jal x6, back
spin: jal x0, spin

