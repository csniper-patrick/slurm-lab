#!/bin/bash -x
PODMAN="$(which podman)"
PODMAN=${PODMAN:=$(which docker)}

distro=${@:-"el8 el9 deb12"}

echo ${distro} | xargs -n1 -I{} -P 3 ${PODMAN} build --pull=newer -t slurm-lab:{} --squash -f build-{}/Containerfile .