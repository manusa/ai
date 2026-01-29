#!/bin/bash
# Check if CLAUDE.md exists (as a symlink to AGENTS.md) and return its status

if [ -L "CLAUDE.md" ]; then
    target=$(readlink CLAUDE.md)
    echo "SYMLINK -> $target"
elif [ -f "CLAUDE.md" ]; then
    echo "FILE (not a symlink)"
else
    echo "NOT_FOUND"
fi