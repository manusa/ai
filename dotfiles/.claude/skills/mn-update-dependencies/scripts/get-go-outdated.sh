#!/bin/bash
# Get outdated Go dependencies
# Returns empty string if not a Go project

result=$(go list -m -u all 2>/dev/null | grep '\[')
if [ -z "$result" ]; then
    echo ""
else
    echo "$result"
fi