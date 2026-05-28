#!/bin/bash
# This tutorial script represents a "cleanup" task in a job dependency chain.
# It displays accounting information for the current user and then sleeps.

# Get the current username from the environment
USER_NAME=${USER:-$(id -un)}

echo "Cleanup task: Displaying Slurm accounting records for user '${USER_NAME}'"

sacct --user "${USER_NAME}"

# Sleep to allow for observation
sleep 30
