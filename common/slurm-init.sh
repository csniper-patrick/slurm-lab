#!/bin/bash
ENV_ROOT=$(dirname ${0})

# Generate slurmdbd.conf
${ENV_ROOT}/bin/jinja2 \
    -D MYSQL_DATABASE="${MYSQL_DATABASE}" \
    -D MYSQL_USER="${MYSQL_USER}" \
    -D MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
    ${ENV_ROOT}/slurmdbd.conf.j2 > /etc/slurm/slurmdbd.conf

# Generate slurm.conf
${ENV_ROOT}/bin/jinja2 ${ENV_ROOT}/slurm.conf.j2 > /etc/slurm/slurm.conf

# Generate cgroup.conf
${ENV_ROOT}/bin/jinja2 \
    -D CGROUP_CONSTRAINCORES="${CGROUP_CONSTRAINCORES}" \
    -D CGROUP_CONSTRAINDEVICES="${CGROUP_CONSTRAINDEVICES}" \
    -D CGROUP_CONSTRAINRAMSPACE="${CGROUP_CONSTRAINRAMSPACE}" \
    -D CGROUP_CONSTRAINSWAPSPACE="${CGROUP_CONSTRAINSWAPSPACE}" \
    ${ENV_ROOT}/cgroup.conf.j2 > /etc/slurm/cgroup.conf

# ensure file permission and ownership 
chown -R slurm:slurm /etc/slurm /var/spool/slurmctld
chmod 0600 /etc/slurm/slurmdbd.conf
