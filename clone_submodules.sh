#!/bin/bash

if [ -z "$SUBMODULES_HOME" ]; then
  
  echo "ERROR: SUBMODULES_HOME not available"
  exit 1
fi

SUBMODULES_INCLUDES="$SUBMODULES_HOME/Upstreamable/submodules.sh"

if [ -z "$SUBMODULES_INCLUDES" ]; then
  
  echo "ERROR: '$SUBMODULES_INCLUDES' not found"
  exit 1
fi

. "$SUBMODULES_INCLUDES"

# Store the current directory as project root
PROJECT_ROOT=$(pwd)

process_submodules
