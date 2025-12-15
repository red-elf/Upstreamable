#!/bin/bash

if [ -z "$1" ]; then
  
  echo "ERROR: Please provide the repository you want to clone"
  exit 1
fi

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

WHAT="$1"

# Clone main repository with all submodules into current directory
echo "Cloning repository into current directory..."
git clone --recurse-submodules "$1" .

# Store the current directory as project root
PROJECT_ROOT=$(pwd)

process_submodules

INSTALL_UPSTREAMS_SCRIPT="$SUBMODULES_HOME/Upstreamable/install_upstreams.sh"

if test -e "$PROJECT_ROOT/Upstreams" && test -e "$INSTALL_UPSTREAMS_SCRIPT"; then

  bash "$INSTALL_UPSTREAMS_SCRIPT" && echo "Upstreams have been installed with success"
fi