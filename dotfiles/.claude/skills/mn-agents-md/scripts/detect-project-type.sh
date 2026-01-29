#!/bin/bash
# Detect the project type based on configuration files present

types=""

# JavaScript/TypeScript (npm/yarn/pnpm/bun)
if [ -f "package.json" ]; then
    types="${types}npm "
fi

# Go
if [ -f "go.mod" ]; then
    types="${types}go "
fi

# Maven (Java)
if [ -f "pom.xml" ]; then
    types="${types}maven "
fi

# Gradle (Java/Kotlin)
if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    types="${types}gradle "
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    types="${types}python "
fi

# Rust
if [ -f "Cargo.toml" ]; then
    types="${types}rust "
fi

# Ruby
if [ -f "Gemfile" ]; then
    types="${types}ruby "
fi

# Dotfiles/Stow
if [ -f ".stow-local-ignore" ] || [ -d "dotfiles" ]; then
    types="${types}stow "
fi

if [ -z "$types" ]; then
    echo "unknown"
else
    echo "$types" | xargs
fi