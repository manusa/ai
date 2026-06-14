#!/bin/bash
# Get list of files changed in a PR
# Usage: get-pr-files.sh <PR_NUMBER_OR_URL>
# Falls back to worktree changed files if no PR specified

PR_ARG="$1"
echo "[FETCHED: $(date -Iseconds)]"
echo ""
if [ -z "$PR_ARG" ]; then
    # List all changed files in worktree (staged + unstaged + untracked)
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
    exit 0
fi

if files=$(gh pr view "$PR_ARG" --json files --jq '.files[].path'); then
    # Cache for sibling scripts (get-language-guidelines) so the identical
    # `gh pr view --json files` isn't fetched twice in one review run.
    printf '%s\n' "$files" > "/tmp/mn-review-files-$(printf '%s' "$PR_ARG" | tr -c 'A-Za-z0-9' '_').txt" 2>/dev/null || true
    printf '%s\n' "$files"
else
    echo "ERROR: could not fetch changed files for PR '$PR_ARG' (exit $? — see stderr above; this is a fetch failure, not a confirmed empty file set)"
fi
