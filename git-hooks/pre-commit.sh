#!/bin/bash -eu
# This Git pre-commit hook automatically updates 'common/packages.yaml'
# with the current versions of Open MPI and Slurm from their respective submodules.
# It ensures that Spack or other package managers use the correct external versions.

PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Function to extract versions and update the packages.yaml file
update_packages_yaml () {
	FILE_PATH=${PROJECT_ROOT}/common/packages.yaml

	# Extract Open MPI version from its VERSION file
	if [[ -s ${PROJECT_ROOT}/modules/ompi/VERSION ]] ; then
		major=$(grep ^major= ${PROJECT_ROOT}/modules/ompi/VERSION | cut -d"=" -f2)
		minor=$(grep ^minor= ${PROJECT_ROOT}/modules/ompi/VERSION | cut -d"=" -f2)
		release=$(grep ^release= ${PROJECT_ROOT}/modules/ompi/VERSION | cut -d"=" -f2)
		ompi_ver=${major}.${minor}.${release}
	fi

	# Extract Slurm version from its RPM spec file
	if [[ -s ${PROJECT_ROOT}/modules/slurm/slurm.spec ]] ; then
		slurm_ver=$( grep ^Version: ${PROJECT_ROOT}/modules/slurm/slurm.spec | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' )
	fi

	# Generate the packages.yaml file if both versions were found
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

	# Stage the updated packages.yaml
	git add ${FILE_PATH}
}

# Function to install this script as the Git pre-commit hook
install_hook () {
	cp -f ${0} ${PROJECT_ROOT}/.git/hooks/pre-commit || true
	chmod +x ${PROJECT_ROOT}/.git/hooks/pre-commit
}

# Execute the update and ensure the hook is installed in the local .git directory
update_packages_yaml && install_hook
