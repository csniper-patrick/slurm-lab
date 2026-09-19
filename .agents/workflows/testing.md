# Running Tests and CI Checks

This workflow describes how to run automated tests, verify CI configurations locally, and inspect cluster status.

## Local CI Stack Testing

You can simulate the GitLab CI environment locally using the `ci` profile and mode:

```sh
make ci
# Or directly using compose:
MODE=ci podman compose up -d
```

### CI Topology Intent

* In CI mode (`MODE=ci` / `COMPOSE_PROFILES=ci`), only controllers and core service daemons are started to verify daemon initialization and database communication.
* `master-lyoko` is included in the `ci` profile to test secondary cluster initialization and federation database binding.
* Compute workers (`compute` and `compute-lyoko`) are scaled to 0 or omitted to minimize resource usage in CI environments.

## CI/CD Pipeline Definitions

The full CI pipeline is specified across the following files:
* `.gitlab-ci.yml`: Entry point for pipeline definitions and stage execution.
* `gitlab-ci.d/test.yml`: Integration test suites and health check routines.
* `gitlab-ci.d/container-build.yml.j2`: Jinja2 template for building the multi-distribution container images.

## Verifying Cluster Daemons

After starting the stack, inspect running daemons and logs:

1. **Check service status:**
   ```sh
   podman compose ps
   ```

2. **Inspect controller logs:**
   ```sh
   podman compose logs controller
   ```

3. **Verify Slurm accounting database:**
   ```sh
   podman compose exec client sacctmgr show cluster
   ```

4. **Verify node registration:**
   ```sh
   podman compose exec client sinfo
   ```

