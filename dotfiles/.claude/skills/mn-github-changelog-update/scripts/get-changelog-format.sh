#!/bin/bash
# Get the first 50 lines of existing CHANGELOG for format reference
# Falls back to a message if no CHANGELOG found

if [ -f "CHANGELOG.md" ]; then
    head -50 CHANGELOG.md
elif [ -f "CHANGELOG" ]; then
    head -50 CHANGELOG
elif [ -f "changelog.md" ]; then
    head -50 changelog.md
else
    echo "No CHANGELOG found - will use Keep a Changelog format"
fi