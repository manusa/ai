#!/bin/bash
#
# Uninstall AI tooling dotfiles (remove symlinks)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed."
    exit 1
fi

cd "$SCRIPT_DIR"

echo "Unstowing dotfiles..."
stow -D -t ~ dotfiles

echo "Done!"