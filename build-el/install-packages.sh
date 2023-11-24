#!/bin/bash

# Install slurm
yum install -y yum-utils epel-release
yum-config-manager --enable powertools
yum install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,example-configs} mpich mpich-devel mpich-doc @development gcc-gfortran hwloc pmix pam_script openssh-server

# install jupyterhub
yum -y install python3.11 python3.11-pip python3.11-devel
yum -y module install nodejs:18

# install nginx
yum -y module install nginx:1.22

# install extra packages
yum -y install tmux sudo vim man ansible iproute nmap

# clean yum
yum clean all