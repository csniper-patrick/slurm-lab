#!/bin/bash -x
cd /
wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.6.tar.gz
tar xvf openmpi-4.1.6.tar.gz
cd openmpi-4.1.6
./configure --prefix=/opt/openmpi --with-slurm --enable-shared --enable-mpi-fortran --enable-mpi-cxx --enable-mpi-cxx-seek --enable-orterun-prefix-by-default --with-hwloc --with-slurm --with-pmi --with-pmix
make -j 
make install
