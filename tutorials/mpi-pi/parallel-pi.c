#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <mpi.h>
#include <signal.h>

long long total_hit = 0;
long long target = 100000;
long long i , start_pt;
volatile sig_atomic_t interrupted = 0;
FILE * file;


void catch_signal(int sig){
	interrupted = 1;
}

int main(){
	signal(SIGUSR1, catch_signal);
	MPI_Init(NULL, NULL);
	int world_size, world_rank;
	MPI_Comm_size(MPI_COMM_WORLD, &world_size);
	MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
	long long turn = target / world_size ; 
	MPI_Bcast(&start_pt, 1, MPI_INT, 0, MPI_COMM_WORLD);
	for(i=start_pt; i<turn; i++){
		double x = (double)rand()/(double)RAND_MAX;
		double y = (double)rand()/(double)RAND_MAX;
		int local_hit = (int) ( x*x + y*y )<1.0 ;
		int global_hit = 0;
		MPI_Reduce(&local_hit, &global_hit, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
		if(world_rank == 0){
			total_hit+=global_hit;
			if( (i+1) % (turn/100) == 0 || interrupted ){
				printf("pi = %.4lf (hit=%6lld, turn=%6lld) \n", (double)total_hit*4.0/(double)((i+1)*world_size), total_hit, (i+1)*world_size );
				interrupted = 0;
			}
			fflush(stdout);
		}
		MPI_Barrier(MPI_COMM_WORLD);
	}
	MPI_Finalize();
	return 0;
}
