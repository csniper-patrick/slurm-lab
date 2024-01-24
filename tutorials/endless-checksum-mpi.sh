#!/bin/bash -lx
#SBATCH --ntasks=4
#SBATCH --mem=1024
module load mpi
which mpirun
mpirun md5sum /dev/zero