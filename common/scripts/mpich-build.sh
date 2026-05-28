#!/bin/bash -x
# This script builds and installs MPICH from source with Slurm support.

cd mpich-src

# Generate build files
./autogen.sh

# Configure for Slurm integration and shared libraries
./configure --prefix=/opt/mpich --enable-shared --with-slurm

# Compile with 4 parallel jobs
make -j 4

# Install to /opt/mpich
make install
