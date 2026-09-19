#!/bin/bash
# Get merged PRs since the last release tag
# Falls back to "No PRs or no tag found" if no PRs or tags exist; reports gh failures
# as errors instead (runs unsandboxed via sandbox.excludedCommands — keyring auth)

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

gh pr list --state merged --search "merged:>=$tag_date" --json number,title,author,mergedAt,labels --limit 100 || echo "ERROR: 'gh pr list' failed (exit $? — see stderr above; this is a fetch failure, not a confirmed empty PR list)"