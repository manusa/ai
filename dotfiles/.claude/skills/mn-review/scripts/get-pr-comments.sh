#!/bin/bash
# Get PR comments and reviews
# Usage: get-pr-comments.sh <PR_NUMBER_OR_URL>
# Falls back to "N/A" for local worktree reviews

PR_ARG="$1"
echo "[FETCHED: $(date -Iseconds)]"
echo ""
if [ -z "$PR_ARG" ]; then
    echo "N/A - Local worktree review (no PR comments)"
    exit 0
fi

result=$(gh pr view "$PR_ARG" --json reviews,comments --jq '.reviews[].body, .comments[].body' 2>/dev/null | head -50)
if [ -z "$result" ]; then
    echo "No comments"
else
    echo "$result"
fi