#!/bin/bash -eux

if [[ $(id -u ${PAM_USER}) -ge 1000 ]] && [[ ${PAM_RUSER} == "root" ]] ; then
        sacctmgr -i create account $(id -gn ${PAM_USER}) || true
        sacctmgr -i create user ${PAM_USER} account=$(id -gn ${PAM_USER}) || true
fi