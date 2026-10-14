#!/bin/bash
# Map the target's diff to line numbers in each file's final (new) version, for
# inline review comments on either forge.
# Usage: get-pr-file-lines.sh <PR_OR_MR> <FILE_PATH> [PATTERN]
# Prints the head SHA (on GitHub the comment's commit_id), then every added (+)
# and context ( ) line of FILE_PATH in the diff as "<new-file line>\t<marker><content>":
# the lines an inline comment can target (side=RIGHT on GitHub, --line on GitLab).
# PATTERN (awk extended regex) filters the listed lines by content. Read-only;
# runs unsandboxed via sandbox.excludedCommands (keyring auth), which is why the
# diff is parsed here instead of piped in the caller.

. "$(dirname "$0")/lib.sh"

TARGET="$1"
FILE_PATH="$2"
if [ -z "$TARGET" ] || [ -z "$FILE_PATH" ]; then
    echo "Usage: get-pr-file-lines.sh <PR_OR_MR> <FILE_PATH> [PATTERN]"
    exit 2
fi
ID=$(mn_id "$TARGET")

echo "[FETCHED: $(date -Iseconds)]"
case "$(mn_forge "$TARGET")" in
    github)
        head_sha=$(gh pr view "$ID" --json headRefOid --jq '.headRefOid') \
            || { rc=$?; echo "ERROR: 'gh pr view $ID' failed (exit $rc; see stderr above)"; exit 1; }
        diff=$(gh pr diff "$ID") \
            || { rc=$?; echo "ERROR: 'gh pr diff $ID' failed (exit $rc; see stderr above; this is a fetch failure, not a confirmed empty diff)"; exit 1; }
        echo "forge: github"
        echo "commit_id: $head_sha"
        ;;
    gitlab)
        head_sha=$(glab mr view "$ID" --output json --jq '.sha') \
            || { rc=$?; echo "ERROR: 'glab mr view $ID' failed (exit $rc; see stderr above)"; exit 1; }
        diff=$(glab mr diff "$ID" --raw) \
            || { rc=$?; echo "ERROR: 'glab mr diff $ID --raw' failed (exit $rc; see stderr above; this is a fetch failure, not a confirmed empty diff)"; exit 1; }
        echo "forge: gitlab"
        echo "head_sha: ${head_sha//\"/} (informational; glab mr note create --file/--line targets the latest diff version)"
        ;;
esac
echo "path: $FILE_PATH"
echo ""

# ENVIRON instead of -v so awk doesn't interpret backslash escapes in the values.
printf '%s\n' "$diff" | FILE_PATH="$FILE_PATH" PATTERN="$3" LC_ALL=C awk "$MN_AWK_LIB"'
BEGIN { file = ENVIRON["FILE_PATH"]; pattern = ENVIRON["PATTERN"] }
/^diff --git / { in_header = 1; in_file = 0; next }
# Match "+++ b/<path>" only in the file header: inside a hunk, an added line whose
# content starts with "++ " also begins with "+++ ". The header path may carry a
# trailing tab (names with spaces) or C quoting (non-ASCII), so normalize it.
in_header && /^\+\+\+ / { in_file = (mn_header_path(substr($0, 5)) == file); next }
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
