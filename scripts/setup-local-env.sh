#!/usr/bin/env bash
#
# Bootstrap script for local xcconfig files.
# Safe to run multiple times.
# It will NOT overwrite existing .local files.

set -e

copy_if_missing() {
  local src="$1"
  local dst="$2"

  if [ -f "$dst" ]; then
    echo "Skipped (already exists): $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Created: $dst"
  fi
}

copy_if_missing "./Signing-Template.xcconfig" "./Signing.local.xcconfig"
copy_if_missing "./Versions-Template.xcconfig" "./Versions.local.xcconfig"

copy_if_missing "./Signing-Template.xcconfig" "./visdiff/Signing.local.xcconfig"
copy_if_missing "./Versions-Template.xcconfig" "./visdiff/Versions.local.xcconfig"

copy_if_missing "./Signing-Template.xcconfig" "./Tests/Signing.local.xcconfig"
copy_if_missing "./Versions-Template.xcconfig" "./Tests/Versions.local.xcconfig"

copy_if_missing "./FinderCompare/Signing.xcconfig" "./FinderCompare/Signing.local.xcconfig"
