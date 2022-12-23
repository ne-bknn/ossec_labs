#include <stdio.h>
#include <stdlib.h>

extern char **environ;

int main(int argc, char *argv[])
{
  char **p;
  int n;

  for (p = environ; *p != NULL; p++) {
	printf("%s\n", *p);
	n++;
	if (n == 10) {
		break;
	}
  }
}
