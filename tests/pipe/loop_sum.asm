# loop_sum.asm for the pipeline: 5 + 4 + 3 + 2 + 1 with a counter that counts down to 0.
# Same instructions as tests/loop_sum.asm plus nops: 2 after the setup, 2 after beq, 2 after each jal.
# The two nops after jal x0, loop are also the gap between addi x1 and the next beq x1.
# Final registers: x1=0 (counter), x2=15 (sum). Spin at address 48.
# nop is addi x0, x0, 0 and changes nothing.
.text
addi x1, x0, 5
addi x2, x0, 0
nop
nop
loop: beq x1, x0, done
nop
nop
add  x2, x2, x1
addi x1, x1, -1
jal  x0, loop
nop
nop
done: jal x0, done
nop
nop
