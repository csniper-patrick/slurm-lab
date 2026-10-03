# Slurm Lab Overview

## System Overview & Architecture

Slurm Lab provides a containerized Slurm cluster environment for testing, learning, and development. The environment runs a multi-container cluster that includes Slurm controllers, a Slurm accounting database daemon, a MariaDB database server, a client node with interactive services, and scalable compute nodes.

### Core Technologies

* **Slurm:** Open-source cluster management and job scheduling system for Linux clusters.
* **Podman / Docker:** Container engines for local container execution.
* **Docker Compose:** Multi-container application orchestration tool.
* **MariaDB:** Relational database backend for Slurm accounting records.
* **JupyterHub:** Interactive web portal running on the client node.

### Cluster Services Topology

The multi-container cluster is defined in `compose.yml` and consists of:

* `controller` (`slurm-lab-controller`): Primary Slurm controller daemon (`slurmctld`). An optional secondary controller (`controller2`) supports high-availability testing.
* `slurmdbd` (`slurm-lab-slurmdbd`): Slurm Database Daemon for job accounting and cluster record keeping.
* `mariadb` (`slurm-lab-mariadb`): MariaDB database backend for SlurmDBD.
* `client` (`slurm-lab-client`): Cluster interaction node hosting JupyterHub, `slurmrestd`, and client toolchains.
* `compute` (`slurm-lab-compute`): Scalable worker nodes running the `slurmd` daemon.

### Directory Structure & Submodules

Core third-party dependencies are tracked as Git submodules in the `modules/` directory:

* `modules/slurm`: Upstream Slurm source code.
* `modules/ompi`: Open MPI source code.
* `modules/slop`: Terminal load and cluster monitoring utility.

Base image build definitions reside in:
* `build-deb12/`, `build-deb13/`: Debian Bookworm and Trixie container build contexts.
* `build-el8/`, `build-el9/`, `build-el10/`: Enterprise Linux (Rocky Linux) container build contexts.
* `common/`: Shared configuration files, secrets, entrypoint scripts, and PAM modules.
* `tutorials/`: Jupyter notebooks demonstrating cluster usage, administration, MPI, REST APIs, and federation.

### Core Capabilities

* **Multi-Distribution Support:** Container images can be built for Debian (12, 13) and Enterprise Linux (8, 9, 10).
* **GPU Integration:** NVIDIA (NVML) and AMD (ROCm) GPU support available in Debian-based images.
* **Metrics Integration:** Prometheus-compatible `/metrics` endpoints available via `MetricsType=metrics/openmetrics` and `MetricsParameters=ignore_private_data`.
* **Automated User Management:** Pluggable Authentication Modules (PAM) automatically register new user accounts in Slurm upon first login.
* **Rootless Podman Support:** Allows running rootless OCI containers inside Slurm jobs using a custom staging mechanism.
* **Interactive Tooling:** Web-based JupyterLab environment with `jupyter-slurm` and `jupyter-moss` integration.

