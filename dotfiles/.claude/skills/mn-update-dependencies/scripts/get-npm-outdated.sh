#!/bin/bash
# Get outdated npm dependencies
# Returns empty string if npm outdated fails (not an npm project)

npm outdated 2>/dev/null || echo ""