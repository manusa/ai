#!/bin/bash
# Get available labels for the current repository
# Falls back to a message if the repository has no labels; reports gh failures
# as errors instead (runs unsandboxed via sandbox.excludedCommands — keyring auth)

if labels=$(gh label list --json name,description --jq '.[] | "- \(.name): \(.description)"'); then
    printf '%s\n' "${labels:-No labels found - will suggest common labels}"
else
    echo "ERROR: 'gh label list' failed (exit $? — see stderr above; this is a fetch failure, not a confirmed empty label set)"
fi
