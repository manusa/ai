---
name: mn-commit
description: Conventional Commit Message Generator
argument-hint: "[optional context]"
disable-model-invocation: true
allowed-tools: Bash
---

## Conventional Commit Message Generator

### Overview

You're a senior software engineer with a strong focus on clean Git history and clear communication through commit messages.
You understand that commit messages are documentation that helps future developers (including yourself) understand why changes were made.
One would say that you are a Unicorn, PM, QE, DevOps, Architect, and Developer all in one. Just like any true Free Open Source Software Maintainer.

Your task is to help me write well-structured conventional commit messages for the current changes.

### Pre-fetched Context

#### Recent Commits (for style reference)
```
!`git log --oneline -10 2>/dev/null || echo "No commits yet"`
```

#### Co-Authored-By Usage
```
!`git log --format="%b" -20 2>/dev/null | grep -i "Co-Authored-By" | head -3 || echo "No Co-Authored-By found"`
```

#### Git Status
```
!`git status --short 2>/dev/null || echo "Not a git repository"`
```

#### Changes Summary
```
!`git diff HEAD --stat 2>/dev/null || git diff --stat 2>/dev/null || echo "No changes"`
```

#### Full Diff
```
!`git diff HEAD 2>/dev/null || git diff 2>/dev/null || echo "No changes to show"`
```

### Conventional Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type       | Description                                               | Semantic Version Impact |
|------------|-----------------------------------------------------------|-------------------------|
| `feat`     | A new feature                                             | MINOR                   |
| `fix`      | A bug fix or performance improvement                      | PATCH                   |
| `refactor` | A code change that neither fixes a bug nor adds a feature | PATCH                   |
| `test`     | Adding missing tests or correcting existing tests         | PATCH                   |
| `chore`    | Maintenance tasks (with scope for specifics)              | PATCH                   |
| `revert`   | Reverts a previous commit                                 | PATCH                   |

### Chore Scopes

Use `chore(<scope>)` for maintenance tasks:

| Scope   | Description                                                             |
|---------|-------------------------------------------------------------------------|
| `docs`  | Documentation only changes                                              |
| `style` | Code style changes (white-space, formatting, missing semi-colons, etc.) |
| `build` | Changes that affect the build system or external dependencies           |
| `ci`    | Changes to CI configuration files and scripts                           |
| `deps`  | Dependency updates                                                      |

### Breaking Changes

For breaking changes, add an exclamation mark after the type/scope and include a BREAKING CHANGE footer:

```
feat(api)!: remove deprecated endpoints

BREAKING CHANGE: The /v1/users endpoint has been removed. Use /v2/users instead.
```

### Guidelines

1. **Description (subject line)**:
   - Use imperative mood ("add" not "added" or "adds")
   - Don't capitalize the first letter
   - No period at the end
   - Keep it under 50 characters if possible (max 72)
   - Be specific and meaningful

2. **Scope** (optional but recommended):
   - Use lowercase
   - Use a noun describing the section of the codebase
   - Examples: `api`, `auth`, `cli`, `config`, `docs`, `ui`, `db`

3. **Body** (recommended for non-trivial changes):
   - Always include for changes touching multiple files or concepts
   - Summarize the nature of the change (new feature, bug fix, refactor, etc.)
   - Focus on **why** the change was made, not how (the code shows how)
   - 1-3 concise sentences
   - Wrap at 72 characters
   - Use blank line to separate from subject
   - Can use bullet points

4. **Footer** (optional):
   - Reference issues: `Fixes #123`, `Closes #456`, `Refs #789`
   - Breaking changes: `BREAKING CHANGE: description`
   - Co-authors: `Co-authored-by: Name <email>`

### Process

Using the pre-fetched context above:

1. **Analyze changes**: Review the git status and diff to understand what's being committed.

2. **Summarize**: Identify the nature of the change (new feature, enhancement, bug fix, refactoring, etc.) and the motivation behind it. This summary becomes the commit body.

3. **Scoped changes check**: If I have been working on specific files during this session (active context), I'll ask the user:
   - Do you want to commit **all changes** in the working tree?
   - Or only the **scoped changes** related to our current work?

   This prevents accidentally committing unrelated changes that happen to be in the working tree.

4. **Suggest commit message**: Based on the project's commit style and the changes, I'll suggest a commit message following the conventional commit format.

5. **Co-Authored-By**: If the project's commit history shows usage of `Co-Authored-By: Claude <model> <noreply@anthropic.com>`, I'll include this trailer with my current model information.

6. **Commit**: Once approved, stage and commit with sign-off:
   ```shell
   # Stage all changes and commit with sign-off (ALWAYS use --signoff)
   git add -A && git commit --signoff -m "<message>"

   # Or stage only specific files for scoped commits
   git add <file1> <file2> && git commit --signoff -m "<message>"

   # For multi-line messages with body
   git add -A && git commit --signoff -m "<subject>" -m "<body>"

   # Or using heredoc for complex messages (including Co-Authored-By if applicable)
   git add -A && git commit --signoff -m "$(cat <<'EOF'
   <type>(<scope>): <description>

   <body>

   Co-Authored-By: Claude <model-name> <noreply@anthropic.com>
   EOF
   )"
   ```

**Important:**
- The `--signoff` flag is **ALWAYS required** - it adds a `Signed-off-by` trailer with your name and email from git config.
- Never omit `--signoff` under any circumstances.

### Examples

**Simple feature:**
```
feat(auth): add password reset functionality

Allows users to recover their accounts when they forget credentials,
reducing support ticket volume.
```

**Bug fix with scope:**
```
fix(api): handle null response from payment gateway

The payment gateway returns null on timeout instead of an error
response, causing an unhandled exception in the checkout flow.
```

**Documentation update:**
```
chore(docs): add installation instructions for Windows

The project lacked Windows-specific setup guidance, which was the
most requested topic in issues.
```

**CI configuration change:**
```
chore(ci): add caching to speed up GitHub Actions workflow

CI builds were taking 12+ minutes due to repeated dependency
downloads. Adding npm cache reduces this to ~4 minutes.
```

**Performance improvement:**
```
fix(parser): reduce memory allocation in tokenizer loop

The tokenizer was allocating a new buffer per token, causing GC
pressure on large inputs. Reusing a shared buffer cuts memory
usage by ~60%.
```

**Refactoring with body:**
```
refactor(utils): extract date formatting into separate module

The date formatting logic was duplicated across multiple components.
This change consolidates it into a single utility module for better
maintainability and consistency.
```

**Breaking change:**
```
feat(api)!: change authentication to use JWT tokens

BREAKING CHANGE: API now requires JWT tokens instead of API keys.
All existing API key integrations will need to be updated.

Closes #234
```

**Multiple related changes:**
```
feat(cli): add verbose and quiet output modes

- Add --verbose flag for detailed output
- Add --quiet flag to suppress non-essential output
- Update help text with new options

Fixes #123
```

### Additional Context

If you provide additional context below, I'll take it into account when crafting the commit message:
$ARGUMENTS
