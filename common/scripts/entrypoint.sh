#!/bin/bash -x
# Main entrypoint script for the Slurm Lab containers.
# This script handles dynamic configuration generation from Jinja2 templates
# and enables the necessary systemd services based on the container's role.

ENV_ROOT=$(dirname ${0})

# Function to generate configuration files from templates
generate_config () {
    # Generate slurmdbd.conf (Slurm Database Daemon)
    [[ -f /etc/slurm/slurmdbd.conf ]] || ${ENV_ROOT}/bin/jinja2 \
        -D JWKS=${JWKS:="/etc/slurm/jwks.pub.json"} \
        ${MYSQL_DATABASE:+-D MYSQL_DATABASE="${MYSQL_DATABASE}"} \
        ${MYSQL_USER:+-D MYSQL_USER="${MYSQL_USER}"} \
        ${MYSQL_PASSWORD:+-D MYSQL_PASSWORD="${MYSQL_PASSWORD}"} \
        ${SLURMDB_PRIVATEDATA:+-D PRIVATEDATA="${SLURMDB_PRIVATEDATA}"} \
        ${AUTHTYPE:+-D AUTHTYPE="${AUTHTYPE}"} \
        ${ENV_ROOT}/slurmdbd.conf.j2 > /etc/slurm/slurmdbd.conf

    # Generate slurm.conf (Main Slurm configuration)
    [[ -f /etc/slurm/slurm.conf ]] || ${ENV_ROOT}/bin/jinja2 \
        -D JWKS=${JWKS:="/etc/slurm/jwks.pub.json"} \
        ${SLURM_PRIVATEDATA:+-D PRIVATEDATA="${SLURM_PRIVATEDATA}"} \
        ${SLURMCTLDHOST:+-D SLURMCTLDHOST="${SLURMCTLDHOST}"} \
        ${CLUSTERNAME:+-D CLUSTERNAME="${CLUSTERNAME}"} \
        ${AUTHTYPE:+-D AUTHTYPE="${AUTHTYPE}"} \
        ${ENV_ROOT}/slurm.conf.j2 > /etc/slurm/slurm.conf

    # Generate cgroup.conf (Slurm cgroup configuration)
    [[ -f /etc/slurm/cgroup.conf ]] || ${ENV_ROOT}/bin/jinja2 \
        ${CGROUP_CONSTRAINCORES:+-D CGROUP_CONSTRAINCORES="${CGROUP_CONSTRAINCORES}"} \
        ${CGROUP_CONSTRAINDEVICES:+-D CGROUP_CONSTRAINDEVICES="${CGROUP_CONSTRAINDEVICES}"} \
        ${CGROUP_CONSTRAINRAMSPACE:+-D CGROUP_CONSTRAINRAMSPACE="${CGROUP_CONSTRAINRAMSPACE}"} \
        ${CGROUP_CONSTRAINSWAPSPACE:+-D CGROUP_CONSTRAINSWAPSPACE="${CGROUP_CONSTRAINSWAPSPACE}"} \
        ${ENV_ROOT}/cgroup.conf.j2 > /etc/slurm/cgroup.conf

    # Generate Ansible inventory for node discovery
    [[ -f /etc/ansible/inventory/01-nmap.yaml ]] || ${ENV_ROOT}/bin/jinja2 \
        -D GATEWAY=$(ip route | grep default | head -1 | awk '{print $3}') \
        -D SUBNET=$(ip route | grep -v default | head -1 | awk '{print $1}') \
        ${ENV_ROOT}/01-nmap.yaml.j2 > /etc/ansible/inventory/01-nmap.yaml

    # Ensure correct file permissions and ownership for Slurm
    chown -R slurm:slurm /etc/slurm /var/spool/slurmctld
    chmod 0600 /etc/slurm/slurmdbd.conf /etc/slurm/slurm.jwks
    
    # Configure JupyterHub spawner if specified
    mkdir -pv /etc/sysconfig/
    [[ -z ${JUPYTER_SPAWNER} ]] || echo "JUPYTER_SPAWNER=${JUPYTER_SPAWNER}" > /etc/sysconfig/jupyter-hub 
}

# Function to enable systemd services based on the hostname
enable_services () {
    HOSTNAME=$(hostname)
    
    # Enable Slurm Database and REST services if this is the database host
    ( grep -E "^(DbdHost|DbdBackupHost)=" /etc/slurm/slurmdbd.conf | cut -d"=" -f2 | grep -q ${HOSTNAME} ) && ln -sf /usr/lib/systemd/system/{slurmdbd,slurmrestd}.service /etc/systemd/system/multi-user.target.wants/
    
    # Enable Slurm Control daemon if this is the controller host
    ( grep -E "^SlurmctldHost=" /etc/slurm/slurm.conf | cut -d"=" -f2 | grep -q ${HOSTNAME} ) && ln -sf /usr/lib/systemd/system/slurmctld.service /etc/systemd/system/multi-user.target.wants/
    
    # Enable client-specific services (Nginx, JupyterHub, SACKD)
    [[ ${HOSTNAME} =~ ^slurm-lab-client.*$ ]] && ln -sf /usr/lib/systemd/system/{nginx,jupyter-hub,sackd}.service /etc/systemd/system/multi-user.target.wants/
    
    # Enable the Slurm compute daemon (slurmd) on all compute nodes
    # Assuming compute nodes don't follow the 'slurm-lab' hostname pattern (which is used for controller/client)
    [[ ${HOSTNAME} =~ ^slurm-lab.*$ ]] || ln -sf /usr/lib/systemd/system/slurmd.service /etc/systemd/system/multi-user.target.wants/
}

# Run configuration generation and service enablement
generate_config && enable_services

# Start systemd as the init process
exec /sbin/init
