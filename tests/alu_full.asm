# alu_full.asm: the 13 ALU-type instructions added in Part 5.
# x1 = 12, x2 = 10, x3 = -16, x4 = 3 are the inputs. Every result goes in its own register (x5 to x22).
addi x1, x0, 12
addi x2, x0, 10
addi x3, x0, -16
addi x4, x0, 3
xor x5, x1, x2
sll x6, x1, x4
srl x7, x3, x4
sra x8, x3, x4
sltu x9, x3, x1
sltu x10, x1, x3
xori x11, x1, -1
ori x12, x2, 1024
andi x13, x3, 1279
slti x14, x1, -1
sltiu x15, x1, -1
slti x16, x3, 5
sltiu x17, x3, 5
slli x18, x1, 4
srli x19, x3, 4
srai x20, x3, 4
srli x21, x3, 31
slli x22, x4, 31
spin: jal x0, spin
