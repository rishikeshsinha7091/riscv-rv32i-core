# runs first: the linker puts this section at address 0
.section .text.init
.globl _start
_start:
# sp = top of data memory
lui sp, %hi(_stack_top)
addi sp, sp, %lo(_stack_top)
# a0 = start of .bss, a1 = end of .bss
lui a0, %hi(_bss_start)
addi a0, a0, %lo(_bss_start)
lui a1, %hi(_bss_end)
addi a1, a1, %lo(_bss_end)
# write zero to every word from a0 up to a1
bss_loop:
bgeu a0, a1, bss_done
sw zero, 0(a0)
addi a0, a0, 4
jal zero, bss_loop
bss_done:
# call main, then stay here forever
jal ra, main
spin:
jal zero, spin
