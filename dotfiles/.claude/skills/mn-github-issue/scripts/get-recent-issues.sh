#!/bin/bash
# Get recent issues for title/style reference
# Falls back to a message if no issues found or gh CLI fails

gh issue list --limit 20 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "No recent issues"