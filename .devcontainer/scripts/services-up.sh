#!/usr/bin/env bash
set -euo pipefail

ROOT="${CONTAINER_WORKSPACE_FOLDER:-$PWD}"
SERV_DIR="$ROOT/.devcontainer/services"
CFG="$SERV_DIR/services.yaml"

if ! command -v docker &>/dev/null; then
  echo "Docker CLI not found in container."
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "Docker daemon not ready yet. Waiting for it to initialize..."
  for attempt in {1..120}; do
    if docker info &>/dev/null; then
      echo "Docker daemon is ready."
      break
    fi
    sleep 1
  done
fi

if ! docker info &>/dev/null; then
  echo "Docker daemon did not become ready after waiting for 120 seconds."
  exit 1
fi

compose_files="-f $SERV_DIR/_base.yml"

mapfile -t names < <(awk '
  $1=="enabled:" {in_list=1; next}
  in_list && $1 ~ /^-/ {sub(/- /,"",$0); gsub(/^[ \t]+|[ \t]+$/,"",$0); print $0; next}
  in_list && NF==0 {in_list=0}
' "$CFG")

for name in "${names[@]}"; do
  f="$SERV_DIR/${name}.yml"
  if [[ -f "$f" ]]; then
    compose_files="$compose_files -f $f"
  fi
done

echo "Bringing up services: ${names[*]}"
docker compose $compose_files -p dev-svcs up -d

# Ensure the devcontainer itself joins the services network for direct access.
network_name="dev-svcs_default"
container_id="${HOSTNAME:-}"

if [[ -z "$container_id" ]] && [[ -r /proc/1/cpuset ]]; then
  container_id="$(basename "$(cat /proc/1/cpuset)")"
fi

if docker network inspect "$network_name" &>/dev/null; then
  if [[ -n "$container_id" ]] && docker inspect "$container_id" &>/dev/null; then
    if docker network connect "$network_name" "$container_id" 2>/dev/null; then
      echo "Attached devcontainer to network $network_name."
    else
      echo "Devcontainer already connected to network $network_name or attach not required."
    fi
  else
    echo "Could not determine devcontainer ID; skipping network attachment."
  fi
else
  echo "Network $network_name not found; skipping devcontainer attachment."
fi

docker compose $compose_files -p dev-svcs ps
