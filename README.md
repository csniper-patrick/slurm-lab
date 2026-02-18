# Slurm Lab

This project provides an easy way to set up a complete Slurm cluster environment on your personal computer using containers. It's perfect for testing, learning, and development purposes.

[Slurm](https://slurm.schedmd.com/) is an open-source, fault-tolerant, and highly scalable cluster management and job scheduling system for Linux clusters.

## Features

*   **Complete Cluster Environment**: Sets up a multi-container Slurm cluster with controllers, a database, a client node, and compute nodes.
*   **JupyterHub Integration**: Includes a JupyterHub instance on the client node for an interactive environment.
*   **Slurm REST API**: The Slurm REST API (`slurmrestd`) is enabled for programmatic access to the cluster.
*   **Choice of OS**: Supports different base OS for the cluster nodes (e.g., Rocky Linux 8/9, Debian 12/13).
*   **Flexible Authentication**: Choose between `auth/munge` (default) and `auth/slurm` for cluster authentication.
*   **Customizable**: Easily configured through a `.env` file.
*   **Federation & Multi Cluster**: Supports federated and multi-cluster environment can be enable but simply uncomment the relevant section in `compose.yml`.
*   **Scalable**: Compute nodes can be scaled up or down on the fly.

## Cluster Components

The cluster consists of the following services, defined in the `compose.yml` file:

1.  **`controller`**: Runs the Slurm control daemon (`slurmctld`). A second controller `controller2` is also available for high-availability testing.
2.  **`slurmdbd`**: Runs the Slurm Database Daemon (`slurmdbd`) for accounting.
3.  **`mariadb`**: A MariaDB database server for Slurm accounting.
4.  **`client`**: A submission node that also hosts JupyterHub and `slurmrestd`. This is your main entry point for interacting with the cluster.
5.  **`compute`**: N (default 4) compute nodes running the `slurmd` daemon.

## Getting Started

### Prerequisites

You need a container engine that supports the Compose specification. The recommended setup is **Podman** with **Docker Compose**.

-   **Recommended:**
    -   [Podman](https://podman.io/docs/installation)
    -   [Docker Compose](https://docs.docker.com/compose/install/) (can be used with Podman)
    -   [Setting Podman to use Docker-compose](https://podman-desktop.io/docs/compose/setting-up-compose)
    -   *Optional:* [Podman Desktop](https://podman-desktop.io/docs/installation) for a graphical interface.

-   **Alternatives:**
    -   [Docker Desktop](https://docs.docker.com/desktop/) (includes Docker and Docker Compose).
    -   [Podman Compose](https://github.com/containers/podman-compose#installation) (less recommended due to container dependency issues).

### Quick Start (Using Pre-built Images)

This is the fastest way to get your Slurm lab running using images from [Docker Hub](https://hub.docker.com/r/csniper/slurm-lab).

1.  **Clone the project:**
    ```sh
    git clone https://gitlab.com/CSniper/slurm-lab.git
    cd slurm-lab
    ```

2.  **Start the cluster:**
    ```sh
    podman compose up -d
    ```
    *(Use `docker-compose` if you are using Docker).*

3.  **Select an image tag (Optional):**
    By default, the cluster uses the `latest` tag (Rocky Linux 9). You can use a different image by specifying the `TAG` in the `.env` file. See the [list of available tags](https://hub.docker.com/r/csniper/slurm-lab/tags).

    For example, to use the Debian-based image, add this line to your `.env` file:
    ```
    TAG=latest-deb
    ```

### Local Development (Building from Source)

If you want to modify the project or build the container images locally, follow these steps.

1.  **Prepare the project (clone with submodules):**
    If you are cloning the project for the first time:
    ```sh
    git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
    cd slurm-lab
    ```
    If you have already cloned the project without submodules:
    ```sh
    cd slurm-lab
    git submodule update --init --recursive
    ```
2.  **Create keys required for the build:**
    ```bash
    mkdir -pv common/secrets
    podman run --rm -it \
        -v ./json-web-key-generator:/json-web-key-generator \
        -v ./common/secrets:/opt \
        -v ./common/scripts/jwt-key-generation.sh:/jwt-key-generation.sh \
        docker.io/library/maven:3.8.7-openjdk-18-slim /jwt-key-generation.sh
    ```
3.  **Build and start the cluster:**
    Use the `compose.dev.yml` file, which is configured to build the images from the local source code.
    ```sh
    podman compose -f compose.dev.yml up -d --build
    ```

## Makefile

This project includes a `Makefile` that simplifies building images and managing the development environment.

*   **`make build`**: Build all container images for the available distributions (e.g., `el8`, `el9`, `deb12`, `deb13`). This is the default target.
*   **`make <distro>`**: Build a specific image, e.g., `make el9`.
*   **`make clean`**: Removes generated files, including JWT keys.
*   **`make prune`**: Prunes unused container images.

The `Makefile` will automatically generate the required JWT keys if they are not present.

## Usage

### Accessing JupyterHub

Once the cluster is running, you can access the JupyterHub environment at [http://localhost:8080/](http://localhost:8080/).

You can log in with one of the following usernames (no password needed): `jeremie`, `aelita`, `yumi`, `ulrich`, `odd`.
*(These are characters from the show [Code Lyoko](https://en.wikipedia.org/wiki/Code_Lyoko)).*

### Submitting a Slurm Job

You can submit jobs from the terminal within JupyterHub or by using `podman exec`.

**Example using `srun`:**
```sh
podman exec -it slurm-lab-client-1 srun --nodes=1 --ntasks=1 hostname
```

**Example using `sbatch`:**
Create a batch script `my_job.sh`:
```sh
#!/bin/bash
#SBATCH --job-name=my_test_job
#SBATCH --output=my_job_%j.out
#SBATCH --error=my_job_%j.err
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1

srun hostname
```
Submit the job from the client container:
```sh
podman cp my_job.sh slurm-lab-client-1:/tmp/my_job.sh
podman exec -it slurm-lab-client-1 sbatch /tmp/my_job.sh
```

### Scaling Compute Nodes

You can easily change the number of active compute nodes. For example, to scale up to 6 nodes:
```sh
podman compose up -d --scale compute=6 --no-recreate
```

### Accessing the Slurm REST API

The Slurm REST API is available through the client container. The service is exposed on the host at `localhost:8080/slurm/v0.0.44` (the exact version may differ).

Please refer to the official documentation for authenticating your requests and for API usage:
-   [Slurm REST API Guide](https://slurm.schedmd.com/rest.html)
-   [API Reference](https://slurm.schedmd.com/rest_api.html)

### Slurm Documentation

The official documentation for the version of Slurm installed in the container is available at [http://localhost:8080/doc/](http://localhost:8080/doc/).

## Tutorials

This project includes a set of tutorials in the `tutorials/` directory to help you get started with Slurm and the lab environment. You can access them through the JupyterHub interface.

*   **`Getting Started.ipynb`**: A good starting point for new users.
*   **`Admin Guide.ipynb`**: Covers administrative tasks and cluster setup.
*   **`MPI Guide.ipynb`**: Demonstrates how to run MPI jobs.
*   **`REST API Guide.ipynb`**: Shows how to interact with the Slurm REST API.
*   **`scrontab Guide.ipynb`**: Explains how to use `scrontab` for scheduling recurring jobs.
*   **`Multi-Cluster & Federation.ipynb`**: A guide to setting up and using the multi-cluster and federation features.

## Configuration

You can customize the cluster by setting variables in the `.env` file.

*   `TAG`: The Docker image tag to use (e.g., `latest`, `latest-deb`). See available tags on [Docker Hub](https://hub.docker.com/r/csniper/slurm-lab/tags).
*   `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_RANDOM_ROOT_PASSWORD`: Required credentials for the MariaDB database.
*   `AUTHTYPE`: The Slurm authentication plugin. Can be `auth/munge` (default) or `auth/slurm`. Setting it to `auth/slurm` removes the need for the `munge` daemon.
*   `JUPYTER_SPAWNER`: By default, JupyterLab sessions are spawned inside the `client` container. Set this to `moss` to use the [JupyterHub MOdular Slurm Spawner (moss)](https://github.com/silx-kit/jupyterhub_moss), which runs each JupyterLab session as a Slurm job on a compute node.

## Known Issues

*   The `module` command is not available in Jupyter Notebooks running on the Debian based image.
*   Rocky 10 image is built but with ugly workaround.
    *   The `http-parser` dependency has not been updated to `llhttp` (see [Replace http-parser dependency with llhttp](https://support.schedmd.com/show_bug.cgi?id=21801))
    *   The `libjwt` shipped in Rocky 10 made `jwt_Base64encode` private, causing symbol lookup error.
    *   The image is built by snatching `http-parser`, `http-parser-devel`, `libjwt`, and `libjwt-devel` package from the rocky 9 repository. Hence, I will not make the el10 image the default for el yet, hopefully these issue are resolved soon.

## Roadmap

*   Feature testing for Lua scripts (burst buffer, job submission plugins, routing).
*   Explore Slurm's Podman integration.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a merge request on [GitLab](https://gitlab.com/CSniper/slurm-lab).

## License

This project is licensed under the [BSD 3-Clause License](./LICENSE).