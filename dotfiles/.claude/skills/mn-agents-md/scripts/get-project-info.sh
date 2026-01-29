#!/bin/bash
# Extract basic project information from available configuration files

echo "=== Repository ==="
gh repo view --json nameWithOwner,description --jq '"Name: \(.nameWithOwner)\nDescription: \(.description // "No description")"' 2>/dev/null || echo "Not a GitHub repository or gh CLI not available"

echo ""
echo "=== Project Files ==="
ls -la README.md AGENTS.md CLAUDE.md LICENSE 2>/dev/null || echo "No standard documentation files found"

echo ""
echo "=== Package Manager Files ==="
ls package.json go.mod pom.xml build.gradle build.gradle.kts pyproject.toml Cargo.toml Gemfile 2>/dev/null || echo "No package manager files found"

echo ""
echo "=== Directory Structure (top-level) ==="
ls -d */ 2>/dev/null | head -20 || echo "No directories found"