volatile int count = 10;
int fibs[10];
int main(void) {
int a = 1;
int b = 1;
int n = count;
for (int i = 0; i < n; i++) {
fibs[i] = a;
int t = a + b;
a = b;
b = t;
}
return fibs[n - 1];
}
