# branch_ops: beq taken, not taken, forward and backward.
# Flow: 0,1,2, beq(taken) to skip1, skip1, beq(not taken), 7, skip2: beq forward to fwd, fwd: beq backward to back,
# back, beq forward to spin.
# Final registers: x1=7 x2=7 x3=5 x11=22 x12=33 x14=55. x10 must stay unwritten (skipped by the first beq).
.text
addi x1, x0, 7
addi x2, x0, 7
addi x3, x0, 5
beq  x1, x2, skip1
addi x10, x0, 111
skip1: addi x11, x0, 22
beq  x1, x3, skip2
addi x12, x0, 33
skip2: beq x0, x0, fwd
back: addi x14, x0, 55
beq  x0, x0, spin
fwd: beq x0, x0, back
spin: jal x0, spin
