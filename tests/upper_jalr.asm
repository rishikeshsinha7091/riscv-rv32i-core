# upper_jalr.asm: lui, auipc and jalr. The code starts at address 0, so the PC values below are worked out from that.
lui x1, 0x12345
lui x2, 2
addi x2, x2, -2048
lui x3, 0x12345
addi x3, x3, 0x678
lui x4, 0x80000
lui x5, 0xFFFFF
auipc x6, 1
auipc x7, 0
auipc x8, 0xFFFFF
jal x9, func
addi x11, x0, 5
auipc x12, 0
jalr x13, x12, 13
addi x14, x0, 99
addi x15, x0, 7
spin: jal x0, spin
func: addi x10, x0, 77
jalr x0, x9, 0
