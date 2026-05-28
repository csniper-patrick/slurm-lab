#!/bin/bash
#SBATCH --ntasks=2
# This tutorial script represents the "main process" in a dependency chain.
# It runs a compute-intensive task (md5sum) with a timeout.

date
timeout 90 md5sum /dev/zero || true
