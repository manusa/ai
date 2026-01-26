---
name: mn-github-changelog-update
description: GitHub Changelog Updater. Generates or updates CHANGELOG.md based on merged PRs since the last release tag.
argument-hint: "[version or context]"
disable-model-invocation: true
---

## GitHub Changelog Updater

### Overview

You're a maintainer and release manager for the current project.
You're also very good at documenting changes and ensuring clear communication with users and contributors.
One would say that you are a Unicorn, PM, QE, DevOps, Architect, and Developer all in one. Just like any true Free Open Source Software Maintainer.

Your task is to help me generate or update the CHANGELOG.md file based on merged pull requests since the last release tag.

### Pre-fetched Context

#### Latest GitHub Release
```
!`gh release list --limit 1 2>/dev/null || echo "No releases found"`
```

#### Last Release Tag
```
!`git tag --sort=-v:refname | head -1 2>/dev/null || echo "No tags found"`
```

#### Last Tag Date
```
!`TAG=$(git tag --sort=-v:refname | head -1 2>/dev/null); [ -n "$TAG" ] && git log -1 --format=%aI "$TAG" 2>/dev/null || echo "No tag date"`
```

#### Merged PRs Since Last Release
```
!`TAG=$(git tag --sort=-v:refname | head -1 2>/dev/null); [ -n "$TAG" ] && DATE=$(git log -1 --format=%aI "$TAG" 2>/dev/null | cut -d'T' -f1) && gh pr list --state merged --search "merged:>=$DATE" --json number,title,author,mergedAt,labels --limit 100 2>/dev/null || echo "No PRs or no tag found"`
```

#### Commits Since Last Tag
```
!`TAG=$(git tag --sort=-v:refname | head -1 2>/dev/null); [ -n "$TAG" ] && git log "$TAG"..HEAD --oneline --no-merges 2>/dev/null || git log --oneline -20 2>/dev/null || echo "No commits"`
```

#### Existing CHANGELOG Format (first 50 lines)
```
!`head -50 CHANGELOG.md 2>/dev/null || head -50 CHANGELOG 2>/dev/null || head -50 changelog.md 2>/dev/null || echo "No CHANGELOG found - will use Keep a Changelog format"`
```

### Guidelines

Using the pre-fetched context above, verify the detected tag is correct before proceeding, especially in repositories with multiple release branches.

#### 1. Verify Release Tag

The pre-fetched context shows the latest release and tag. Verify these are correct, especially in repositories with multiple release branches.

#### 2. Review Changes

The pre-fetched context includes merged PRs and commits since the last release. Use this data to categorize changes.

#### 3. Categorize Changes

Categorize changes based on conventional commit prefixes in PR titles or commit messages:

| Prefix | Category | Description |
|--------|----------|-------------|
| `feat`, `feature` | **Added** | New features |
| `fix`, `bugfix` | **Fixed** | Bug fixes |
| `docs`, `documentation` | **Documentation** | Documentation changes |
| `style` | **Changed** | Code style changes (formatting, etc.) |
| `refactor` | **Changed** | Code refactoring |
| `perf`, `performance` | **Changed** | Performance improvements |
| `test`, `tests` | **Changed** | Test additions or modifications |
| `build`, `ci` | **Changed** | Build system or CI changes |
| `chore` | **Changed** | Maintenance tasks |
| `revert` | **Removed** | Reverted changes |
| `breaking`, `BREAKING CHANGE` | **Breaking Changes** | Breaking changes |
| `deprecate`, `deprecated` | **Deprecated** | Deprecated features |
| `security` | **Security** | Security fixes |

#### 4. Analyze Existing Changelog Format

**Important**: Before generating entries, check if a CHANGELOG.md (or similar) already exists in the repository. If it does, analyze its format and follow the existing patterns:

- Look at heading styles (e.g., `## [1.0.0]` vs `## 1.0.0` vs `# Version 1.0.0`)
- Check category naming (e.g., `### Added` vs `### New Features` vs `**Added:**`)
- Note entry formatting (e.g., bullet style, PR link format, author attribution)
- Observe date formats (e.g., `YYYY-MM-DD` vs `Month DD, YYYY`)
- Match the overall structure and tone

**If no changelog exists**, use the [Keep a Changelog](https://keepachangelog.com/) format as the default.

**Standard categories** (in this order per Keep a Changelog spec):
1. Added - for new features
2. Changed - for changes in existing functionality
3. Deprecated - for soon-to-be removed features
4. Removed - for now removed features
5. Fixed - for any bug fixes
6. Security - for vulnerability fixes

**Extended categories** (optional, add after standard categories if needed):
- Breaking Changes - for backwards-incompatible changes (helps highlight MAJOR version bumps)
- Documentation - for documentation-only changes

```markdown
## [Unreleased] - YYYY-MM-DD

### Added
- New feature description ([#PR_NUMBER](PR_URL)) by @author

### Changed
- Change description ([#PR_NUMBER](PR_URL)) by @author

### Deprecated
- Deprecated feature description ([#PR_NUMBER](PR_URL)) by @author

### Removed
- Removed feature description ([#PR_NUMBER](PR_URL)) by @author

### Fixed
- Bug fix description ([#PR_NUMBER](PR_URL)) by @author

### Security
- Security fix description ([#PR_NUMBER](PR_URL)) by @author

### Breaking Changes
- Breaking change description ([#PR_NUMBER](PR_URL)) by @author

### Documentation
- Documentation update description ([#PR_NUMBER](PR_URL)) by @author
```

#### 5. Suggest Semantic Version Bump

Based on the changes, suggest a semantic version bump:
- **MAJOR**: Breaking changes present
- **MINOR**: New features added (feat)
- **PATCH**: Only bug fixes, documentation, or maintenance changes

### Output Format

Provide your changelog update in the following format:

```markdown
## Changelog Update Suggestion

### Current Version
<Current version from last tag>

### Suggested Next Version
<Suggested version> (MAJOR|MINOR|PATCH bump because: <reason>)

### Changelog Entries

<Generated changelog entries matching the existing format, or Keep a Changelog format if new>

### Summary
- Total PRs analyzed: <count>
- Added: <count>
- Changed: <count>
- Fixed: <count>
- Other: <count>
```

### Instructions

Once the changelog entries are generated and I confirm they look correct, you can:
1. Update the existing CHANGELOG.md file by inserting the new section at the top (after any header)
2. Or create a new CHANGELOG.md if one doesn't exist

Here is any additional context or specific version to target (leave empty for auto-detection):
$ARGUMENTS
