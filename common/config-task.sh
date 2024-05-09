#!/bin/bash

# Prepare Jupyterhub environment
python3 -m venv /opt/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install wheel
/opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab bash_kernel
/opt/jupyterhub/bin/python3 -m pip install ipywidgets jupyterlab-slurm sudospawner jupyterhub_moss 
/opt/jupyterhub/bin/python3 -m bash_kernel.install
npm install -g configurable-http-proxy
mkdir -p /opt/jupyterhub/etc/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install PyJWT requests getent2 pandas

# Create users
useradd -r -b /var/lib slurm
groupadd lyoko
useradd -m -g lyoko --shell /bin/bash jeremie
useradd -m -g lyoko --shell /bin/bash aelita
useradd -m -g lyoko --shell /bin/bash yumi
useradd -m -g lyoko --shell /bin/bash william
useradd -m -g lyoko --shell /bin/bash ulrich
useradd -m -g lyoko --shell /bin/bash odd

# Install jinja2 and jinja2-cli
python3 -m venv /opt/templates/
/opt/templates/bin/python3 -m pip install jinja2-cli

# create auth/slurm key
dd if=/dev/random of=/etc/slurm/slurm.key bs=1024 count=1
chown slurm:slurm /etc/slurm/slurm.key
chmod 600 /etc/slurm/slurm.key