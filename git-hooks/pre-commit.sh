#!/bin/bash -eu
PROJECT_ROOT=$(git rev-parse --show-toplevel)

update_packages_yaml () {
	FILE_PATH=${PROJECT_ROOT}/common/packages.yaml

	if [[ -s ${PROJECT_ROOT}/ompi/VERSION ]] ; then
		major=$(grep ^major= ${PROJECT_ROOT}/ompi/VERSION | cut -d"=" -f2)
		minor=$(grep ^minor= ${PROJECT_ROOT}/ompi/VERSION | cut -d"=" -f2)
		release=$(grep ^release= ${PROJECT_ROOT}/ompi/VERSION | cut -d"=" -f2)
		ompi_ver=${major}.${minor}.${release}
	fi

	if [[ -s ${PROJECT_ROOT}/slurm/slurm.spec ]] ; then
		slurm_ver=$( grep ^Version: ${PROJECT_ROOT}/slurm/slurm.spec | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' )
	fi

	[[ -n ${ompi_ver} ]] && [[ -n ${slurm_ver} ]] && cat <<-EOF > ${FILE_PATH}
	packages:
	  openmpi:
	    externals:
	      - spec: "openmpi@${ompi_ver}"
	        prefix: /opt/openmpi
	    buildable: False
	  slurm:
	    externals:
	      - spec: "slurm@${slurm_ver}"
	        prefix: /usr
	    buildable: False
	EOF

	git add ${FILE_PATH}

}

install_hook () {
	cp -f ${0} ${PROJECT_ROOT}/.git/hooks/pre-commit || true
	chmod +x ${PROJECT_ROOT}/.git/hooks/pre-commit
}

update_packages_yaml && install_hook
