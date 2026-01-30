#!/bin/bash
set -e

# =============================================================================
# Headless Devcontainer Deployment Script
# For running on servers without VS Code (e.g., OCI VM, CI/CD)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Duckietown Devcontainer - Headless Deployment ==="
echo "Workspace: $WORKSPACE_DIR"

# Check for devcontainer CLI
if ! command -v devcontainer &> /dev/null; then
    echo "Error: devcontainer CLI not found."
    echo ""
    echo "Install with:"
    echo "  npm install -g @devcontainers/cli"
    echo ""
    echo "Prerequisites:"
    echo "  - Node.js (https://nodejs.org/)"
    echo "  - Docker"
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker first."
    exit 1
fi

# Set headless mode environment
export HEADLESS_MODE=true

# Export host UID/GID for container user matching
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        PLATFORM="linux/arm64"
        ;;
    x86_64|amd64)
        PLATFORM="linux/amd64"
        ;;
    *)
        PLATFORM=""
        echo "Warning: Unknown architecture '$ARCH'. Proceeding without platform specification."
        ;;
esac

echo ""
echo "Architecture: $ARCH"
echo "Host UID/GID: $HOST_UID:$HOST_GID"
[ -n "$PLATFORM" ] && echo "Platform: $PLATFORM"
echo "Starting devcontainer in headless mode..."
echo ""

# Build and start the container
devcontainer up --workspace-folder "$WORKSPACE_DIR"

echo ""
echo "=== Container is running! ==="
echo ""

# Get container name for direct docker access
CONTAINER_NAME="dt-env-developer_devcontainer-devcontainer-1"

echo "=== Verification ==="
echo "Checking container status..."
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
echo ""

echo "=== Usage ==="
echo ""
echo "Attach to container (interactive shell):"
echo "  docker exec -it $CONTAINER_NAME bash"
echo ""
echo "Run a command in container:"
echo "  docker exec $CONTAINER_NAME <command>"
echo ""
echo "Stop the container:"
echo "  docker compose -f \"$SCRIPT_DIR/docker-compose.yml\" down"
echo ""
echo "=== Quick Test ==="
echo "  docker exec $CONTAINER_NAME dts version"
echo ""

