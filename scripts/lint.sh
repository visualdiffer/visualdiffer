#!/usr/bin/env bash

set -euo pipefail

# Resolve symlinks, too
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PARENT_DIR="$DIR/.."

LINT_FLAG="${1:-m}"

if [ "$LINT_FLAG" == "p" ]
then
    (cd "$PARENT_DIR" && periphery scan )
else
    cd "$PARENT_DIR"

    SWIFT_CONFIG=.swiftlint.yml
    SWIFT_CONFIG_LOCAL=.swiftlint.local.yml


    if [ -e "$SWIFT_CONFIG_LOCAL" ]; then
        SWIFT_CONFIG=$SWIFT_CONFIG_LOCAL
    fi

    if [ "$LINT_FLAG" == "a" ]
    then
        swiftformat . && swiftlint --quiet --config $SWIFT_CONFIG
    else
        (git diff --name-only --diff-filter=ACM; git diff --cached --name-only --diff-filter=ACM) \
        | sort -u \
        | grep '\.swift$' \
        | xargs swiftformat && swiftlint --quiet --config $SWIFT_CONFIG
        echo "Applied format only to modified files, pass 'a' to format all"
    fi
    echo using $SWIFT_CONFIG
fi
