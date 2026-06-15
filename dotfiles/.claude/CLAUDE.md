# Global instructions (all projects, all machines)

Personal cross-project preferences, loaded every session. A project's own
`CLAUDE.md` / `AGENTS.md` overrides these where they conflict.

## Bash command hygiene — keep the permission allowlist working

Claude Code decomposes a compound Bash command and requires *every* part to be
independently auto-approvable; a single un-approvable part forces a permission
prompt and the user's read-only allowlist never fires. Minimize that friction:

- **No leading `cd`.** The Bash working directory persists across calls — use the
  persisted cwd or absolute paths. `cd /x && grep …` defeats the `grep` allow
  rule and prompts. (Exception: sandbox-*excluded* git commands must be run **bare** —
  set the cwd in a separate `cd` step, then `git <subcommand>` — because a leading
  `cd &&`, `git -C`, or `git -c` defeats the exclusion and forces sandboxed
  execution; see the Sandbox section.)
- **Prefer the dedicated `Read`, `Grep`, and `Glob` tools** over `cat` / `grep` /
  `find` / `head` / `sed` for inspection — they never need an allowlist entry.
- **One command per Bash call** for read-only work. Avoid `&&` / `|` chains,
  command substitution `$(…)`, redirections, `tee <file>`, and `for` / `while`
  loops inside otherwise-allowlistable commands.
- **No `node -e` / `python3 -c` / heredocs for inspection, counting, or JSON
  parsing** — arbitrary-code interpreters can never be allowlisted, so they
  always prompt. Use `jq`, `git`, or the dedicated tools instead.
- **Scratch files/scripts: write under `/tmp` explicitly (e.g. `mktemp -p /tmp`),
  NOT bare `mktemp`.** Bare `mktemp` targets the macOS per-user `$TMPDIR`
  (`/var/folders/.../T`), which the sandbox does NOT grant — Claude Code does not
  reliably remap `$TMPDIR` to a sandbox-writable path. `/tmp` is sandbox-writable
  (the config lists `/tmp` and its macOS resolved target `/private/tmp`, since the
  sandbox matches the canonicalized symlink), and the same `/tmp` path works on
  Linux.

## Sandbox: GitHub commands are excluded from it (keyring auth); writes are gated

`gh`'s token lives in the OS **keyring** (`~/.config/gh/hosts.yml` has no
`oauth_token`), which the sandbox blocks — so an authenticated `gh` run *inside* the
sandbox can't read its credential and returns HTTP 401. Rather than disable the
sandbox per call (always prompts), copy the token to a plaintext file, or maintain a
GitHub-API entry in the network allowlist, `gh` and the `mn-review` fetch scripts are
in `sandbox.excludedCommands`, so they run **outside** the sandbox (keyring and
network both work) and go through the normal permission flow. Excluding a command
un-sandboxes its whole child-process tree, so `gh` called *inside* an excluded
script authenticates too. The token never leaves the keyring; nothing is exported or
written to disk.

Net effect for read-only review:
- `gh pr view`/`diff`/`list`, `gh issue view`, and the `get-pr-*.sh` scripts run
  unsandboxed and are auto-approved by their `permissions.allow` rules — **no
  prompt**. (`autoAllowBashIfSandboxed` does NOT cover excluded commands, so the
  `allow` rule is what makes them prompt-free; without one they'd prompt.)
- Everything else still runs sandboxed and auto-approves as before.

Writes stay gated regardless — excluded commands still pass through `ask`/`deny`.
Every mutating `gh`/`git` command — `gh pr review`/`merge`/`comment`/`create`/
`close`/`edit`, the `gh issue` writes, `gh api`, `gh release`/`repo`/`secret`/
`workflow` writes, and `git commit`/`push`/`merge`/`rebase`/`reset`/`revert`/
`cherry-pick` — is in `permissions.ask`, so it always prompts (content-scoped `ask`
beats both the sandbox auto-allow and any `allow` rule; precedence is deny → ask →
allow, specificity ignored). The commit-creating and remote git ops
(`git commit`/`merge`/`rebase`/`cherry-pick`/`revert`/`push`, plus `git tag`) are in
BOTH `excludedCommands` and `ask`: a sandboxed `git commit` fails when
`commit.gpgsign` is on because the **gpg-agent socket is blocked** (same class of
failure as the gh keyring), so they must run unsandboxed to sign / authenticate —
while `ask` still prompts for each. Never rely on a bare `Bash`/`Bash(*)` ask —
those are skipped for sandboxed commands.

**Invocation form matters for excluded git commands.** The sandbox checks
`excludedCommands` against the command's *leading* token(s) — NOT the per-part
*permission* decomposition — so anything in front of the excluded command defeats the
match. `cd <dir> && git commit …` (leads with `cd`) and `git -C <dir> commit …`
(leads with `git -C`) both run **sandboxed**, where the gpg-agent socket and a
non-writable `.git` are blocked and signing / index writes fail ("Read-only file
system / can't connect to gpg-agent"). Only a **bare** excluded command matches: set
the directory in a *separate* `cd` step (the cwd persists across calls), then run
bare `git <subcommand>` — never `cd && git …`, `git -C`, `git -c`, or `--git-dir`. If
that isn't practical (e.g. the repo's `.git` is outside the sandbox-writable paths),
fall back to `dangerouslyDisableSandbox`, which prompts — fine for an `ask`-gated
write. (Measured: a commit in this dotfiles repo run as `cd … && git commit` went
sandboxed and needed the escape hatch.)

Reach for `dangerouslyDisableSandbox` only for a host/op covered by neither the
allowlist nor `excludedCommands`. If a `gh`/`git` call 401s or hangs inside the
sandbox, the fix is to add it to `excludedCommands` (keyring) or its host to
`sandbox.network.allowedDomains` — not to chase a phantom token problem.

**`podman` and `make lint`/`make build` are excluded too.** `podman` can't run
sandboxed — it needs its lockfile (`~/.config/containers/...`) and the VM socket
(`127.0.0.1:<ssh-port>`), both blocked — so it's in `excludedCommands`; the
read-only subcommands (`podman machine`/`info`/`ps`/`system connection`) and
`podman run` are allow-listed and auto-approve unsandboxed. `make lint`/`make build`
are excluded because the golangci-lint installer needs the macOS `$TMPDIR` and a
download. Do NOT reach for `dangerouslyDisableSandbox` on these — it always prompts
and bypasses the allow rule; the exclusion + allow rule is what makes them
prompt-free. As with git, invoke them **bare** (leading `podman …` / `make …`): a
leading `VAR=…` assignment, `$(…)`, or `cd &&` defeats the `excludedCommands` match
and forces a sandboxed (failing) run. Inline absolute paths instead of `REPO=…;
podman run -v "$REPO":…`.
