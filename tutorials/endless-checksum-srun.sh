#!/bin/bash -l
echo Hello ${NAME:-World}!

cat <<EOF
SLURM_JOBID=${SLURM_JOBID}
SLURM_NTASKS=${SLURM_NTASKS}
SLURM_NNODES=${SLURM_NNODES}
SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
EOF

# show hostname by running hostname
srun --ntasks ${SLURM_NTASKS} $(which hostname)

for i in $( seq ${SLURM_NTASKS} ); do
    srun --nodes=1 --ntasks=1 $(which md5sum) /dev/zero &
done

wait