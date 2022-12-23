#include <stdio.h>
#include <unistd.h>

int main(void)
{
  int pid = fork();
  // определить, в каком процессе мы находимся, помогает переменная pid

  if (pid == 0) {
    // дочерний процесс получает в качестве значения 0
    // это не является корректным PID и служит для определения
    // того факта, что данный код выполняется в дочернем процессе
    printf("Child process\n");
    printf("Child process pid: %d\n", getpid());
  } else if (pid > 0) {
    // родительский процесс получает значение PID дочернего, он должен быть > 0
    printf("Parent process\n"
           "Parent pid:  %d\n", getpid());
  }

  return 0;
}
