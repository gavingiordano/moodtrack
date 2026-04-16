#!/usr/bin/env bash
set -euo pipefail

# Fix permissions for Docker socket on macOS
SOCK=/var/run/docker.sock
TARGET_GID=staff

# prefer group 'docker' if it exists
if getent() { return 1; } 2>/dev/null; then
  :
fi

if getent group docker >/dev/null 2>&1; then
  TARGET_GID=docker
fi

if [[ -e "$SOCK" ]]; then
  echo "Fixing ownership and permissions for $SOCK"
  chgrp $TARGET_GID "$SOCK" || true
  chmod 0660 "$SOCK" || true
else
  echo "$SOCK does not exist yet"
fi
