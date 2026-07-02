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
  "Test (use with VM to test on other OS versions):test"
  "Pre-release (use with beta testers):prerelease"
  "Sparkle (no upload appcast):sparkle"
  "Create Changelog:changelog"
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

generate_release_notes() {
  local xcconfig_file="$PROJECT_DIR/Versions.local.xcconfig"
  local app_version
  app_version="$(sed -nE "s/^[[:space:]]*APP_VERSION[[:space:]]*=[[:space:]]*(.*)/\1/p" "$xcconfig_file" | tr -d '[:space:]')"

  if [ -z "$app_version" ]; then
    echo "Unable to read APP_VERSION from $xcconfig_file" >&2
    exit 1
  fi

  local notes_dir="$PROJECT_DIR/build/notes"
  local notes_file="$notes_dir/${app_version}.md"

  mkdir -p "$notes_dir"
  echo "Generating release notes: $notes_file"
  (cd "$PROJECT_DIR" && "$SCRIPT_DIR/changelog.sh" prod) > "$notes_file"

  echo "Opening release notes, close the file to continue..."
  open -W "$notes_file"
}

run_tests() {
  echo "Running tests"

  bundle exec fastlane tests
}

case "$selected_profile" in
  release)
    build_command=(bundle exec fastlane release --env local)
    ;;
  test)
    build_command=(bundle exec fastlane release --env test.local)
    ;;
  sparkle)
    build_command=(bundle exec fastlane release --env sparkle.local)
    ;;
  prerelease)
    build_command=(bundle exec fastlane release --env prerelease.local)
    ;;
  changelog)
    generate_release_notes
    exit 0
    ;;
  *)
    echo "Unsupported profile: $selected_profile" >&2
    exit 1
    ;;
esac

if [ ${#build_command[@]} -gt 0 ]; then
  generate_release_notes
  run_tests

  echo "Running profile: $selected_profile"

  cd "$PROJECT_DIR"
  "${build_command[@]}"
fi
