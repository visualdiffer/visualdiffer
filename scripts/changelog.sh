#!/usr/bin/env bash
set -euo pipefail

include_scope="${1:-dev}"

XC_CONFIG_FILE="Versions.local.xcconfig"
CONTEXT_JSON="changelog-context.local.json"

get_key_from_xcconfig() {
  local xcconfig_file="$1"
  local key="${2:-APP_VERSION}"

  if [[ ! -f "$xcconfig_file" ]]; then
    echo "Error: file not found: $xcconfig_file" >&2
    return 1
  fi

  local value
  value="$(sed -nE "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*(.*)\$/\1/p" "$xcconfig_file")"
  value="${value%%[[:space:]]*}"

  if [[ -z "$value" ]]; then
    echo "Error: $key not found in $xcconfig_file" >&2
    return 1
  fi

  echo "$value"
}

update_json_property() {
  local json_file="$1"
  local property="$2"
  local prop_value="$3"

  if [[ ! -f "$json_file" ]]; then
    echo "Error: file not found: $json_file" >&2
    return 1
  fi

  sed -i '' -E \
    's/^([[:space:]]*"'$property'":[[:space:]]*")[^"]*(")/\1'"$prop_value"'\2/' \
    "$json_file"
}

rename_json_property() {
  local json_file="$1"
  local old_name="$2"
  local new_name="$3"

  if [[ ! -f "$json_file" ]]; then
    echo "Error: file not found: $json_file" >&2
    return 1
  fi

  sed -i '' -E \
    's/^([[:space:]]*")'$old_name'(":)/\1'"$new_name"'\2/' \
    "$json_file"
}


version="$(get_key_from_xcconfig $XC_CONFIG_FILE)"
update_json_property $CONTEXT_JSON "appVersion" "v$version"

if [ "$include_scope" == "dev" ]; then
  rename_json_property $CONTEXT_JSON "excludeTypes" "_excludeTypes"
elif [ "$include_scope" == "prod" ]; then
  rename_json_property $CONTEXT_JSON "_excludeTypes" "excludeTypes"
else
  echo "Pass dev or prod to exclude the dev scopes"
  exit 1
fi

npx conventional-changelog -p visualdiffer -c $CONTEXT_JSON
