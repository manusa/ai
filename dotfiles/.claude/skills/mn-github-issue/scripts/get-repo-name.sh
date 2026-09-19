#!/bin/bash
# Get the repository name in owner/repo format
# Reports gh failures as errors (runs unsandboxed via sandbox.excludedCommands — keyring auth)

gh repo view --json nameWithOwner --jq '.nameWithOwner' || echo "ERROR: 'gh repo view' failed (exit $? — see stderr above; not in a GitHub repo, or a network/auth failure)"
