# slurm-lab
This project aim to provide an easy way to set up a slurm environment on your personal computer for testing, learning, and development purposes. 

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

### Architecture
The cluster consist of these components:
1. 2 master container running slurm control daemon (slurmctld) and slurm accounting daemon (slurmdbd)
2. 1 mariadb container
3. 1 frontend container running jupyter hub, and configured as slurm client
4. N (default 2) compute container running slurmd

If you find 2 compute container is not enough for your test you can scale it up(eg. scale to 4 compute containers):
```
podman compose -f compose.dev.yml up -d --scale compute=4 --no-recreate
```