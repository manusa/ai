#!/bin/bash
# Get outdated Maven dependencies
# Returns empty string if not a Maven project

result=$(mvn versions:display-dependency-updates -q 2>/dev/null | grep -E "^\[INFO\].*->" | head -30)
if [ -z "$result" ]; then
    echo ""
else
    echo "$result"
fi