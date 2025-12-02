# AI Tooling Dotfiles

Configuration files for AI development tools, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
dotfiles/
├── .claude/
│   └── settings.json    # Claude Code settings
└── .cursor/
    └── mcp.json         # Cursor MCP server configurations
```

## Installation

### Prerequisites

Install GNU Stow:

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow

# Fedora
sudo dnf install stow
```

### Setup

1. Clone this repository
2. Backup existing config files if they exist:
   ```bash
   mv ~/.claude/settings.json ~/.claude/settings.json.bak
   mv ~/.cursor/mcp.json ~/.cursor/mcp.json.bak
   ```
3. Run the install script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

This creates symlinks from your home directory to the files in this repo.

## Uninstallation

To remove the symlinks:

```bash
./uninstall.sh
```

## Adding New Config Files

1. Place the file in `dotfiles/` mirroring its path relative to `~`
2. Run `./install.sh` again

Example: To add `~/.config/some-tool/config.yaml`:

```
dotfiles/.config/some-tool/config.yaml
```