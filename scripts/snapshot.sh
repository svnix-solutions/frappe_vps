#!/bin/bash
# =============================================================================
# Create Volume Snapshots (Hetzner Cloud)
# =============================================================================

set -e

# Check for Hetzner CLI
if ! command -v hcloud &> /dev/null; then
    echo "Error: hcloud CLI not installed"
    echo "Install: brew install hcloud"
    exit 1
fi

# Check for token
if [ -z "$HCLOUD_TOKEN" ]; then
    echo "Error: HCLOUD_TOKEN environment variable not set"
    exit 1
fi

PROJECT_NAME="${PROJECT_NAME:-frappe}"
ENVIRONMENT="${ENVIRONMENT:-production}"
DESCRIPTION="${1:-Manual snapshot $(date +%Y-%m-%d_%H:%M)}"

echo "Creating volume snapshots..."
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Description: $DESCRIPTION"
echo ""

# Get all volumes for this project
VOLUMES=$(hcloud volume list -o columns=id,name | grep "${PROJECT_NAME}-${ENVIRONMENT}" || true)

if [ -z "$VOLUMES" ]; then
    echo "No volumes found matching: ${PROJECT_NAME}-${ENVIRONMENT}-*"
    exit 1
fi

echo "Found volumes:"
echo "$VOLUMES"
echo ""

# Create snapshots
while IFS= read -r line; do
    VOL_ID=$(echo "$line" | awk '{print $1}')
    VOL_NAME=$(echo "$line" | awk '{print $2}')

    if [ -n "$VOL_ID" ]; then
        echo "Creating snapshot for: $VOL_NAME (ID: $VOL_ID)"
        hcloud volume create-snapshot "$VOL_ID" --description "$DESCRIPTION"
    fi
done <<< "$VOLUMES"

echo ""
echo "✅ Snapshots created successfully"
