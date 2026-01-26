#!/bin/bash
# Get commits since the last tag
# Falls back to recent commits if no tags exist

tag=$(git tag --sort=-v:refname 2>/dev/null | head -1)
if [ -z "$tag" ]; then
    # No tags, show recent commits
    git log --oneline -20 2>/dev/null || echo "No commits"
else
    git log "$tag"..HEAD --oneline --no-merges 2>/dev/null || git log --oneline -20 2>/dev/null || echo "No commits"
fi