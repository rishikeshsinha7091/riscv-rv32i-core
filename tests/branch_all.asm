# branch_all.asm: bne, blt, bge, bltu, bgeu, each taken and not taken.
# Result register = 1 if the branch was taken, 0 if it was not.
# x1 = 5, x2 = 9, x3 = -1, x4 = 1, x5 = 5, x6 = 0x7FFFFFFF
addi x1, x0, 5
addi x2, x0, 9
addi x3, x0, -1
addi x4, x0, 1
addi x5, x0, 5
lui x6, 0x80000
addi x6, x6, -1
addi x8, x0, 1
bne x1, x5, skip1
addi x8, x0, 0
skip1:
addi x9, x0, 1
bne x1, x2, skip2
addi x9, x0, 0
skip2:
addi x10, x0, 1
blt x1, x2, skip3
addi x10, x0, 0
skip3:
addi x11, x0, 1
blt x2, x1, skip4
addi x11, x0, 0
skip4:
addi x12, x0, 1
blt x1, x5, skip5
addi x12, x0, 0
skip5:
addi x13, x0, 1
blt x3, x4, skip6
addi x13, x0, 0
skip6:
addi x14, x0, 1
blt x6, x3, skip7
addi x14, x0, 0
skip7:
addi x15, x0, 1
bge x1, x5, skip8
addi x15, x0, 0
skip8:
addi x16, x0, 1
bge x3, x4, skip9
addi x16, x0, 0
skip9:
addi x17, x0, 1
bge x6, x3, skip10
addi x17, x0, 0
skip10:
addi x18, x0, 1
bltu x3, x4, skip11
addi x18, x0, 0
skip11:
addi x19, x0, 1
bltu x4, x3, skip12
addi x19, x0, 0
skip12:
addi x20, x0, 1
bltu x6, x3, skip13
addi x20, x0, 0
skip13:
addi x21, x0, 1
bgeu x3, x4, skip14
addi x21, x0, 0
skip14:
addi x22, x0, 1
bgeu x4, x3, skip15
addi x22, x0, 0
skip15:
addi x23, x0, 1
bgeu x1, x5, skip16
addi x23, x0, 0
skip16:
spin: jal x0, spin
