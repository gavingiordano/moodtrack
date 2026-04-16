#!/usr/bin/env bash
# Description: Show service status

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"

# Change to project root
cd "$PROJECT_ROOT"

# Build compose command with all service files
compose_files="-f .devcontainer/services/_base.yml"
for f in .devcontainer/services/*.yml; do
    [[ "$(basename "$f")" == "_base.yml" ]] || compose_files="$compose_files -f $f"
done

# Show service status
exec docker compose -p dev-svcs $compose_files ps