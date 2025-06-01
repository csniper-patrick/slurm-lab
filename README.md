# Slurm Lab
This project aims to provide an easy way to set up a Slurm cluster environment on your personal computer for testing, learning, and development purposes. 

## Getting started

### Prerequisite

Install and set up Podman Desktop or Docker Desktop on your computer.
- [Podman Installation Instructions](https://podman.io/docs/installation)
- [Docker Installation Instructions](https://docs.docker.com/desktop/install/mac-install/)

Make sure you have enabled `podman compose` or `podman-compose` as well.

### Quick start
The images built from this project are published to [Docker hub - csniper/slurm-lab](https://hub.docker.com/r/csniper/slurm-lab). You could start your slurm-lab container cluster following these simple steps. 
```
git clone https://gitlab.com/CSniper/slurm-lab.git
cd slurm-lab
podman compose up -d
```
If you want to run your lab using other available images, check out the list of available tags [here](https://hub.docker.com/r/csniper/slurm-lab/tags). Then specify the tag you want to use in file `.env`.  
eg. specify tag latest-deb to use Debian-based image. 
```
TAG=latest-deb
```

### Develop and build the project locally
To develop and build this project locally, you need to clone all the submodules and use compose file `compose.dev.yml` instead. 

1. Prepare the project
   If you clone the project from scratch:
      ```
      git clone --recurse-submodules https://gitlab.com/CSniper/slurm-lab.git
      cd slurm-lab
      ```
   If you've cloned the project already without submodules:
      ```
      cd slurm-lab
      git submodule update --init --recursive
      ```
2. build the container image
   ```
   podman build --tag slurm-lab:el9 -f build-el9/Containerfile .
   ```
   or
   ```
   podman compose -f compose.dev.yml build
   ```
3. Starting the container cluster
   ```
   podman compose -f compose.dev.yml up -d 
   ```
4. Start playing around in your local web browser. If you go to [localhost:8080](http://localhost:8080/). You can use one of these accounts to log in the Jupyter hub environment: jeremie, aelita, yumi, ulrich, odd ( [If you wonder who are they: Code Lyoko](https://en.wikipedia.org/wiki/Code_Lyoko) ). No password.
5. You can access and explore the Slurm REST API as well.
   The json web keyset location is specified by `AuthAltParameters` in `slurm.conf`
   Please refer to the relevant documents for authenticating your request.
   - [Slurm REST API](https://slurm.schedmd.com/rest.html)
   - [API reference](https://slurm.schedmd.com/rest_api.html)
6. The official document of the exact version of Slurm installed in the container is available at [localhost:8080/doc/](http://localhost:8080/doc/) . 

### Components
The cluster consists of these components:
1. 2 master container running slurm control daemon (slurmctld) and Slurm accounting daemon (slurmdbd)
2. 1 mariadb container, serving database for slurm accounting. 
3. 1 client container, configured as submission node, hosting Jupyter hub and slurmrestd as well. 
4. N (default 4) compute container running slurmd. You can scale it up in runtime. eg.:
```
podman compose up -d --scale compute=6 --no-recreate
```

## `.env` options
### MySQL variables
You can change the following MySQL variables in `.env` file. Note that these variables are required.
* `MYSQL_PASSWORD`
* `MYSQL_USER`
* `MYSQL_DATABASE`
* `MYSQL_RANDOM_ROOT_PASSWORD`

### AuthType plugin option
You can choose between `auth/munge`(default) or `auth/slurm` to authenticating the cluster.
By setting variable `AUTHTYPE=auth/slurm` you can start a slurm cluster that doesn't require munge daemon. 

### Use `jupyter_moss` spawner
By default the jupyter lab session is spawned in the slurm-lab-client container. If you want to start the jupyter lab session as a slurm job and run in a compute container instead, you can switch the [JupyterHub MOdular Slurm Spawner (moss)](https://github.com/silx-kit/jupyterhub_moss) by setting `JUPYTER_SPAWNER=moss`.

## TODO/Wishlist
Feature test:
* Lua script:
  * burst buffer
  * job submission plugin
  * routing partition
* Slurm's podman integration is work in progress.
* strigger

## Known Issues
* Jupyter Notebook is not able to use the `module` command in Debian 12 container.
* debian 11 image is not built/released, as slurm debian package can not be built on arm for this debian version. 