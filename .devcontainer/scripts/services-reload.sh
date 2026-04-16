#!/usr/bin/env bash
set -euo pipefail
ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"
SERV_DIR="$ROOT/.devcontainer/services"

compose_files="-f $SERV_DIR/_base.yml"
for f in "$SERV_DIR"/*.yml; do
  [[ "$(basename "$f")" == "_base.yml" ]] && continue
  compose_files="$compose_files -f $f"
done

docker compose $compose_files -p dev-svcs up -d
docker compose $compose_files -p dev-svcs ps
