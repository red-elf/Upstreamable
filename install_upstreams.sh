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

for i in "$DIR_UPSTREAMS"/*.sh; do

  UNSET_UPSTREAM_VARIABLES

  if test -e "$i"; then

    echo "Processing upstream file: $i"

    # shellcheck disable=SC1090
    . "$i"

    echo "Upstream: $UPSTREAMABLE_REPOSITORY"

  else

    echo "ERROR: '$i' not found at: '$(pwd)'"
    exit 1
  fi
done