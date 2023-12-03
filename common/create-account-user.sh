#!/bin/bash -u

if [[ $(id -u ${PAM_USER}) -ge 1000 ]] && [[ $(id -un) == "root" ]] ; then
        sacctmgr -i create account $(id -gn ${PAM_USER}) || true
        sacctmgr -i create user ${PAM_USER} account=$(id -gn ${PAM_USER}) || true
fi