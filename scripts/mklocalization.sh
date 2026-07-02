#!/usr/bin/env bash

set -euo pipefail

# Resolve symlinks, too
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

find "$PROJECT_DIR/Sources" -name "*.swift" -print0 | xargs -0 genstrings -o "$PROJECT_DIR/en.lproj"

