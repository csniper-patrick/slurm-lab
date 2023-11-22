CC=gcc
MPICC=mpicc

default: serial parallel

serial: serial-count serial-pi

serial-count: serial-count.c
	$(CC) serial-count.c -o serial-count

serial-pi: serial-pi.c
	$(CC) serial-pi.c -o serial-pi

parallel: parallel-pi 

parallel-pi: parallel-pi.c
	$(MPICC) parallel-pi.c -o parallel-pi

clean: 
	find -maxdepth 1 -executable -type f -delete
	find -maxdepth 1 -iname "*.checkpt" -delete
