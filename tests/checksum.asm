# checksum.asm: a small program that uses every group of instructions.
# Fill 4 bytes at 0x200 with 17, 17+147, ... (only the low byte is stored), call a function that
# adds and xors them in a loop, then combine the results with lui constants, shifts, halves and bytes.
addi x1, x0, 512
addi x2, x0, 17
addi x3, x0, 0
addi x4, x0, 4
fill:
add x5, x1, x3
sb x2, 0(x5)
addi x2, x2, 147
addi x3, x3, 1
bne x3, x4, fill
addi x10, x1, 0
addi x11, x0, 4
jal x6, reduce
slli x14, x12, 16
add x14, x14, x13
lui x15, 0xCAFEF
addi x15, x15, 13
xor x16, x14, x15
sw x16, 8(x1)
lhu x17, 8(x1)
lh x18, 10(x1)
lb x19, 11(x1)
srai x20, x16, 24
sub x21, x19, x20
slt x23, x14, x15
sltu x24, x14, x15
addi x25, x0, 1
bge x14, x15, skip
addi x25, x0, 0
skip:
auipc x22, 0
spin: jal x0, spin
reduce:
addi x12, x0, 0
addi x13, x0, 0
addi x7, x0, 0
loop:
add x8, x10, x7
lbu x9, 0(x8)
add x12, x12, x9
xor x13, x13, x9
addi x7, x7, 1
bltu x7, x11, loop
jalr x0, x6, 0
