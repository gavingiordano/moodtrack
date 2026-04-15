#!/usr/bin/env bash
# Description: Format Python code with Black and organize imports with isort

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

echo "Organizing imports with isort..."
isort .

echo "Formatting code with Black..."
black .

echo "Code formatting complete!"