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

    # TODO:
    #
    # cd ../../.git/modules/_Submodules/Software-Toolkit
    #
    # more config
    #   [core]
    #   repositoryformatversion = 0
    #   filemode = true
    #   bare = false
    #   logallrefupdates = true
    #   worktree = ../../../../_Submodules/Software-Toolkit
    # [remote "origin"]
    #   url = git@github.com:red-elf/Software-Toolkit.git
    #   fetch = +refs/heads/*:refs/remotes/origin/*
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    #   pushurl = git@gitflic.ru:red-elf/software-toolkit.git
    #   pushurl = git@github.com:red-elf/Software-Toolkit.git
    # [branch "main"]
    #   remote = origin
    #   merge = refs/heads/main
    # [remote "gitflic"]
    #   url = git@gitflic.ru:red-elf/software-toolkit.git
    #   fetch = +refs/heads/*:refs/remotes/gitflic/*
    # [remote "upstream"]
    #   url = git@gitflic.ru:red-elf/software-toolkit.git
    #   fetch = +refs/heads/*:refs/remotes/upstream/*
    # [remote "github"]
    #   url = git@github.com:red-elf/Software-Toolkit.git
    #   fetch = +refs/heads/*:refs/remotes/github/*
    # [pull]
    #   rebase = false
    # 
    # ^^^ Remove all duplicates, for new installations check of the existing strings existence!   

    HERE=$(pwd)
    PARENT=$(dirname "$HERE")
    GIT_FILE="$PARENT/.git"

    GIT_TYPE=$(file "$GIT_FILE")

    if echo "$GIT_TYPE" | grep ".git: directory"; then

      GIT_DIR="$GIT_FILE"

    else

      if echo "$GIT_TYPE" | grep ".git: ASCII text"; then

        GIT_CONTENT=$(cat "$GIT_FILE")
        
        # TODO: Obtain the directory path, set and enter.
        #
        #   gitdir: ../../.git/modules/_Submodules/Software-Toolkit
        #

      else

        echo "ERROR: Unsupported .git type '$GIT_TYPE'"
        exit 1
      fi
    fi

    if ! cd "$HERE"; then

      echo "ERROR: Could not go back into '$HERE'"
      exit 1
    fi

    ORIGIN=$(git remote show origin)

    if check_contains "$ORIGIN" "Push  URL: $UPSTREAM"; then

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