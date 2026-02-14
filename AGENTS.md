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

The repository includes custom slash commands for project management tasks:

- `/mn-github-changelog-update` - Generates or updates CHANGELOG.md based on merged PRs since the last release tag. Categorizes changes using conventional commit prefixes, follows Keep a Changelog format, and suggests semantic version bumps.
- `/mn-github-issue` - Creates well-structured GitHub issues. Accepts a description and generates a complete issue with title, description, steps to reproduce, expected/actual behavior, labels, and acceptance criteria.
- `/mn-github-pr-review` - Performs thorough code reviews as a project maintainer. Accepts a PR number or URL, or reviews local worktree changes when no arguments provided. Covers code quality, security, performance, testing, and documentation.
- `/mn-agents-md` - Creates or updates AGENTS.md file for AI coding agents. Generates project-specific instructions including development commands, architecture overview, code style, and testing guidelines following a black-box, no-mocks testing philosophy. Also creates the CLAUDE.md symlink.
- `/mn-update-dependencies` - Checks for outdated dependencies in package.json and updates them one by one with isolated commits. Uses exact versions and the pattern `chore(deps): bump $dependencyName from $oldVersion to $newVersion`.
