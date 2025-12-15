#!/bin/bash

process_submodule() {

    if [ -z "$PROJECT_ROOT" ]; then
        
        # Store the current directory as project root
        PROJECT_ROOT=$(pwd)
    fi
    
    local sm_path=$1
    local sm_name=$2
    
    echo "=== Processing submodule: $sm_name ($sm_path) ==="
    
    # Navigate to submodule
    cd "$sm_path" || { echo "Cannot navigate to $sm_path"; return 1; }
    
    # Extract the branch for this submodule from .gitmodules (in project root)
    local configured_branch
    configured_branch=$(git -C "$PROJECT_ROOT" config --file "$PROJECT_ROOT/.gitmodules" submodule.$sm_path.branch 2>/dev/null || \
                       git -C "$PROJECT_ROOT" config --file "$PROJECT_ROOT/.gitmodules" submodule.$sm_name.branch 2>/dev/null)
    
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
                local default_branch
                default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d" " -f5)
                [ -z "$default_branch" ] && default_branch="main"
                git checkout "$default_branch" 2>/dev/null || git checkout master 2>/dev/null
            fi
        fi
        
        # Pull latest from the configured branch
        git pull origin "$configured_branch" 2>/dev/null || echo "  Could not pull from $configured_branch"
        
    else
        echo "  No branch configured in .gitmodules"
        
        # Try to get default branch
        local default_branch
        default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d" " -f5)
        
        if [ -z "$default_branch" ]; then
            # Try common branch names
            if git show-ref --verify --quiet refs/heads/main; then
                default_branch="main"
            elif git show-ref --verify --quiet refs/heads/master; then
                default_branch="master"
            else
                # Get first branch from remote
                default_branch=$(git branch -r 2>/dev/null | grep -v HEAD | head -1 | sed 's/origin\///' || echo "main")
            fi
        fi
        
        echo "  Using branch: $default_branch"
        git checkout "$default_branch" 2>/dev/null || git checkout master 2>/dev/null || true
        git pull origin "$default_branch" 2>/dev/null || echo "  Could not pull from $default_branch"
    fi
    
    # Recursively process nested submodules
    if [ -f .gitmodules ]; then
        echo "  Processing nested submodules..."
        git submodule update --init --recursive
        
        # Store current submodule directory
        local submodule_dir=$(pwd)
        
        # Process nested submodules
        git submodule foreach --recursive '
            echo "    Nested: $name"
            cd "$toplevel/$path"
            
            # For nested submodules, look for .gitmodules in the immediate parent
            parent_gitmodules="$toplevel/../.gitmodules"
            if [ -f "$toplevel/.gitmodules" ]; then
                parent_gitmodules="$toplevel/.gitmodules"
            fi
            
            configured_branch=$(git config --file "$parent_gitmodules" submodule.$path.branch 2>/dev/null || \
                               git config --file "$parent_gitmodules" submodule.$name.branch 2>/dev/null)
            
            if [ -n "$configured_branch" ]; then
                git checkout "$configured_branch" 2>/dev/null || git checkout -b "$configured_branch" "origin/$configured_branch" 2>/dev/null
                git pull origin "$configured_branch" 2>/dev/null || true
            else
                default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d" " -f5 2>/dev/null || echo "main")
                git checkout "$default_branch" 2>/dev/null || git checkout master 2>/dev/null
                git pull origin "$default_branch" 2>/dev/null || true
            fi
        '
    fi
    
    # Return to project root
    cd "$PROJECT_ROOT" || return 1
}

process_submodules() {

    # Check if .gitmodules exists before trying to process
    if [ -f ".gitmodules" ]; then
        
        # Get all submodules
        echo "Initializing all submodules..."
        git submodule update --init --recursive

        # Process each submodule
        git config --file .gitmodules --get-regexp path | while read key path; do
        
            # Extract submodule name from the key
            name=${key#submodule.}
            name=${name%.path}
            
            # Only process if the submodule directory exists
            if [ -d "$path" ]; then
        
                process_submodule "$path" "$name"

            else
                
                echo "Warning: Submodule directory $path not found. Initializing..."
                git submodule update --init "$path" 2>/dev/null && process_submodule "$path" "$name"
            fi
        done

        echo "=== All submodules processed ==="

    else
        
        echo "No .gitmodules file found. No submodules to process."
    fi
}
