#!/bin/bash
# Changed files of the review target (GitHub PR or GitLab MR, inside an
# untrusted-data fence), or of the worktree when no target is given. Cached for
# the sibling scripts (see lib.sh).
# Usage: get-pr-files.sh "<TARGETS>"

. "$(dirname "$0")/lib.sh"
mn_begin "$1"

if [ -z "$TARGET" ]; then
    mn_local_files
    exit 0
fi

if files=$(mn_changed_files "$(mn_forge "$TARGET")" "$(mn_id "$TARGET")" fetch); then
    mn_fenced "changed files of $TARGET" "$files"
else
    echo "ERROR: could not fetch the changed files of '$TARGET' (exit $?; see stderr above; this is a fetch failure, not a confirmed empty file set)"
fi
exit 0
