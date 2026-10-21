# loop_sum: 5 + 4 + 3 + 2 + 1 with a counter that counts down to 0.
# Uses only the supported instructions (no bne): beq to leave the loop, jal to go back.
# Final registers: x1=0 (counter), x2=15 (sum).
.text
addi x1, x0, 5
addi x2, x0, 0
loop: beq x1, x0, done
add  x2, x2, x1
addi x1, x1, -1
jal  x0, loop
done: jal x0, done
