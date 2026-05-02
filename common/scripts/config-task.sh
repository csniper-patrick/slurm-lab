#!/bin/bash

# 1. Define the list of versions from newest to oldest
py_vers=("python3.14" "python3.13" "python3.12" "python3.11" "python3")
SYS_PYTHON=""
# 2. Loop through and find the best one
for py in "${py_vers[@]}"; do
    # Short-circuit one-liner: Assign the variable AND break if successful
    SYS_PYTHON=$(command -v "$py" 2>/dev/null) && break
done

# Prepare Jupyterhub environment
${SYS_PYTHON} -m venv /opt/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install wheel
/opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab bash_kernel
/opt/jupyterhub/bin/python3 -m pip install ipywidgets sudospawner
/opt/jupyterhub/bin/python3 -m pip install jupyterlab-slurm || /opt/jupyterhub/bin/python3 -m pip install git+https://github.com/NERSC/jupyterlab-slurm.git
/opt/jupyterhub/bin/python3 -m pip install jupyterhub-moss>=10.0.0
/opt/jupyterhub/bin/python3 -m bash_kernel.install
npm install -g only-allow
npm install -g configurable-http-proxy
mkdir -p /opt/jupyterhub/etc/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install PyJWT requests getent2 pandas

# build and install slop
${SYS_PYTHON} -m venv /opt/slop/
cd /opt/slop
/opt/slop/bin/python3 -m pip install -r slop/requirements.txt
/opt/slop/bin/python3 -m pip install pyinstaller
/opt/slop/bin/pyinstaller --collect-all=urwid --onefile slop/main.py -n slop
cp dist/slop /usr/local/bin/

# Create users
useradd -r -b /var/lib slurm
useradd -r -b /var/lib -s /usr/sbin/nologin slurmrestd
groupadd lyoko
useradd -m -g lyoko --shell /bin/bash jeremie
useradd -m -g lyoko --shell /bin/bash aelita
useradd -m -g lyoko --shell /bin/bash yumi
useradd -m -g lyoko --shell /bin/bash ulrich
useradd -m -g lyoko --shell /bin/bash odd
loginctl enable-linger jeremie
loginctl enable-linger aelita
loginctl enable-linger yumi
loginctl enable-linger ulrich
loginctl enable-linger odd

# Install jinja2 and jinja2-cli
${SYS_PYTHON} -m venv /opt/local/
/opt/local/bin/python3 -m pip install jinja2-cli

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

# config ssh
ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys