#!/bin/bash

# find best python
SYS_PYTHON=$(which python3.12)
SYS_PYTHON=${SYS_PYTHON:-$(which python3.11)}
SYS_PYTHON=${SYS_PYTHON:-$(which python3)}

# Prepare Jupyterhub environment
${SYS_PYTHON} -m venv /opt/jupyterhub/
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
useradd -m -g lyoko --shell /bin/bash ulrich
useradd -m -g lyoko --shell /bin/bash odd

# Install jinja2 and jinja2-cli
${SYS_PYTHON} -m venv /opt/local/
/opt/local/bin/python3 -m pip install jinja2-cli

# create auth/slurm key
dd if=/dev/random of=/etc/slurm/slurm.key bs=1024 count=1
chown slurm:slurm /etc/slurm/slurm.key
chmod 600 /etc/slurm/slurm.key

# enable nss_slurm
sed -i '/^passwd:/ s/passwd:\s*/passwd: slurm /' /etc/nsswitch.conf
sed -i '/^group:/ s/group:\s*/group: slurm /'  /etc/nsswitch.conf

# setup pam_slurm_adopt
sed -i '0,/^account/ s/^account/account sufficient pam_access.so\n&/' /etc/pam.d/sshd
cat >> /etc/security/access.conf <<EOF
+:(lyoko):ALL
-:ALL:ALL
EOF
tac /etc/pam.d/sshd | sed -e '0,/^account/ s/^account/-account required pam_slurm_adopt.so\n&/' | tac > /etc/pam.d/sshd-new && mv /etc/pam.d/sshd-new /etc/pam.d/sshd