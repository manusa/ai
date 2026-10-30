#!/bin/bash
# Details of the review target: a GitHub PR or GitLab MR (number, !N / #N, or
# URL), or the worktree status when no target is given. Several targets print
# the driver banner instead (see lib.sh). A target's details open with a STATE
# block read from the forge's JSON, the only source for its live state
# (SKILL.md, Review method), then the prose view inside an untrusted-data fence.
# Never exits non-zero.
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

# Each value is reduced to [A-Za-z0-9_.:+-], so the block holds no forge prose.
# shellcheck disable=SC2016 # jq source, not shell expansion
MN_STATE_JQ='
def v: if . == null then "none" else tostring | gsub("[^A-Za-z0-9_.:+-]"; "?") end;
if type != "object" or .state == null then error("no state field") else . end
'

# print_state CMD JQ_FIELDS ARGS...: runs ARGS, renders its JSON with
# JQ_FIELDS, and prints the STATE block, or a "state unknown" line on failure.
print_state() {
    local cmd="$1" fields="$2" json rc block
    shift 2
    json=$("$@")
    rc=$?
    if [ "$rc" -eq 0 ]; then
        block=$(printf '%s' "$json" | jq -r "$MN_STATE_JQ | $fields" 2>/dev/null)
        rc=$?
        [ "$rc" -ne 0 ] || [ -n "$block" ] || rc=1
    fi
    if [ "$rc" -eq 0 ]; then
        echo "STATE (live, read by this script from '$cmd'; the only source for open/merged/closed, draft and conflicts):"
        printf '%s\n' "$block" | sed 's/^/  /'
    else
        echo "STATE: unknown ('$cmd' or its JSON parse failed, exit $rc; see stderr above). Do not infer the state from SHAs or branch ancestry: re-run get-pr-details.sh, or report the state as unknown."
    fi
    echo ""
}

ID=$(mn_id "$TARGET")
case "$(mn_forge "$TARGET")" in
    github)
        echo "MODE: Pull request review (GitHub, gh)"
        echo ""
        print_state "gh pr view $ID --json" \
            '"state: \(.state | v)", "draft: \(.isDraft | v)", "merge state: \(.mergeStateStatus | v)", "head sha: \(.headRefOid | v)", "author: @\(.author.login | v)", "merged at: \(.mergedAt | v)"' \
            gh pr view "$ID" --json state,mergeStateStatus,isDraft,headRefOid,author,mergedAt
        if view=$(gh pr view "$ID"); then
            mn_fenced "details of $TARGET" "$view"
        else
            echo "ERROR: 'gh pr view $ID' failed (exit $?). The stderr above distinguishes a missing/wrong PR from a network/sandbox/auth failure; do not treat this as a confirmed 'not found'."
        fi
        ;;
    gitlab)
        echo "MODE: Merge request review (GitLab, glab)"
        echo ""
        mn_glab_mr "$ID"
        print_state "glab mr view $ID --output json" \
            '"state: \(.state | v)", "draft: \(.draft | v)", "merge status: \(.detailed_merge_status | v)", "has conflicts: \(.has_conflicts | v)", "head sha: \(.sha | v)", "author: @\(.author.username | v)", "merged at: \(.merged_at | v)"' \
            glab mr view "$MN_MR" "${MN_REPO_FLAG[@]}" --output json
        if view=$(glab mr view "$MN_MR" "${MN_REPO_FLAG[@]}"); then
            mn_fenced "details of $TARGET" "$view"
        else
            echo "ERROR: 'glab mr view $ID' failed (exit $?). The stderr above distinguishes a missing/wrong MR from a network/VPN/auth failure; do not treat this as a confirmed 'not found'."
        fi
        ;;
esac
exit 0
