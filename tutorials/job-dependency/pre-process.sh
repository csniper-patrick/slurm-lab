#!/bin/bash
#SBATCH --time 00:00:10
# This tutorial script represents a "pre-processing" task that must
# complete before subsequent jobs in the dependency chain can start.

date
echo "Pre-processing: Initializing environment..."
sleep 30
