#!/bin/bash
# mn-session-retrospective :: get-context.sh
# Resolves the edit targets for the retrospective (the dotfiles repo) and the
# current session's working project. Read-only; no prompts (covered by the
# Bash(~/.claude/skills/:*) allow rule).
set -u

echo "[FETCHED: $(date -Iseconds)]"
echo ""

# ---------------------------------------------------------------------------
# 1. Resolve the dotfiles repo — home of the global config + skills to edit.
#    Primary: $MN_PROJECTS/manusa/ai. Fallback: follow the ~/.claude symlink.
# ---------------------------------------------------------------------------
REPO=""
RESOLVED_BY=""
if [ -n "${MN_PROJECTS:-}" ] && [ -d "${MN_PROJECTS}/manusa/ai/dotfiles/.claude" ]; then
  REPO="${MN_PROJECTS}/manusa/ai"
  RESOLVED_BY="\$MN_PROJECTS/manusa/ai"
else
  link="$(readlink "$HOME/.claude/settings.json" 2>/dev/null || true)"
  if [ -n "$link" ]; then
    abs="$(cd "$HOME/.claude" 2>/dev/null && cd "$(dirname "$link")" 2>/dev/null && pwd -P)"
    if [ -n "$abs" ]; then
      REPO="${abs%/dotfiles/.claude}"
      RESOLVED_BY="readlink(~/.claude/settings.json)"
    fi
  fi
fi

if [ -z "$REPO" ]; then
  echo "DOTFILES_REPO: UNRESOLVED"
  echo "  \$MN_PROJECTS is unset/invalid and ~/.claude/settings.json is not a symlink"
  echo "  into the repo. Ask the user for the dotfiles repo path before editing anything."
  exit 0
fi
echo "DOTFILES_REPO: $REPO   (resolved via $RESOLVED_BY)"
echo ""

CLAUDE_DIR="$REPO/dotfiles/.claude"
echo "Edit targets — operate on these SOURCE files (version-controlled), not the ~/.claude symlinks:"
for rel in "settings.json" "CLAUDE.md" "skills" "agents"; do
  p="$CLAUDE_DIR/$rel"
  if [ -e "$p" ]; then echo "  [OK]      $p"; else echo "  [MISSING] $p"; fi
done
echo ""

# Stow sanity: confirm the live ~/.claude files point back into the repo, so the
# user knows edits take effect immediately (no re-stow needed).
echo "Stow status (live ~/.claude -> repo):"
for rel in "settings.json" "CLAUDE.md"; do
  live="$HOME/.claude/$rel"
  if [ -L "$live" ]; then
    echo "  $live -> $(readlink "$live")"
  elif [ -e "$live" ]; then
    echo "  $live is a REAL FILE (not stowed) — repo edits will NOT apply until stowed."
  else
    echo "  $live MISSING"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 2. The current session's working project (may differ from the dotfiles repo).
#    PROJECT-LOCAL fixes (project-specific permissions, skills, docs) land here.
# ---------------------------------------------------------------------------
echo "Current session project — target for PROJECT-LOCAL fixes:"
echo "  cwd: $PWD"
top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$top" ]; then
  echo "  git root: $top"
  echo "  branch:   $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if [ "$top" = "$REPO" ]; then
    echo "  NOTE: this session ran INSIDE the dotfiles repo — global and project scope coincide."
  fi
  echo "  project-local Claude config (edit these for project-specific findings):"
  for p in ".claude/settings.json" ".claude/settings.local.json" ".claude/skills" ".claude/CLAUDE.md" "AGENTS.md" "CLAUDE.md"; do
    if [ -e "$top/$p" ]; then echo "    [present] $top/$p"; else echo "    [absent ] $p"; fi
  done
else
  echo "  (not a git repository)"
fi
