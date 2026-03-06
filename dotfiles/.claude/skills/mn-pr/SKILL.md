---
name: mn-pr
description: PR Workflow. Creates a branch, commits changes with conventional commit conventions, pushes, and opens a pull request.
argument-hint: "[optional context]"
disable-model-invocation: true
allowed-tools: Bash
---

## PR Workflow

### Overview

You're a senior software engineer with a strong focus on clean Git history and clear communication through commit messages.
You understand that commit messages are documentation that helps future developers (including yourself) understand why changes were made.
One would say that you are a Unicorn, PM, QE, DevOps, Architect, and Developer all in one. Just like any true Free Open Source Software Maintainer.

Your task is to help me create a pull request for the current changes following a safe, step-by-step workflow.

### Pre-fetched Context

#### Current Branch
```
!`git branch --show-current 2>/dev/null || echo "UNKNOWN"`
```

#### Default Branch
```
!`git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //' || echo "main"`
```

#### Remotes
```
!`git remote -v 2>/dev/null || echo "No remotes configured"`
```

#### Git Status
```
!`git status --short 2>/dev/null || echo "Not a git repository"`
```

#### Changes Summary
```
!`git diff HEAD --stat 2>/dev/null || git diff --stat 2>/dev/null || echo "No changes"`
```

#### Commit Conventions (from mn-commit)
```
!`cat ~/.claude/skills/mn-commit/SKILL.md 2>/dev/null || echo "mn-commit skill not found"`
```

### Process

Using the pre-fetched context above:

#### Step 0: Safety Check — Verify we are on the default branch

Before anything else, verify the **Current Branch** from the pre-fetched context matches the **Default Branch** (typically `main` or `master`).

- If we are **NOT** on the default branch: **STOP immediately**. Inform the user which branch they're on and that they must switch to the default branch before running this workflow. Do not proceed with any other steps.
- If we **are** on the default branch: continue to Step 1.

#### Step 1: Validate there are changes to commit

Check the pre-fetched **Git Status**. If there are no changes (working tree clean), inform the user and stop.

#### Step 2: Determine the branch name

Analyze the changes to determine the commit type (using the mn-commit conventions) and suggest a branch name following the pattern `<type>/<short-description>`:

- `fix/handle-null-payment-response`
- `feat/add-password-reset`
- `refactor/extract-date-formatting`
- `test/add-checkout-edge-cases`
- `chore/update-ci-caching`

Present the suggested branch name to the user for confirmation. If the user provided arguments, use them as **additional context** for both the branch name suggestion and the commit message.

The user may override the suggestion with a custom branch name.

#### Step 3: Create and checkout the new branch

```shell
git checkout -b <branch-name>
```

#### Step 4: Stage and commit

Follow the **Commit Conventions** from the embedded mn-commit skill above. This includes:

1. Analyzing the changes (use the pre-fetched context and diff)
2. Suggesting a conventional commit message
3. **MANDATORY STOP: Present the commit message to the user and ask for explicit confirmation before proceeding. Do NOT run `git commit` until the user approves. The user may want to refine the message.**
4. Staging changes in one Bash call, then committing in a **separate** Bash call (never chain `git add` and `git commit` with `&&`)

For the full diff needed to craft the commit message, run:
```shell
git diff HEAD
```

If no changes are staged yet, use:
```shell
git diff
```

#### Step 5: Push the branch

Determine the push target from the pre-fetched **Remotes**:
- If an `upstream` remote exists, this is a **fork**. Push to `origin` (the fork).
- If only `origin` exists, push to `origin`.

```shell
git push -u origin <branch-name>
```

#### Step 6: Create the Pull Request

Determine the PR target:
- If an `upstream` remote exists (fork workflow): create the PR against the **upstream** repository's default branch using `--repo` flag with the upstream URL.
- If only `origin` exists: create the PR against `origin`'s default branch.

Use the commit subject as the PR title. Generate a PR body summarizing the changes.

**Important:** The PR description should focus only on the changes themselves. Do NOT include Co-Authored-By lines, AI agent references, or any mention of the tool used to create the PR.

**MANDATORY STOP: Present the PR title and body to the user and ask for explicit confirmation before proceeding. Do NOT run `gh pr create` until the user approves. The user may want to refine the PR title or description.**

```shell
# For fork workflow (upstream exists)
gh pr create --repo <upstream-owner>/<upstream-repo> --head <your-fork-owner>:<branch-name> --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"

# For origin-only workflow
gh pr create --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

### Arguments
$ARGUMENTS
