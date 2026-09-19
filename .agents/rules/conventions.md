# Development Conventions

These conventions govern configuration, architecture, and coding practices across the repository:

* **Containerization:** The project is fully containerized, defined in a single unified `compose.yml` supporting `MODE=prod`, `MODE=dev`, and `MODE=ci`, alongside Compose profiles (such as `lyoko`). Do not create separate compose files for each mode.
* **Configuration:** The primary cluster is configured through `.env`. The secondary multi-cluster environment is configured through `.env-lyoko`. All user-configurable parameters must remain configurable through environment variables.
* **Submodules:** Core dependencies (`modules/slurm`, `modules/ompi`, `modules/slop`, `modules/json-web-key-generator`) are maintained as Git submodules. Do not commit vendored source code directly into the main repository tree.
* **Building:** Image builds must be orchestrated through the `Makefile` to ensure prerequisites (such as secret generation) are executed before builds start.
* **CI/CD:** Pipelines are defined in `.gitlab-ci.yml` and modular definitions in `gitlab-ci.d/`. Automated tests must reflect real cluster deployment conditions.
* **Documentation:** Core utility scripts and tutorial notebooks must contain descriptive headers and inline explanations. Keep user-facing documentation synchronized with configuration changes.
* **Branching:** Container image tags and automated test matrix behavior in CI correspond to the Git branch name.

