#!/usr/bin/env bash
# Detect Node.js version from sub-repo package.json files
# Checks ama-app/package.json first, then ama-infra/package.json engines
# Outputs just the version string (e.g., "20" or "18.19.1")

set -euo pipefail

# Try ama-app/package.json first - look for "engines" field
APP_ENGINE=$(grep -m1 '"engines"' ../ama-app/package.json 2>/dev/null | sed -E 's/.*"node"[[:space:]]*[:][[:space:]]*"([^"]+)".*/\1/' || true)

if [[ -n "$APP_ENGINE" && "$APP_ENGINE" != "null" ]]; then
    # Strip range operators, just give major version or exact version
    # Handle ">=14.0", "^20.0.0", "v22.17.0", etc.
    CLEANED=$(echo "$APP_ENGINE" | sed -E 's/^[^0-9]*//' | sed -E 's/[^0-9.].*//')
    echo "$CLEANED"
    exit 0
fi

# Fall back to ama-infra/package.json
INFRA_ENGINE=$(grep -m1 '"engines"' ../ama-infra/package.json 2>/dev/null | sed -E 's/.*"node"[[:space:]]*[:][[:space:]]*"([^"]+)".*/\1/' || true)

if [[ -n "$INFRA_ENGINE" && "$INFRA_ENGINE" != "null" ]]; then
    CLEANED=$(echo "$INFRA_ENGINE" | sed -E 's/^[^0-9]*//' | sed -E 's/[^0-9.].*//')
    echo "$CLEANED"
    exit 0
fi

echo "20" # default fallback