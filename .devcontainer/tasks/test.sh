#!/usr/bin/env bash
# Description: Run Python tests with pytest

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

# Run pytest with coverage if available
if python -c "import pytest_cov" 2>/dev/null; then
    exec pytest --cov=. "$@"
else
    exec pytest "$@"
fi