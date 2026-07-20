#!/usr/bin/env bash
#
# Bootstrap script for local xcconfig files.
# Combines the local and maintainer setups in a single entry point.
#
# Default mode copies the template xcconfig files (same as setup-local-env.sh),
# it is safe to run multiple times and will NOT overwrite existing .local files.
#
# Maintainer mode (-m admin) installs the maintainer configurations as symbolic
# links (same as setup-maintainer-env.sh) and must be run only on maintainer
# machines because it requires access to sensible informations.

set -euo pipefail

# gnu-getopt is required, the BSD getopt shipped in /usr/bin does not support long options
GETOPT="$(brew --prefix gnu-getopt 2>/dev/null)/bin/getopt"

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [-m|--mode MODE] [maintainer-config-dir]

Modes:
  local   (default)  copy the template xcconfig files without overwriting
  admin              install the maintainer configurations as symbolic links,
                     requires <maintainer-config-dir> as an absolute path
EOF
}

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

setup_local() {
  copy_if_missing "./Signing-Template.xcconfig" "./Signing.local.xcconfig"
  copy_if_missing "./Versions-Template.xcconfig" "./Versions.local.xcconfig"

  copy_if_missing "./Signing-Template.xcconfig" "./visdiff/Signing.local.xcconfig"
  copy_if_missing "./Versions-Template.xcconfig" "./visdiff/Versions.local.xcconfig"

  copy_if_missing "./Signing-Template.xcconfig" "./Tests/Signing.local.xcconfig"
  copy_if_missing "./Versions-Template.xcconfig" "./Tests/Versions.local.xcconfig"
}

setup_maintainer() {
  local config_dir="$1"

  if [ -z "$config_dir" ]; then
    echo "Error: admin mode requires <maintainer-config-dir>" >&2
    usage
    exit 1
  fi

  if [[ "$config_dir" != /* ]]; then
    echo "Error: '$config_dir' must be an absolute path" >&2
    exit 1
  fi

  if [ ! -d "$config_dir" ]; then
    echo "Error: '$config_dir' is not a directory" >&2
    exit 1
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_dir
  project_dir="$(cd "$script_dir/.." && pwd)"

  ###
  # Custom local files
  ###
  ln -fs "$config_dir/stuff/swiftlint.custom.yml" "$project_dir/.swiftlint.local.yml"
  ln -fs "$config_dir/stuff/changelog-context.local.json" "$project_dir/changelog-context.local.json"

  ###
  # Signing and Versions
  ###
  ln -fs "$config_dir/appconfig/Signing.local.xcconfig" "$project_dir/Signing.local.xcconfig"
  ln -fs "$config_dir/appconfig/Versions.local.xcconfig" "$project_dir/Versions.local.xcconfig"

  ln -fs "$config_dir/appconfig/Tests/Signing.local.xcconfig" "$project_dir/Tests/Signing.local.xcconfig"
  ln -fs "$config_dir/appconfig/Tests/Versions.local.xcconfig" "$project_dir/Tests/Versions.local.xcconfig"

  ln -fs "$config_dir/appconfig/visdiff/Signing.local.xcconfig" "$project_dir/visdiff/Signing.local.xcconfig"
  ln -fs "$config_dir/appconfig/visdiff/Versions.local.xcconfig" "$project_dir/visdiff/Versions.local.xcconfig"

  ###
  # Fastlane
  ###

 ln -fs "$config_dir/fastlane/.env.local" "$project_dir/fastlane/.env.local"
 ln -fs "$config_dir/fastlane/.env.prerelease.local" "$project_dir/fastlane/.env.prerelease.local"
 ln -fs "$config_dir/fastlane/.env.sparkle.local" "$project_dir/fastlane/.env.sparkle.local"
 ln -fs "$config_dir/fastlane/.env.test.local" "$project_dir/fastlane/.env.test.local"
 ln -fs "$config_dir/secrets.local" "$project_dir/fastlane/secrets.local"
}

if [ ! -x "$GETOPT" ]; then
  echo "Error: gnu-getopt not found, install it with 'brew install gnu-getopt'" >&2
  exit 1
fi

parsed="$("$GETOPT" --options m:h --longoptions mode:,help --name "$(basename "$0")" -- "$@")"
eval set -- "$parsed"

mode="local"

while true; do
  case "$1" in
    -m | --mode)
      mode="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
  esac
done

case "$mode" in
  local)
    setup_local
    ;;
  admin)
    setup_maintainer "${1:-}"
    ;;
  *)
    echo "Error: unknown mode '$mode'" >&2
    usage
    exit 1
    ;;
esac
