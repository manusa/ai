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
- **Shell is zsh: bash `$PIPESTATUS` expands empty — use `${pipestatus[1]}`.** To
  verify a command's exit code/output, don't pipe it; redirect to a scratch file
  (`cmd >/tmp/claude/out 2>&1; rc=$?`), then Read/Grep. **Not for an
  `excludedCommands` target** (`make test`, `go test`, `make lint`, `gh`, `git commit`):
  a pipe *or* a redirect makes it run sandboxed (see the Sandbox section) — run it
  bare and read the Bash tool's own output and exit code.
- **zsh expands unquoted globs** (`*` `?` `[`) and aborts with `no matches found`;
  quote them: `grep --include='*.java'`, `gh api '.../F.java?ref=abc'`.
- **The default `java` on PATH varies by machine — pin the JDK with a `javaNN` function.**
  `java8`/`java17`/`java21`/`java25` exist on every machine; each sets `JAVA_HOME`/`PATH` then
  execs what's passed, so a **single command** works: `java25 mvn verify`, `java21 gradle build`
  (no `&&` needed). It runs sandboxed → auto-approves, no prompt, and is confined to the
  sandbox's write/network allowlists. **Only prefix commands that genuinely need a JDK**
  (Maven/Gradle/`java`, or a `make` target that builds/tests Java). Do NOT prefix `go`/`bun`/`npm`
  or a non-JVM `make` target: `javaNN` becomes the leading token and defeats that command's
  `sandbox.excludedCommands` match, re-sandboxing it — a sandboxed `go test`/`make test` can't
  reach the gpg-agent socket, so fixture `git commit`s fail with `exit status 128`. Run those bare.

## Spawning subagents

- **Binds any orchestration, not only skills**, including a session acting as an
  orchestrator ("Oracle"). An independent review or check goes to a **fresh** agent with
  an explicit non-fork `subagent_type` (`general-purpose`), never `fork`, and never to an
  agent that wrote the change or proposed its design; its brief carries the target, the
  files and the method, not the spawner's conclusions. Continuation work, such as shipping
  a change with `mn-pr`, never goes to a fresh agent: continue the agent that did the
  work (SendMessage), or, for your own work, dispatch a **fork** (`subagent_type: fork`)
  of yourself.

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
- **Every skill script that calls `gh` or `glab` needs its own `excludedCommands` entry** —
  skill `!`-prefetch runs sandboxed like any Bash call, and `gh` then fails. Keep such
  scripts **read-only**: `Bash(~/.claude/skills/:*)` allows them without a prompt, so a
  script that commits or posts would bypass the `ask` gates below. The one writing
  script, `mn-review/scripts/post-mr-review.sh`, posts a whole approved review to a
  GitLab MR in one run: the overview note, every inline note and the approval (glab has
  no `--body-file`, so the bodies are read inside the excluded script). It is listed in
  `permissions.ask` by its own path: `ask` beats `allow`, so an approved review prompts
  me **once**, like the single `gh api …/reviews` POST on GitHub. The ask rule is one
  literal spelling, while the allow rule and the exclusion are directory-wide, so the
  script refuses to run under any other spelling of its path (`scripts/./…`,
  `scripts//…`). It posts only body files under `/tmp` and never a symlink, so a
  manifest can't point straight at an arbitrary file; that checks the path, not the
  content (a copy or hard link in `/tmp` still passes), so the review I approved in the
  conversation is the real gate; the one prompt shows the target and the verdict. Gate any
  new writing skill script the same way.
- **Jira reads go through a skill script too.** The linked-issues pre-fetch and
  `mn-review/scripts/get-jira-issue.sh` run the `jira` CLI unsandboxed through the same
  exclusion, prompt-free. An agent-run `jira issue view` runs sandboxed, can't reach the
  Jira host, and prompts on the unsandboxed retry, so the review never runs it directly.
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

**The whole command must be one simple command, not just start with one.** A
`$(…)`, backticks, a heredoc (even plain stdin `<<'EOF'`), a pipe, a redirection, or a
trailing `&&`/`;` *anywhere* in it also makes it run sandboxed, even after a bare
`gh …` / `git commit …` start. Multi-line quoted arguments and backslash line
continuations are fine. (Measured 2026-09-19: bare `gh pr list` authenticated; the same
call with `--limit "$(echo 1)"`, a backtick argument, a trailing `<<'EOF'` heredoc,
`| cat`, `>file 2>&1`, or `&& echo` was sandboxed and denied `api.github.com`.)
When `gh` output needs parsing, put the parsing in a read-only skill script listed in
`excludedCommands` (e.g. `mn-review/scripts/get-pr-file-lines.sh`) — not a pipe.
So never build a commit message or a PR/issue/review body with
`-m "$(cat <<'EOF' …)"` / `--body "$(…)"`: write it with the Write tool to a scratch
file and pass `git commit -F <file>` / `gh … --body-file <file>`. Single-quote inline
`-m` / `--title` text so a backtick in it isn't executed as a substitution.

Reach for `dangerouslyDisableSandbox` only for a host/op covered by neither the
allowlist nor `excludedCommands`. If a `gh`/`git` call 401s or hangs inside the
sandbox, the fix is to add it to `excludedCommands` (keyring) or its host to
`sandbox.network.allowedDomains` — not to chase a phantom token problem.

**A sandboxed HTTPS tool failing TLS is the proxy, not a bad cert.** The sandbox
routes network through a local proxy (`HTTPS_PROXY=…@localhost:<port>`) that MITMs any
host **not** in `sandbox.network.allowedDomains` with its own self-signed CA — so any
Go/HTTPS CLI (`glab`, `curl`, anything honoring `HTTPS_PROXY`) fails with `tls: failed
to verify certificate: x509: OSStatus <n>` (Go/macOS) or `curl: (60) self signed
certificate in certificate chain`. This is **not** the corporate/Red Hat CA, and
**not** fixable with `SSL_CERT_FILE` (Go ignores it on macOS — Linux-only). Diagnose in
one step with `env | grep -i proxy`; the allow-listed vs. non-allow-listed contrast is
the tell (`curl https://github.com` → exit 0 tunnelled, `curl https://<internal-host>`
→ self-signed-cert error MITM'd). Fix by adding the host to
`sandbox.network.allowedDomains` (the proxy then tunnels it and the real cert
verifies). The proxy also supplies DNS for internal hosts, so **allow-list, don't
unsandbox** for hosts the proxy can tunnel: `dangerouslyDisableSandbox` clears the
proxy but internal names then fail `no such host`. (`gitlab.cee.redhat.com` is
allow-listed, but `glab`/`curl` to it still fail TLS *sandboxed* and must run
**unsandboxed** — see the `glab` note below.)

**`podman` and `make lint`/`make build` are excluded too.** `podman` can't run
sandboxed — it needs its lockfile (`~/.config/containers/...`) and the VM socket
(`127.0.0.1:<ssh-port>`), both blocked — so it's in `excludedCommands`; the
read-only subcommands (`podman machine`/`info`/`ps`/`system connection`) and
`podman run` are allow-listed and auto-approve unsandboxed. `make lint`/`make build`
are excluded because the golangci-lint installer needs the macOS `$TMPDIR` and a
download. Do NOT reach for `dangerouslyDisableSandbox` on these — it always prompts
and bypasses the allow rule; the exclusion + allow rule is what makes them
prompt-free. As with git, invoke them **bare** (leading `podman …` / `make …`): a
leading `VAR=…` assignment or `cd &&`, or a `$(…)` / pipe / redirect anywhere, defeats
the `excludedCommands` match and forces a sandboxed (failing) run. Inline absolute
paths instead of `REPO=…; podman run -v "$REPO":…`.

**`glab` is excluded too** (Red Hat's `gitlab.cee.redhat.com` and other private
GitLab). Sandboxed it fails TLS against that host (`self signed certificate in
certificate chain` / `x509: failed to verify certificate`) **despite the host being
allow-listed** — it resolves into the `NO_PROXY` internal ranges, so the proxy can't
tunnel it. In `excludedCommands` it runs unsandboxed and the real Red Hat CA (trusted
on the machine) verifies. Read-only subcommands (`glab mr view`/`list`/`diff`,
`glab issue view`/`list`, `glab repo view`, `glab ci view`/`list`, `glab auth status`)
are allow-listed → prompt-free; mutating ones (`glab mr create`/`merge`/`note`/`approve`,
`glab issue create`, `glab api`, `glab config set`, …) stay in `ask`. **Don't reach
for `dangerouslyDisableSandbox` on `glab`** — the exclusion handles it, prompt-free.
Note `gitlab.cee.redhat.com` is reachable **only over the Red Hat VPN**; when the VPN
drops (it does, intermittently) `glab`/`git` fail with `could not resolve host` /
`no such host` / connection timeouts — that is a **VPN outage, not** a sandbox or cert
problem, so reconnect the VPN rather than touching the sandbox config.

## Python / uv

- **`pytest`/`unittest` (every form) are in `excludedCommands`** so they run
  unsandboxed — *precautionary*, mirroring `go test` (gpg-agent, keyring); no Python
  suite has actually been measured failing sandboxed yet.
- **Matching is on leading tokens, so invoke them bare.** `cd &&`, `VAR=…`, `javaNN`,
  an absolute path, or **any flag between `uv run` and `pytest`** (`uv run --frozen
  pytest`) silently re-sandboxes the run.
- **Everything else stays sandboxed** and auto-approves. uv needs `~/.cache/uv` and
  `~/.local/share/uv` writable, plus `objects.githubusercontent.com` allow-listed —
  fetching a managed Python redirects there from `github.com`.
- **`.venv/bin/x` needs no `./`** (it contains a `/`, so no `PATH` lookup); both forms
  are allow-listed.
- **Nothing here is *blocked*** — `autoAllowBashIfSandboxed` auto-approves every
  sandboxed command, so `pip3 install`, `uv sync`, `uv add`, `ruff format`,
  `ruff check --fix`, `pymarkdown fix` and `uv version --bump` all just run. Absent
  from `allow` means "don't reach for it unasked", not "gated"; the real gate is
  commit/PR review.
- `uv run` syncs implicitly — `--frozen --no-sync` for a read-only `uv run mypy` /
  `ruff check` / `pymarkdown`, but never with `pytest` (see above).
- Syntax check with `python3 -m py_compile`, not `python3 -c`.
