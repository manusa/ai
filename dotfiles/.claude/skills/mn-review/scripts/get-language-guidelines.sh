#!/bin/bash
# Detect languages/frameworks from changed files and output relevant review guidelines
# Usage: get-language-guidelines.sh <PR_NUMBER_OR_URL>
# Falls back to worktree changed files if no PR specified

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUIDELINES_DIR="$SCRIPT_DIR/../guidelines"

PR_ARG="$1"
echo "[FETCHED: $(date -Iseconds)]"
echo ""

# Get the list of changed files
if [ -z "$PR_ARG" ]; then
    files=$(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)
else
    files=$(gh pr view "$PR_ARG" --json files --jq '.files[].path' 2>/dev/null)
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
