#!/bin/bash
# Get merged PRs since the last release tag
# Falls back to "No PRs or no tag found" if no PRs or tags exist

tag=$(git tag --sort=-v:refname 2>/dev/null | head -1)
if [ -z "$tag" ]; then
    echo "No PRs or no tag found"
    exit 0
fi

tag_date=$(git log -1 --format=%as "$tag" 2>/dev/null)
if [ -z "$tag_date" ]; then
    echo "No PRs or no tag found"
    exit 0
fi

gh pr list --state merged --search "merged:>=$tag_date" --json number,title,author,mergedAt,labels --limit 100 2>/dev/null || echo "No PRs or no tag found"