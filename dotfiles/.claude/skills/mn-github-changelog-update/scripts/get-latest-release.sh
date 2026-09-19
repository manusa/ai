#!/bin/bash
# Get the latest GitHub release
# Falls back to "No releases found" if no releases exist; reports gh failures
# as errors instead (runs unsandboxed via sandbox.excludedCommands — keyring auth)

if release=$(gh release list --limit 1); then
    printf '%s\n' "${release:-No releases found}"
else
    echo "ERROR: 'gh release list' failed (exit $? — see stderr above; this is a fetch failure, not a confirmed absence of releases)"
fi
