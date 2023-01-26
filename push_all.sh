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

  if echo "Upstream '$NAME': $UPSTREAM" && git push "$NAME"; then

    git fetch && git pull
  fi
}

cd "$DIR_UPSTREAMS" && echo "Processing upstreams from: $DIR_UPSTREAMS"

for i in *.sh; do

  UNSET_UPSTREAM_VARIABLES

  if test -e "$i"; then

    UPSTREAM_FILE="$(pwd)"/"$i"
    # shellcheck disable=SC1090
    echo "Processing the upstream file: $UPSTREAM_FILE" && . "$UPSTREAM_FILE"

    FILE_NAME=$(basename -- "$i")
    FILE_NAME="${FILE_NAME%.*}"
    FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')

    PROCESS_UPSTREAM "$UPSTREAMABLE_REPOSITORY" "$FILE_NAME"

  else

    echo "ERROR: '$i' not found at: '$(pwd)' (2)"
    exit 1
  fi
done

if git push --tags; then

  echo "All tags have been pushed with success"

else

  echo "ERROR: Tags have failed to be pushed pushed to upstream"
  exit 1
fi