#!/bin/bash -lx
#SBATCH --ntasks=2
#SBATCH --mem=1024
module load mpi
which mpirun
mpirun md5sum /dev/zero