# Makefile for building slurm-lab container images

# Use podman if available, otherwise fall back to docker.
PODMAN ?= $(shell which podman 2>/dev/null || which docker 2>/dev/null)
ifeq ($(PODMAN),)
    $(error "Neither podman nor docker found in PATH")
endif

# Default distributions to build.
# Can be overridden from the command line, e.g.:
DISTROS := $(sort $(patsubst build-%/Containerfile,%,$(shell ls build-*/Containerfile 2>/dev/null)))

# JWT key files that need to be generated.
SECRET_FILES = common/secrets/jwks.json common/secrets/jwks.pub.json common/secrets/slurm.jwks

.PHONY: all build clean prune $(DISTROS) up dev down
.DEFAULT_GOAL := all

# Build all specified distro images.
# To build in parallel, run: make -j<number_of_jobs> build
all: build

# Build images for each distribution.
build: $(DISTROS)

# A rule to build a single distro image.
# Depends on the JWT key files being present.
$(DISTROS): $(SECRET_FILES)
	@echo "Building slurm-lab:$@" image...
	@$(PODMAN) build --jobs=0 --pull=newer -t slurm-lab:$@ --squash -f build-$@/Containerfile .

# A rule to generate JWT key files if they don't exist.
$(SECRET_FILES): | common/secrets
	@echo "Generating JWT keys..."
	@$(PODMAN) run --rm -it \
		-v "$(CURDIR)/json-web-key-generator:/json-web-key-generator" \
		-v "$(CURDIR)/common/secrets:/opt" \
		-v "$(CURDIR)/common/scripts/jwt-key-generation.sh:/jwt-key-generation.sh" \
		docker.io/library/maven:3.8.7-openjdk-18-slim /jwt-key-generation.sh

# Create the secrets directory if it doesn't exist.
common/secrets:
	@mkdir -p common/secrets

# Prune unused container images.
prune:
	@echo "Pruning images and volume..."
	@$(PODMAN) compose down --volumes --remove-orphans
	@$(PODMAN) image prune -f

# Start/stop slurm-lab stack using compose.
up:
	@echo "Starting slurm-lab stack..."
	@$(PODMAN) compose up -d --remove-orphans --force-recreate

dev:
	@echo "Starting slurm-lab stack (localhost)..."
	@$(PODMAN) compose -f compose.dev.yml up -d --remove-orphans --force-recreate

down:
	@echo "Stopping slurm-lab stack..."
	@$(PODMAN) compose down --remove-orphans

# Clean up generated files.
clean:
	@echo "Cleaning up generated files..."
	@rm -rf common/secrets
