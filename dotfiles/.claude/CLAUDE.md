# Global instructions (all projects, all machines)

Personal cross-project preferences, loaded every session. A project's own
`CLAUDE.md` / `AGENTS.md` overrides these where they conflict.

## Bash command hygiene — keep the permission allowlist working

Claude Code decomposes a compound Bash command and requires *every* part to be
independently auto-approvable; a single un-approvable part forces a permission
prompt and the user's read-only allowlist never fires. Minimize that friction:

- **No leading `cd`.** The Bash working directory persists across calls — use the
  persisted cwd or absolute paths. `cd /x && grep …` defeats the `grep` allow
  rule and prompts.
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

## Sandbox: networked commands need it disabled

The sandbox permits only a small host allowlist — in practice it tracks your
allowed `WebFetch` domains — so most hosts, including `api.github.com` and
anything not on that list, are blocked. `gh`, `git fetch` / `push` / `pull`, and
`curl` / `wget` to off-list hosts fail inside it, often as a misleading TLS/x509
or "invalid token" auth error rather than a clean "network blocked". Run those
with the sandbox disabled (the Bash tool's `dangerouslyDisableSandbox`); they
still go through the normal permission prompt. Don't chase the auth/TLS error as a
real credential problem — it's the sandbox.
