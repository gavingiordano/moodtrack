#!/usr/bin/env bash
# set-prompt.sh - install a single, centralized devcontainer prompt block
# Writes a marker-delimited block into the user's ~/.bashrc (or
# /etc/profile.d if run as root). The block defines docker_summary() and
# update_prompt(), and prints them once per session.

set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
devcontainer_json="$script_dir/../devcontainer.json"
version_file="$script_dir/../VERSION"

IMAGE="unknown"
VERSION="unknown"

if [ -f "$devcontainer_json" ]; then
  IMAGE_LINE=$(grep -m1 '"image"' "$devcontainer_json" || true)
  if [ -n "$IMAGE_LINE" ]; then
    IMAGE=$(printf "%s" "$IMAGE_LINE" | sed -E 's/.*"image"\s*:\s*"([^"]+)".*/\1/')
  fi
fi

if [ -f "$version_file" ]; then
  VERSION=$(head -n1 "$version_file" | tr -d '\r\n' || true)
fi

IMAGE_NAME="${IMAGE%%:*}"
IMAGE_NAME="${IMAGE_NAME##*/}"
IMAGE_SAFE=$(printf "%s" "$IMAGE_NAME" | sed 's/[^a-zA-Z0-9_.-]/_/g')

MARKER_START="# >>> devcontainer prompt start"
MARKER_END="# <<< devcontainer prompt end"

# Centralized prompt template. Edit here to change layout/colors.
prompt_template() {
  cat <<'EOF'
__MARKER_START__
# devcontainer prompt block: defines docker_summary() and update_prompt()

docker_summary() {
    if command -v docker >/dev/null 2>&1; then
      local nets_list ctrs_list vols_list cpu mem_kb mem_h
      local current_container_id current_network
      
      # Get current container ID - try hostname first (works in most containers)
      current_container_id=$(hostname 2>/dev/null)
      
      # Verify it's a valid container ID
      if ! docker inspect "$current_container_id" >/dev/null 2>&1; then
        # Fallback: try to extract from cgroup (older Docker/cgroup v1)
        current_container_id=$(cat /proc/self/cgroup 2>/dev/null | grep -o -E '[a-f0-9]{64}' | head -1 | cut -c1-12)
      fi
      
      # Get networks this container is connected to
      if [ -n "$current_container_id" ] && docker inspect "$current_container_id" >/dev/null 2>&1; then
        current_network=$(docker inspect "$current_container_id" --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null | head -c 12)
        if [ -n "$current_network" ]; then
          nets_list=$(docker network inspect "$current_network" --format '{{.Name}}' 2>/dev/null)
        fi
      fi
      
      # Fallback to listing custom networks if we couldn't detect current network
      if [ -z "$nets_list" ]; then
        nets_list=$(docker network ls --format '{{.Name}}' 2>/dev/null | grep -v '^bridge$\|^host$\|^none$' | head -n5)
      fi
      [ -z "$nets_list" ] && nets_list="default"
      
      # Get containers on the same network, excluding self
      if [ -n "$current_network" ]; then
        ctrs_list=$(docker ps --filter "network=${current_network}" --format '{{.Names}}' 2>/dev/null | grep -v "^$(docker inspect "$current_container_id" --format '{{.Name}}' 2>/dev/null | sed 's/^\///')" | head -n10)
      else
        # Fallback: show running containers if we can't detect network
        ctrs_list=$(docker ps --format '{{.Names}}' 2>/dev/null | head -n5)
      fi
      [ -z "$ctrs_list" ] && ctrs_list="none"
      
      # Get volumes actually mounted in this container with their mount paths
      if [ -n "$current_container_id" ] && docker inspect "$current_container_id" >/dev/null 2>&1; then
        vols_list=$(docker inspect "$current_container_id" --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}|{{.Source}}|{{.Destination}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | head -n10)
      fi
      [ -z "$vols_list" ] && vols_list="none"

      cpu=$(nproc 2>/dev/null || echo '?')
      mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
      if [ "$mem_kb" -gt 0 ] 2>/dev/null; then
        mem_h=$(awk "BEGIN{printf \"%.1fG\", $mem_kb/1024/1024}")
      else
        mem_h='?'
      fi

      # Pretty-printed docker environment summary
      echo ""
      echo -e "\033[2mDocker Environment\033[0m"
      echo ""
      echo -e "\033[36mNetworks:\033[0m"
      echo "$nets_list" | while read -r net; do
        [ -n "$net" ] && echo -e "  \033[2m•\033[0m $net"
      done
      echo ""
      echo -e "\033[32mContainers:\033[0m"
      if [ "$ctrs_list" = "none" ]; then
        echo -e "  \033[2m• none\033[0m"
      else
        echo "$ctrs_list" | while read -r ctr; do
          [ -n "$ctr" ] && echo -e "  \033[2m•\033[0m $ctr"
        done
      fi
      echo ""
      echo -e "\033[33mVolumes:\033[0m"
      if [ "$vols_list" = "none" ]; then
        echo -e "  \033[2m• none\033[0m"
      else
        echo "$vols_list" | while IFS='|' read -r vol_name vol_host vol_container; do
          if [ -n "$vol_name" ]; then
            echo -e "  \033[2m•\033[0m $vol_name"
            echo -e "    \033[2mHost:\033[0m $vol_host"
            echo -e "    \033[2mContainer:\033[0m $vol_container"
          fi
        done
      fi
      echo ""
      echo -e "\033[35mResources:\033[0m CPU=${cpu} cores, Memory=${mem_h}"
      echo ""
      
      # Show connection examples for known services
      local has_redis=false has_postgres=false
      echo "$ctrs_list" | grep -q "dev_redis" && has_redis=true
      echo "$ctrs_list" | grep -q "dev_pg" && has_postgres=true
      
      if [ "$has_redis" = true ] || [ "$has_postgres" = true ]; then
        echo -e "\033[36mQuick Connect:\033[0m"
        if [ "$has_redis" = true ]; then
          echo -e "  \033[2m•\033[0m Redis:  \033[33mredis-cli -h dev_redis\033[0m"
        fi
        if [ "$has_postgres" = true ]; then
          echo -e "  \033[2m•\033[0m PostgreSQL:  \033[33mpsql -h dev_pg -U app -d db (password: app)\033[0m"
        fi
        echo ""
      fi
    fi
}

update_prompt() {
  PS1='\n╭───────────────────╮\n│ \[\e[34m\]__IMAGE_SAFE__ \[\e[32m\]__VERSION__\[\e[0m\] │ ⌖ \[\e[34m\]\w\[\e[0m\]\n╰───────────────────╯\n\[\e[2m\]λ \[\e[0m\]'
}

# Print docker summary once per session
if [ -z "${__DEVCONTAINER_PROMPT_PRINTED:-}" ] && [ -n "${PS1:-}" ] && [ -t 1 ]; then
  if command -v docker_summary >/dev/null 2>&1; then
    docker_summary
  fi
  __DEVCONTAINER_PROMPT_PRINTED=1
  export __DEVCONTAINER_PROMPT_PRINTED
fi

# Set the prompt (always, for interactive shells)
if [ -n "${PS1:-}" ]; then
  update_prompt
fi
__MARKER_END__
EOF
}

# Build the final block with substitutions
block=$(prompt_template | sed -e "s|__IMAGE_SAFE__|${IMAGE_SAFE}|g" -e "s|__VERSION__|${VERSION}|g" -e "s|__MARKER_START__|${MARKER_START}|g" -e "s|__MARKER_END__|${MARKER_END}|g")

# Write to /etc/profile.d if root, else to user's .bashrc
if [ "$(id -u)" -eq 0 ] && [ -w /etc/profile.d ]; then
  printf '%s\n' "$block" > /etc/profile.d/devcontainer-prompt.sh
  chmod 644 /etc/profile.d/devcontainer-prompt.sh || true
  exit 0
fi

TARGET_USER_HOME="/home/vscode"
[ -d "$TARGET_USER_HOME" ] || TARGET_USER_HOME="$HOME"
TARGET_BASHRC="$TARGET_USER_HOME/.bashrc"
[ -f "$TARGET_BASHRC" ] || touch "$TARGET_BASHRC" || true

# Remove any existing blocks and append the single block
sed -i "/^${MARKER_START}$/,/^${MARKER_END}$/d" "$TARGET_BASHRC" 2>/dev/null || true
printf '%s\n' "$block" >> "$TARGET_BASHRC"
chmod 644 "$TARGET_BASHRC" || true

exit 0
# Print once per session if available
