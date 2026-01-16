#!/bin/bash -x
apt-get -y update
apt-get -y install fakeroot devscripts git wget munge libmunge-dev mariadb-server mariadb-client libmariadb-dev libhttp-parser2.9 libhttp-parser-dev libjson-c5 libjson-c-dev libyaml-0-2 libyaml-dev libjwt2 libjwt-dev openssl libssl-dev curl bzip2 build-essential python3 libpmix-bin libpmix-dev libpmix2t64 systemd dpkg-dev vim gfortran libsysfs2 libsysfs-dev pkg-config lua5.4 lua5.4-dev libucx0 libucx-dev ucx-utils

# install nvml
[[ $(uname -m) == x86_64 ]] && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
[[ $(uname -m) == aarch64 ]] && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update
apt-get -y install cuda-nvml-dev-13-0
export CPPFLAGS="$(pkg-config --cflags-only-I --keep-system-cflags nvidia-ml-13.0) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L --keep-system-libs nvidia-ml-13.0) ${LDFLAGS}"

cd slurm-src
yes | mk-build-deps -i debian/control
debuild -b -uc -us

# create local repo
mkdir /opt/slurm-repo
cd /opt/slurm-repo
mv /*.deb /opt/slurm-repo
dpkg-scanpackages . /dev/null > Release
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cat > /etc/apt/sources.list.d/slurm.list <<EOF
deb [trusted=yes] file:/opt/slurm-repo /
EOF

# extract documents
cd ~
mkdir extract
cd extract
dpkg-deb -xv /opt/slurm-repo/slurm-smd-doc*.deb .
find . -iname slurm.html -exec dirname {} \; | xargs -i mv -v {} /opt/doc