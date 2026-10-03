#!/usr/bin/env bash
set -euo pipefail
# Cryptographic key generation utility for Slurm JWT and symmetric authentication.
# Generates RSA keypair sets (jwks.json, jwks.pub.json) and symmetric octet keys (slurm.jwks)
# using step-cli, jq, and openssl with canonical RFC 7638 SHA-256 thumbprints.
#
# Arguments:
#   $1 - Output directory where generated JWKS files are saved (default: /opt)
#
# Execution Context:
#   Supports host-native execution when step, jq, and openssl are installed.
#   Falls back to auto-installing dependencies when run inside a container
#   (e.g., quay.io/rockylinux/rockylinux:10) as root.

# Helper function to wrap a JWK into a JWK Set {"keys": [...]} with a key ID (kid)
wrap_jwk() {
    local kid="$1" input="$2" output="$3"
    jq --arg kid "$kid" '{"keys": [. + {kid: $kid}]}' "$input" > "$output"
}

# Ensure step, jq, and openssl are installed
if ! command -v step &>/dev/null || ! command -v jq &>/dev/null || ! command -v openssl &>/dev/null; then
    # Container fallback: when executed in quay.io/rockylinux/rockylinux:10 as root, auto-install prerequisites
    if [ "$(id -u)" -eq 0 ] && ([ -f /.dockerenv ] || [ -f /run/.containerenv ]) && command -v dnf &>/dev/null; then
        echo "Configuring Smallstep repository and installing step-cli, jq, and openssl..."
        cat <<-EOT > /etc/yum.repos.d/smallstep.repo
		[smallstep]
		name=Smallstep
		baseurl=https://packages.smallstep.com/stable/fedora/
		enabled=1
		repo_gpgcheck=0
		gpgcheck=1
		gpgkey=https://packages.smallstep.com/keys/smallstep-0x889B19391F774443.gpg
		EOT
        dnf install -y step-cli jq openssl
    else
        echo "Error: 'step', 'jq', and 'openssl' are required but not found in PATH." >&2
        echo "Please install them on your host or run key generation via 'make'." >&2
        exit 1
    fi
fi

# Output directory (defaults to /opt when running in container, or user-provided path)
TARGET_DIR="${1:-/opt}"
mkdir -p "${TARGET_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Generating RSA key pair for JWT authentication..."
step crypto jwk create "${TMP_DIR}/pub.raw.json" "${TMP_DIR}/priv.raw.json" \
  --kty RSA --size 2048 --alg RS256 --no-password --insecure

# Get RFC 7638 thumbprint (base64url encoded SHA-256)
KID_RSA=$(step crypto jwk thumbprint < "${TMP_DIR}/pub.raw.json")

wrap_jwk "$KID_RSA" "${TMP_DIR}/priv.raw.json" "${TARGET_DIR}/jwks.json"
wrap_jwk "$KID_RSA" "${TMP_DIR}/pub.raw.json" "${TARGET_DIR}/jwks.pub.json"

echo "Generating Octet key for Slurm symmetric authentication..."
step crypto jwk create "${TMP_DIR}/oct.pub.raw.json" "${TMP_DIR}/oct.priv.raw.json" \
  --kty oct --size 2048 --alg HS256 --no-password --insecure

# Compute RFC 7638 thumbprint (canonical {"k": ..., "kty": "oct"} without whitespace, SHA-256 in base64url)
KID_OCT=$(jq -j -S -c '{k, kty}' "${TMP_DIR}/oct.priv.raw.json" | openssl dgst -sha256 -binary | base64 | tr '+/' '-_' | tr -d '=')

wrap_jwk "$KID_OCT" "${TMP_DIR}/oct.priv.raw.json" "${TARGET_DIR}/slurm.jwks"

# Secure permissions: private and symmetric keys are restricted to owner (0600), public key is world readable (0644)
chmod 0600 "${TARGET_DIR}/jwks.json" "${TARGET_DIR}/slurm.jwks"
chmod 0644 "${TARGET_DIR}/jwks.pub.json"

echo "JWT keys successfully generated in ${TARGET_DIR}."
