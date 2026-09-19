# Claude Code permission & sandbox model

How Bash approval is decided in this profile (`settings.json`:
`sandbox.enabled: true`, `autoAllowBashIfSandboxed: true`). This is the decision
*model*; the *why* behind `excludedCommands` (gh keyring, gpg-agent, podman,
golangci-lint) and Bash hygiene lives in `CLAUDE.md`.

## Decision order (per Bash command)

| # | Match | Result |
|---|-------|--------|
| 1 | `permissions.deny` | blocked |
| 2 | `permissions.ask` (content-scoped) | **prompt** — beats sandbox auto-allow *and* `allow` |
| 3 | `permissions.allow` | auto-approve, no prompt |
| 4 | no match + sandboxable (not in `excludedCommands`) | auto-run **sandboxed**, no prompt (`autoAllowBashIfSandboxed`) |
| 5 | no match + excluded (runs unsandboxed) | prompt (default Bash gate) |

Precedence is `deny → ask → allow`; rule specificity is ignored.

> An `excludedCommand` runs unsandboxed **only as the entire command**. Anything else in
> it — `&&`/`;` chaining, a pipe, a redirect, a heredoc, `$(…)` or backticks, anywhere,
> even after an otherwise-bare `gh …` — runs the **whole compound sandboxed**, so the
> excluded command loses its keyring / gpg-agent / socket access and fails (e.g.
> `make test | tail`, `gh pr diff | grep`, `git commit -m "$(cat <<'EOF' …)"`). Run
> excluded commands bare, one per call, and pass long text via a file (`git commit -F`,
> `gh … --body-file`). Parsing that must follow a `gh` call belongs in a read-only skill
> script listed in `excludedCommands` (its child processes inherit the exclusion).

## What each list actually does here

- **`allow`** — earns its keep for read-only commands. *Decorative* only for a
  sandboxable read-only command run **standalone** (the sandbox auto-allows it whether
  listed or not; verified: `rg`/`fd` run with no rule). **Load-bearing whenever the
  command runs unsandboxed:** an `excludedCommand` (no sandbox net), or any command with
  the sandbox disabled (`dangerouslyDisableSandbox`). **Keep an `allow` rule for every
  read-only command** so those unsandboxed runs stay prompt-free. (Piping a filter onto
  an excluded command no longer counts: the compound runs sandboxed — see above.)
- **`ask`** — the only real-time human gate. **Overrides the sandbox auto-allow**,
  so it fires even on sandboxable commands (verified: `find` placed in `ask`
  prompted despite being sandboxable). The dial for "technically sandboxable but I
  still want eyes on it."
- **`deny`** — hard block.
- **sandbox auto-allow** — runs any non-excluded command silently, confined by
  `filesystem.allowWrite` + `network.allowedDomains`.

## Verified facts & gotchas (2026-06)

- `ask` > sandbox auto-allow. To gate a sandboxable-but-dangerous command, add it to
  `ask` (prefix-matched → all-or-nothing) or use a `PreToolUse` hook for surgical
  matching (e.g. only `find … -exec` / `-delete`).
- The sandbox confines writes to `allowWrite` **+ the cwd** — it does **not** protect
  the working tree. `find . -exec rm {} +` auto-runs in cwd with no prompt. Accepted
  here: Claude is only ever run inside git projects, so in-tree damage is
  recoverable — that's the sandbox's purpose, not `ask`'s.
- `settings.local.json` hot-reloads mid-session — permission edits take effect on the
  next command, no restart.
- `excludedCommands` run fully unsandboxed (keyring / gpg-agent / VM socket /
  installer needs); their `allow` rule is what keeps them prompt-free. See `CLAUDE.md`.
- (2026-09-19) Exclusion needs the **whole command** to be the bare excluded command.
  Measured with `gh pr list`: bare → authenticated; with `&& echo`, `| cat`,
  `>file 2>&1`, a trailing `<<'EOF'` heredoc, `"$(echo 1)"`, or a backtick argument →
  sandboxed (`api.github.com` denied). Backslash line continuations and multi-line
  quoted arguments are fine. This contradicts this file's earlier claim that a compound
  with an excluded part runs unsandboxed (either Claude Code changed, or that claim was
  never measured).
- A skill's `!`-prefetch script runs sandboxed like any Bash command; one that calls
  `gh` needs its own `excludedCommands` entry, or `gh` fails (measured: the
  `mn-github-issue` scripts silently printed their "Unknown repository" fallback).
