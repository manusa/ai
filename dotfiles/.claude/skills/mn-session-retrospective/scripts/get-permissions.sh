#!/bin/bash
# mn-session-retrospective :: get-permissions.sh
# Compact view of the CURRENT permission + sandbox config, so each finding can be
# checked against what is already allowed and turned into a precise addition.
# Read-only.
set -u

REPO="${MN_PROJECTS:-$HOME/00-MN/projects}/manusa/ai"
SETTINGS="$REPO/dotfiles/.claude/settings.json"

echo "[FETCHED: $(date -Iseconds)]"
echo "source: $SETTINGS"
echo ""

if [ ! -f "$SETTINGS" ]; then
  echo "ERROR: settings.json not found at the path above — confirm DOTFILES_REPO first."
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq unavailable — Read $SETTINGS directly instead."
  exit 0
fi

echo "## sandbox flags"
jq -r '.sandbox | "enabled=\(.enabled)  autoAllowBashIfSandboxed=\(.autoAllowBashIfSandboxed)  allowUnsandboxedCommands=\(.allowUnsandboxedCommands)"' "$SETTINGS" 2>/dev/null
echo ""

echo "## permissions.allow  (auto-approved, no prompt)"
jq -r '.permissions.allow[]?' "$SETTINGS" 2>/dev/null
echo ""

echo "## permissions.ask  (always prompts — keep all mutating ops here)"
jq -r '.permissions.ask[]?' "$SETTINGS" 2>/dev/null
echo ""

echo "## permissions.deny"
deny="$(jq -r '.permissions.deny[]?' "$SETTINGS" 2>/dev/null)"
[ -z "$deny" ] && echo "(empty)" || printf '%s\n' "$deny"
echo ""

echo "## sandbox.excludedCommands  (run OUTSIDE the sandbox — keyring/network/gpg work)"
jq -r '.sandbox.excludedCommands[]?' "$SETTINGS" 2>/dev/null
echo ""

echo "## sandbox.network.allowedDomains  (reachable while sandboxed)"
jq -r '.sandbox.network.allowedDomains[]?' "$SETTINGS" 2>/dev/null
echo ""

echo "## sandbox.filesystem.allowWrite  (writable while sandboxed)"
jq -r '.sandbox.filesystem.allowWrite[]?' "$SETTINGS" 2>/dev/null
