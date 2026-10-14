#!/bin/bash
# Shared helpers for the mn-review scripts. Sourced, never executed: the calling
# script is the sandbox-excluded command, so the gh/glab calls below inherit its
# keyring and network access.

set -o pipefail
export PAGER=cat GH_PAGER=cat GLAB_PAGER=cat NO_COLOR=1

# mn_begin "<ARGUMENTS>": prints the fetch timestamp, splits the skill arguments
# into targets, and exits with the driver banner when there are several. Leaves
# the single target (or "" for a worktree review) in TARGET.
mn_begin() {
    echo "[FETCHED: $(date -Iseconds)]"
    echo ""
    local -a targets
    # shellcheck disable=SC2206 # word-splitting the argument list is the point
    targets=($1)
    if [ "${#targets[@]}" -gt 1 ]; then
        echo "MODE: Multi-target driver (${#targets[@]} targets)"
        echo ""
        echo "Targets:"
        local t
        for t in "${targets[@]}"; do echo "  - $t"; done
        echo ""
        echo "Nothing was fetched: the driver delegates each target to its own reviewer sub-agent (SKILL.md, Multi-target driver mode)."
        exit 0
    fi
    TARGET="${targets[0]:-}"
}

# mn_forge TARGET: prints github or gitlab. The URL shape decides first, then a
# !N / #N sigil, then the cwd origin remote (github.com or none: github; any
# other host: gitlab).
mn_forge() {
    case "$1" in
        *github.com/*) echo github; return ;;
        */-/merge_requests/*) echo gitlab; return ;;
        '!'*) echo gitlab; return ;;
        '#'*) echo github; return ;;
    esac
    local host
    host=$(mn_remote_host "$(git remote get-url origin 2>/dev/null)")
    case "$host" in
        ""|github.com) echo github ;;
        *) echo gitlab ;;
    esac
}

# mn_remote_host URL: the lowercase host of an https:// or scp-like git remote.
mn_remote_host() {
    local host
    case "$1" in
        *://*) host="${1#*://}"; host="${host%%/*}"; host="${host##*@}"; host="${host%%:*}" ;;
        *@*:*) host="${1#*@}"; host="${host%%:*}" ;;
        *) host="" ;;
    esac
    printf '%s' "$host" | tr '[:upper:]' '[:lower:]'
}

# mn_id TARGET: strips a leading ! or # sigil; URLs and bare numbers pass through.
mn_id() {
    local t="$1"
    t="${t#!}"
    t="${t#\#}"
    printf '%s' "$t"
}

# mn_cache_file ID: the per-target changed-files cache the scripts share.
mn_cache_file() {
    printf '/tmp/mn-review-files-%s.txt' "$(printf '%s' "$1" | tr -c 'A-Za-z0-9' '_')"
}

# mn_changed_files FORGE ID: the changed paths, one per line, cached for two
# minutes so get-language-guidelines reuses what get-pr-files just fetched.
mn_changed_files() {
    local cache files
    cache=$(mn_cache_file "$2")
    if [ -f "$cache" ] && [ -n "$(find "$cache" -mmin -2 2>/dev/null)" ]; then
        cat "$cache"
        return 0
    fi
    case "$1" in
        github) files=$(gh pr view "$2" --json files --jq '.files[].path') || return $? ;;
        gitlab) files=$(glab mr diff "$2" --raw | awk '/^diff --git / { sub(/^diff --git a\/.* b\//, ""); print }') || return $? ;;
        *) return 1 ;;
    esac
    printf '%s\n' "$files" > "$cache" 2>/dev/null || true
    printf '%s\n' "$files"
}

# mn_local_files: staged, unstaged and untracked paths of the working tree.
mn_local_files() {
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
}
