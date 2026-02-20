#!/bin/bash
# Get PR details for the specified PR number/URL
# Usage: get-pr-details.sh <PR_NUMBER_OR_URL>
# Falls back to worktree changes if no PR specified

PR_ARG="$1"
echo "[FETCHED: $(date -Iseconds)]"
echo ""
if [ -z "$PR_ARG" ]; then
    echo "MODE: Local worktree changes review"
    echo ""
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "Repository: $(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Working tree status:"
    git status --short 2>/dev/null || echo "Unable to get git status"
    exit 0
fi

gh pr view "$PR_ARG" 2>/dev/null || echo "PR not found: $PR_ARG"