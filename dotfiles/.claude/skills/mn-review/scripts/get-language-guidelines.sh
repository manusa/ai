#!/bin/bash
# Detect languages/frameworks from the changed files and output the relevant
# review guidelines. Works for a GitHub PR, a GitLab MR, or the worktree when no
# target is given.
# Usage: get-language-guidelines.sh "<TARGETS>"

. "$(dirname "$0")/lib.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUIDELINES_DIR="$SCRIPT_DIR/../guidelines"

mn_begin "$1"

if [ -z "$TARGET" ]; then
    files=$(mn_local_files)
else
    # Reuses the list get-pr-files just cached instead of refetching it.
    files=$(mn_changed_files "$(mn_forge "$TARGET")" "$(mn_id "$TARGET")" 2>/dev/null)
fi

if [ -z "$files" ]; then
    echo "No files detected"
    exit 0
fi

# Collect guideline names (use array for dedup)
guidelines=()

add_guideline() {
    for g in "${guidelines[@]}"; do [ "$g" = "$1" ] && return; done
    guidelines+=("$1")
}

# Map file extensions/names to guideline files
while IFS= read -r file; do
    basename=$(basename "$file")
    case "$file" in
        *.tsx)
            add_guideline react
            add_guideline typescript
            ;;
        *.jsx)
            add_guideline react
            add_guideline javascript
            ;;
        *.ts|*.mts|*.cts)
            add_guideline typescript
            ;;
        *.js|*.mjs|*.cjs)
            add_guideline javascript
            ;;
        *.go)
            add_guideline go
            ;;
        *.java)
            add_guideline java
            ;;
        *.sh|*.bash)
            add_guideline bash
            ;;
        *.css|*.scss|*.less)
            add_guideline css
            ;;
    esac
    case "$basename" in
        Makefile|makefile|GNUmakefile|*.mk)
            add_guideline makefile
            ;;
    esac
done <<< "$files"

if [ ${#guidelines[@]} -eq 0 ]; then
    echo "No language-specific guidelines for the detected file types"
    exit 0
fi

# Output detected languages
detected=$(IFS=,; echo "${guidelines[*]}")
echo "Detected: $detected"
echo ""

# Concatenate relevant guideline files
for lang in "${guidelines[@]}"; do
    guideline_file="$GUIDELINES_DIR/$lang.md"
    if [ -f "$guideline_file" ]; then
        cat "$guideline_file"
        echo ""
    fi
done
