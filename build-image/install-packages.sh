#!/bin/bash

# Install 
yum install -y yum-utils epel-release
yum-config-manager --enable powertools
yum install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,example-configs} sudo vim man mpich mpich-devel mpich-doc @development gcc-gfortran hwloc pmix pam_script tmux

# install jupyterhub
yum -y module install python39
yum -y module enable python39-devel
yum -y install python39-devel
# pip3 install packaging
# pip3 install jupyterlab bash_kernel
# python3 -m bash_kernel.install
python3 -m venv /opt/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install wheel
/opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab bash_kernel
/opt/jupyterhub/bin/python3 -m pip install ipywidgets
/opt/jupyterhub/bin/python3 -m bash_kernel.install
yum -y module install nodejs:18
npm install -g configurable-http-proxy
mkdir -p /opt/jupyterhub/etc/jupyterhub/

yum clean all

# Create users
useradd -r -b /var/lib slurm
useradd jeremie
useradd aelita
useradd yumi
useradd william
useradd ulrich
useradd odd