#!/bin/bash
#SBATCH --ntasks=2

date
timeout 90 md5sum /dev/zero || true