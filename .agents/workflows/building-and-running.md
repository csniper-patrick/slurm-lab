# Building and Running the Slurm Cluster

This workflow describes how to build, configure, and start the Slurm Lab cluster.

## Using Pre-built Images

Using pre-built images from Docker Hub is the fastest way to run the cluster.

1. **Start the cluster:**
   ```sh
   make up
   # Or directly using Podman:
   podman compose up -d
   ```
   *(Use `docker compose` or `docker-compose` if using Docker).*

2. **Select an image tag (Optional):**
   By default, the cluster uses the `latest` tag (Rocky Linux 9). To select a different distribution image, set `TAG` in `.env`:
   ```sh
   # Example: Use Debian Bookworm
   TAG=latest-deb
   ```

## Building from Source

Build container images locally if you modify Slurm source code, build recipes, or configurations.

1. **Prepare the repository with submodules:**
   ```sh
   git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
   cd slurm-lab
   # If already cloned without submodules:
   git submodule update --init --recursive
   ```

2. **Generate required cryptographic keys:**
   The `Makefile` automatically generates required JWT secrets before builds. If running manually:
   ```sh
   mkdir -pv common/secrets
   podman run --rm -it \
       -v ./modules/json-web-key-generator:/json-web-key-generator \
       -v ./common/secrets:/opt \
       -v ./common/scripts/jwt-key-generation.sh:/jwt-key-generation.sh \
       docker.io/library/maven:3.8.7-openjdk-18-slim /jwt-key-generation.sh
   ```

3. **Build the container images:**
   Build all supported target distributions:
   ```sh
   make build
   ```
   Or build an image for a specific distribution:
   * Debian Bookworm (12): `make deb12`
   * Debian Trixie (13): `make deb13`
   * Enterprise Linux 8: `make el8`
   * Enterprise Linux 9: `make el9`
   * Enterprise Linux 10: `make el10`

4. **Start the cluster in development mode:**
   After building the local images, launch the cluster in development mode (`MODE=dev`):
   ```sh
   make dev
   # Or directly with compose:
   MODE=dev podman compose up -d
   ```

## Stopping the Cluster

* Gracefully stop all running containers:
  ```sh
  make down
  # Or:
  podman compose down
  ```
* Remove generated secrets and build logs:
  ```sh
  make clean
  ```

