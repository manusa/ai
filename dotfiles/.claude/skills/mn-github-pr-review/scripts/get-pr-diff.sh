#!/bin/bash
# Get the diff for a PR
# Usage: get-pr-diff.sh <PR_NUMBER_OR_URL>
# Falls back to "No diff available" if PR not found

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    echo "No PR specified"
    exit 0
fi

gh pr diff "$PR_ARG" 2>/dev/null || echo "No diff available"