#!/bin/bash -lx
#SBATCH --ntasks=4
#SBATCH --mem=1024
#SBATCH --job-name=mpi-test

# This tutorial script demonstrates how to run an MPI job using Slurm.
# It loads the MPI module and runs 'md5sum' across multiple tasks using mpirun.

# Load the MPI environment module
module load mpi

# Print the path to mpirun for debugging
which mpirun

# Execute md5sum on /dev/zero across all allocated tasks
mpirun md5sum /dev/zero
