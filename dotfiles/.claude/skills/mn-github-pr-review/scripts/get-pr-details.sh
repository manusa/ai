#!/bin/bash
# Get PR details for the specified PR number/URL
# Usage: get-pr-details.sh <PR_NUMBER_OR_URL>
# Falls back to error message if PR not found

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    echo "No PR specified"
    exit 0
fi

gh pr view "$PR_ARG" 2>/dev/null || echo "PR not found: $PR_ARG"