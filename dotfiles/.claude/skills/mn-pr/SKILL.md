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

- **Branch creation** (Step 3): if a new branch is being created, present the suggested name and wait for explicit user confirmation. This gate is independent and cannot be bundled with the next one.
- **Commit + Push + PR creation** (Steps 4–6, consolidated): present the proposed commit message, the push target (remote + branch), and the PR title/body/base/target-repo *together in a single message*, then wait for one explicit user confirmation. On approval, run `git commit`, `git push`, and `gh pr create` back-to-back without further prompts. If any step fails, stop and surface the error — do not silently retry or skip subsequent steps.

Never bypass these gates and never assume the branch-creation approval covers the consolidated gate. The goal is one confirmation per logical decision (branch identity, then ship-it), not one confirmation per shell command.

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

#### Steps 4–6: Prepare the full proposal, then ship in one go

These three steps share a **single confirmation gate**. Prepare everything first, present it together, and only after the user approves run all three commands sequentially.

##### 4a. Gather the diff

Read the full diff so you can write both the commit message and the PR body from the same source of truth:

```shell
git diff HEAD
```

If nothing is staged yet, `git diff HEAD` already covers working-tree changes. If you are on Existing Branch Mode with prior unpushed commits, also review them with `git log @{u}..HEAD --patch` so the PR body covers the whole branch, not just the new commit.

##### 4b. Draft the commit message

Follow the **Commit Conventions** from the embedded mn-commit skill above to draft a conventional commit message. Do not run `git commit` yet.

##### 5a. Determine the push target

From the pre-fetched **Remotes**:
- If an `upstream` remote exists, this is a **fork** — push to `origin` (the fork).
- If only `origin` exists, push to `origin`.

The push command will be `git push -u origin <branch-name>`.

##### 6a. Determine the PR target and draft title/body

- If an `upstream` remote exists (fork workflow): the PR targets the **upstream** repository's default branch, using `--repo` with the upstream URL and `--head <your-fork-owner>:<branch-name>`.
- If only `origin` exists: the PR targets `origin`'s default branch.

Use the commit subject as the PR title. Generate a PR body summarizing the changes.

**Important:** The PR description should focus only on the changes themselves. Do NOT include Co-Authored-By lines, AI agent references, or any mention of the tool used to create the PR.

##### Single confirmation gate

**MANDATORY STOP.** Present *all* of the following in one message and ask for one confirmation:

1. The proposed commit message (full subject + body)
2. The push target: `origin <branch-name>`
3. The PR target repo + base branch
4. The proposed PR title
5. The proposed PR body

Tell the user they can refine any piece before approving. Wait for an explicit "yes" / "approve" / "ship it" — do not infer approval from silence or from the original task prompt.

##### Execute (only after approval)

Run the following in order. Use **separate** Bash calls (never chain `git add` and `git commit` with `&&`). If any step fails, stop and report — do not continue to the next step.

```shell
# 1. Stage
git add <paths>     # or `git add -A` if appropriate for the change set

# 2. Commit
git commit -m "<subject>" -m "<body>"

# 3. Push
git push -u origin <branch-name>

# 4. Create the PR
# Fork workflow (upstream exists):
gh pr create --repo <upstream-owner>/<upstream-repo> --head <your-fork-owner>:<branch-name> --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"

# Origin-only workflow:
gh pr create --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

If the working tree is clean and there are only unpushed commits to ship (Existing Branch Mode), skip the stage + commit calls and start at `git push`.

### Arguments
$ARGUMENTS
