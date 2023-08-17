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
. "$FILE_RC"

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: The SUBMODULES_HOME is not defined"
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

UPSTREAMS="Upstreams"
DIR_UPSTREAMS="$UPSTREAMS"

if [ -n "$1" ]; then

  DIR_UPSTREAMS="$1"

  if ! echo "$DIR_UPSTREAMS" | grep "$UPSTREAMS"; then

      DIR_UPSTREAMS="$DIR_UPSTREAMS/$UPSTREAMS"
  fi
fi

if [ -n "$2" ]; then

  HOOK_SCRIPT="$2"

  echo "Hook script set to: $HOOK_SCRIPT"
fi

SCRIPT_PUSH_ALL="$SUBMODULES_HOME/Software-Toolkit/Utils/Git/push_all.sh"

if test -e "$SCRIPT_PUSH_ALL"; then

  if sh "$SCRIPT_PUSH_ALL" "$DIR_UPSTREAMS"; then

    echo "Push all success"

  else

    echo "ERROR: Push all failure"
    exit 1
  fi

else

  echo "ERROR: Script not found '$SCRIPT_PUSH_ALL'"
  exit 1
fi

if test -e "$HOOK_SCRIPT"; then

  echo "Executing the hook script: $HOOK_SCRIPT"

  sh "$HOOK_SCRIPT" "$(pwd)/$DIR_UPSTREAMS"
fi