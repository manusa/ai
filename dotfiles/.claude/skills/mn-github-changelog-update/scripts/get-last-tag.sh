#!/bin/bash
# Get the last release tag sorted by version
# Falls back to "No tags found" if no tags exist

tag=$(git tag --sort=-v:refname 2>/dev/null | head -1)
if [ -z "$tag" ]; then
    echo "No tags found"
else
    echo "$tag"
fi
