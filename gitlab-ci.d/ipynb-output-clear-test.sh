#!/bin/bash
# This script verifies that all Jupyter notebooks (.ipynb) in the repository
# have their outputs cleared. This is used in CI/CD to keep the repository clean
# and minimize binary diffs in notebook files.

IFS=$'\n';
# Iterate through all notebooks in the HEAD commit
for notebook in $(git ls-tree --full-tree --name-only -r HEAD | grep -iE ".ipynb$"); do
    # Clear output in memory, calculate MD5 sum, and associate with filename
    echo $(jupyter nbconvert --stdout --to notebook --clear-output "${notebook}" 2>/dev/null | md5sum | cut -d" " -f1)  ${notebook}
done | tee /tmp/clear-notebook.md5sum

# Check if the current notebooks match the "cleared" MD5 sums
md5sum --check /tmp/clear-notebook.md5sum || ( echo "Error: Please clear output in all .ipynb files before committing." && exit 1 ) 
