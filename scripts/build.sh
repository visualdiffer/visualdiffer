#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is required but was not found in PATH" >&2
  exit 1
fi

profile_entries=(
  "Release:release"
  "Test:test"
  "Sparkle (no upload appcast):sparkle"
)

selected_entry="$(
  printf '%s\n' "${profile_entries[@]}" | cut -d ':' -f 1 | fzf \
    --prompt="build profile > " \
    --height=10 \
    --border \
    --reverse
)"

if [ -z "$selected_entry" ]; then
  echo "No profile selected"
  exit 1
fi

selected_profile=""

for entry in "${profile_entries[@]}"; do
  label="${entry%%:*}"
  value="${entry#*:}"

  if [ "$label" = "$selected_entry" ]; then
    selected_profile="$value"
    break
  fi
done

if [ -z "$selected_profile" ]; then
  echo "Unable to resolve selected profile: $selected_entry" >&2
  exit 1
fi

case "$selected_profile" in
  release)
    build_command=(bundle exec fastlane release --env env.local)
    ;;
  test)
    build_command=(bundle exec fastlane release --env test.local)
    ;;
  sparkle)
    build_command=(bundle exec fastlane release --env sparkle.local)
    ;;
  *)
    echo "Unsupported profile: $selected_profile" >&2
    exit 1
    ;;
esac

echo "Running profile: $selected_profile"

cd "$PROJECT_DIR"
"${build_command[@]}"
