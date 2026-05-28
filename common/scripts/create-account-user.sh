#!/bin/bash -u
# This script is intended to be used by PAM (Pluggable Authentication Modules)
# to automatically create a Slurm account and user when a user first logs in.
# It ensures that users are known to Slurm for accounting purposes.

# Check if the PAM user has a normal UID and if the script is running as root
if [[ $(id -u ${PAM_USER}) -ge 1000 ]] && [[ $(id -un) == "root" ]] ; then
        # Create a Slurm account named after the user's primary group
        sacctmgr -i create account $(id -gn ${PAM_USER}) || true
        # Create the Slurm user and associate them with the account
        sacctmgr -i create user ${PAM_USER} account=$(id -gn ${PAM_USER}) || true
fi
