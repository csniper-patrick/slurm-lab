#!/bin/bash
# This script installs Slurm and other essential packages for Debian 12 (Bookworm).
# It also configures JupyterHub, Nginx, and PAM for automated user management.

# 1. Install Slurm and its dependencies
apt-get -y update
apt-get -y install build-essential slurm-smd-{client,slurmd,slurmctld,slurmdbd,slurmrestd,sackd,sview,doc,dev,libpmi0,libpmi2-0,libnss-slurm,libpam-slurm-adopt} gfortran hwloc openssh-server systemd systemd-sysv cron systemd tmux vim wget git openssh-* libsysfs2 autotools-dev autoconf libtool xauth hostname htop lmod rsync btop iotop chrony munge libmunge-dev flex libpmix-bin libpmix-dev libpmix2 

# 2. Install Python and Node.js for JupyterHub
apt-get -y install python3 python3-{pip,dev,venv} libpython3-{dev,stdlib}
apt-get -y install nodejs npm

# 3. Install Nginx for serving documentation and as a proxy
apt-get -y install nginx

# 4. Install extra utility packages
apt-get -y install tmux sudo vim man ansible nmap iproute2 less curl

# 5. Perform system upgrade and cleanup
apt-get -y upgrade
apt-get clean

# 6. Configure PAM to automatically create Slurm accounts and users on login
cat >> /etc/pam.d/common-auth <<EOF
auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF

cat >> /etc/pam.d/common-session <<EOF
session     optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF

cat >> /etc/pam.d/common-session-noninteractive <<EOF
session     optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF
