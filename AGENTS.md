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
    make up
    # Or directly:
    podman compose up -d
    ```
    *(Use `docker compose` or `docker-compose` if you are using Docker).*

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
    The `Makefile` supports building images for several Linux distributions:
    *   **Debian:** `deb12` (Bookworm), `deb13` (Trixie)
    *   **Rocky Linux / EL:** `el8`, `el9`, `el10`

    To build all default distributions:
    ```sh
    make build
    ```
    To build for a specific distribution (e.g., `deb12`):
    ```sh
    make deb12
    ```

3.  **Start the cluster in development mode:**
    Local images should first be built with `make <distro>` (e.g., `make el10`). Run `make dev` or set `MODE=dev` with Compose to start the cluster:
    ```sh
    make dev
    # Or directly with compose:
    MODE=dev podman compose up -d
    ```

## Multi-Cluster & Federation (Lyoko Profile)

The lab supports a secondary cluster named **`lyoko`** to test Slurm multi-cluster configurations and federations that share the primary accounting database (`slurmdbd`).

Multi-cluster services are managed using the Compose profile **`lyoko`**, eliminating the need to manually edit compose files:

*   **Starting with `make`:**
    ```sh
    # In production / default mode:
    make up COMPOSE_PROFILES=lyoko

    # In development mode (local images):
    make dev COMPOSE_PROFILES=lyoko
    ```

*   **Starting with `podman compose` directly:**
    ```sh
    podman compose --profile lyoko up -d
    # Or in development mode:
    MODE=dev podman compose --profile lyoko up -d
    ```

*   **Starting via `.env`:**
    Add or uncomment in `.env`:
    ```sh
    COMPOSE_PROFILES=lyoko
    ```
    Then run `make up` or `make dev` as normal.

### Secondary Cluster Architecture
*   **`master-lyoko` (`slurm-lab-master-lyoko`)**: Slurm controller for the `lyoko` cluster, configured via `.env-lyoko`.
*   **`compute-lyoko`**: Compute node for the `lyoko` cluster. The replica count can be configured using `COMPUTE_LYOKO_REPLICAS` (default: `1`).
*   See `tutorials/Multi-Cluster & Federation.ipynb` for hands-on exercises and federation verification.

## Core Features & Configuration

*   **Multi-Distribution Support:** Build and run the Slurm cluster on various base OSs (Debian 12/13, Rocky Linux 8/9/10).
*   **GPU Support:** Built-in support for NVIDIA (NVML) and AMD (ROCm) GPUs in the Debian-based images.
*   **Metrics Integration:** Prometheus-compatible `/metrics` endpoints are available. Configure `MetricsType=metrics/openmetrics` and `MetricsParameters=ignore_private_data` in `slurm.conf` to enable them without compromising `PrivateData`.
*   **Automated User Management:** Integrated PAM modules automatically create Slurm accounts and users upon first login.
*   **Interactive Environment:** JupyterHub is pre-installed on the client node for a seamless interactive experience.
*   **Federation & Multi-Cluster:** Test multi-cluster configurations and federations using the built-in `lyoko` Compose profile.
*   **Comprehensive Tutorials:** A rich set of Jupyter notebooks and bash scripts in the `tutorials/` directory covers basic usage, MPI jobs, job dependencies, and administrative tasks.

## Running Tests

The project has a CI/CD pipeline defined in `.gitlab-ci.yml` that runs tests.
*   To test the CI stack locally with Compose:
    ```sh
    make ci
    # Or directly:
    MODE=ci podman compose up -d
    ```
*   The `gitlab-ci.d/test.yml` and `gitlab-ci.d/container-build.yml.j2` files contain the full CI pipeline and test definitions.
*   **CI Topology Intent:** In CI mode (`MODE=ci` / `COMPOSE_PROFILES=ci`), only controllers and service daemons are tested (`master-lyoko` is included in the `ci` profile to verify multi-cluster/federation initialization, while compute workers `compute` and `compute-lyoko` are scaled to 0 or omitted to conserve CI resources).

## Development Conventions

*   **Containerization:** The project is fully containerized, defined in a single unified `compose.yml` supporting `MODE=prod`, `MODE=dev`, and `MODE=ci`, alongside Compose profiles (such as `lyoko`).
*   **Configuration:** The cluster is configured through the `.env` file (and `.env-lyoko` for the secondary cluster).
*   **CI/CD:** The `.gitlab-ci.yml` file defines the CI/CD pipeline for building, testing, and deploying the container images.
*   **Submodules:** All core dependencies (Slurm, Open MPI, Slop, JSON Web Key Generator) are included as Git submodules located in the `modules/` directory.
*   **Building:** The `Makefile` provides a convenient way to build container images for different distributions and run different cluster modes.
*   **Documentation:** Core utility scripts and tutorial scripts are systematically documented with descriptive headers and inline comments.
*   **Branching:** The CI pipeline is configured to build and tag images based on the Git branch.

## Agent Coding Rules

These rules apply to every task in this project unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

*   **Rule 1 — Think Before Coding:**
    *   State assumptions explicitly. If uncertain, ask rather than guess.
    *   Present multiple interpretations when ambiguity exists.
    *   Push back when a simpler approach exists.
    *   Stop when confused. Name what's unclear.
*   **Rule 2 — Simplicity First:**
    *   Minimum code that solves the problem. Nothing speculative.
    *   No features beyond what was asked. No abstractions for single-use code, scripts, or configurations.
    *   Test: would a senior engineer say this is overcomplicated? If yes, simplify.
*   **Rule 3 — Surgical Changes:**
    *   Touch only what you must. Clean up only your own mess.
    *   Don't "improve" adjacent code, playbooks, comments, or formatting.
    *   Don't refactor what isn't broken. Match existing style.
*   **Rule 4 — Goal-Driven Execution:**
    *   Define success criteria. Loop until verified.
    *   Don't follow steps blindly. Define success and iterate.
    *   Strong success criteria let you loop independently.
*   **Rule 5 — Leverage the model's strengths:**
    *   Use me for: large-scale context analysis, multi-modal data extraction, architectural drafting, and cross-file summarization.
    *   Do NOT use me for: deterministic transforms, executing pipelines, or tasks where simple scripts suffice.
    *   If a native tool or code can answer, let it.
*   **Rule 6 — Context is vast, but focus is critical:**
    *   While my context window is massive, do not unnecessarily bloat it with irrelevant logs or unrelated data dumps.
    *   If the project shifts to a completely new domain, summarize the current state and start fresh to maintain absolute precision.
    *   Surface any context drift. Do not silently lose track of the core objective.
*   **Rule 7 — Surface conflicts, don't average them:**
    *   If two patterns or configurations contradict, pick one (more recent / more tested).
    *   Explain why. Flag the other for cleanup.
    *   Don't blend conflicting architectures or patterns.
*   **Rule 8 — Read before you write:**
    *   Before adding code, read exports, immediate callers, shared utilities, and relevant deployment pipelines.
    *   "Looks orthogonal" is dangerous. If unsure why code or infrastructure is structured a certain way, ask.
*   **Rule 9 — Tests verify intent, not just behavior:**
    *   Tests (and CI checks) must encode WHY behavior matters, not just WHAT it does.
    *   A test that can't fail when business logic or system state changes is wrong.
*   **Rule 10 — Checkpoint after every significant step:**
    *   Summarize what was done, what's verified, what's left.
    *   Don't continue from a state you can't describe back.
    *   If you lose track of the state, stop and restate.
*   **Rule 11 — Match the project's conventions, even if you disagree:**
    *   Conformance > taste inside the repository.
    *   If you genuinely think a convention is harmful, surface it. Don't fork silently or introduce divergent setups.
*   **Rule 12 — Fail loud:**
    *   "Completed" is wrong if anything was skipped silently.
    *   "Pipelines pass" is wrong if any checks were bypassed.
    *   Default to surfacing system errors and uncertainty, not hiding them.

