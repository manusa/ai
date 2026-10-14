#!/bin/bash
# Details of the review target: a GitHub PR or GitLab MR (number, !N / #N, or
# URL), or the worktree status when no target is given. Several targets print
# the driver banner instead (see lib.sh).
# Usage: get-pr-details.sh "<TARGETS>"

. "$(dirname "$0")/lib.sh"
mn_begin "$1"

if [ -z "$TARGET" ]; then
    echo "MODE: Local worktree changes review"
    echo ""
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "Repository: $(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Working tree status:"
    git status --short 2>/dev/null || echo "Unable to get git status"
    exit 0
fi

ID=$(mn_id "$TARGET")
case "$(mn_forge "$TARGET")" in
    github)
        echo "MODE: Pull request review (GitHub, gh)"
        echo ""
        gh pr view "$ID" || echo "ERROR: 'gh pr view $ID' failed (exit $?). The stderr above distinguishes a missing/wrong PR from a network/sandbox/auth failure; do not treat this as a confirmed 'not found'."
        ;;
    gitlab)
        echo "MODE: Merge request review (GitLab, glab)"
        echo ""
        glab mr view "$ID" || echo "ERROR: 'glab mr view $ID' failed (exit $?). The stderr above distinguishes a missing/wrong MR from a network/VPN/auth failure; do not treat this as a confirmed 'not found'."
        ;;
esac
