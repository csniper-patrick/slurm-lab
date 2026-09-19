# Multi-Cluster and Federation (Lyoko Profile)

This workflow describes the multi-cluster and federation architecture, how to activate the secondary cluster, and how to verify cross-cluster communication.

## Architecture

The lab supports a secondary cluster named `lyoko` that shares the primary accounting database daemon (`slurmdbd`):

* `master-lyoko` (`slurm-lab-master-lyoko`): Controller daemon (`slurmctld`) for the `lyoko` cluster, configured via `.env-lyoko`.
* `compute-lyoko`: Worker compute node for the `lyoko` cluster. Scale using `COMPUTE_LYOKO_REPLICAS` (default: `1`).
* Accounting database: Both clusters register with and report to the shared `slurmdbd` and `mariadb` instances.

## Starting the Secondary Cluster

Activate the `lyoko` Compose profile:

### Using Make
```sh
# In production mode:
make up COMPOSE_PROFILES=lyoko

# In development mode (local images):
make dev COMPOSE_PROFILES=lyoko
```

### Using Compose Directly
```sh
# In production mode:
podman compose --profile lyoko up -d

# In development mode:
MODE=dev podman compose --profile lyoko up -d
```

### Using `.env` Configuration
Add or uncomment in `.env`:
```sh
COMPOSE_PROFILES=lyoko
```
Then run `make up` or `make dev` normally.

## Verifying Federation & Multi-Cluster State

1. **Check both clusters in the accounting database:**
   ```sh
   podman compose exec client sacctmgr show cluster
   ```

2. **Query node status across all clusters:**
   ```sh
   podman compose exec client sinfo -M all
   ```

3. **Verify controller responsiveness:**
   ```sh
   podman compose exec client scontrol -M lyoko ping
   ```

4. **Hands-on tutorials:**
   Refer to `tutorials/Multi-Cluster & Federation.ipynb` inside JupyterHub for step-by-step federation job submission exercises.

