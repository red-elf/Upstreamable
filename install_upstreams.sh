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

        if check_contains "$GIT_CONTENT" "$PREFIX"; then

            GIT_DIR=$(echo "$GIT_CONTENT" | grep -o -P "(?<=$PREFIX).*(?=)")
            GIT_DIR="$PARENT/$GIT_DIR"

        fi
        
        echo "Git dir found at: '$GIT_DIR'"

      else

        echo "ERROR: Unsupported .git type '$GIT_TYPE'"
        exit 1
      fi
    fi

    GIT_CONFIG_CONTENT=""

    if cd "$GIT_DIR"; then

      GIT_CONFIG="$GIT_DIR/config"

      if test -e "$GIT_CONFIG"; then

        GIT_CONFIG_CONTENT=$(cat "$GIT_CONFIG")
        PUSH_URL="pushurl = $UPSTREAM"

        if echo "$GIT_CONFIG_CONTENT" | grep "$PUSH_URL" >/dev/null 2>&1; then

          echo "Push URL is present: $PUSH_URL"

          TRIM_LINES() {

            if [ -z "$1" ]; then

              echo "ERROR: File parameter is mandatoy"
              exit 1
            fi

            FILE_TO_TRIM="$1"

            echo "Trimming: $FILE_TO_TRIM"

            FILE_TMP="$FILE_TO_TRIM.tmp"

            if cp "$FILE_TO_TRIM" "$FILE_TMP"; then

                echo "Working file created: $FILE_TMP"

            else

              echo "ERROR: Could not create tmp file '$GIT_CONFIG_TMP'"
              exit 1
            fi

            # TODO: Implement and move to string utils
            #
            #     GIT_CONFIG_TMP_CONTENT=$(cat "$GIT_CONFIG_TMP")
      
            #     if [ "$GIT_CONFIG_TMP_CONTENT" = "" ]; then

            #       echo "ERROR: Empty tmp file '$GIT_CONFIG_TMP'"
            #       exit 1

            #     else

            #       if [ "$GIT_CONFIG_TMP_CONTENT" = "$GIT_CONFIG_CONTENT" ]; then

            #         echo "No changes in Git config content"

            #       else

            #         SUFIX=$(($(date +%s%N)/1000000))

            #         if ! cp "$GIT_CONFIG" "$GIT_CONFIG.$SUFIX.bak"; then

            #             echo "ERROR: Could not create a backup of '$GIT_CONFIG'"
            #             exit 1
            #         fi

            #         if echo "$GIT_CONFIG_TMP_CONTENT" > "$GIT_CONFIG"; then

            #           echo "Changes have been applied to Git config '$GIT_CONFIG'"

            #         else

            #           echo "ERROR: Failed to apply changes to Git config '$GIT_CONFIG'"
            #           exit 1
            #         fi
            #       fi

            #       if rm -f "$GIT_CONFIG_TMP"; then

            #         echo "Tmp file removed: '$GIT_CONFIG_TMP'"

            #       else

            #         echo "ERROR: Tmp file was not removed '$GIT_CONFIG_TMP'"
            #         exit 1
            #       fi

            #     fi
          }

          TRIM_LINES "$GIT_CONFIG_TMP"
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

    if [ "$GIT_CONFIG_CONTENT" = "" ]; then

      echo "ERROR: No Git config obtained"
      exit 1
    fi

    if echo "$GIT_CONFIG_CONTENT" | grep "$PUSH_URL" >/dev/null 2>&1; then

      echo "WARNING: Upstream remote '$NAME' already added"

    else

      git remote add "$NAME" "$UPSTREAM" && \
        echo "Upstream remote '$NAME' added"

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