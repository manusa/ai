#!/bin/bash
# The full discussion of the review target: every comment and review, inline
# (diff-anchored) threads included, each with author, time, anchor and thread
# state. "N/A" for a worktree review.
# Usage: get-pr-comments.sh "<TARGETS>"

. "$(dirname "$0")/lib.sh"
mn_begin "$1"

if [ -z "$TARGET" ]; then
    echo "N/A - Local worktree review (no PR comments)"
    exit 0
fi

ID=$(mn_id "$TARGET")

# section TITLE BODY: a titled section, "(none)" when the body is empty.
section() {
    echo "## $1"
    if [ -n "$2" ]; then printf '%s\n' "$2"; else echo "(none)"; fi
    echo ""
}

github_comments() {
    local meta url number repo issue_comments reviews inline
    meta=$(gh pr view "$ID" --json url,number --jq '"\(.url) \(.number)"') || return $?
    url=${meta% *}
    number=${meta##* }
    repo=${url#https://github.com/}
    repo=${repo%%/pull/*}
    issue_comments=$(gh api "repos/$repo/issues/$number/comments?per_page=100" --paginate \
        --jq '.[] | "--- @\(.user.login) (\(.created_at)):\n\(.body)\n"') || return $?
    reviews=$(gh api "repos/$repo/pulls/$number/reviews?per_page=100" --paginate \
        --jq '.[] | select(.body != "" or .state != "COMMENTED") | "--- @\(.user.login) [\(.state)] (\(.submitted_at)):\n\(.body)\n"') || return $?
    inline=$(gh api "repos/$repo/pulls/$number/comments?per_page=100" --paginate \
        --jq '.[] | "--- @\(.user.login) (\(.created_at)) on \(.path):\(.line // .original_line) [\(.side)]\(if .in_reply_to_id then " (reply)" else "" end):\n\(.body)\n"') || return $?
    section "Comments" "$issue_comments"
    section "Reviews" "$reviews"
    section "Inline review comments (new-file line numbers; [LEFT] marks a removed line)" "$inline"
}

gitlab_comments() {
    local threads
    threads=$(glab mr view "$ID" --comments --per-page 100 --output json | jq -r '
        .Discussions // [] | .[] | select(any(.notes[]; .system == false)) |
        (if .notes[0].resolvable then (if .notes[0].resolved then " [resolved]" else " [unresolved]" end) else "" end) as $state |
        "=== Thread \(.id[0:8])\($state)",
        (.notes[] | select(.system == false) |
          "--- @\(.author.username) (\(.created_at))" +
          (if .position then
             " on \(.position.new_path // .position.old_path):" +
             (if .position.new_line then (.position.new_line | tostring) else "old " + (.position.old_line | tostring) end)
           else "" end) + ":",
          .body, "")') || return $?
    section "Discussion threads (inline threads show path:line; old N marks a removed line)" "$threads"
}

case "$(mn_forge "$TARGET")" in
    github) github_comments || echo "ERROR: could not fetch the discussion of '$TARGET' (exit $?; see stderr above; this is a fetch failure, not a confirmed 'no comments')" ;;
    gitlab) gitlab_comments || echo "ERROR: could not fetch the discussion of '$TARGET' (exit $?; see stderr above; this is a fetch failure, not a confirmed 'no comments')" ;;
esac
