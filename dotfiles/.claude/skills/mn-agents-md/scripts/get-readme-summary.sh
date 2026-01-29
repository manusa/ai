#!/bin/bash
# Get first 100 lines of README.md for context about the project

if [ -f "README.md" ]; then
    head -100 README.md
else
    echo "No README.md found"
fi