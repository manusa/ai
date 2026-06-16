#!/bin/bash
# mn-session-retrospective :: get-skills-inventory.sh
# Lists the repo's skills (name + description) and agents so a finding can target
# the right one for improvement. Read-only.
set -u

REPO="${MN_PROJECTS:-$HOME/00-MN/projects}/manusa/ai"
SKILLS="$REPO/dotfiles/.claude/skills"
AGENTS="$REPO/dotfiles/.claude/agents"

echo "[FETCHED: $(date -Iseconds)]"
echo ""

echo "## Skills ($SKILLS)"
if [ -d "$SKILLS" ]; then
  for d in "$SKILLS"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    name="$(basename "$d")"
    desc="$(grep -m1 '^description:' "${d}SKILL.md" | sed 's/^description:[[:space:]]*//')"
    extra=""
    [ -d "${d}scripts" ] && extra=" [scripts/]"
    [ -d "${d}guidelines" ] && extra="$extra [guidelines/]"
    echo "- ${name}${extra}"
    [ -n "$desc" ] && echo "    ${desc}"
  done
else
  echo "(skills dir missing)"
fi
echo ""

echo "## Agents ($AGENTS)"
if [ -d "$AGENTS" ]; then
  for f in "$AGENTS"/*.md; do
    [ -f "$f" ] || continue
    echo "- $(basename "$f" .md)"
  done
else
  echo "(none)"
fi
