#!/usr/bin/env bash
# Description: Start all enabled services

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"

# Execute the existing service startup script
exec "$PROJECT_ROOT/.devcontainer/scripts/services-up.sh"