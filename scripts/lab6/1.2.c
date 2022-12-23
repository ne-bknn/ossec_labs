#include <stdio.h>
#include <stdlib.h>

extern char **environ;

int main(int argc, char *argv[])
{
  char **p;
  int n;

  for (p = environ; *p != NULL; p++) {
	n++;
  }

  printf("Number of environment variables: %d\n", n);
  printf("Number of arguments: %d\n", argc-1);
}
