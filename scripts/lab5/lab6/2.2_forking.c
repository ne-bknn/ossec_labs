#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

int main(void) {
	int children_ids[10];
	for (int i = 0; i < 1; ++i) {
	    int pid = fork();

	    if (pid == 0) {
		    printf("Child process\n");
		    sleep(10);
		    printf("Child process terminating\n");
		    return 0;
	    } else {
		    printf("Parent, pid: %d\n", pid);
		    printf("Parent spawns new child\n");
	    }
	}
	int status;
	while (wait(&status) > 0) {
		sleep(0.1);
	}
	printf("Children terminated\n");
	return 0;
}
