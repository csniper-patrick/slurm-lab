#!/bin/bash
# This script installs Slurm and other essential packages for Enterprise Linux 9 (RHEL/Rocky 9).
# It also configures JupyterHub, Nginx, PAM, and Lmod for the environment.

# 1. Install Slurm and its dependencies
dnf install -y yum-utils epel-release
dnf config-manager --enable crb
dnf install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,sackd,example-configs,contribs,devel,libpmi,pam_slurm}  @development gcc-gfortran hwloc openssh-server rdma-core rdma-core-devel librdmacm hwloc hwloc-devel which autoconf automake libtool xorg-x11-xauth hostname htop Lmod rsync btop iotop chrony munge munge-devel pmix pmix-devel

# 2. Install Python and Node.js for JupyterHub
dnf -y install python3.12 python3.12-pip python3.12-devel
dnf -y module install nodejs:20

# 3. Install Nginx for serving documentation and as a proxy
dnf -y module install nginx:1.24

# 4. Install extra utility packages
dnf -y install tmux sudo vim man ansible iproute nmap wget 

# 5. Perform system cleanup
# dnf -y update
dnf clean all

# 6. Configure PAM to automatically create Slurm accounts and users on login
for pam_file in /etc/pam.d/{password-auth,system-auth} ; do
	cat >> ${pam_file} <<-EOF
		auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
		session     optional      pam_exec.so /etc/slurm/create-account-user.sh
	EOF
done

# 7. Activate Lmod (Lua-based module system)
ln -s /usr/share/lmod/lmod/init/bash /etc/profile.d/z99-lmod.sh
