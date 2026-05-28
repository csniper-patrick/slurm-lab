#!/bin/bash -l
# This tutorial script demonstrates how to use 'srun' to launch multiple
# parallel tasks within a single Slurm allocation.

echo "Hello ${NAME:-World}!"

# Display various Slurm environment variables
cat <<EOF
SLURM_JOBID=${SLURM_JOBID}
SLURM_NTASKS=${SLURM_NTASKS}
SLURM_NNODES=${SLURM_NNODES}
SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
EOF

# Run 'hostname' across all tasks in the allocation
srun --ntasks ${SLURM_NTASKS} $(which hostname)

# Launch multiple background 'srun' tasks, each consuming 1 task/node
for i in $( seq ${SLURM_NTASKS} ); do
    srun --nodes=1 --ntasks=1 $(which md5sum) /dev/zero &
done

# Wait for all background tasks to finish
wait
