#!/bin/bash
# get-context.sh [TARGET]: the mn-pr context for the repository or worktree at
# TARGET (default: the cwd). Read-only, and it never exits non-zero, because a
# failing pre-fetch aborts the whole skill.

export GIT_OPTIONAL_LOCKS=0 PAGER=cat GIT_PAGER=cat NO_COLOR=1

target="${1:-.}"
case "$target" in
    "~") target="$HOME" ;;
    "~/"*) target="$HOME/${target#\~/}" ;;
esac

# Porcelain git diff rewrites the index unless auto-refresh is off; the target
# may be a worktree another agent is using.
g() { git -C "$target" -c diff.autoRefreshIndex=false "$@"; }

top=$(g rev-parse --show-toplevel 2>/dev/null)
if [ -z "$top" ]; then
    echo "NOT A GIT REPOSITORY: $target (cwd: $PWD)"
    echo "Run ~/.claude/skills/mn-pr/scripts/get-context.sh <repo-or-worktree-path> (SKILL.md, Target)."
    exit 0
fi
target="$top"

default=$(g symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
default="${default#origin/}"
if [ -z "$default" ]; then
    default=$(g remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
fi
[ -n "$default" ] || default=main

git_dir=$(g rev-parse --path-format=absolute --git-dir 2>/dev/null)
common_dir=$(g rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ "$git_dir" = "$common_dir" ]; then worktree=main; else worktree=linked; fi

# Fingerprint: HEAD, the staged blobs, and every changed or untracked path with
# its working-tree blob, so Execute can tell whether the change moved since
# Prepare. The branch is left out: Execute checks it on its own.
fingerprint() {
    g rev-parse HEAD 2>/dev/null
    g diff-index --cached --raw -z HEAD 2>/dev/null
    local entry status path
    while IFS= read -r -d '' entry; do
        status="${entry:0:2}"
        path="${entry:3}"
        case "$status" in R*|C*) IFS= read -r -d '' _ ;; esac
        printf '%s %s ' "$status" "$path"
        if [ -f "$target/$path" ]; then g hash-object -- "$path"; else echo -; fi
    done < <(g status --porcelain=v1 -z --untracked-files=all 2>/dev/null)
}

echo "#### Target"
echo "$target"
echo ""
echo "#### Current Branch"
g branch --show-current 2>/dev/null || echo "UNKNOWN"
echo ""
echo "#### Default Branch"
echo "$default"
echo ""
echo "#### Worktree Type"
echo "$worktree"
echo ""
echo "#### Remotes"
remotes=$(g remote -v 2>/dev/null)
echo "${remotes:-No remotes configured}"
echo ""
echo "#### Git Status"
status=$(g status --short 2>/dev/null)
echo "${status:-(clean)}"
echo ""
echo "#### Changes Summary"
changes=$(g diff HEAD --stat 2>/dev/null || g diff --stat 2>/dev/null)
echo "${changes:-No changes}"
echo ""
echo "#### Unpushed Commits"
if upstream=$(g rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    echo "(against $upstream)"
    commits=$(g log --oneline '@{u}..HEAD' 2>/dev/null)
elif g rev-parse --verify --quiet "refs/remotes/origin/$default" >/dev/null; then
    echo "No upstream tracking branch (against origin/$default)"
    commits=$(g log --oneline "origin/$default..HEAD" 2>/dev/null)
else
    echo "No upstream tracking branch"
    commits=""
fi
echo "${commits:-(none)}"
echo ""
echo "#### Fingerprint"
fingerprint | git hash-object --stdin 2>/dev/null || echo "UNAVAILABLE"
exit 0
