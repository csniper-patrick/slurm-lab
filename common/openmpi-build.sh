#!/bin/bash -x
# cd /
# wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.6.tar.gz
# tar xvf openmpi-4.1.6.tar.gz
# cd openmpi-4.1.6
cd ompi-src
./autogen.pl
./configure --prefix=/opt/openmpi --with-slurm --enable-shared --enable-mpi-fortran --enable-orterun-prefix-by-default --with-hwloc --with-pmix
make -j 
make install
