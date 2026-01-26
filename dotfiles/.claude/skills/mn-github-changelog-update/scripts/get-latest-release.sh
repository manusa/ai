#!/bin/bash
# Get the latest GitHub release
# Falls back to "No releases found" if no releases exist

gh release list --limit 1 2>/dev/null || echo "No releases found"