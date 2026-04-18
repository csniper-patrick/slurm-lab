#!/bin/bash -x

# 1. Root Elevation
if [[ $EUID -ne 0 ]]; then
   echo "Requesting root privileges..."
   exec sudo "$0" "$@"
fi

# 2. clone project if not exist
[[ -d /opt/slop ]] || git clone https://github.com/buzh/slop.git /opt/slop

# 3. build and install
cd /opt/slop
python3 -m venv .venv
source .venv/bin/activate
pip install -r slop/requirements.txt
pip install pyinstaller
pyinstaller --hidden-import=urwid.display.html_fragment --hidden-import=urwid.display.lcd --collect-all=urwid --onefile slop/main.py -n slop
cp dist/slop /usr/local/bin/