#!/usr/bin/env bash
# Description: Check Python code with Flake8 linter

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"
cd "$PROJECT_ROOT"

# Ensure virtual environment is activated
if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    if [[ -f ".venv/bin/activate" ]]; then
        echo "Activating virtual environment..."
        source .venv/bin/activate
    else
        echo "Warning: No virtual environment found"
    fi
fi

echo "Checking code with Flake8..."
exec flake8 . "$@"