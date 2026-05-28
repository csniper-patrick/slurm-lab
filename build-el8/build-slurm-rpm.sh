#!/bin/bash -x
# This script builds Slurm RPM packages for Enterprise Linux 8 (RHEL/Rocky 8).
# It installs build dependencies, configures GPU support (NVML/ROCm),
# and creates a local repository for the built packages.

# 1. Install build dependencies
dnf -y install @development yum-utils rpm-build epel-release
dnf config-manager --enable powertools
dnf -y install munge munge-devel mariadb mariadb-devel gtk2 gtk2-devel gtk3 gtk3-devel http-parser http-parser-devel json-c json-c-devel libyaml libyaml-devel libjwt libjwt-devel wget python3 readline-devel pam-devel perl-ExtUtils-MakeMaker perl-devel perl-JSON-PP createrepo_c hdf5 hdf5-devel man2html man2html-core pam pam-devel freeipmi freeipmi-devel numactl numactl-devel pmix pmix-devel hwloc hwloc-devel lua lua-devel ucx ucx-devel 

# 2. Install GPU support libraries (NVML for NVIDIA, ROCm for AMD)
case $(uname -m) in
	x86_64)
		# Install CUDA repository for x86_64 architecture
		dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
		
		# Install ROCm repository for x86_64 architecture
		tee /etc/yum.repos.d/rocm.repo <<-EOF
		[rocm]
		name=ROCm 7.2.0 repository
		baseurl=https://repo.radeon.com/rocm/el8/latest/main
		enabled=1
		priority=50
		gpgcheck=1
		gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key

		[amdgraphics]
		name=AMD Graphics repository
		baseurl=https://repo.radeon.com/graphics/latest/el/8/main/x86_64/
		enabled=1
		priority=50
		gpgcheck=1
		gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
		EOF
		dnf clean all
		# Install NVML and ROCm development libraries
		dnf install -y $(dnf list cuda-nvml-devel* | grep -oE "^cuda-nvml-devel-[0-9]+-[0-9]+" | tail -n1) rocm-core rocm-dev rocm-smi-lib
		
		# Configure dynamic linker for ROCm libraries
		tee --append /etc/ld.so.conf.d/rocm.conf <<-EOF
		/opt/rocm/lib
		/opt/rocm/lib64
		EOF
		ldconfig
		
		# Set environment variables for ROCm
		export CPPFLAGS="-I/opt/rocm/include ${CPPFLAGS}"
		export LDFLAGS="-L/opt/rocm/lib -L/opt/rocm/lib64 ${LDFLAGS}"
		export LD_LIBRARY_PATH="/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH}"
		;;
	aarch64)
		# Install CUDA repository for aarch64 architecture
		dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-rhel8.repo
		dnf clean all
		dnf install -y $(dnf list cuda-nvml-devel* | grep -oE "^cuda-nvml-devel-[0-9]+-[0-9]+" | tail -n1)
		;;
esac

# 3. Configure compiler and linker flags for NVML
export CPPFLAGS="$(pkg-config --cflags-only-I $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${LDFLAGS}"

# 4. Prepare source tarball and build Slurm RPMs
ver=$(grep "Version:" /usr/local/src/slurm/slurm.spec | head -n 1 | awk '{print $2}' )
rel=$(grep "%define rel" /usr/local/src/slurm/slurm.spec | head -n 1 | awk '{print $3}')
if [[ ${rel} == 1 ]]; then 
	slurm_source_dir=slurm-${ver}
else
	slurm_source_dir=slurm-${ver}-${rel}
fi
mv /usr/local/src/slurm ${slurm_source_dir}
tar azcf ${slurm_source_dir}.tar.bz2 ${slurm_source_dir}
# Build all packages with specified features
rpmbuild --noclean -ta --with slurmrestd --with hdf5 --with hwloc --with numa --with pmix --with lua --with ucx --with jwt --with freeipmi --with nvml ${slurm_source_dir}.tar.bz2 |& tee build.log

# 5. Create a local RPM repository for the built packages
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

# 6. Extract documentation for Nginx to serve
mkdir -pv /usr/share/nginx/html/
cd /root/rpmbuild/BUILD/${slurm_source_dir}
dnf -y install python3-pip pandoc
python3 -m pip install pypandoc
make html
find /root/rpmbuild/BUILD -iname slurm.html -exec dirname {} \; | xargs -I{} mv -v {} /usr/share/nginx/html/doc