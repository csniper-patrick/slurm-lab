#!/bin/bash -x
# This script builds and installs 'slop' (Slurm Output monitor) from source.

# 1. Root Elevation: Ensure the script runs as root
if [[ $EUID -ne 0 ]]; then
   echo "Requesting root privileges..."
   exec sudo "$0" "$@"
fi

# 2. Clone project if it doesn't already exist in /usr/local/src
[[ -d /usr/local/src/slop ]] || git clone https://github.com/buzh/slop.git /usr/local/src/slop

# 3. Build and install using a Python virtual environment and PyInstaller
cd /usr/local/src/slop
python3 -m venv .
source /usr/local/src/slop/bin/activate
pip install -r slop/requirements.txt
pip install pyinstaller

# Create a single-file executable using PyInstaller
pyinstaller --collect-all=urwid --onefile slop/main.py -n slop

# Install the executable to /usr/local/bin
cp /usr/local/src/slop/dist/slop /usr/local/bin/
