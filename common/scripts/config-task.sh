#!/bin/bash -x
# This script performs the initial configuration tasks for the Slurm cluster environment.
# It sets up JupyterHub, creates system and regular users, configures PAM and NSS for Slurm,
# and prepares the SSH environment for the root user.

# 1. Find the best available Python 3 version
py_vers=("python3.14" "python3.13" "python3.12" "python3.11" "python3")
SYS_PYTHON=""
for py in "${py_vers[@]}"; do
    SYS_PYTHON=$(command -v "$py" 2>/dev/null) && break
done

# 2. Prepare JupyterHub environment in a virtualenv
${SYS_PYTHON} -m venv /opt/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install wheel
/opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab bash_kernel
/opt/jupyterhub/bin/python3 -m pip install ipywidgets sudospawner
# Install jupyterlab-slurm extension (try pip first, fallback to git)
/opt/jupyterhub/bin/python3 -m pip install jupyterlab-slurm || /opt/jupyterhub/bin/python3 -m pip install git+https://github.com/NERSC/jupyterlab-slurm.git
/opt/jupyterhub/bin/python3 -m pip install jupyterhub-moss>=10.0.0
/opt/jupyterhub/bin/python3 -m bash_kernel.install
npm install -g only-allow
npm install -g configurable-http-proxy
mkdir -p /opt/jupyterhub/etc/jupyterhub/
/opt/jupyterhub/bin/python3 -m pip install PyJWT requests getent2 pandas

# 3. Build and install 'slop' (Slurm Output monitor)
${SYS_PYTHON} -m venv /usr/local/src/slop/
cd /usr/local/src/slop
/usr/local/src/slop/bin/python3 -m pip install -r slop/requirements.txt
/usr/local/src/slop/bin/python3 -m pip install pyinstaller
/usr/local/src/slop/bin/pyinstaller --collect-all=urwid --onefile slop/main.py -n slop
cp /usr/local/src/slop/dist/slop /usr/local/bin/
cd ~
rm -rf /usr/local/src/slop

# 4. Create system and regular users
useradd -r -b /var/lib slurm
useradd -r -b /var/lib -s /usr/sbin/nologin slurmrestd
groupadd lyoko
# Create tutorial users (Lyoko characters)
useradd -m -g lyoko --shell /bin/bash jeremie
useradd -m -g lyoko --shell /bin/bash aelita
useradd -m -g lyoko --shell /bin/bash yumi
useradd -m -g lyoko --shell /bin/bash ulrich
useradd -m -g lyoko --shell /bin/bash odd
# Enable linger for these users to keep their sessions/services alive
loginctl enable-linger jeremie
loginctl enable-linger aelita
loginctl enable-linger yumi
loginctl enable-linger ulrich
loginctl enable-linger odd

# 5. Install jinja2-cli for template rendering in a separate virtualenv
${SYS_PYTHON} -m venv /opt/local/
/opt/local/bin/python3 -m pip install jinja2-cli

# 6. Enable nss_slurm to allow Slurm to resolve users/groups within jobs
sed -i '/^passwd:/ s/passwd:\s*/passwd: slurm /' /etc/nsswitch.conf
sed -i '/^group:/ s/group:\s*/group: slurm /'  /etc/nsswitch.conf

# 7. Setup pam_slurm_adopt to restrict SSH access to compute nodes to users with active jobs
sed -i '0,/^account/ s/^account/account sufficient pam_access.so\n&/' /etc/pam.d/sshd
cat >> /etc/security/access.conf <<EOF
+:(lyoko):ALL
-:ALL:ALL
EOF
# Insert pam_slurm_adopt.so into the SSH PAM configuration
tac /etc/pam.d/sshd | sed -e '0,/^account/ s/^account/-account required pam_slurm_adopt.so\n&/' | tac > /etc/pam.d/sshd-new && mv /etc/pam.d/sshd-new /etc/pam.d/sshd

# 8. Configure SSH for the root user
ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

# 9. Install community.general collection for Ansible
ansible-galaxy collection install -r /requirements.yaml -p /usr/share/ansible/collections
rm -f /requirements.yaml

