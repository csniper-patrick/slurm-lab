# Slurm Lab

## Project Overview

This project provides a complete Slurm cluster environment using containers, ideal for testing, learning, and development. It sets up a multi-container Slurm cluster with controllers, a database, a client node, and compute nodes. The environment is highly customizable, supporting different base operating systems, authentication methods, and scaling of compute nodes.

The core technologies used are:

*   **Slurm:** An open-source cluster management and job scheduling system.
*   **Docker/Podman:** For containerization.
*   **Docker Compose:** For defining and running the multi-container application.
*   **JupyterHub:** Integrated into the client node for an interactive environment.
*   **MariaDB:** Used as the database for Slurm accounting.

The project is structured to allow for both using pre-built images from Docker Hub and building the images locally from source. The source code for Slurm and Open MPI are included as Git submodules.

## Building and Running

### Using Pre-built Images

The fastest way to get the Slurm lab running is by using the pre-built images from Docker Hub.

1.  **Start the cluster:**
    ```sh
    podman compose up -d
    ```
    *(Use `docker-compose` if you are using Docker).*

2.  **Select an image tag (Optional):**
    By default, the cluster uses the `latest` tag (Rocky Linux 9). You can use a different image by specifying the `TAG` in the `.env` file. For example, to use the Debian-based image, add this line to your `.env` file:
    ```
    TAG=latest-deb
    ```

### Building from Source

If you want to modify the project or build the container images locally, you can use the provided `Makefile`.

1.  **Prepare the project (clone with submodules):**
    ```sh
    git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
    cd slurm-lab
    ```

2.  **Build the container images:**
    The `Makefile` can build images for different Linux distributions. To build all default distributions:
    ```sh
    make build
    ```
    To build for a specific distribution (e.g., `deb12`):
    ```sh
    make deb12
    ```

3.  **Start the cluster with local images:**
    Use the `compose.dev.yml` file, which is configured to build the images from the local source code.
    ```sh
    podman compose -f compose.dev.yml up -d --build
    ```

### Running Tests

The project has a CI/CD pipeline defined in `.gitlab-ci.yml` that runs tests. To run the tests locally, you would need to replicate the steps in the `test` stage of the CI pipeline. The `gitlab-ci.d/test.yml` file contains the test definitions.

## Development Conventions

*   **Containerization:** The project is fully containerized, and the environment is defined in `compose.yml` and `compose.dev.yml`.
*   **Configuration:** The cluster is configured through the `.env` file.
*   **CI/CD:** The `.gitlab-ci.yml` file defines the CI/CD pipeline for building, testing, and deploying the container images.
*   **Submodules:** The project uses Git submodules to include the source code for Slurm and Open MPI.
*   **Building:** The `Makefile` provides a convenient way to build the container images for different distributions.
*   **Branching:** The CI pipeline is configured to build and tag images based on the Git branch.
