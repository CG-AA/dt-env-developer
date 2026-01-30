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

echo ""
echo "Starting devcontainer in headless mode..."
echo ""

# Build and start the container
devcontainer up --workspace-folder "$WORKSPACE_DIR"

echo ""
echo "=== Container is running! ==="
echo ""
echo "To attach to the container:"
echo "  devcontainer exec --workspace-folder \"$WORKSPACE_DIR\" bash"
echo ""
echo "To stop the container:"
echo "  docker compose -f \"$SCRIPT_DIR/docker-compose.yml\" down"
echo ""
