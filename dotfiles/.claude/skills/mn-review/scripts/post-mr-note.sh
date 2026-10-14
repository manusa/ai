#!/bin/bash
# Post a note on a GitLab merge request from a body file. A WRITE: gated by
# `ask` in settings.json, so it prompts exactly like `glab mr note` would.
# Usage: post-mr-note.sh <MR_ID_OR_URL> <BODY_FILE> [--file <path> [--line <n>|<a:b> | --old-line <n>]]
# glab has no --body-file, and `-m "$(cat …)"` or `< file` on the caller's
# command line would re-sandbox glab (keyring and TLS failures), so the body is
# read here, inside the sandbox-excluded script. Only the diff-position flags
# pass through; anything else is a usage error.

. "$(dirname "$0")/lib.sh"

usage() {
    echo "Usage: post-mr-note.sh <MR_ID_OR_URL> <BODY_FILE> [--file <path> [--line <n>|<a:b> | --old-line <n>]]" >&2
    exit 2
}

[ $# -ge 2 ] || usage
MR=$(mn_id "$1")
BODY_FILE="$2"
shift 2
{ [ -n "$MR" ] && [ -f "$BODY_FILE" ]; } || usage

POSITION=()
while [ $# -gt 0 ]; do
    case "$1" in
        --file|--line|--old-line)
            [ $# -ge 2 ] || usage
            POSITION+=("$1" "$2")
            shift 2
            ;;
        *) usage ;;
    esac
done

BODY=$(cat "$BODY_FILE")
if [ -z "$BODY" ]; then
    echo "post-mr-note.sh: empty body file $BODY_FILE" >&2
    exit 2
fi

exec glab mr note create "$MR" -m "$BODY" "${POSITION[@]}"
