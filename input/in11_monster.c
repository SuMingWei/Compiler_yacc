int i;
for (i = 0; i < 10; i++) {
	print(i);
}
while (i > 0)
{
	int x[3];
	x[0] = 1 + 2;
	x[1] = x[0] - 1;
	x[2] = x[1] / 3;
	print(x[2]);
	print(3 - 4 * (+5 + -8) - 10 / 7 > -4 % 3 || !true && !!false);
}

int x;
x += 10;
while (x > 0) {
	print(x);
	x--;
	if (x != 0) {
		float y = 3.14;
		print("If x != ");
		print(0);
		print(y);
		/* print
		a string and y with
		newline */
	} else {
		float z = 6.6;
		print("If x == ");
		print(0);
		print(z);
	}
	int j;
	int i;
	for (i = 1; i <= 9; i++) {
		for (j = 9; j >= 1; j--) {
			print(i);
			print("*");
			print(j);
			print("=");
			print(i * j);
			print("\t");
		}
		print("\n");
	}
}