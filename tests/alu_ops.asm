# alu_ops: every ALU instruction and addi, with operands chosen so all results differ.
# Final registers: x1=12 x2=10 x3=22 x4=2 x5=8 x6=14 x7=0 x8=1
#                  x9=0xFFFFFFFF x10=1 x11=0xFFFFFFFE x12=6 x13=112
.text
addi x1, x0, 12
addi x2, x0, 10
add  x3, x1, x2
sub  x4, x1, x2
and  x5, x1, x2
or   x6, x1, x2
slt  x7, x1, x2
slt  x8, x2, x1
addi x9, x0, -1
slt  x10, x9, x1
sub  x11, x2, x1
addi x12, x2, -4
addi x13, x1, 100
spin: jal x0, spin
