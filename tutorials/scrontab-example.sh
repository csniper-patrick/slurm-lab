#!/bin/bash -v

#write a seperated log file
exec &> >(tee ~/scrontab-example.$(date +"%FT%R").log) 2>&1

pwd

hostname

uptime

date

scontrol show job ${SLURM_JOBID}

sleep infinity