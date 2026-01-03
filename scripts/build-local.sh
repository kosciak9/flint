#!/bin/bash
# =============================================================================
# Local build script for Flint image
# Run from inside distrobox, uses host podman via distrobox-host-exec
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE_NAME="${IMAGE_NAME:-flint}"
IMAGE_TAG="${IMAGE_TAG:-local}"

cd "$PROJECT_DIR"

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
echo "Project directory: $PROJECT_DIR"

# Use host podman from distrobox
podman build \
    --format docker \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f Containerfile \
    .

echo ""
echo "Build complete: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To test locally:"
echo "  podman run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} /bin/bash"
