# upper_jalr.asm for the pipeline: lui, auipc and jalr. The code starts at address 0.
# Same instructions as tests/upper_jalr.asm plus nops, and jalr x13, x12, 33 (was 13) because of the padding.
# Expected: x1=0x12345000 x2=0x1800 x3=0x12345678 x4=0x80000000 x5=0xFFFFF000 x6=0x1034 x7=0x38
# x8=0xFFFFF03C x9=0x44 x10=77 x11=5 x12=0x50 x13=0x64 x14 unwritten x15=7. Spin at address 116.
# nop is addi x0, x0, 0 and changes nothing.
lui x1, 0x12345
lui x2, 2
nop
nop
nop
addi x2, x2, -2048
lui x3, 0x12345
nop
nop
nop
addi x3, x3, 0x678
lui x4, 0x80000
lui x5, 0xFFFFF
auipc x6, 1
auipc x7, 0
auipc x8, 0xFFFFF
jal x9, func
nop
nop
addi x11, x0, 5
auipc x12, 0
nop
nop
nop
jalr x13, x12, 33
nop
nop
addi x14, x0, 99
addi x15, x0, 7
spin: jal x0, spin
nop
nop
func: addi x10, x0, 77
jalr x0, x9, 0
nop
nop
