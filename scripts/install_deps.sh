#!/usr/bin/env bash
# Install all dependencies dynamically from sub-repos
# - First checks if neighboring ama-* dirs exist, clones if missing
# - Then detects Go version from ama-api/go.mod
# - Detects Node version from sub-repo package.json engines
# - Runs npm install in ama-app
# - Runs go mod tidy in ama-api
# - Runs npm install in ama-infra

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GIT_BASE="git@github.com:Romanmc72/ama-"

echo "=== ama-local: Installing dependencies dynamically ==="

# ============================================================
# STEP 1: Ensure neighboring ama-* directories exist
# ============================================================

# List of required sub-repos and their git suffixes
REPOS=(
    "ama-api   ama-api"
    "ama-app   ama-app"
    "ama-infra ama-infra"
)

MISSING=0

for entry in "${REPOS[@]}"; do
    repo_name=$(echo "$entry" | awk '{print $1}')
    dir_name=$(echo "$entry" | awk '{print $2}')

    if [[ ! -d "$PROJECT_DIR/$dir_name" ]]; then
        echo "→ Missing directory: $dir_name. Cloning..."
        git clone "${GIT_BASE}${repo_name}.git" "$PROJECT_DIR/$dir_name" \
            || { echo "ERROR: Failed to clone $repo_name"; MISSING=1; }
    else
        echo "→ Found: $dir_name"
    fi
done

if [[ "$MISSING" -eq 1 ]]; then
    echo "WARNING: Some repos failed to clone. Continuing if possible..."
fi

# ============================================================
# STEP 2: Detect Go version from ama-api/go.mod
# ============================================================

echo "--- Detecting Go version from ama-api ---"
GO_VERSION=$(bash "$SCRIPT_DIR/detect_go_version.sh")
echo "Go version: $GO_VERSION"

# Ensure mise has the Go version available
if ! mise list | grep -q "go@$GO_VERSION"; then
    echo "Installing Go $GO_VERSION via mise..."
    mise install "go@$GO_VERSION" 2>&1 || echo "Warning: mise install go@$GO_VERSION had issues"
else
    echo "Go $GO_VERSION already installed via mise"
fi

# ============================================================
# STEP 3: Detect Node version from sub-repo package.json engines
# ============================================================

echo "--- Detecting Node version ---"
NODE_VERSION=$(bash "$SCRIPT_DIR/detect_node_version.sh")
echo "Node version: $NODE_VERSION"

if ! mise list | grep -q "node@$NODE_VERSION"; then
    echo "Installing Node $NODE_VERSION via mise..."
    mise install "node@$NODE_VERSION" 2>&1 || echo "Warning: mise install node@$NODE_VERSION had issues"
else
    echo "Node $NODE_VERSION already installed via mise"
fi

# ============================================================
# STEP 4: npm install in ama-app (pnpm is not used anywhere)
# ============================================================

echo "--- Installing dependencies in ama-app ---"
if cd ../ama-app && npm install 2>&1; then
    echo "npm install in ama-app completed"
else
    echo "Warning: npm install in ama-app had issues"
fi

# ============================================================
# STEP 5: go mod tidy in ama-api
# ============================================================

echo "--- Running go mod tidy in ama-api ---"
if cd ../ama-api && go mod tidy 2>&1; then
    echo "go mod tidy completed"
else
    echo "Warning: go mod tidy had issues"
fi

# ============================================================
# STEP 6: npm install in ama-infra
# ============================================================

echo "--- Running npm install in ama-infra ---"
if cd ../ama-infra && npm install 2>&1; then
    echo "npm install in ama-infra completed"
else
    echo "Warning: npm install in ama-infra had issues"
fi

echo "=== ama-local: All dependencies installed ==="