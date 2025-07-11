#!/bin/bash

# Install slurm
yum install -y yum-utils epel-release
yum-config-manager --enable powertools
yum install -y slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,sackd,example-configs,contribs,devel,libpmi,pam_slurm}  @development gcc-gfortran hwloc openssh-server rdma-core rdma-core-devel librdmacm hwloc hwloc-devel which autoconf automake libtool xorg-x11-xauth hostname htop Lmod rsync btop iotop chrony munge munge-devel pmix pmix-devel

# install jupyterhub
yum -y install python3.12 python3.12-pip python3.12-devel
yum -y module install nodejs:18

# install nginx
yum -y module install nginx:1.22

# install extra packages
yum -y install tmux sudo vim man ansible iproute nmap wget 

# update all and clear yum cache
yum -y upadte
yum clean all

# create slurm account and user on login
for pam_file in /etc/pam.d/{password-auth,system-auth} ; do
	cat >> ${pam_file} <<-EOF
		auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
		session     optional      pam_exec.so /etc/slurm/create-account-user.sh
	EOF
done

# activate lmod
ln -s /usr/share/lmod/lmod/init/bash /etc/profile.d/z99-lmod.sh
