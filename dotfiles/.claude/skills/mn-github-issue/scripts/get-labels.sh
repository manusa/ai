#!/bin/bash
# Get available labels for the current repository
# Falls back to a message if no labels found or gh CLI fails

gh label list --json name,description --jq '.[] | "- \(.name): \(.description)"' 2>/dev/null || echo "No labels found - will suggest common labels"