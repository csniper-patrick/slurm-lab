#!/bin/bash

# Install slurm
yum install -y yum-utils epel-release
yum-config-manager --enable powertools
yum install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,example-configs} mpich mpich-devel mpich-doc @development gcc-gfortran hwloc pmix pam_script

# install jupyterhub
yum -y module install python39
yum -y module enable python39-devel
yum -y install python39-devel
yum -y module install nodejs:18

# install extra packages
yum -y install tmux sudo vim man 

# clean yum
yum clean all