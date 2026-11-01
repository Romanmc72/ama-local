#!/usr/bin/env bash
# Detect Go version from ama-api/go.mod
# Outputs just the version string (e.g., "1.25.0")

set -euo pipefail

GO_MOD="../ama-api/go.mod"

if [[ ! -f "$GO_MOD" ]]; then
    echo "ERROR: $GO_MOD not found" >&2
    exit 1
fi

# Extract the Go version from the first line: "go 1.25.0"
# Handle both "go 1.25.0" and "go1.25.0" formats
VERSION=$(head -1 "$GO_MOD" | sed -E 's/^go[[:space:]]*([0-9]+\.[0-9]+(\.[0-9]+)?) .*/\1/' || true)

if [[ -z "$VERSION" ]]; then
    echo "ERROR: Could not parse Go version from $GO_MOD" >&2
    exit 1
fi

echo "$VERSION"