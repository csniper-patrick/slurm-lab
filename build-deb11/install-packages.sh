#!/bin/bash

# Install slurm
apt-get -y update
apt-get -y install build-essential slurm-smd-{client,slurmd,slurmctld,slurmdbd,slurmrestd,sackd,sview,doc,dev,libpmi0,libpmi2-0,libnss-slurm,libpam-slurm-adopt} environment-modules gfortran hwloc openssh-server systemd systemd-sysv cron systemd tmux vim wget git openssh-* libsysfs2 autotools-dev autoconf libtool xauth hostname

# install jupyterhub
apt-get -y install python3 python3-{pip,dev,venv} libpython3-{dev,stdlib}
apt-get -y install nodejs npm

# install nginx
apt-get -y install nginx

# install extra packages
apt-get -y install tmux sudo vim man ansible nmap wget iproute2 iproute2-doc less

# clean apt
apt-get clean

cat >> /etc/pam.d/common-auth <<EOF
auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF

cat >> /etc/pam.d/common-session <<EOF
session     optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF

cat >> /etc/pam.d/common-session-noninteractive <<EOF
session     optional      pam_exec.so /etc/slurm/create-account-user.sh
EOF