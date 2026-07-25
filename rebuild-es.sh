#!/bin/bash
# Rebuild the emulationstation-next fork for RK3326 (aarch64).
# Compile-only — see DEPLOY_ES.md for copying the result to the device.
#
# Usage:
#   ./rebuild-es.sh                # build latest commit on your fork's master
#   ./rebuild-es.sh <git-commit>   # build a specific commit instead

set -euo pipefail

REPO_ROOT="/home/sacha/Documents/rocknix"
ES_PKG_MK="${REPO_ROOT}/projects/ROCKNIX/packages/ui/emulationstation/package.mk"
ES_FORK_URL="git@github.com:sachafulep/emulationstation-next.git"
IMAGE="ghcr.io/rocknix/rocknix-build:latest"
CONTAINER_MOUNT="/home/runner/work/distribution/distribution"

COMMIT="${1:-}"

cd "$REPO_ROOT"

if [ -z "$COMMIT" ]; then
  echo "==> Resolving latest commit on ${ES_FORK_URL} (master)..."
  COMMIT=$(git ls-remote "$ES_FORK_URL" master | cut -f1)
  if [ -z "$COMMIT" ]; then
    echo "ERROR: could not resolve latest commit from fork" >&2
    exit 1
  fi
fi
echo "==> Building emulationstation @ ${COMMIT}"

sed -i "s/^PKG_VERSION=\".*\"/PKG_VERSION=\"${COMMIT}\"/" "$ES_PKG_MK"
grep -n "^PKG_VERSION=" "$ES_PKG_MK"

podman run --rm \
  --userns=keep-id \
  -v "$REPO_ROOT":"$CONTAINER_MOUNT" \
  -v "$HOME/.ssh":/ssh-host:ro \
  -w "$CONTAINER_MOUNT" \
  -e PROJECT=ROCKNIX -e DEVICE=RK3326 -e ARCH=aarch64 \
  -e CCACHE_COMPILERCHECK=content \
  "$IMAGE" \
  bash -lc '
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    cp /ssh-host/id_ed25519 /ssh-host/id_ed25519.pub ~/.ssh/
    chmod 600 ~/.ssh/id_ed25519
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null
    scripts/build emulationstation
  '

echo "==> Build finished: emulationstation @ ${COMMIT}"
echo "==> Binary: build.ROCKNIX-RK3326.aarch64/install_pkg/emulationstation-${COMMIT}/usr/bin/emulationstation"
echo "$COMMIT" > "${REPO_ROOT}/.last-es-commit"
