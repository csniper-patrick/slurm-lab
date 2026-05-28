#!/bin/bash -x
# This script builds Slurm DEB packages for Debian 13 (Trixie).
# It installs build dependencies, configures GPU support (NVML/ROCm),
# and creates a local repository for the built packages.

# 1. Install build dependencies
apt-get -y update
apt-get -y install fakeroot devscripts git wget munge libmunge-dev mariadb-server mariadb-client libmariadb-dev libllhttp-dev libjson-c5 libjson-c-dev libyaml-0-2 libyaml-dev libjwt2 libjwt-dev openssl libssl-dev curl bzip2 build-essential python3 libpmix-bin libpmix-dev libpmix2t64 systemd dpkg-dev vim gfortran libsysfs2 libsysfs-dev pkg-config lua5.4 lua5.4-dev libucx0 libucx-dev ucx-utils python3-pypandoc pandoc

# 2. Install GPU support libraries (NVML for NVIDIA, ROCm for AMD)
case $(uname -m) in
	x86_64)
		# Install CUDA keyring for x86_64 architecture
		wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
		dpkg -i cuda-keyring_1.1-1_all.deb

		# Install ROCm keyring for x86_64 architecture
		mkdir --parents --mode=0755 /etc/apt/keyrings
		wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
			gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null

		# Register ROCm repositories (using Noble/Jammy as Trixie equivalents)
		tee /etc/apt/sources.list.d/rocm.list <<-EOF
		deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main
		deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/latest/ubuntu noble main
		EOF

		tee /etc/apt/preferences.d/rocm-pin-600 <<-EOF
		Package: *
		Pin: release o=repo.radeon.com
		Pin-Priority: 600
		EOF

		# Update package lists and install GPU development libraries
		apt-get update
		apt-get -y install $(apt-cache search cuda-nvml-dev | grep -oE "^cuda-nvml-dev-[0-9]+-[0-9]+" | sort | tail -n1) rocm-core rocm-dev rocm-smi-lib
		;;
	aarch64)
		# Install CUDA keyring for aarch64 architecture
		wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa/cuda-keyring_1.1-1_all.deb
		dpkg -i cuda-keyring_1.1-1_all.deb
		apt-get update
		apt-get -y install $(apt-cache search cuda-nvml-dev | grep -oE "^cuda-nvml-dev-[0-9]+-[0-9]+" | sort | tail -n1)
		;;
esac

# 3. Configure compiler and linker flags for NVML
export CPPFLAGS="$(pkg-config --cflags-only-I $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${LDFLAGS}"

# 4. Build Slurm packages
cd /usr/local/src/slurm
# Install build-time dependencies defined in debian/control
yes | mk-build-deps -i debian/control
# Build binary packages without signing
debuild -b -uc -us

# 5. Create a local Debian repository for the built packages
mkdir /opt/slurm-repo
cd /opt/slurm-repo
mv /usr/local/src/*.deb /opt/slurm-repo
dpkg-scanpackages . /dev/null > Release
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cat > /etc/apt/sources.list.d/slurm.list <<EOF
deb [trusted=yes] file:/opt/slurm-repo /
EOF

# 6. Extract documentation for Nginx to serve
mkdir -pv /usr/share/nginx/html/
cd /usr/local/src/slurm/obj-$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)
make html
find . -iname slurm.html -exec dirname {} \; | xargs -I{} mv -v {} /usr/share/nginx/html/doc
