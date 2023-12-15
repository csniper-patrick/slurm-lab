#!/bin/bash -x
cd /
wget https://www.mpich.org/static/downloads/4.1.2/mpich-4.1.2.tar.gz
tar xvf mpich-4.1.2.tar.gz
cd mpich-4.1.2
./configure --prefix=/opt/mpich --with-slurm --enable-shared --with-slurm --with-pmi --with-pmix
make -j 
make install
