#!/bin/bash
# Get PR comments and reviews
# Usage: get-pr-comments.sh <PR_NUMBER_OR_URL>
# Falls back to "No comments" if PR not found or no comments

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    echo "No PR specified"
    exit 0
fi

result=$(gh pr view "$PR_ARG" --json reviews,comments --jq '.reviews[].body, .comments[].body' 2>/dev/null | head -50)
if [ -z "$result" ]; then
    echo "No comments"
else
    echo "$result"
fi