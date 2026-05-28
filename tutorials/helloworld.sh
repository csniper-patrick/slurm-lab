#!/bin/bash -x
# This is a very basic "Hello World" script for Slurm testing.
# It prints some system information and then sleeps indefinitely.

echo "Hello World!"

# Print hostname aliases
hostname -a

# Print kernel information
uname -a

# Print current date and time
date

# Sleep forever to keep the Slurm job active for inspection
sleep infinity
