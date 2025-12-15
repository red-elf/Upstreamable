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

# Clone main repository with all submodules
git clone --recurse-submodules "$1" .

# Function to process a submodule
process_submodule() {

    local sm_path=$1
    local sm_name=$2
    
    echo "=== Processing submodule: $sm_name ($sm_path) ==="
    
    cd "$sm_path"
    
    # Get the branch configured in parent's .gitmodules
    # Navigate back to project root to check .gitmodules
    local project_root=$(git rev-parse --show-toplevel 2>/dev/null)
    cd "$project_root"
    
    # Extract the branch for this submodule from .gitmodules
    local configured_branch=$(git config --file .gitmodules submodule.$sm_path.branch || \
                             git config --file .gitmodules submodule.$sm_name.branch)
    
    cd "$sm_path"
    
    if [ -n "$configured_branch" ]; then
        
        echo "  Branch configured in .gitmodules: $configured_branch"
        
        # Check if branch exists locally
        if git show-ref --verify --quiet "refs/heads/$configured_branch"; then
        
            echo "  Branch exists locally, checking out"
            git checkout "$configured_branch"

        else
            
            echo "  Branch doesn't exist locally, checking out from origin"
            
            # Try to checkout from remote
            if git ls-remote --exit-code origin "$configured_branch" >/dev/null 2>&1; then
            
                git checkout -b "$configured_branch" "origin/$configured_branch"

            else
                
                echo "  WARNING: Branch '$configured_branch' doesn't exist on remote"
                # Fall back to default branch
                local default_branch=$(git remote show origin | grep "HEAD branch" | cut -d" " -f5)
                [ -z "$default_branch" ] && default_branch="main"
                git checkout "$default_branch"
            fi
        fi
        
        # Pull latest from the configured branch
        git pull origin "$configured_branch"
        
    else

        echo "  No branch configured in .gitmodules"
        
        # Try to get default branch
        local default_branch=$(git remote show origin | grep "HEAD branch" | cut -d" " -f5)
        
        if [ -z "$default_branch" ]; then
            
            # Try common branch names
            if git show-ref --verify --quiet refs/heads/main; then
            
                default_branch="main"

            elif git show-ref --verify --quiet refs/heads/master; then
                
                default_branch="master"

            else
                
                # Get first branch from remote
                default_branch=$(git branch -r | grep -v HEAD | head -1 | sed 's/origin\///')
            fi
        fi
        
        echo "  Using branch: $default_branch"
        git checkout "$default_branch"
        git pull origin "$default_branch"
    fi
    
    # Recursively process nested submodules
    if [ -f .gitmodules ]; then
        
        echo "  Processing nested submodules..."
        git submodule update --init --recursive
        
        # Recursively apply the same logic to nested submodules
        git submodule foreach --recursive '
            echo "    Nested: $name"
            configured_branch=$(git config --file ../../../.gitmodules submodule.$path.branch 2>/dev/null || \
                               git config --file ../../../.gitmodules submodule.$name.branch 2>/dev/null)
            
            if [ -n "$configured_branch" ]; then
                git checkout "$configured_branch" 2>/dev/null || git checkout -b "$configured_branch" "origin/$configured_branch"
                git pull origin "$configured_branch"
            else
                default_branch=$(git remote show origin | grep "HEAD branch" | cut -d" " -f5 2>/dev/null || echo "main")
                git checkout "$default_branch"
                git pull origin "$default_branch"
            fi
        '
    fi
    
    cd "$project_root"
}

# Get all submodules
echo "Initializing all submodules..."
git submodule update --init --recursive

# Process each submodule
git config --file .gitmodules --get-regexp path | while read key path; do
    
    # Extract submodule name from the key
    name=${key#submodule.}
    name=${name%.path}
    
    process_submodule "$path" "$name"
done

echo "=== All submodules processed ==="