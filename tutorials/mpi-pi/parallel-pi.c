#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <mpi.h>
#include <signal.h>


long long total_hit = 0;
long long turn = 100000000;
long long i , start_pt;
volatile sig_atomic_t interrupted = 0;
FILE * file;


void catch_signal(int sig){
	interrupted = 1;
}

int main(){
	signal(SIGUSR1, catch_signal);
	file = fopen("parallel-pi.checkpt", "r");
	if(file){
		fscanf(file, "%lld %lld", &start_pt, &total_hit);
		fclose(file);
		printf("resumed \n");
	}else{
		start_pt = 0;
		printf("new run\n");
	}

	MPI_Init(NULL, NULL);
	int world_size, world_rank;
	MPI_Comm_size(MPI_COMM_WORLD, &world_size);
	MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

	MPI_Bcast(&start_pt, 1, MPI_INT, 0, MPI_COMM_WORLD);

	for(i=start_pt; i<turn; i++){
		double x = (double)rand()/(double)RAND_MAX;
		double y = (double)rand()/(double)RAND_MAX;
		int local_hit = (int) ( x*x + y*y )<1.0 ;
		int global_hit = 0;
		MPI_Reduce(&local_hit, &global_hit, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
		if(world_rank == 0){
			total_hit+=global_hit;
			if(interrupted){
				FILE * file2;
				file2 = fopen("parallel-pi.checkpt", "w");
				fprintf(file2, "%lld %lld\n", i, total_hit);
				fclose(file2);
				interrupted = 0; 
			}
			if( (i+1) % (turn/100) == 0 ) printf("pi = %lf (hit=%lld, turn=%lld) \n", (double)total_hit*4.0/(double)((i+1)*world_size), total_hit, (i+1)*world_size );
			fflush(stdout);
		}
		MPI_Barrier(MPI_COMM_WORLD);
	}
	if(world_rank==0){
		remove("parallel-pi.checkpt");
	}
	MPI_Finalize();
	return 0;
}
