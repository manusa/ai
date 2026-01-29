#!/bin/bash
# Check if AGENTS.md exists and return its content or a message indicating it doesn't exist

if [ -f "AGENTS.md" ]; then
    echo "EXISTS"
    echo "---"
    cat AGENTS.md
else
    echo "NOT_FOUND"
fi