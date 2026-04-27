---
name: mn-pr
description: PR Workflow. Creates a branch (or reuses a dedicated one), commits changes with conventional commit conventions, pushes, and opens a pull request. Safe to invoke at the end of an agent task — every destructive step (commit, push, PR creation) is gated behind an explicit user confirmation.
argument-hint: "[optional context]"
allowed-tools: Bash
---

## PR Workflow

### Overview

You're a senior software engineer with a strong focus on clean Git history and clear communication through commit messages.
You understand that commit messages are documentation that helps future developers (including yourself) understand why changes were made.
One would say that you are a Unicorn, PM, QE, DevOps, Architect, and Developer all in one. Just like any true Free Open Source Software Maintainer.

Your task is to help me create a pull request for the current changes following a safe, step-by-step workflow.

### Human-in-the-loop gates (NON-NEGOTIABLE)

This skill may be invoked autonomously by another agent at the end of a task. To keep that safe, the following gates MUST be honored on every run, regardless of caller:

- **Branch creation** (Step 3): if a new branch is being created, present the suggested name and wait for explicit user confirmation.
- **Commit** (Step 4): present the proposed commit message and wait for explicit user confirmation before running `git commit`.
- **Push** (Step 5): present the push target (remote + branch) and wait for explicit user confirmation before running `git push`.
- **PR creation** (Step 6): present the PR title, body, base branch, and target repo and wait for explicit user confirmation before running `gh pr create`.

Never bypass these gates, never assume prior approval covers a later step, and never chain confirmations ("approve everything"). Each gate is independent.

### Pre-fetched Context

#### Current Branch
```
!`git branch --show-current 2>/dev/null || echo "UNKNOWN"`
```

#### Default Branch
```
!`git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //' || echo "main"`
```

#### Worktree Type
```
!`[ "$(git rev-parse --git-dir 2>/dev/null)" = "$(git rev-parse --git-common-dir 2>/dev/null)" ] && echo "main" || echo "linked"`
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

#### Unpushed Commits
```
!`git log @{u}..HEAD --oneline 2>/dev/null || echo "No upstream tracking branch"`
```

#### Commit Conventions (from mn-commit)
```
!`cat ~/.claude/skills/mn-commit/SKILL.md 2>/dev/null || echo "mn-commit skill not found"`
```

### Process

Using the pre-fetched context above:

#### Step 0: Workflow Mode Detection

Use the pre-fetched **Current Branch**, **Default Branch**, and **Worktree Type** to pick a mode:

- **Create Branch Mode** — Current branch equals the default branch.
  → Run all steps (1 → 6) including the branch suggestion and creation.

- **Existing Branch Mode** — Current branch differs from the default branch AND **Worktree Type** is `linked`.
  → The current branch is treated as dedicated. **Skip Steps 2 and 3.** Reuse the current branch name in Steps 5 and 6.

- **Ambiguous** — Current branch differs from the default branch AND **Worktree Type** is `main`.
  → **STOP and ask the user** which mode to use. Default-suggest aborting (i.e. switch to the default branch and re-run). Do not assume; wait for explicit confirmation. If the user picks "treat as dedicated", continue in Existing Branch Mode.

#### Step 1: Validate there is work to do

Inspect the pre-fetched **Git Status** and **Unpushed Commits**:

- **Create Branch Mode**: if working tree is clean, stop — there is nothing to commit.
- **Existing Branch Mode**:
  - If working tree is clean AND there are no unpushed commits → stop, nothing to do.
  - If there are unpushed commits AND a dirty working tree → **ask the user** whether the unpushed commits should be included in this PR (almost always "yes", but confirm) and whether the working-tree changes should be committed as a new commit on top. Wait for explicit confirmation before staging anything.
  - If working tree is clean but there are unpushed commits → ask the user to confirm pushing them as-is, then skip Step 4 and proceed to Step 5.
  - If dirty working tree but no unpushed commits → proceed to Step 4 normally.

#### Step 2: Determine the branch name *(Create Branch Mode only — skip in Existing Branch Mode)*

Analyze the changes to determine the commit type (using the mn-commit conventions) and suggest a branch name following the pattern `<type>/<short-description>`:

- `fix/handle-null-payment-response`
- `feat/add-password-reset`
- `refactor/extract-date-formatting`
- `test/add-checkout-edge-cases`
- `chore/update-ci-caching`

Present the suggested branch name to the user for confirmation. If the user provided arguments, use them as **additional context** for both the branch name suggestion and the commit message.

The user may override the suggestion with a custom branch name.

#### Step 3: Create and checkout the new branch *(Create Branch Mode only — skip in Existing Branch Mode)*

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

**MANDATORY STOP: Present the push target (`origin <branch-name>`) and ask for explicit user confirmation before proceeding. Do NOT run `git push` until the user approves.**

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
