#!/usr/bin/env bash
# Description: Restart all services

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"

# Execute the existing service reload script
exec "$PROJECT_ROOT/.devcontainer/scripts/services-reload.sh"