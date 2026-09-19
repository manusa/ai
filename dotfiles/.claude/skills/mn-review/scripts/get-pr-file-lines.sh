#!/bin/bash
# Map a PR diff to line numbers in the file's final (new) version, for inline review comments
# Usage: get-pr-file-lines.sh <PR_NUMBER_OR_URL> <FILE_PATH> [PATTERN]
# Prints the PR head SHA (the comment's commit_id), then every added (+) and context ( )
# line of FILE_PATH in the diff as "<new-file line>\t<marker><content>" — the lines an
# inline comment with side=RIGHT can target. PATTERN (awk extended regex) filters the
# listed lines by content. Read-only; runs unsandboxed via sandbox.excludedCommands
# (keyring auth), which is why the diff is parsed here instead of piped in the caller.

PR_ARG="$1"
FILE_PATH="$2"
if [ -z "$PR_ARG" ] || [ -z "$FILE_PATH" ]; then
    echo "Usage: get-pr-file-lines.sh <PR_NUMBER_OR_URL> <FILE_PATH> [PATTERN]"
    exit 2
fi

echo "[FETCHED: $(date -Iseconds)]"
if ! head_sha=$(gh pr view "$PR_ARG" --json headRefOid --jq '.headRefOid'); then
    echo "ERROR: 'gh pr view $PR_ARG' failed (exit $? — see stderr above)"
    exit 1
fi
if ! diff=$(gh pr diff "$PR_ARG"); then
    echo "ERROR: 'gh pr diff $PR_ARG' failed (exit $? — see stderr above; this is a fetch failure, not a confirmed empty diff)"
    exit 1
fi
echo "commit_id: $head_sha"
echo "path: $FILE_PATH"
echo ""

# ENVIRON instead of -v so awk doesn't interpret backslash escapes in the values.
printf '%s\n' "$diff" | FILE_PATH="$FILE_PATH" PATTERN="$3" awk '
BEGIN { file = ENVIRON["FILE_PATH"]; pattern = ENVIRON["PATTERN"] }
/^diff --git / { in_header = 1; in_file = 0; next }
# Match "+++ b/<path>" only in the file header: inside a hunk, an added line whose
# content starts with "++ " also begins with "+++ ".
in_header && /^\+\+\+ / { in_file = ($0 == "+++ b/" file); next }
in_header && !/^@@ / { next }
!in_file { in_header = 0; next }
/^@@ / {
    # "@@ -old_start,old_count +new_start,new_count @@": the new-file counter starts at new_start
    in_header = 0
    match($0, /\+[0-9]+/)
    line = substr($0, RSTART + 1, RLENGTH - 1) + 0
    next
}
/^[+ ]/ {
    if (pattern == "" || substr($0, 2) ~ pattern) { printf "%d\t%s\n", line, $0; shown++ }
    line++
    next
}
# Removed lines ("-") and "\ No newline at end of file" do not advance the new-file counter.
END {
    if (!shown) print "No commentable lines: " file " is not in the diff, was deleted, or PATTERN matched nothing"
}
'
