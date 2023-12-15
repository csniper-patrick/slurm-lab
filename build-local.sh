#!/bin/bash -x
PODMAN="$(which podman)"
PODMAN=${PODMAN:=$(which docker)}

echo el8 deb12 | xargs -n1 -I{} -P 2 ${PODMAN} build -t slurm-lab:{} -f build-{}/Containerfile .

${PODMAN} tag slurm-lab:el8 slurm-lab:latest