#!/bin/bash
#
# Install AI tooling dotfiles using GNU Stow
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed."
    echo "Install it with:"
    echo "  macOS:  brew install stow"
    echo "  Ubuntu: sudo apt install stow"
    echo "  Fedora: sudo dnf install stow"
    exit 1
fi

cd "$SCRIPT_DIR"

echo "Stowing dotfiles..."
stow -t ~ dotfiles

echo "Done!"