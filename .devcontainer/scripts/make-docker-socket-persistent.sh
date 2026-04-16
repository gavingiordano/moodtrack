#!/usr/bin/env bash
set -euo pipefail

cat <<'DESC'
This script creates a systemd drop-in to ensure /var/run/docker.sock is created
with group 'docker' and mode 0660. It must be run on the Docker host with sudo.

Usage (on host):
  sudo bash .devcontainer/scripts/make-docker-socket-persistent.sh

DESC

if ! command -v systemctl >/dev/null 2>&1; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    cat <<'MACMSG'
This machine appears to be macOS. Docker Desktop on macOS does not use systemd,
so the systemd-based approach in this script won't work.

If you want the Docker socket on macOS to keep particular permissions, one
approach is to install a small launchd job that runs a tiny helper script which
adjusts /var/run/docker.sock after Docker Desktop creates it.

I added helper files in `.devcontainer/scripts/macos/` in this repository:

  - fix-docker-sock-perms.sh
    A small script that will chgrp/chmod the socket. Install it to
    /usr/local/bin/fix-docker-sock-perms.sh and make it executable.

  - com.local.fixdockersock.plist
    A launchd plist to run the helper at load and whenever /var/run/docker.sock
    changes. Install it to /Library/LaunchDaemons/ and load it with launchctl.

Installation (run these commands in a macOS terminal with sudo):

  sudo cp .devcontainer/scripts/macos/fix-docker-sock-perms.sh /usr/local/bin/
  sudo chmod 755 /usr/local/bin/fix-docker-sock-perms.sh
  sudo cp .devcontainer/scripts/macos/com.local.fixdockersock.plist \
    /Library/LaunchDaemons/com.local.fixdockersock.plist
  sudo chown root:wheel /Library/LaunchDaemons/com.local.fixdockersock.plist
  sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.fixdockersock.plist || \
    sudo launchctl load /Library/LaunchDaemons/com.local.fixdockersock.plist

Notes:
  - The helper tries to chgrp the socket to group 'docker' and falls back to
    'staff' if 'docker' doesn't exist. If you need a 'docker' group, create it
    and add users as appropriate.
  - This is a macOS workaround. It adjusts socket permissions after Docker
    creates the socket; Docker Desktop may reset permissions on update, so the
    launchd watcher ensures the helper runs when the socket is recreated.

If you're not on macOS, run this script on the Docker host where systemd is
available.
MACMSG

    exit 1
  fi

  echo "systemctl does not appear to be available on this machine."
  echo "You must run this on the Docker host where systemd is present."
  exit 1
fi

echo "Creating /etc/systemd/system/docker.socket.d/override.conf..."
sudo mkdir -p /etc/systemd/system/docker.socket.d
sudo tee /etc/systemd/system/docker.socket.d/override.conf > /dev/null <<'EOF'
[Socket]
SocketUser=root
SocketGroup=docker
SocketMode=0660
EOF

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Restarting docker.socket and docker.service (may briefly interrupt docker)..."
sudo systemctl restart docker.socket || true
sudo systemctl restart docker.service || true

echo
echo "Status of docker.socket:"
sudo systemctl status docker.socket --no-pager -l || true

echo
echo "Permissions for /var/run/docker.sock:" 
ls -l /var/run/docker.sock || true

echo
echo "Done. If the socket is not owned by root:docker with 660, check the Docker packaging
and system start logic on this host."
