#!/bin/bash -x
apt-get -y update
apt-get -y install fakeroot devscripts git wget munge libmunge-dev mariadb-server mariadb-client libmariadb-dev libhttp-parser2.9 libhttp-parser-dev libjson-c5 libjson-c-dev libyaml-0-2 libyaml-dev libjwt0 libjwt-dev openssl libssl-dev wget curl bzip2 build-essential python3 libpmix-bin libpmix-dev libpmix2 systemd dpkg-dev vim gfortran libsysfs2 libsysfs-dev
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