#!/bin/bash

# Generate slurmdbd.conf
cat > $(dirname ${0})/slurmdbd.conf <<EOF
#
# Example slurmdbd.conf file.
#
# See the slurmdbd.conf man page for more information.
#
# Archive info
#ArchiveJobs=yes
#ArchiveDir="/tmp"
#ArchiveSteps=yes
#ArchiveScript=
#JobPurge=12
#StepPurge=1
#
# Authentication info
AuthType=auth/munge
#AuthInfo=/var/run/munge/munge.socket.2
#
# slurmDBD info
#DbdAddr=localhost
DbdHost=slurm-lab-master-2
DbdBackupHost=slurm-lab-master-1
#DbdPort=7031
SlurmUser=slurm
#MessageTimeout=300
DebugLevel=verbose
#DefaultQOS=normal,standby
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/var/run/slurmdbd.pid
#PluginDir=/usr/lib/slurm
#PrivateData=accounts,users,usage,jobs
#TrackWCKey=yes
#
# Database info
StorageType=accounting_storage/mysql
StorageHost=slurm-lab-db-1
#StoragePort=1234
StoragePass=${MYSQL_PASSWORD:-password}
StorageUser=${MYSQL_USER:-slurm}
StorageLoc=${MYSQL_DATABASE:-slurm_acct_db}
EOF

# ensure file permission and ownership 
chown -R slurm:slurm $(dirname ${0}) /var/spool/slurmctld
chmod 0600 $(dirname ${0})/slurmdbd.conf
