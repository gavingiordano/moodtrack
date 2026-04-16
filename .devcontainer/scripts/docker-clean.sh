#!/bin/bash

# Docker Clean - Remove all Docker resources
# This script will completely clean your Docker environment

set -e

echo "🧹 Starting Docker cleanup..."

# Stop all running containers
echo "Stopping all running containers..."
if [ "$(docker ps -aq)" ]; then
    docker stop $(docker ps -aq) 2>/dev/null || true
fi

# Remove all containers
echo "Removing all containers..."
if [ "$(docker ps -aq)" ]; then
    docker rm $(docker ps -aq) 2>/dev/null || true
fi

# Remove all images
echo "Removing all images..."
if [ "$(docker images -q)" ]; then
    docker rmi $(docker images -q) 2>/dev/null || true
fi

# Remove all volumes
echo "Removing all volumes..."
if [ "$(docker volume ls -q)" ]; then
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
fi

# Remove all networks (except defaults)
echo "Removing all custom networks..."
docker network prune -f 2>/dev/null || true

# Remove all build cache
echo "Removing build cache..."
docker builder prune -af 2>/dev/null || true

# Final system prune
echo "Running final system prune..."
docker system prune -af --volumes

echo "✅ Docker cleanup complete!"
