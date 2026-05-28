#!/bin/bash -v
# This script is a tutorial example for 'scrontab' (Slurm Cron).
# It logs system information and Slurm job details to a timestamped log file.

# Redirect both stdout and stderr to a timestamped log file in the user's home directory
exec &> >(tee ~/scrontab-example.$(date +"%FT%R").log) 2>&1

# Print current working directory
pwd

# Print hostname
hostname

# Print system uptime and load average
uptime

# Print current date and time
date

# Show Slurm details for the current job
scontrol show job ${SLURM_JOBID}

# Sleep indefinitely (useful for inspecting the job while it's "running")
sleep infinity
