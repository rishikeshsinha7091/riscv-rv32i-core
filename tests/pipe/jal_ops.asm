# jal_ops.asm for the pipeline: the same instructions as tests/jal_ops.asm plus two nops after every jal.
# Flow: jal x5 to first, jal x0 to second, jal x6 back to back, jal x0 to spin.
# Final registers: x1=1 x2=2 x4=4 x5=8 x6=60. x3 must stay unwritten (skipped). Spin at address 68.
# nop is addi x0, x0, 0 and changes nothing.
.text
addi x1, x0, 1
jal  x5, first
nop
nop
addi x1, x0, 99
first: addi x2, x0, 2
jal  x0, second
nop
nop
addi x3, x0, 98
back: addi x4, x0, 4
jal  x0, spin
nop
nop
second: jal x6, back
nop
nop
spin: jal x0, spin
nop
nop
