#!/usr/bin/env bash
# Deploy latest Pawa version
# Pulls git changes, pulls the new Docker image, and restarts the container
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAWA_DIR="$(dirname "$SCRIPT_DIR")"
# Pawa is a submodule at docker/pawa/ inside razzorstack
DOCKER_DIR="$(dirname "$PAWA_DIR")"

echo "=== Pawa Deploy ==="

echo "Pulling latest pawa submodule..."
cd "$PAWA_DIR"
git pull origin main

echo ""
echo "Pulling new Pawa Docker image..."
cd "$DOCKER_DIR"
docker compose pull pawa

echo ""
echo "Restarting Pawa container..."
docker compose up -d pawa

echo ""
sleep 5

echo "=== Container Status ==="
docker compose ps pawa

echo ""
echo "=== Recent Logs ==="
docker compose logs pawa --tail 20
