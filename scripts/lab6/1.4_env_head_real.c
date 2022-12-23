#include <stdio.h>
#include <stdlib.h>

extern char **environ;

int main(int argc, char *argv[])
{
  char **p;
  int n;
  if (argc != 2) {
	  printf("Provide n envs to show as first argument\n");
	  exit(1);
  }

  int n_vars = atoi(argv[1]);

  for (p = environ; *p != NULL; p++) {
	printf("%s\n", *p);
	n++;
	if (n == n_vars) {
		break;
	}
  }
}
