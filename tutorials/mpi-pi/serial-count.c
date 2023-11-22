#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

#ifndef MAX
#define MAX (600)
#endif

volatile sig_atomic_t interrupted = 0;
int i, start_pt;
FILE * file;

void catch_signal(int sig){
    interrupted = 1;
}

int main(){
    signal(SIGUSR1, catch_signal);
    
    file = fopen("serial-count.checkpt","r");
    if(file){
        fscanf(file, "%d", &start_pt);
        fclose(file);
    }else{
        start_pt = 0;
    }
    
    for( i = start_pt; i < MAX; i++){
        printf("%d\n", i);
		fflush(stdout);
		if(interrupted){
			file = fopen("serial-count.checkpt","w");
			fprintf(file, "%d\n", i);
			fclose(file);
			interrupted = 0;
		}
		sleep(1);
    }
    
    remove("serial-count.checkpt");
    
    return 0;
}
