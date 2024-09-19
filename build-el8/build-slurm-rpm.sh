#!/bin/bash -x
dnf -y install @development yum-utils rpm-build epel-release
dnf config-manager --enable powertools
dnf -y install munge munge-devel mariadb mariadb-devel gtk2 gtk2-devel gtk3 gtk3-devel http-parser http-parser-devel json-c json-c-devel libyaml libyaml-devel libjwt libjwt-devel wget python3 readline-devel pam-devel perl-ExtUtils-MakeMaker perl-devel perl-JSON-PP createrepo_c hdf5 hdf5-devel man2html man2html-core pam pam-devel freeipmi freeipmi-devel numactl numactl-devel pmix pmix-devel hwloc hwloc-devel

# install nvml
[[ $(uname -m) == x86_64 ]] && dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
[[ $(uname -m) == aarch64 ]] && dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-rhel8.repo
dnf clean all
dnf install -y cuda-nvml-devel-12-6
export CPPFLAGS="$(pkg-config --cflags-only-I --keep-system-cflags nvidia-ml-12.6) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L --keep-system-libs nvidia-ml-12.6) ${LDFLAGS}"

ver=$(grep "Version:" slurm-src/slurm.spec | head -n 1 | awk '{print $2}' )
mv slurm-src slurm-${ver}
tar azcvf slurm-${ver}.tar.bz2 slurm-${ver}
rpmbuild -ta --with slurmrestd --with hdf5 --with hwloc --with numa --with pmix --with nvml slurm-${ver}.tar.bz2 |& tee build.log
cd ~
# create local repo
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

# extract documents
mkdir extract
cd extract
rpm2cpio /opt/slurm-repo/Packages/slurm-${ver}*.rpm | cpio -idvm
find . -iname slurm.html -exec dirname {} \; | xargs -i mv -v {} /opt/doc