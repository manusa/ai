#!/bin/bash
# Get the diff for a PR
# Usage: get-pr-diff.sh <PR_NUMBER_OR_URL>
# Falls back to worktree diff if no PR specified

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    # Show staged changes
    staged=$(git diff --cached 2>/dev/null)
    if [ -n "$staged" ]; then
        echo "=== STAGED CHANGES ==="
        echo "$staged"
        echo ""
    fi
    # Show unstaged changes
    unstaged=$(git diff 2>/dev/null)
    if [ -n "$unstaged" ]; then
        echo "=== UNSTAGED CHANGES ==="
        echo "$unstaged"
    fi
    # If no changes, indicate that
    if [ -z "$staged" ] && [ -z "$unstaged" ]; then
        echo "No changes in worktree"
    fi
    exit 0
fi

gh pr diff "$PR_ARG" 2>/dev/null || echo "No diff available"