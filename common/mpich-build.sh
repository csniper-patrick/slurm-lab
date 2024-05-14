#!/bin/bash -x
cd mpich-src
./autogen.sh
./configure --prefix=/opt/mpich --enable-shared --with-slurm
make -j 4
make install
