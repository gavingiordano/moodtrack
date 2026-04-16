#!/usr/bin/env bash
# Description: Show service logs (optional service name as argument)

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"
cd "$PROJECT_ROOT"

# Build compose command with all service files
compose_files="-f .devcontainer/services/_base.yml"
for f in .devcontainer/services/*.yml; do
    [[ "$(basename "$f")" == "_base.yml" ]] || compose_files="$compose_files -f $f"
done

# Show logs - if service specified, show just that service
if [[ $# -gt 0 ]]; then
    exec docker compose -p dev-svcs $compose_files logs -f "$1"
else
    exec docker compose -p dev-svcs $compose_files logs -f
fi