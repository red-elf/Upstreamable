#!/bin/bash

if [ -z "$1" ]; then

  echo "ERROR: Please provide the repository you want to clone"
  exit 1
fi

if [ -z "$SUBMODULES_HOME" ]; then

  echo "ERROR: SUBMODULES_HOME not available"
  exit 1
fi

WHAT="$1"

git clone --recurse-submodules --remote-submodules "$1"
