#!/bin/bash

# Install slurm
dnf install -y yum-utils epel-release
dnf config-manager --enable crb
dnf -y --enablerepo=rocky-9-baseos,rocky-9-appstream,rocky-9-crb,rocky-9-epel install http-parser http-parser-devel libjwt libjwt-devel
dnf -y install slurm-{slurmctld,slurmd,slurmdbd,slurmrestd,sackd,example-configs,contribs,devel,libpmi,pam_slurm}  @development gcc-gfortran hwloc openssh-server rdma-core rdma-core-devel librdmacm hwloc hwloc-devel which autoconf automake libtool xorg-x11-xauth hostname htop Lmod rsync btop iotop chrony munge munge-devel pmix pmix-devel

# install jupyterhub
dnf -y install python3.12 python3.12-pip python3.12-devel
dnf -y install nodejs

# install nginx
dnf -y install nginx

# install extra packages
dnf -y install tmux sudo vim man ansible-core iproute nmap wget 

# update all and clear yum cache
dnf -y update
dnf clean all

# create slurm account and user on login
for pam_file in /etc/pam.d/{password-auth,system-auth} ; do
	cat >> ${pam_file} <<-EOF
		auth        optional      pam_exec.so /etc/slurm/create-account-user.sh
		session     optional      pam_exec.so /etc/slurm/create-account-user.sh
	EOF
done

# activate lmod
ln -s /usr/share/lmod/lmod/init/bash /etc/profile.d/z99-lmod.sh
