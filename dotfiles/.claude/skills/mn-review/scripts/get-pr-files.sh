#!/bin/bash
# Get list of files changed in a PR
# Usage: get-pr-files.sh <PR_NUMBER_OR_URL>
# Falls back to worktree changed files if no PR specified

PR_ARG="$1"
if [ -z "$PR_ARG" ]; then
    # List all changed files in worktree (staged + unstaged + untracked)
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
    exit 0
fi

gh pr view "$PR_ARG" --json files --jq '.files[].path' 2>/dev/null || echo "No files"