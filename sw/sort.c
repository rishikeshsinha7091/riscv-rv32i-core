int values[8] = { 5, -2, 9, 1, -7, 3, 8, 4 };
int swaps;
int main(void) {
for (int i = 0; i < 7; i++) {
for (int j = 0; j < 7 - i; j++) {
if (values[j] > values[j + 1]) {
int t = values[j];
values[j] = values[j + 1];
values[j + 1] = t;
swaps++;
}
}
}
return values[0];
}
