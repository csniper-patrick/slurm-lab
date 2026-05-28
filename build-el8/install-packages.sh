#!/bin/bash
# This script installs Slurm and other essential packages for Enterprise Linux 8 (RHEL/Rocky 8).
# It also configures JupyterHub, Nginx, PAM, and Lmod for the environment.

# 1. Install Slurm and its dependencies
yum install -y yum-utils epel-release
yum-config-manager --enable powertools
yum install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,sackd,example-configs,contribs,devel,libpmi,pam_slurm}  @development gcc-gfortran hwloc openssh-server rdma-core rdma-core-devel librdmacm hwloc hwloc-devel which autoconf automake libtool xorg-x11-xauth hostname htop Lmod rsync btop iotop chrony munge munge-devel pmix pmix-devel

# 2. Install Python and Node.js for JupyterHub
yum -y install python3.12 python3.12-pip python3.12-devel
yum -y module install nodejs:18

# 3. Install Nginx for serving documentation and as a proxy
yum -y module install nginx:1.22

# 4. Install extra utility packages
yum -y install tmux sudo vim man ansible iproute nmap wget 

# 5. Perform system cleanup
# yum -y upadte
yum clean all

# 6. Configure PAM to automatically create Slurm accounts and users on login
for pam_file in /etc/pam.d/{password-auth,system-auth} ; do
	cat >> ${pam_file} <<-EOF
		auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
		session     optional      pam_exec.so /etc/slurm/create-account-user.sh
	EOF
done

# 7. Activate Lmod (Lua-based module system)
ln -s /usr/share/lmod/lmod/init/bash /etc/profile.d/z99-lmod.sh
