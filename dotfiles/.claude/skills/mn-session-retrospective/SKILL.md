---
name: mn-session-retrospective
description: Session Retrospective. Reviews the just-completed session for friction — permission prompts on safe read-only ops, sandbox blocks, chained/piped commands that defeated the allowlist, rabbit holes, wrong or missing guidance — then proposes precise edits to the right settings.json, CLAUDE.md/AGENTS.md, or skill (global or project-local) so the next session runs more autonomously. Every file edit is gated behind explicit confirmation.
argument-hint: "[optional focus, e.g. permissions | sandbox | tooling | a specific pain point]"
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

## Session Retrospective

Engineering-productivity coach + toolsmith for this developer's AI-tooling setup. Subject:
the session that just ran. Find every friction point — anything that forced a permission
prompt, hit the sandbox, slowed you down, sent you down a rabbit hole, or hurt correctness —
and turn each into a durable fix so the next session runs better.

**Why this skill exists.** The `manusa/ai` repo (this developer's AI-tooling dotfiles, stowed
into `~/.claude`) tunes Claude Code so safe, **read-only work runs unsupervised** — via the
sandbox + `permissions` (allow/ask/deny) + a global `CLAUDE.md`. Prompts still slip through,
usually because commands were chained/piped (`make test | tail`, `a && b`, `$(…)`) so the
per-part allowlist never fired, or a safe read-only command isn't allow-listed yet. Catch
those — but equally in scope: stale docs, missing project knowledge, flaky tooling, skill
defects, repeated failures.

Run this **while session context is fresh** (before `/clear`). Your memory of the session is
the primary source; the pre-fetched data augments it and survives compaction.

### Pre-fetched context

#### Edit targets & session project
```
!`~/.claude/skills/mn-session-retrospective/scripts/get-context.sh`
```

#### Current permission & sandbox config
```
!`~/.claude/skills/mn-session-retrospective/scripts/get-permissions.sh`
```

#### Skills & agents available to improve
```
!`~/.claude/skills/mn-session-retrospective/scripts/get-skills-inventory.sh`
```

#### This session's Bash commands (auto-flagged for allowlist-defeating patterns)
```
!`~/.claude/skills/mn-session-retrospective/scripts/get-session-commands.sh`
```

### Where fixes land — two scopes

Pick a scope per finding, then edit the **source** file (never the `~/.claude` symlink):

- **Global** — `DOTFILES_REPO/dotfiles/.claude/` (`settings.json`, `CLAUDE.md`, `skills/<name>/`,
  `agents/`). Applies to every project. Use for fixes that are safe and useful everywhere.
- **Project-local** — the session project's own `.claude/settings.json`, `.claude/skills/<name>/`,
  and `AGENTS.md`/`CLAUDE.md`. Applies to that project only (it may differ from `manusa/ai` —
  see *Edit targets* context). Use for project-specific commands, layout, gotchas, or
  permissions that shouldn't be global.

Prefer project-local over bloating the global config when a fix is genuinely project-specific.
Each scope is a separate proposal with its own confirmation.

### Source material
- **Live memory (primary)** — you ran every command and saw every failure, denial, retry, and
  `dangerouslyDisableSandbox`.
- **Auto-flagged command list (augment)** — flags pipes/chaining/`$(…)`/leading-`cd`; ignore
  this skill's own scaffolding lines.
- **Can't see directly** — whether an approvable-looking command silently prompted. For a
  rigorous allowlist sweep recommend the built-in **`/fewer-permission-prompts`**; don't
  reimplement it.

### Lens A — supervision & sandbox friction
For each command that prompted, was denied, or failed in the sandbox, find the root cause → fix.
Cross-check candidates against the *permission config* context so you propose a precise diff,
never a duplicate.

For how the lists interact — the `deny → ask → allow → sandbox auto-allow` order, and why `ask`
is the only gate that overrides the sandbox auto-allow — see
`DOTFILES_REPO/dotfiles/.claude/README.md`. Key point for proposals: a read-only command's
`allow` rule looks redundant under the sandbox (it auto-allows standalone) but is **load-bearing
the moment that command is piped/chained onto an `excludedCommand`** — the whole compound runs
unsandboxed, so the filter needs its own rule (this is exactly why row 1 below, `make test | tail`,
prompts). So keep/add `allow` for read-only filters; never treat them as decorative.

| Symptom | Root cause | Fix |
|---|---|---|
| Safe read-only cmd prompted | not in `permissions.allow` | add `Bash(<cmd>:*)` — e.g. `head` is allowed but `tail`/`sort`/`uniq`/`cut` are not, so `make test \| tail` prompts |
| Whole pipe/chain prompted | a part not independently approvable, or `$(…)`/backtick/redirect | **behavioral** (split calls, pipe only to allow-listed filters, use Read/Grep/Glob) — *unless* only a safe filter is missing, then allow it |
| `git`/`podman`/`make` prompted or failed | leading `cd` defeated the `excludedCommands` match | **behavioral**: set cwd separately, run bare |
| Sandbox blocked a resource | network host / write path / keyring·gpg·socket | `sandbox.network.allowedDomains` / `sandbox.filesystem.allowWrite` / `sandbox.excludedCommands` (+ matching `allow`/`ask`) |
| Mutating op gated inconsistently | missing from `ask` | add to `permissions.ask` (never `allow`) |

### Lens B — effectiveness & correctness friction
Anything that cost time or quality beyond permissions:
- Wrong/outdated guidance in global `CLAUDE.md` or a project `AGENTS.md` → fix it.
- Missing project knowledge (build/test cmd, layout, gotcha) → session project's `AGENTS.md`
  (or suggest `/mn-agents-md` there).
- A skill misbehaved / was unclear / buggy → its `SKILL.md` or scripts. **Including this one:**
  if `mn-session-retrospective` missed a pattern, a script errored, or its guidance is unclear,
  propose fixing it too.
- Tooling/env friction (flaky test, wrong assumption) → doc note if fixable, else surface plainly.
- Repeated loops / wasted turns → what would have prevented them?

### Guardrails (non-negotiable)
- Read-only → `allow`; mutating/destructive → `ask`; **never** the reverse. A retrospective that
  widens the trust boundary is a regression.
- **Never blanket-allow code-executors**: `awk`/`sed`/`xargs`/`find -exec`/`sh -c`/`node -e`/
  `python -c`/`eval`/leading `VAR=…`. Fix behaviorally.
- Keep `filesystem.allowWrite` tight (scratch/cache/build only); be conservative with
  `network.allowedDomains`.
- Recurrence bar: a one-off exotic command is a behavioral note, not a new rule. Lean allowlist
  beats a sprawling one.
- "Guidance missing" → edit; "guidance ignored" → behavioral note (sharpen wording only if
  genuinely ambiguous), don't bloat.

### Output (report first — no edits yet)
```markdown
## Session Retrospective
**Session:** <task + outcome, 1–2 lines>
**Friction found** — per item: `[A/B] title` · what happened (quote the cmd/failure) ·
  impact (prompt | sandbox block | wasted N turns | wrong result) · root cause · confidence.
  ("No A/B friction this session." if clean — don't pad.)
**Proposed changes** — grouped by file, exact before/after, each tagged [global] or [project].
  e.g. `[global] + Bash(tail:*) → permissions.allow — fixes 'make test | tail'`.
**Behavioral reminders** — already-documented things that were missed (no edit).
**Follow-ups** — /fewer-permission-prompts (allowlist sweep) · /mn-agents-md (project gaps) ·
  /mn-commit or /mn-pr to commit.
```

### Confirmation gate & apply
**STOP** after the report; wait for approval. The user may accept all / a subset / none and
refine first — do not edit any file before explicit approval.
On approval: edit the correct **source** file (verify the path + scope against *Edit targets*);
for `settings.json` preserve JSON validity and the existing grouping/order, then sanity-check
with a read-only `jq . <file>`; keep each change easy to commit on its own. **Do not
auto-commit** — point the user at `/mn-commit` or `/mn-pr`. Stowed/global edits are live for the
next session immediately. Don't manufacture findings on a clean session.

### Additional focus / context
$ARGUMENTS
