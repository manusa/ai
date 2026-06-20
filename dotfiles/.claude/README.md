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

> A compound/piped command runs **unsandboxed** if **any** part is an `excludedCommand` — its
> sandboxable parts then fall to row 5 and need an `allow` rule (e.g. `make test | tail`).

## What each list actually does here

- **`allow`** — earns its keep for read-only commands. *Decorative* only for a
  sandboxable read-only command run **standalone** (the sandbox auto-allows it whether
  listed or not; verified: `rg`/`fd` run with no rule). **Load-bearing whenever the
  command runs unsandboxed:** an `excludedCommand` (no sandbox net), a read-only filter
  **piped/chained onto** an excluded command (the whole compound goes unsandboxed → the
  filter needs its rule — e.g. `make test | tail`, `go test ./… | grep`,
  `gh pr diff | grep`), or any command with the sandbox disabled. Because piping
  read-only filters onto excluded commands is routine, **keep an `allow` rule for every
  read-only command** — it's the everyday safety net, not just future-proofing.
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
