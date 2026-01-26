#!/bin/bash
# Get the date of the last release tag
# Falls back to "No tag date" if no tags exist

tag=$(git tag --sort=-v:refname 2>/dev/null | head -1)
if [ -z "$tag" ]; then
    echo "No tag date"
else
    git log -1 --format=%aI "$tag" 2>/dev/null || echo "No tag date"
fi
