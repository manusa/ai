#!/bin/bash
# Detect which package manager(s) are used in the project
# Lists found package manager files or a fallback message

found=$(ls package.json go.mod pom.xml build.gradle build.gradle.kts 2>/dev/null)
if [ -z "$found" ]; then
    echo "No supported package manager detected"
else
    echo "$found"
fi