#!/bin/bash
# Post one approved review to a GitLab merge request in one invocation: the
# overview note, every inline note and, for an APPROVE verdict, the approval.
# A WRITE: listed under `ask` in settings.json by its canonical path, so the
# whole review costs one prompt.
# Usage: post-mr-review.sh <MR_IID_OR_URL> <VERDICT> <MANIFEST_JSON>
# The manifest (written with the Write tool, never built in the shell):
#   {
#     "verdict": "APPROVE" | "REQUEST_CHANGES" | "COMMENT",
#     "head_sha": "<the full reviewed head SHA; always required>",
#     "overview": "<overview body file>",
#     "inline": [
#       {"file": "<path>", "line": 42 | "10:15", "body": "<body file>"},
#       {"file": "<path>", "old_line": 7, "body": "<body file>"},
#       {"file": "<path>", "body": "<body file>"}
#     ]
#   }
# VERDICT repeats the manifest's, so the one prompt shows it; a mismatch posts
# nothing. The verdict picks the overview's form: REQUEST_CHANGES opens a
# resolvable thread, the others post a non-resolvable note. Inline notes stay
# resolvable; one without line or old_line lands on the first line of that
# file's diff (glab anchors it there, and errors if that diff is empty).
# The MR head is checked against head_sha before anything is posted, and the
# approval passes --sha too. The whole manifest is validated before anything is
# posted, and a failing jq posts nothing; on a failure mid-batch the script
# stops and reports what was and was not posted.

. "$(dirname "$0")/lib.sh"

die() {
    echo "post-mr-review.sh: $*" >&2
    exit 2
}

usage() {
    die "usage: post-mr-review.sh <MR_IID_OR_URL> <APPROVE|REQUEST_CHANGES|COMMENT> <MANIFEST_JSON>"
}

# The ask rule is the literal canonical path. Another spelling (scripts/./…,
# scripts//…, scripts/../scripts/…) would still match the directory-wide allow
# rule and sandbox exclusion while missing the ask gate, so refuse it here.
CANONICAL="$HOME/.claude/skills/mn-review/scripts/post-mr-review.sh"
[ "$0" = "$CANONICAL" ] || die "run it as $CANONICAL (got '$0'); any other spelling of the path skips the ask gate"

[ $# -eq 3 ] || usage
RAW_TARGET="$1"
ARG_VERDICT="$2"
MANIFEST="$3"

# The verdict is on the command line so the one prompt shows it; it must match
# the manifest's.
case "$ARG_VERDICT" in
    APPROVE|REQUEST_CHANGES|COMMENT) ;;
    *) die "the verdict must be APPROVE, REQUEST_CHANGES or COMMENT, not '$ARG_VERDICT'" ;;
esac

case "$RAW_TARGET" in
    ""|-*) die "the merge request must be an IID or an MR URL, not '$RAW_TARGET'" ;;
esac
[ "$(mn_forge "$RAW_TARGET")" = gitlab ] || die "'$RAW_TARGET' is not a GitLab merge request (its URL or the cwd origin points at another forge)"
MR=$(mn_id "$RAW_TARGET")
REPO_FLAG=()
re_url='^(https?)://([^/[:space:]]+)/([^[:space:]]+)/-/merge_requests/([0-9]+)/?$'
if [[ "$MR" =~ $re_url ]]; then
    # -R as a URL pins glab to the MR's host; a bare host/path would make glab
    # guess, and it reads an unconfigured host as a gitlab.com group.
    REPO_FLAG=(-R "${BASH_REMATCH[1]}://${BASH_REMATCH[2]}/${BASH_REMATCH[3]}")
    MR=${BASH_REMATCH[4]}
elif ! [[ "$MR" =~ ^[0-9]+$ ]]; then
    die "the merge request must be an IID or an MR URL, not '$RAW_TARGET'"
fi

# body_ok PATH: a regular, non-empty file under /tmp (the session scratchpad
# and /tmp/claude live there), never a symlink, so a manifest cannot post an
# arbitrary file such as a credential.
body_ok() {
    local dir
    case "$1" in ""|-*) return 1 ;; esac
    [ -f "$1" ] && [ ! -L "$1" ] || return 1
    grep -q '[^[:space:]]' "$1" || return 1
    dir=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
    case "$dir/" in /tmp/*|/private/tmp/*) return 0 ;; esac
    return 1
}

body_ok "$MANIFEST" || die "the manifest must be a non-empty regular file under /tmp, not '$MANIFEST'"
jq -e . "$MANIFEST" >/dev/null 2>&1 || die "the manifest $MANIFEST is not valid JSON"

ERRORS=$(jq -r '
    def sha_ok: type == "string" and test("^[0-9a-f]{40}$");
    def path_ok: type == "string" and length > 0 and (test("^-") | not) and (test("[[:cntrl:]\\\\]") | not);
    def line_ok: tostring | test("^[1-9][0-9]*(:[1-9][0-9]*)?$")
        and (split(":") | length == 1 or ((.[0] | tonumber) <= (.[1] | tonumber)));
    if type != "object" then "the manifest is not a JSON object" else
        ((keys - ["verdict", "head_sha", "overview", "inline"])[] | "unknown key \(tojson)"),
        (if (.verdict | IN("APPROVE", "REQUEST_CHANGES", "COMMENT")) then empty else "verdict must be APPROVE, REQUEST_CHANGES or COMMENT" end),
        (if (.head_sha | sha_ok) then empty else "head_sha must be the full 40-digit SHA of the reviewed head; it is checked against the MR before anything is posted" end),
        (if (.overview | path_ok) then empty else "overview must be the path of the overview body file, without a leading -, control characters or backslashes" end),
        (if has("inline") and (.inline | type) != "array" then "inline must be an array" else empty end),
        ((.inline // []) | if type == "array" then to_entries[] else empty end | .key as $i | .value |
            if type != "object" then "inline[\($i)] is not an object" else
                ((keys - ["file", "line", "old_line", "body"])[] | "inline[\($i)]: unknown key \(tojson)"),
                (if (.file | path_ok) then empty else "inline[\($i)]: file must be a path without a leading -, control characters or backslashes" end),
                (if (.body | path_ok) then empty else "inline[\($i)]: body must be the path of its body file, without a leading -, control characters or backslashes" end),
                (if has("line") and has("old_line") then "inline[\($i)]: line and old_line are exclusive"
                 elif has("line") and ((.line | line_ok) | not) then "inline[\($i)]: line takes N or A:B, positive, with A <= B"
                 elif has("old_line") and ((.old_line | tostring | test("^[1-9][0-9]*$")) | not) then "inline[\($i)]: old_line takes a positive N"
                 else empty end)
            end)
    end' "$MANIFEST") || die "could not validate the manifest $MANIFEST (jq failed, see stderr above); nothing was posted"
[ -z "$ERRORS" ] || die "invalid manifest $MANIFEST, nothing was posted:
$ERRORS"

# Every extraction fails closed: an empty value from a failed jq would skip a check.
VERDICT=$(jq -r .verdict "$MANIFEST") || die "could not read the verdict (jq failed); nothing was posted"
[ "$VERDICT" = "$ARG_VERDICT" ] || die "the command line says $ARG_VERDICT but the manifest says $VERDICT; nothing was posted"
HEAD_SHA=$(jq -r .head_sha "$MANIFEST") || die "could not read head_sha (jq failed); nothing was posted"
[[ "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]] || die "head_sha '$HEAD_SHA' is not a full 40-digit SHA; nothing was posted"
OVERVIEW=$(jq -r .overview "$MANIFEST") || die "could not read the overview path (jq failed); nothing was posted"
body_ok "$OVERVIEW" || die "overview body file '$OVERVIEW' must be a non-empty regular file under /tmp; nothing was posted"
INLINE_COUNT=$(jq '.inline // [] | length' "$MANIFEST") || die "could not count the inline notes (jq failed); nothing was posted"

# One "file line-flag line body" row per inline note, in manifest order,
# separated by \x1f: a tab is IFS whitespace, so read would merge the empty
# fields of a file-level note and shift its body into the flag.
INLINE=$(jq -r '(.inline // [])[]
    | [.file, (if has("line") then "--line" elif has("old_line") then "--old-line" else "" end),
       ((.line // .old_line // "") | tostring), .body] | join("\u001f")' "$MANIFEST") \
    || die "could not read the inline notes (jq failed, see stderr above); nothing was posted"
rows=0
while IFS=$'\x1f' read -r file _ _ body; do
    [ -n "$file" ] || continue
    rows=$((rows + 1))
    body_ok "$body" || die "inline body file '$body' must be a non-empty regular file under /tmp; nothing was posted"
done <<EOF
$INLINE
EOF
[ "$rows" = "$INLINE_COUNT" ] || die "read $rows inline notes but the manifest has $INLINE_COUNT; nothing was posted"

# STEPS describes each posting step, in the order the code below runs them, so
# report_failure N can say what was and was not posted.
STEPS=()
case "$VERDICT" in
    REQUEST_CHANGES) STEPS+=("overview note (resolvable thread) from $OVERVIEW") ;;
    *) STEPS+=("overview note (non-resolvable) from $OVERVIEW") ;;
esac
while IFS=$'\x1f' read -r file flag line body; do
    [ -n "$file" ] || continue
    STEPS+=("inline note on $file${flag:+ $flag $line} from $body")
done <<EOF
$INLINE
EOF
[ "$VERDICT" = APPROVE ] && STEPS+=("approval at $HEAD_SHA")

# A review of an older head would misplace its inline notes, and its approval
# would fail after the notes were posted. This read is also the first contact
# with the MR, so a wrong host or a wrong MR fails here, before any write.
CURRENT=$(glab mr view "$MR" "${REPO_FLAG[@]}" --output json | jq -r '.sha // empty') \
    || die "could not read the head of merge request $RAW_TARGET (see stderr above); nothing was posted"
[ "$CURRENT" = "$HEAD_SHA" ] || die "merge request $RAW_TARGET is at ${CURRENT:-an unknown head}, not the reviewed $HEAD_SHA; re-review it. Nothing was posted"

echo "Posting to merge request $RAW_TARGET (${#STEPS[@]} steps, verdict $VERDICT):"
for s in "${STEPS[@]}"; do echo "  - $s"; done
echo ""

# report_failure N: what was posted before step N failed, and what was not.
report_failure() {
    local i
    echo "" >&2
    echo "post-mr-review.sh: step $(($1 + 1)) of ${#STEPS[@]} failed: ${STEPS[$1]}" >&2
    echo "Posted:" >&2
    if [ "$1" -eq 0 ]; then echo "  (nothing)" >&2; fi
    for ((i = 0; i < $1; i++)); do echo "  - ${STEPS[$i]}" >&2; done
    echo "Not posted:" >&2
    for ((i = $1; i < ${#STEPS[@]}; i++)); do echo "  - ${STEPS[$i]}" >&2; done
    exit 1
}

step=0
if [ "$VERDICT" = REQUEST_CHANGES ]; then
    glab mr note create "$MR" "${REPO_FLAG[@]}" < "$OVERVIEW" || report_failure "$step"
else
    glab mr note create "$MR" "${REPO_FLAG[@]}" --resolvable=false < "$OVERVIEW" || report_failure "$step"
fi
step=$((step + 1))

while IFS=$'\x1f' read -r file flag line body <&3; do
    [ -n "$file" ] || continue
    if [ -n "$flag" ]; then
        glab mr note create "$MR" "${REPO_FLAG[@]}" --file "$file" "$flag" "$line" < "$body" || report_failure "$step"
    else
        glab mr note create "$MR" "${REPO_FLAG[@]}" --file "$file" < "$body" || report_failure "$step"
    fi
    step=$((step + 1))
done 3<<EOF
$INLINE
EOF

if [ "$VERDICT" = APPROVE ]; then
    glab mr approve "$MR" "${REPO_FLAG[@]}" --sha "$HEAD_SHA" || report_failure "$step"
fi

echo ""
echo "Posted all ${#STEPS[@]} steps to merge request $RAW_TARGET."
