#!/bin/bash
# Detect languages/frameworks from changed files and output relevant review guidelines
# Usage: get-language-guidelines.sh <PR_NUMBER_OR_URL>
# Falls back to worktree changed files if no PR specified

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUIDELINES_DIR="$SCRIPT_DIR/../guidelines"

PR_ARG="$1"

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

# Collect guideline names (use a string with dedup via grep)
guidelines=""

add_guideline() {
    if ! echo "$guidelines" | grep -qw "$1"; then
        guidelines="$guidelines $1"
    fi
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

# Trim leading space
guidelines=$(echo "$guidelines" | xargs)

if [ -z "$guidelines" ]; then
    echo "No language-specific guidelines for the detected file types"
    exit 0
fi

# Output detected languages
echo "Detected: $(echo "$guidelines" | tr ' ' ', ')"
echo ""

# Concatenate relevant guideline files
for lang in $guidelines; do
    guideline_file="$GUIDELINES_DIR/$lang.md"
    if [ -f "$guideline_file" ]; then
        cat "$guideline_file"
        echo ""
    fi
done
