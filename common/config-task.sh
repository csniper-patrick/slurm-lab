#!/bin/bash

# Install Jupyterhub
python3 -m venv /opt/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install wheel
/opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab bash_kernel
/opt/jupyterhub/bin/python3 -m pip install ipywidgets
/opt/jupyterhub/bin/python3 -m bash_kernel.install
npm install -g configurable-http-proxy
mkdir -p /opt/jupyterhub/etc/jupyterhub/

# Create users
useradd -r -b /var/lib slurm
groupadd lyoko
useradd -g lyoko jeremie
useradd -g lyoko aelita
useradd -g lyoko yumi
useradd -g lyoko william
useradd -g lyoko ulrich
useradd -g lyoko odd
