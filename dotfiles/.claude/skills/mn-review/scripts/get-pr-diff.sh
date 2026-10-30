#!/bin/bash
# Diff of the review target (GitHub PR or GitLab MR, as a plain git patch, inside
# an untrusted-data fence), or of the worktree when no target is given.
# Usage: get-pr-diff.sh "<TARGETS>"

. "$(dirname "$0")/lib.sh"
mn_begin "$1"

if [ -z "$TARGET" ]; then
    staged=$(git diff --cached 2>/dev/null)
    if [ -n "$staged" ]; then
        echo "=== STAGED CHANGES ==="
        echo "$staged"
        echo ""
    fi
    unstaged=$(git diff 2>/dev/null)
    if [ -n "$unstaged" ]; then
        echo "=== UNSTAGED CHANGES ==="
        echo "$unstaged"
    fi
    if [ -z "$staged" ] && [ -z "$unstaged" ]; then
        echo "No changes in worktree"
    fi
    exit 0
fi

ID=$(mn_id "$TARGET")
case "$(mn_forge "$TARGET")" in
    github) diff=$(gh pr diff "$ID") ;;
    gitlab) mn_glab_mr "$ID"; diff=$(glab mr diff "$MN_MR" "${MN_REPO_FLAG[@]}" --raw) ;;
esac
rc=$?
if [ "$rc" -eq 0 ]; then
    mn_fenced "diff of $TARGET" "$diff"
else
    echo "ERROR: the diff of '$TARGET' could not be fetched (exit $rc; see stderr above; this is a fetch failure, not a confirmed empty diff)"
fi
exit 0
