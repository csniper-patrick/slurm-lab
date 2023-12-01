#!/bin/bash
ENV_ROOT=$(dirname ${0})

# Generate slurmdbd.conf
${ENV_ROOT}/bin/jinja2 \
    -D MYSQL_DATABASE="${MYSQL_DATABASE}" \
    -D MYSQL_USER="${MYSQL_USER}" \
    -D MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
    -D JWKS=${JWKS:="/etc/slurm/jwks.pub.json"} \
    -D PRIVATEDATA="${SLURMDB_PRIVATEDATA}" \
    ${ENV_ROOT}/slurmdbd.conf.j2 > /etc/slurm/slurmdbd.conf

# Generate slurm.conf
${ENV_ROOT}/bin/jinja2 \
    -D JWKS=${JWKS:="/etc/slurm/jwks.pub.json"} \
    -D PRIVATEDATA="${SLURM_PRIVATEDATA}" \
    ${ENV_ROOT}/slurm.conf.j2 > /etc/slurm/slurm.conf

# Generate cgroup.conf
${ENV_ROOT}/bin/jinja2 \
    -D CGROUP_CONSTRAINCORES="${CGROUP_CONSTRAINCORES}" \
    -D CGROUP_CONSTRAINDEVICES="${CGROUP_CONSTRAINDEVICES}" \
    -D CGROUP_CONSTRAINRAMSPACE="${CGROUP_CONSTRAINRAMSPACE}" \
    -D CGROUP_CONSTRAINSWAPSPACE="${CGROUP_CONSTRAINSWAPSPACE}" \
    ${ENV_ROOT}/cgroup.conf.j2 > /etc/slurm/cgroup.conf

# Generate ansible inventory
${ENV_ROOT}/bin/jinja2 \
    -D GATEWAY=$(ip route | grep default | head -1 | awk '{print $3}') \
    -D SUBNET=$(ip route | grep -v default | head -1 | awk '{print $1}') \
    ${ENV_ROOT}/01-nmap.yaml.j2 > /etc/ansible/inventory/01-nmap.yaml

# ensure file permission and ownership 
chown -R slurm:slurm /etc/slurm /var/spool/slurmctld
chmod 0600 /etc/slurm/slurmdbd.conf
