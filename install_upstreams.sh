#!/bin/bash

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: SUBMODULES_HOME not available"
  exit 1
fi

SCRIPT_STRINGS="$SUBMODULES_HOME/Software-Toolkit/Utils/strings.sh"

if test -e "$SCRIPT_STRINGS"; then

  # shellcheck disable=SC1090
  . "$SCRIPT_STRINGS"

else

  echo "ERROR: Script not found '$SCRIPT_STRINGS'"
  exit 1
fi

DIR_UPSTREAMS="Upstreams"

if [ -n "$1" ]; then

  DIR_UPSTREAMS="$1"
fi

if test -e "$DIR_UPSTREAMS"; then

  echo "Upstreams sources path: '$DIR_UPSTREAMS'"

  UNSET_UPSTREAM_VARIABLES() {

    unset UPSTREAMABLE_REPOSITORY

    if [ -n "$UPSTREAMABLE_REPOSITORY" ]; then

      echo "ERROR: The UPSTREAMABLE_REPOSITORY environment variable is still set"
      exit 1
    fi
  }

  PROCESS_UPSTREAM() {

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

    HERE=$(pwd)
    PARENT=$(dirname "$HERE")
    GIT_FILE="$PARENT/.git"

    GIT_TYPE=$(file "$GIT_FILE")

    if echo "$GIT_TYPE" | grep ".git: directory"; then

      GIT_DIR="$GIT_FILE"

    else

      if echo "$GIT_TYPE" | grep ".git: ASCII text"; then

        PREFIX="gitdir: "
        GIT_CONTENT=$(cat "$GIT_FILE")

        if CHECK_CONTAINS "$GIT_CONTENT" "$PREFIX"; then

            GIT_DIR=$(echo "$GIT_CONTENT" | grep -o -P "(?<=$PREFIX).*(?=)")
            GIT_DIR="$PARENT/$GIT_DIR"

        fi
        
        echo "Git dir found at: '$GIT_DIR'"

      else

        echo "ERROR: Unsupported .git type '$GIT_TYPE'"
        exit 1
      fi
    fi

    if cd "$GIT_DIR"; then

      GIT_CONFIG="$GIT_DIR/config"

      if test -e "$GIT_CONFIG"; then

        PUSH_URL="pushurl = $UPSTREAM"

        if echo "$GIT_CONFIG_CONTENT" | grep "$PUSH_URL" >/dev/null 2>&1; then

          echo "Push URL is present: $PUSH_URL"
        fi

      else

        echo "ERROR: Git config not found at '$GIT_CONFIG'"
        exit 1
      fi

    else

      echo "ERROR: Could not go to '$GIT_DIR'"
      exit 1
    fi

    if ! cd "$HERE"; then

      echo "ERROR: Could not go back into '$HERE'"
      exit 1
    fi

    GIT_CONFIG_CONTENT=$(cat "$GIT_CONFIG")

    if [ "$GIT_CONFIG_CONTENT" = "" ]; then

      echo "ERROR: No Git config obtained"
      exit 1
    fi

    if echo "$GIT_CONFIG_CONTENT" | grep "$PUSH_URL" >/dev/null 2>&1; then

      echo "WARNING: Upstream remote '$NAME' already added"

    else

      git remote add "$NAME" "$UPSTREAM" && \
        echo "Upstream remote '$NAME' added"

      if git remote set-url --delete --push origin "$UPSTREAM"; then

        echo "Upstream push '$NAME' cleared"
      fi

      if git remote set-url --add --push origin "$UPSTREAM"; then

        echo "Upstream push '$NAME' added"

        if git remote add upstream "$UPSTREAM"; then

          echo "Upstream '$NAME' added"

        else

          echo "WARNING: Upstream '$NAME' not added"
        fi

      else

        echo "WARNING: Upstream push '$NAME' not added"
      fi
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

      echo "WARNING: Upstreams not found at '$DIR_UPSTREAMS'"
      exit 0
    fi
  done

else

  echo "WARNING: '$DIR_UPSTREAMS' sources path not found"
fi