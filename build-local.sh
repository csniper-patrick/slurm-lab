#!/bin/bash -x
PODMAN="$(which podman)"
PODMAN=${PODMAN:=$(which docker)}

echo el{8..9} deb12 | xargs -n1 -I{} -P 3 ${PODMAN} build -t slurm-lab:{} -f build-{}/Containerfile .

${PODMAN} tag slurm-lab:el9 slurm-lab:latest