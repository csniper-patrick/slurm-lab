#!/bin/bash -x
# This script builds and installs Open MPI from source with Slurm support.

cd /usr/local/src/ompi

# Generate build files
./autogen.pl

# Configure with various options:
# --with-slurm: Enable Slurm integration
# --enable-mpi-fortran: Enable Fortran bindings
# --with-pmix=internal: Use internal PMIX
# --with-pmi2: Enable PMI2 support
./configure --prefix=/opt/openmpi --with-slurm --enable-shared \
    --enable-mpi-fortran --enable-orterun-prefix-by-default \
    --with-hwloc --with-pmix=internal --with-pmi2

# Compile
make -j 

# Install to /opt/openmpi
make install
