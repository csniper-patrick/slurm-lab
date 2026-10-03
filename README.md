# Slurm Lab

Slurm Lab sets up a Slurm cluster environment on your computer with containers. You can use this environment to test, learn, and develop Slurm workflows. [Slurm](https://slurm.schedmd.com/) is an open-source workload manager that manages clusters and schedules jobs on Linux systems.

## Features

The cluster environment includes these capabilities:

* Multi-container Slurm cluster with controllers, a database, a client node, and compute nodes.
* Slurm REST API (`slurmrestd`) enabled for programmatic cluster access.
* Multiple Linux distributions for node images, including Rocky Linux 8, Rocky Linux 9, Debian 12, and Debian 13.
* Authentication with `auth/munge` by default or `auth/slurm`.
* Configuration controlled through the `.env` file.
* Multi-cluster and federation support with the `lyoko` Compose profile.
* Dynamic scaling for compute nodes.
* Rootless OCI container execution with Podman inside Slurm jobs.

### Plugins and Integrations

The client node includes JupyterHub and several tools:

* [jupyter-slurm](https://github.com/NERSC/jupyterlab-slurm.git) provides a dashboard interface for Slurm in JupyterLab.
* [jupyter-moss](https://github.com/silx-kit/jupyterhub_moss) starts JupyterHub user sessions as jobs on Slurm compute nodes.
* [slop](https://github.com/buzh/slop) displays Slurm jobs and cluster load in real time in the terminal.

## Cluster Components

The `compose.yml` file defines five primary services:

1. `controller` runs the primary Slurm control daemon (`slurmctld`). An optional `controller2` service provides high-availability testing.
2. `slurmdbd` runs the Slurm Database Daemon (`slurmdbd`) for job accounting.
3. `mariadb` runs the MariaDB database server for Slurm accounting storage.
4. `client` runs the submission node, JupyterHub, and `slurmrestd`.
5. `compute` runs worker nodes that execute the `slurmd` daemon.

## Getting Started

You can run the Slurm cluster locally with minimal setup. First make sure that your host machine has a compatible container engine installed. Then choose whether to start the cluster with pre-built container images or build images from source.

### Prerequisites

You need a container engine that supports the Compose specification. The primary configuration uses Podman with Docker Compose. You can also run the environment with standard Docker tools.

The recommended tools are:
* [Podman](https://podman.io/docs/installation)
* [Docker Compose](https://docs.docker.com/compose/install/)
* [Instructions for Podman with Docker Compose](https://podman-desktop.io/docs/compose/setting-up-compose)
* [Podman Desktop](https://podman-desktop.io/docs/installation) if you need a graphical interface

Alternative tools are:
* [Docker Desktop](https://docs.docker.com/desktop/)
* [Podman Compose](https://github.com/containers/podman-compose#installation)

### Quick Start with Pre-built Images

You can start the cluster with pre-built images from [Docker Hub](https://hub.docker.com/r/csniper/slurm-lab). This is the fastest way to get a running cluster. Follow these steps to start the cluster:

1. Clone the project repository:
   ```sh
   git clone https://gitlab.com/CSniper/slurm-lab.git
   cd slurm-lab
   ```

2. Start the cluster services:
   ```sh
   podman compose up -d
   ```
   If you use Docker, run:
   ```sh
   docker compose up -d
   ```

3. Optional: Select an image tag.
   The cluster uses the `latest` tag (Rocky Linux 9) by default. You can specify a different image by setting `TAG` in the `.env` file. See the [list of available tags](https://hub.docker.com/r/csniper/slurm-lab/tags).
   If you want to use the Debian image, add this line to `.env`:
   ```sh
   TAG=latest-deb
   ```
   If you use a private registry, set the `IMAGE` variable to the complete image reference:
   ```sh
   IMAGE=harbor.example.com/slurm/slurm-lab:latest
   ```
   When you set `IMAGE`, Compose ignores the `TAG` variable.

### Local Development from Source

You can build custom container images from source code. This workflow is useful when you modify Slurm source code, build scripts, or configuration files. Follow these steps to build and launch the cluster:

1. Clone the project with submodules:
   ```sh
   git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
   cd slurm-lab
   ```
   If you already cloned the repository without submodules, run:
   ```sh
   cd slurm-lab
   git submodule update --init --recursive
   ```

2. Generate the cryptographic keys for the build (optional if building with `make`, which auto-generates missing keys):
   ```bash
   # If step, jq, and openssl are installed locally:
   ./common/scripts/jwt-key-generation.sh common/secrets

   # Or using Podman:
   mkdir -pv common/secrets
   podman run --rm \
       -v ./common/secrets:/opt:Z \
       -v ./common/scripts/jwt-key-generation.sh:/jwt-key-generation.sh:Z \
       quay.io/rockylinux/rockylinux:10 /jwt-key-generation.sh /opt
   ```

3. Build the container images and start the cluster:
   Build your target image with `make <distro>`, for example `make el10`.
   Start the development cluster:
   ```sh
   make dev
   ```
   If you use Compose directly, run:
   ```sh
   MODE=dev podman compose up -d
   ```

### Developing with VS Code Dev Containers

You can develop inside the cluster with VS Code Dev Containers. The container workspace mounts the repository and provides preconfigured tools. Follow these steps to attach to the environment:

1. Install the Dev Containers extension in VS Code.
2. Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
3. Run `Dev Containers: Reopen in Container`.
4. VS Code starts the cluster services and opens a shell inside the `client` container at `/root/slurm-lab`.

## Makefile

The `Makefile` automates image builds and cluster operations. It runs required prerequisite steps, such as key generation, before starting any build. Build logs for each distribution are saved to `*-img-build.log` in the root directory.

The primary build targets are:
* `make build` builds container images for all supported distributions (`el8`, `el9`, `deb12`, `deb13`).
* `make <distro>` builds a specific image, for example `make el9`.
* `make ci` starts the cluster in CI mode (`MODE=ci`) to test controller and service initialization.
* `make clean` removes generated secret keys and build logs.
* `make prune` removes unused container images and volumes.

The workflow targets follow this sequence:
1. Run `make` to generate secret keys and build container images.
2. Run `make up` to start all services defined in `compose.yml`.
3. Run `make dev` to start the cluster with locally built images.
4. Run `make ci` to test the CI configuration locally.
5. Run `make down` to stop and remove all cluster containers.
6. Run `make clean` to remove generated keys and build logs.

If required JWT keys do not exist, the `Makefile` creates them before building images.

> [!NOTE]
> The build process writes logs to `*-img-build.log` in the root directory.

## Usage

Once the cluster starts, you can interact with Slurm through several interfaces. You can submit jobs via the command line or through web services. You can also monitor cluster state and scale nodes dynamically.

### Accessing JupyterHub

When the cluster is running, open [http://localhost:8080/](http://localhost:8080/) in your browser. If you configured a different port, use that port number instead. You can log in without a password with any of these user names: `jeremie`, `aelita`, `yumi`, `ulrich`, or `odd`.

### Submitting a Slurm Job

You can submit jobs from the JupyterHub terminal or with `podman exec`. The cluster supports both interactive jobs and batch script submissions. Follow the examples below to run jobs:

To run an interactive job with `srun`:
```sh
podman exec -it slurm-lab-client-1 srun --nodes=1 --ntasks=1 hostname
```

To submit a batch job script with `sbatch`, create `my_job.sh`:
```sh
#!/bin/bash
#SBATCH --job-name=my_test_job
#SBATCH --output=my_job_%j.out
#SBATCH --error=my_job_%j.err
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1

srun hostname
```

Copy the script to the client container and submit it:
```sh
podman cp my_job.sh slurm-lab-client-1:/tmp/my_job.sh
podman exec -it slurm-lab-client-1 sbatch /tmp/my_job.sh
```

### Scaling Compute Nodes

You can change the number of active worker nodes while the cluster runs. This allows you to test multi-node jobs with different worker counts. If you want to scale the cluster to six compute nodes, run:
```sh
podman compose up -d --scale compute=6 --no-recreate
```

### Accessing the Slurm REST API

The client container provides the Slurm REST API at `localhost:8080/slurm/v0.0.45`. If you changed the web port, use that port number instead. Read the official documentation for request authentication and endpoint details:
* [Slurm REST API Guide](https://slurm.schedmd.com/rest.html)
* [Slurm REST API Reference](https://slurm.schedmd.com/rest_api.html)

### Slurm Documentation

The client container serves documentation for the installed Slurm version at [http://localhost:8080/doc/](http://localhost:8080/doc/). If you configured a custom web port, replace `8080` with that port number. The local documentation matches the exact build version of Slurm running in your containers.

## Tutorials

The `tutorials/` directory contains interactive tutorial notebooks. You can open these notebooks in the JupyterHub web interface. The tutorials cover basic usage, parallel programming, and cluster administration:
* `Getting Started.ipynb` introduces basic Slurm commands and job management.
* `Admin Guide.ipynb` describes administrative tasks and cluster management.
* `MPI Guide.ipynb` shows how to execute parallel MPI jobs.
* `REST API Guide.ipynb` explains how to query the Slurm REST API.
* `scrontab Guide.ipynb` shows how to schedule recurring jobs with `scrontab`.
* `Multi-Cluster & Federation.ipynb` describes multi-cluster and federation setups.

## Configuration

You can configure the cluster by editing the `.env` file or exporting environment variables. The configuration file sets image tags, credentials, authentication plugins, and port bindings. Changes to `.env` take effect when you restart the cluster services:
* `TAG` specifies the container image tag from [Docker Hub](https://hub.docker.com/r/csniper/slurm-lab/tags).
* `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, and `MYSQL_RANDOM_ROOT_PASSWORD` set database credentials.
* `AUTHTYPE` sets the Slurm authentication plugin to `auth/munge` or `auth/slurm`.
* `JUPYTER_SPAWNER` controls how JupyterLab starts. Set this variable to `moss` to run user sessions as Slurm jobs.
* `PORT` specifies the host port for client web services. The default value is `8080`.

### Customizing the Web Port

The client container maps JupyterHub, Slurm documentation, and the REST API to port `8080` by default. You can change this port by setting `PORT` in `.env` or on the command line:

```sh
PORT=9000 make up
```

You can change the port for three reasons:
1. To run multiple cluster stacks at the same time without port conflicts.
2. To avoid conflicts when another local service already uses port `8080`.
3. To assign a random available port automatically by setting `PORT=0`. When services start, the `Makefile` prints the assigned port.

### Multi-Cluster and Federation with the Lyoko Profile

The project includes an optional secondary cluster named `lyoko`. Both clusters share the primary `slurmdbd` accounting database. You can activate the secondary cluster with the `lyoko` Compose profile:

If you use `make` in production mode:
```sh
make up COMPOSE_PROFILES=lyoko
```

If you use `make` in development mode:
```sh
make dev COMPOSE_PROFILES=lyoko
```

If you use Compose directly:
```sh
podman compose --profile lyoko up -d
```

If you want the `lyoko` profile enabled permanently, add this line to `.env`:
```sh
COMPOSE_PROFILES=lyoko
```

When the `lyoko` profile is active:
* `master-lyoko` runs the controller for the `lyoko` cluster and reads configuration from `.env-lyoko`.
* `compute-lyoko` runs worker nodes for the `lyoko` cluster. Set `COMPUTE_LYOKO_REPLICAS` to change worker counts.
* `tutorials/Multi-Cluster & Federation.ipynb` provides exercises for multi-cluster and federation features.

## Known Issues

The Debian container image does not support the `module` command inside Jupyter notebooks. If you need environment modules inside notebooks, use the Enterprise Linux images. Work is ongoing to enable environment modules across all supported distributions.

## Roadmap

Future releases will add tests for custom Slurm Lua scripts. These tests will cover burst buffers, job submission plugins, and job routing. We also plan to expand automated integration tests for rootless Podman execution.

## Contributing

We welcome contributions to this project. You can report bugs, suggest features, or submit code changes. Open an issue or submit a merge request on [GitLab](https://gitlab.com/CSniper/slurm-lab).

## License

This project uses the [BSD 3-Clause License](./LICENSE). You can read the full license text in the `LICENSE` file in the root directory. Third-party components retain their original licenses as described in their respective submodules.