#!/bin/bash
# Get list of files changed in a PR
# Usage: get-pr-files.sh <PR_NUMBER_OR_URL>
# Falls back to "No files" if PR not found

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    echo "No PR specified"
    exit 0
fi

gh pr view "$PR_ARG" --json files --jq '.files[].path' 2>/dev/null || echo "No files"