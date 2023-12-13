#!/bin/bash

DIR_HOME=$(eval echo ~"$USER")
FILE_ZSH_RC="$DIR_HOME/.zshrc"
FILE_BASH_RC="$DIR_HOME/.bashrc"

FILE_RC=""
    
if test -e "$FILE_ZSH_RC"; then

  FILE_RC="$FILE_ZSH_RC"

else

    if test -e "$FILE_BASH_RC"; then

      FILE_RC="$FILE_BASH_RC"

    else

      echo "ERROR: No '$FILE_ZSH_RC' or '$FILE_BASH_RC' found on the system"
      exit 1
    fi
fi

# shellcheck disable=SC1090
. "$FILE_RC" >/dev/null 2>&1

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: The SUBMODULES_HOME is not defined"
  exit 1
fi

SCRIPT_COMMIT="$SUBMODULES_HOME/Software-Toolkit/Utils/Git/commit.sh"

if test -e "$SCRIPT_COMMIT"; then

  MESSAGE="Auto-commit $SESSION"

  if [ -n "$1" ]; then

      MESSAGE="$1"
  fi

  if ! bash "$SCRIPT_COMMIT" "$MESSAGE"; then

    echo "ERROR: Commit failure"
    exit 1
  fi

else

  echo "ERROR: Script not found '$SCRIPT_COMMIT'"
  exit 1
fi
