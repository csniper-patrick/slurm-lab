#!/bin/bash -x
version=23.02.5

yum -y install @development yum-utils rpm-build epel-release
# yum -y install http://repo.openfusion.net/centos8-x86_64/openfusion-release-0.8-1.of.el8.noarch.rpm
yum-config-manager --enable powertools
yum -y install munge munge-devel mariadb mariadb-devel gtk2 gtk2-devel gtk3 gtk3-devel http-parser http-parser-devel json-c json-c-devel libyaml libyaml-devel libjwt libjwt-devel wget python3 readline-devel pam-devel perl-ExtUtils-MakeMaker perl-devel perl-JSON-PP createrepo_c hdf5 hdf5-devel man2html man2html-core pam pam-devel freeipmi freeipmi-devel numactl numactl-devel pmix pmix-devel hwloc hwloc-devel
cd ~
mkdir ~/source
cd ~/source
wget https://download.schedmd.com/slurm/slurm-${version}.tar.bz2
rpmbuild -ta --with slurmrestd --with hdf5 --with hwloc --with numa --with pmix slurm-${version}.tar.bz2 |& tee build.log
cd ~
mkdir -pv /opt/slurm-repo/Packages
find /root/rpmbuild/RPMS/ -iname "*.rpm" -exec mv {} /opt/slurm-repo/Packages \;
createrepo /opt/slurm-repo
cat > /etc/yum.repos.d/slurm.repo <<EOF
[slurm]
name=slurm local repository
baseurl=file:///opt/slurm-repo/
gpgcheck=0
enabled=1
EOF
