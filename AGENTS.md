# AI Tooling Dotfiles - AI Agents Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

This file provides guidance to AI coding agents (GitHub Copilot, Claude Code, etc.) when working with code in this repository.

## Project Overview

This repository manages configuration files (dotfiles) for AI development tools using GNU Stow. It provides a centralized way to version control and deploy AI tool configurations across machines.

## Development Commands

```bash
# Install dotfiles (creates symlinks from ~ to dotfiles/)
./install.sh

# Uninstall dotfiles (removes symlinks)
./uninstall.sh
```

## Architecture

The repository uses GNU Stow to create symlinks from `$HOME` to files in `dotfiles/`. The directory structure under `dotfiles/` mirrors the home directory structure:

- `dotfiles/.claude/` → `~/.claude/` (Claude Code settings and custom commands)
- `dotfiles/.cursor/` → `~/.cursor/` (Cursor MCP server configurations)

Files listed in `.stow-local-ignore` (README, LICENSE, scripts, etc.) are excluded from stowing.

## Custom Claude Commands

The repository includes a custom slash command `/mn-github-issue` for creating well-structured GitHub issues. The command accepts a description and generates a complete issue with title, description, steps to reproduce, expected/actual behavior, labels, and acceptance criteria.