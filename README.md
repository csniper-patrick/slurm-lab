# SLURM Lab
This project aim to provide an easy way to set up a slurm cluster environment on your personal computer for testing, learning, and development purposes. 

## Getting started

### Prerequisite

Install and set up Podman Desktop or Docker Desktop on your computer.
- [Podman Installation Instructions](https://podman.io/docs/installation)
- [Docker Installation Instructions](https://docs.docker.com/desktop/install/mac-install/)

Make sure you have enabled `podman compose` as well.

### Build and run the project

1. Clone the project and all the submodules
   ```
   git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
   cd slurm-lab
   ```
2. Build the container image
   ```
   podman build --tag slurm-lab:latest -f build-el/Containerfile .
   ```
3. Starting the container cluster
   ```
   podman compose -f compose.dev.yml up -d 
   ```
4. Start playing around in your local web browser. If you go to [localhost](http://localhost/). You can use one of these accounts to log in the Jupyter hub environment: jeremie, aelita, yumi, william, ulrich, odd ( [If you wonder who are they: Code Lyoko](https://en.wikipedia.org/wiki/Code_Lyoko) ). No password.
5. You can access and explore the Slurm REST API exposed at localhost port 80 as well.
   The json web keyset location is specified by `AuthAltParameters` in `slurm.conf`
   Please refer to the relevant documents for authenticating your request.
   - [Slurm REST API](https://slurm.schedmd.com/rest.html)
   - [API reference](https://slurm.schedmd.com/rest_api.html)


### Components
The cluster consist of these components:
1. 2 master container running slurm control daemon (slurmctld) and slurm accounting daemon (slurmdbd)
2. 1 mariadb container, serving database for slurm accounting. 
3. 1 client container, configured as submission node, hosting jupyter hub and slurmrestd as well. 
4. N (default 2) compute container running slurmd. You can scale it in runtime:

## TODO/Wishlist
Feature test
* Federation & multi-cluster operation
* Debian package build
* CICD, release, publish, versioning
* pam_slurm_adopt & nss_slurm

Tutorials
* Admin guide
  * intro to command (scontrol, sacctmgr, sacct, slurm.conf, slurmdbd.conf)
  * node, partition operation (ephemeral)
  * slurm conf change (persistent) (ansible)
  * reservation
  * create account and user
    * admin level
    * pam_exec.so
  * config examples
    * floating partition
    * prolog drop cache
    * node shuffle
  * GPU/Gres (no resource)
* REST API example