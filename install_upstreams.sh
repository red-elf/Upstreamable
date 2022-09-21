#!/bin/bash

DIR_UPSTREAMS="Upstreams"

if [ -n "$1" ]; then

  DIR_UPSTREAMS="$1"
fi

echo "Upstreams sources path: '$DIR_UPSTREAMS'"

function UNSET_UPSTREAM_VARIABLES {

  unset UPSTREAMABLE_REPOSITORY

  if [ -n "$UPSTREAMABLE_REPOSITORY" ]; then

    echo "ERROR: The UPSTREAMABLE_REPOSITORY environment variable is still set"
    exit 1
  fi
}

function PROCESS_UPSTREAM {

  if [ -z "$1" ]; then

    echo "ERROR: No upstream repository provided"
    exit 1
  fi

  if [ -z "$2" ]; then

    echo "ERROR: No upstream name provided"
    exit 1
  fi

  UPSTREAM="$1"
  NAME="$2"

  echo "Upstream '$NAME': $UPSTREAM"


}

for i in "$DIR_UPSTREAMS"/*.sh; do

  UNSET_UPSTREAM_VARIABLES

  if test -e "$i"; then

    echo "Processing upstream file: $i"

    # shellcheck disable=SC1090
    . "$i"

    FILE_NAME=$(basename -- "$i")
    FILE_NAME="${FILE_NAME%.*}"
    FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
    PROCESS_UPSTREAM "$UPSTREAMABLE_REPOSITORY" "$FILE_NAME"

  else

    echo "ERROR: '$i' not found at: '$(pwd)'"
    exit 1
  fi
done