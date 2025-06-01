#!/bin/bash -x

cd ompi-src
./autogen.pl
./configure --prefix=/opt/openmpi --with-slurm --enable-shared --enable-mpi-fortran --enable-orterun-prefix-by-default --with-hwloc --with-pmix --with-pmi2
make -j 
make install
