#!/bin/bash
# mn-session-retrospective :: get-session-commands.sh
# Best-effort augmentation: pulls the Bash commands run THIS session from the
# transcript and auto-flags the patterns that defeat the permission allowlist
# (pipes, chaining, command substitution, leading cd) plus the read-only filters
# used. The transcript format is an internal Claude Code detail — this degrades
# gracefully and never errors. Your OWN live memory of the session is the primary
# source; this just survives context compaction and adds deterministic flags.
set -u

echo "[FETCHED: $(date -Iseconds)]"
echo ""

# Locate the current session transcript by session id; fall back to newest.
TX=""
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  TX="$(ls "$HOME"/.claude/projects/*/"${CLAUDE_CODE_SESSION_ID}".jsonl 2>/dev/null | head -1)"
fi
[ -z "$TX" ] && TX="$(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -1)"
if [ -z "$TX" ] || [ ! -f "$TX" ]; then
  echo "No transcript found — rely on your live memory of the session."
  exit 0
fi
echo "transcript: $TX"
if ! command -v jq >/dev/null 2>&1; then
  echo "jq unavailable — rely on your live memory of the session."
  exit 0
fi

TMP="$(mktemp /tmp/mn-retro-cmds.XXXXXX 2>/dev/null)" || TMP=""
if [ -z "$TMP" ]; then
  echo "Could not create a temp file under /tmp — rely on your live memory."
  exit 0
fi
trap 'rm -f "$TMP"' EXIT

jq -r 'select(.type=="assistant") | .message.content[]?
       | select(.type=="tool_use" and .name=="Bash") | .input.command' \
   "$TX" 2>/dev/null > "$TMP"

total="$(grep -c '' "$TMP" 2>/dev/null || echo 0)"
echo "Bash tool invocations captured (lines; multi-line commands count as several): ${total}"
echo ""
echo "NOTE: some lines below are this retrospective's own scaffolding — ignore those."
echo "      Lines are split on newlines, so a multi-line command shows as several lines."
echo ""

echo "### Piped / chained commands ( | && ; ) — EVERY part must be independently allow-listed,"
echo "### else the whole command prompts. This is the #1 cause of avoidable prompts."
grep -nE '[|]|&&|;' "$TMP" 2>/dev/null | sort -u | head -60
echo ""

echo "### Command substitution \$( ... ) — never allow-listable, always prompts"
grep -nE '\$\(' "$TMP" 2>/dev/null | sort -u | head -30
echo "### Backtick substitution"
grep -nF '`' "$TMP" 2>/dev/null | sort -u | head -15
echo ""

echo "### Leading cd (defeats allow rules AND the excludedCommands match for git/podman/make)"
grep -nE '^[[:space:]]*cd[[:space:]]' "$TMP" 2>/dev/null | sort -u | head -20
echo ""

echo "### Read-only filters used this session — cross-check get-permissions: which are NOT"
echo "### in permissions.allow? Adding the safe ones removes the prompt on '<allowed> | <filter>'."
grep -owE 'tail|sort|uniq|cut|column|nl|comm|paste|rev|fold|tac|diff|tr|awk|sed|xargs|head|wc|tee|grep|jq' "$TMP" 2>/dev/null | sort | uniq -c | sort -rn
echo ""

echo "### All distinct command lines (review for anything that shouldn't have needed a prompt)"
sort -u "$TMP" 2>/dev/null | head -150
