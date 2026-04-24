#!/bin/bash -x
dnf -y install @development yum-utils rpm-build epel-release
dnf config-manager --enable crb
dnf -y --enablerepo=rocky-9-baseos,rocky-9-appstream,rocky-9-crb,rocky-9-epel install http-parser http-parser-devel libjwt libjwt-devel
dnf -y install munge munge-devel mariadb mariadb-devel gtk2 gtk2-devel gtk3 gtk3-devel http-parser http-parser-devel json-c json-c-devel libyaml libyaml-devel wget python3 readline-devel pam-devel perl-ExtUtils-MakeMaker perl-devel perl-JSON-PP createrepo_c hdf5 hdf5-devel man2html man2html-core pam pam-devel freeipmi freeipmi-devel numactl numactl-devel pmix pmix-devel hwloc hwloc-devel lua lua-devel ucx ucx-devel

# install nvml
case $(uname -m) in
	x86_64)
		# Install CUDA keyring for x86_64 architecture
		dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel10/x86_64/cuda-rhel10.repo
		# Install ROCm repository for x86_64 architecture
		tee /etc/yum.repos.d/rocm.repo <<-EOF
		[rocm]
		name=ROCm repository
		baseurl=https://repo.radeon.com/rocm/el10/latest/main
		enabled=1
		priority=50
		gpgcheck=1
		gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key

		[amdgraphics]
		name=AMD Graphics repository
		baseurl=https://repo.radeon.com/graphics/latest/el/10/main/x86_64/
		enabled=1
		priority=50
		gpgcheck=1
		gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
		EOF
		dnf clean all
		dnf install -y $(dnf list cuda-nvml-devel* | grep -oE "^cuda-nvml-devel-[0-9]+-[0-9]+" | tail -n1) rocm
		tee --append /etc/ld.so.conf.d/rocm.conf <<-EOF
		/opt/rocm/lib
		/opt/rocm/lib64
		EOF
		ldconfig
		export CPPFLAGS="-I/opt/rocm/include ${CPPFLAGS}"
		export LDFLAGS="-L/opt/rocm/lib -L/opt/rocm/lib64 ${LDFLAGS}"
		export LD_LIBRARY_PATH="/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH}"
		;;
	aarch64)
		# Install CUDA keyring for aarch64 architecture
		dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel10/sbsa/cuda-rhel10.repo
		dnf clean all
		dnf install -y $(dnf list cuda-nvml-devel* | grep -oE "^cuda-nvml-devel-[0-9]+-[0-9]+" | tail -n1)
		;;
esac

export CPPFLAGS="$(pkg-config --cflags-only-I $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${CPPFLAGS}"
export LDFLAGS="$(pkg-config --libs-only-L $(pkg-config --list-all | grep -oE 'nvidia-ml-[0-9]+\.[0-9+]') ) ${LDFLAGS}"

ver=$(rpmspec -q --qf '%{version}\n' slurm-src/slurm.spec | head -n 1)
rel=$(rpmspec -q --qf '%{release}\n' slurm-src/slurm.spec | head -n 1 | cut -d. -f1)
if [[ ${rel} == 1 ]]; then 
	slurm_source_dir=slurm-${ver}
else
	slurm_source_dir=slurm-${ver}-${rel}
fi
mv slurm-src ${slurm_source_dir}
tar azcvf ${slurm_source_dir}.tar.bz2 ${slurm_source_dir}
rpmbuild -ta --with slurmrestd --with hdf5 --with hwloc --with numa --with pmix --with lua --with ucx --with jwt --with freeipmi --with nvml ${slurm_source_dir}.tar.bz2 |& tee build.log
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