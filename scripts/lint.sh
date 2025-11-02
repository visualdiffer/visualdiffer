#!/bin/bash

# Resolve symlinks, too
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PARENT_DIR="$DIR/.."

if [ "$1" == "p" ]
then
    (cd "$PARENT_DIR" && periphery scan )
else
    cd "$PARENT_DIR"

    SWIFT_CONFIG=.swiftlint.yml
    SWIFT_CONFIG_LOCAL=.swiftlint.local.yml


    if [ -e "$SWIFT_CONFIG_LOCAL" ]; then
        SWIFT_CONFIG=$SWIFT_CONFIG_LOCAL
    fi

    swiftformat . && swiftlint --quiet --config $SWIFT_CONFIG
    echo using $SWIFT_CONFIG
fi
