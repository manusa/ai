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

if ! result=$(gh pr view "$PR_ARG" --json reviews,comments --jq '.reviews[].body, .comments[].body'); then
    echo "ERROR: could not fetch comments/reviews for PR '$PR_ARG' (see stderr above; this is a fetch failure, not a confirmed 'no comments')"
elif [ -z "$result" ]; then
    echo "No comments"
else
    printf '%s\n' "$result" | head -50
fi
