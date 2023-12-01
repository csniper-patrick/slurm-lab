#!/bin/bash
IFS=$'\n';
for notebook in $(git ls-tree --full-tree --name-only -r HEAD | grep -iE ".ipynb$"); do
    echo $(jupyter nbconvert --stdout --to notebook --clear-output "${notebook}" 2>/dev/null | md5sum | cut -d" " -f1)  ${notebook}
done | tee clear-notebook.md5sum
md5sum --check clear-notebook.md5sum || ( echo "Please clear output in all .ipynb file" && exit 1 ) 