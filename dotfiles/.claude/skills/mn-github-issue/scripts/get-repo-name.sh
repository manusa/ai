#!/bin/bash
# Get the repository name in owner/repo format
# Falls back to "Unknown repository" if not in a git repo or gh CLI fails

gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "Unknown repository"