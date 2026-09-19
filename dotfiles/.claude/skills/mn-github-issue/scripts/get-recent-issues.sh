#!/bin/bash
# Get recent issues for title/style reference
# Falls back to a message if the repository has no issues; reports gh failures
# as errors instead (runs unsandboxed via sandbox.excludedCommands — keyring auth)

if issues=$(gh issue list --limit 20 --json number,title --jq '.[] | "#\(.number) \(.title)"'); then
    printf '%s\n' "${issues:-No recent issues}"
else
    echo "ERROR: 'gh issue list' failed (exit $? — see stderr above; this is a fetch failure, not a confirmed empty issue list)"
fi
