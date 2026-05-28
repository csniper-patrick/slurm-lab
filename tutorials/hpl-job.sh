#!/bin/bash -l
#SBATCH --output %x-%j.out
#SBATCH --mem 0
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive

# This tutorial script demonstrates how to run the HPL (High-Performance Linpack)
# benchmark within the Slurm Lab environment. It dynamically generates an
# HPL.dat input file based on the job allocation.

# 1. Load HPL using environment modules or Spack
module load hpl || spack load hpl

# 2. Safety check: ensure we are running inside a Slurm job
[[ -n ${SLURM_JOBID} ]] || { echo "This script must be run via sbatch/salloc"; exit 1; }

# 3. Create a unique run directory for this job
mkdir HPL-${SLURM_JOBID}
cd HPL-${SLURM_JOBID}

# 4. Generate HPL.dat input file
# The matrix size (N) is scaled based on the number of nodes
cat > HPL.dat <<EOF
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
$(( 4096 * SLURM_NNODES ))         Ns
1            # of NBs
64          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
${SLURM_NNODES}            Ps
${SLURM_NTASKS_PER_NODE}            Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
1            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
0            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
0            DEPTHs (>=0)
2            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF

# 5. Set OpenMP threads per MPI task
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Print the path to the xhpl executable
which xhpl

# 6. Run the benchmark using mpirun
mpirun --bind-to none xhpl
