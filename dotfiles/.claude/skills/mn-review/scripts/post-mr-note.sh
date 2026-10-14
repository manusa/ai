#!/bin/bash
# Post a note on a GitLab merge request from a body file. A WRITE: listed under
# `ask` in settings.json by its canonical path, so it prompts like `glab mr note`.
# Usage: post-mr-note.sh <MR_IID_OR_URL> <BODY_FILE> [--resolvable=false] [--file <path> [--line <n>|<a>:<b> | --old-line <n>]]
# glab has no --body-file, and `-m "$(cat …)"` or `< file` on the caller's
# command line would re-sandbox glab (keyring and TLS failures), so the body is
# fed on stdin here, inside the sandbox-excluded script. The target must be an
# MR IID or MR URL on a GitLab forge, never a flag; only the flags above pass
# through, each validated.

. "$(dirname "$0")/lib.sh"

die() {
    echo "post-mr-note.sh: $*" >&2
    exit 2
}

usage() {
    die "usage: post-mr-note.sh <MR_IID_OR_URL> <BODY_FILE> [--resolvable=false] [--file <path> [--line <n>|<a>:<b> | --old-line <n>]]"
}

# The ask rule is the literal canonical path. Another spelling (scripts/./…,
# scripts//…, scripts/../scripts/…) would still match the directory-wide allow
# rule and sandbox exclusion while missing the ask gate, so refuse it here.
CANONICAL="$HOME/.claude/skills/mn-review/scripts/post-mr-note.sh"
[ "$0" = "$CANONICAL" ] || die "run it as $CANONICAL (got '$0'); any other spelling of the path skips the ask gate"

[ $# -ge 2 ] || usage
RAW_TARGET="$1"
BODY_FILE="$2"
shift 2

case "$RAW_TARGET" in
    ""|-*) die "the merge request must be an IID or an MR URL, not '$RAW_TARGET'" ;;
esac
[ "$(mn_forge "$RAW_TARGET")" = gitlab ] || die "'$RAW_TARGET' is not a GitLab merge request (its URL or the cwd origin points at another forge)"
MR=$(mn_id "$RAW_TARGET")
if ! [[ "$MR" =~ ^[0-9]+$ || "$MR" =~ ^https?://[^[:space:]]+/merge_requests/[0-9]+/?$ ]]; then
    die "the merge request must be an IID or an MR URL, not '$RAW_TARGET'"
fi

case "$BODY_FILE" in
    ""|-*) die "the body file must be a path, not '$BODY_FILE'" ;;
esac
[ -f "$BODY_FILE" ] || die "body file not found: $BODY_FILE"
grep -q '[^[:space:]]' "$BODY_FILE" || die "empty body file $BODY_FILE"

FLAGS=()
HAS_FILE=
HAS_LINE=
NON_RESOLVABLE=
while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            [ $# -ge 2 ] || usage
            case "$2" in ""|-*) die "--file needs a path, not '$2'" ;; esac
            FLAGS+=(--file "$2")
            HAS_FILE=1
            shift 2
            ;;
        --line)
            [ $# -ge 2 ] || usage
            [[ "$2" =~ ^[0-9]+(:[0-9]+)?$ ]] || die "--line takes <n> or <a>:<b>, not '$2'"
            FLAGS+=(--line "$2")
            HAS_LINE=1
            shift 2
            ;;
        --old-line)
            [ $# -ge 2 ] || usage
            [[ "$2" =~ ^[0-9]+$ ]] || die "--old-line takes <n>, not '$2'"
            FLAGS+=(--old-line "$2")
            HAS_LINE=1
            shift 2
            ;;
        --resolvable=false)
            FLAGS+=(--resolvable=false)
            NON_RESOLVABLE=1
            shift
            ;;
        *) die "unsupported argument '$1' (only --resolvable=false, --file, --line and --old-line pass through)" ;;
    esac
done
[ -z "$HAS_LINE" ] || [ -n "$HAS_FILE" ] || die "--line / --old-line need --file"
[ -z "$NON_RESOLVABLE" ] || [ -z "$HAS_FILE" ] || die "--resolvable=false cannot be combined with --file (glab rejects it); inline findings stay resolvable threads"

exec glab mr note create "${FLAGS[@]}" -- "$MR" < "$BODY_FILE"
