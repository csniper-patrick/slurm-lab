#!/bin/bash -x
apt-get -y update
apt-get -y install fakeroot devscripts git munge libmunge-dev mariadb-server mariadb-client libmariadb-dev libhttp-parser2.9 libhttp-parser-dev libjson-c5 libjson-c-dev libyaml-0-2 libyaml-dev libjwt0 libjwt-dev openssl libssl-dev wget curl bzip2 build-essential python3 libpmix-bin libpmix-dev libpmix2 systemd dpkg-dev vim gfortran libsysfs2 libsysfs-dev pkg-config lua5.4 lua5.4-dev libucx0 libucx-dev ucx-utils

# install nvml
case $(uname -m) in
	x86_64)
		# Install CUDA keyring for x86_64 architecture
		wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
		dpkg -i cuda-keyring_1.1-1_all.deb
		# Install ROCm keyring for x86_64 architecture
		# Make the directory if it doesn't exist yet.
		# This location is recommended by the distribution maintainers.
		mkdir --parents --mode=0755 /etc/apt/keyrings

		# Download the key, convert the signing-key to a full
		# keyring required by apt and store in the keyring directory
		wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
			gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null
		# Add the repository to the apt sources list
		# Register ROCm packages
		tee /etc/apt/sources.list.d/rocm.list <<-EOF
		deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest jammy main
		deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/latest/ubuntu jammy main
		EOF

		tee /etc/apt/preferences.d/rocm-pin-600 <<-EOF
		Package: *
		Pin: release o=repo.radeon.com
		Pin-Priority: 600
		EOF

		# Update the package lists to include the new repositories
		apt-get update
		# Install the latest available versions of the packages from the repositories
		apt-get -y install $(apt-cache search cuda-nvml-dev | grep -oE "^cuda-nvml-dev-[0-9]+-[0-9]+" | sort | tail -n1) rocm
		;;
	aarch64)
		# Install CUDA keyring for aarch64 architecture
		wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa/cuda-keyring_1.1-1_all.deb
		dpkg -i cuda-keyring_1.1-1_all.deb
		apt-get update
		apt-get -y install $(apt-cache search cuda-nvml-dev | grep -oE "^cuda-nvml-dev-[0-9]+-[0-9]+" | sort | tail -n1)
		;;
esac

export CPPFLAGS="$(pkg-config --cflags-only-I $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${LDFLAGS}"

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