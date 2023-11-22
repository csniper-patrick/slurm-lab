#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

int main(){
	long long hit = 0;
	long long turn = 10000000000;
	for(long long i=0; i<turn; i++){
		double x = (double)rand()/(double)RAND_MAX;
		double y = (double)rand()/(double)RAND_MAX;
		hit += ( x*x + y*y )<1.0;
		if( (i+1) % (turn/100) == 0 ) printf("pi = %lf (hit=%lld, turn=%lld) \n", (double)hit*4.0/(double)(i+1), hit, i+1 );
	}
	return 0;
}
