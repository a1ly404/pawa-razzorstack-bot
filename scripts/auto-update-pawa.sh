#!/bin/bash
# Auto-update script for Pawa Discord bot
# This script pulls latest changes from git and restarts container if Pawa version changed
# Add to crontab: 0 * * * * /home/daffy/Tools/razzorstack/docker/pawa/scripts/auto-update-pawa.sh >> /var/log/pawa-auto-update.log 2>&1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

LOG_FILE="/var/log/pawa-auto-update.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$TIMESTAMP] $1"
}

log "Checking for Pawa updates..."

# Fetch latest changes from origin
git fetch origin main || {
    log "ERROR: Failed to fetch from origin"
    exit 1
}

# Check if there are new commits
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "No updates found (at $LOCAL)"
    exit 0
fi

log "New commits detected: $LOCAL -> $REMOTE"

# Pull the latest changes
if ! git pull origin main; then
    log "ERROR: Failed to pull latest changes"
    exit 1
fi

# Check if Pawa version changed in docker-compose
if git diff HEAD~1 HEAD -- docker-compose.pawa.yml | grep -q "PAWA_VERSION"; then
    OLD_VERSION=$(git show HEAD~1:docker-compose.pawa.yml | grep -oP 'PAWA_VERSION:-\K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    NEW_VERSION=$(grep -oP 'PAWA_VERSION:-\K[0-9]+\.[0-9]+\.[0-9]+' docker-compose.pawa.yml || echo "unknown")
    
    log "Pawa version updated: $OLD_VERSION -> $NEW_VERSION"
    log "Restarting Pawa container..."
    
    if docker compose up -d pawa; then
        log "SUCCESS: Pawa container restarted with version $NEW_VERSION"
    else
        log "ERROR: Failed to restart Pawa container"
        exit 1
    fi
else
    log "No Pawa version changes detected"
fi

log "Update check complete"
