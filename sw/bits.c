volatile unsigned int in[2] = { 0x80F0A55Au, 0xFFFFFFC0u };
unsigned int out[7];
int main(void) {
unsigned int w = in[0];
unsigned int u = in[1];
int s = (int)u;
unsigned int v = w;
unsigned int ones = 0;
while (v) {
ones += v & 1;
v >>= 1;
}
out[0] = ones;
out[1] = (unsigned int)(s >> 3);
out[2] = u >> 28;
out[3] = w << 4;
out[4] = w & 0xFFFFu;
out[5] = w | 0xFu;
out[6] = w ^ 0xFFFFFFFFu;
return (int)ones;
}
