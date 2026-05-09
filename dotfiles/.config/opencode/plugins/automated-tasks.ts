// Butler opencode bridge.
//
// Stowed from the ai repo to ~/.config/opencode/plugins/automated-tasks.ts.
// Mirrors ai-beacon's pkg/plugin/opencode/embed/ai-beacon.ts (post-#1654);
// resync that file's logic here when it changes meaningfully. Forwards
// opencode bus events to `automated-tasks agent hook event` so the binary's
// SSH-challenge TokenFunc handles auth — the bridge holds no credentials.
// The `agent` prefix is intentional drift from upstream: automated-tasks
// is multi-domain (fitness, github, garmin, ...), so hook commands nest
// under `agent`. See HOOK_ARGV below for the load-bearing fork point.
// In wrapper mode AI_BEACON_WRAPPER_BIN takes precedence; standalone runs
// fall back to PATH lookup on `automated-tasks`.

import type { Plugin } from "@opencode-ai/plugin"
import { hostname as osHostname } from "node:os"

// Butler-baked default. Upstream uses an install-time-templated absolute
// path; the stow flow doesn't run `automated-tasks install`, so we rely on
// PATH lookup (`_ensure_automated_tasks` in the dotfiles repo guarantees
// the binary is on $PATH on every Butler-managed host). Wrapper-mode
// sessions override via process.env.AI_BEACON_WRAPPER_BIN, set by
// `automated-tasks agent session` — that's the path the dashboard reaches
// when the user runs `opencode` through the dotfiles wrapper function.
const INSTALL_BIN = "automated-tasks"

// HOOK_ARGV — Butler-specific subcommand path. Upstream `ai-beacon` exposes
// hook subcommands at the root (`ai-beacon hook event`); `automated-tasks`
// nests them under the `agent` subdomain (the binary spans many domains —
// fitness, github, garmin, etc. — so hook commands live under `agent` by
// design, not by accident). This is the load-bearing place to fork from
// upstream when resyncing.
const HOOK_ARGV = ["agent", "hook"]

const wrapperBin = (): string =>
  process.env.AI_BEACON_WRAPPER_BIN || INSTALL_BIN

// resolveSessionID — wrapper mode (AGENT_SESSION_ID set) keys the dashboard
// record on the wrapper UUID so a single record absorbs both wrapper and
// plugin updates. Standalone mode uses opencode's own session UUID.
const resolveSessionID = (opencodeSessionID: string): string =>
  process.env.AGENT_SESSION_ID || opencodeSessionID

type BusPayload = {
  type: string
  properties?: { sessionID?: string } & Record<string, unknown>
}

type EventPayload = {
  agent_type: "opencode"
  session_id: string
  agent_session_id: string
  cwd: string
  hook_event_name: string
  device: string
  project: string
  started_at: string
  properties: Record<string, unknown>
}

// SPAWN_TIMEOUT_MS — belt-and-suspenders cap on how long any single hook
// event can keep the bridge waiting on the binary. The binary's HTTP client
// has its own timeout, so a hang here is a defensive guard against any
// future code path that doesn't honour it (wedged dashboard + slow DNS +
// blocked syscall, etc.). Without this, await proc.exited would never
// resolve and opencode's plugin loader would pile up pending hooks.
const SPAWN_TIMEOUT_MS = 10000

// dispatchEvent spawns the binary with `hook event` and pipes the JSON
// payload via stdin. Failures (binary missing, non-zero exit, timeout) are
// logged to stderr but never thrown — opencode's plugin loader silently
// swallows rejections from the event hook, so we keep a breadcrumb visible
// without taking the loader down with us.
const dispatchEvent = async (payload: EventPayload): Promise<void> => {
  const bin = wrapperBin()
  if (!bin) {
    console.error("[ai-beacon] no wrapper binary configured (install-time path empty and AI_BEACON_WRAPPER_BIN unset)")
    return
  }
  try {
    const proc = Bun.spawn([bin, ...HOOK_ARGV, "event"], {
      stdin: "pipe",
      stdout: "ignore",
      stderr: "inherit",
    })
    // Kill the subprocess if it overruns the deadline. proc.exited then
    // resolves with the killed exit code; the !== 0 branch logs it.
    const timer = setTimeout(() => {
      try { proc.kill() } catch {}
      console.error(`[ai-beacon] ${bin} ${HOOK_ARGV.join(" ")} event exceeded ${SPAWN_TIMEOUT_MS}ms — killed`)
    }, SPAWN_TIMEOUT_MS)
    try {
      // Awaiting write defends against backpressure when the kernel pipe
      // buffer is full (large `properties` blobs, stressed system).
      await proc.stdin.write(JSON.stringify(payload))
      await proc.stdin.end()
      const code = await proc.exited
      if (code !== 0) {
        console.error(`[ai-beacon] ${bin} ${HOOK_ARGV.join(" ")} event exited ${code}`)
      }
    } finally {
      clearTimeout(timer)
    }
  } catch (err) {
    console.error("[ai-beacon] spawn failed:", err)
  }
}

const server: Plugin = async ({ project, directory }) => {
  const startedAt = new Date().toISOString()
  const device = osHostname()
  const cwd = directory ?? project?.worktree ?? ""
  return {
    event: async ({ event }) => {
      try {
        const payload = event as unknown as BusPayload
        const opencodeSessionID = payload.properties?.sessionID
        if (!opencodeSessionID) return
        await dispatchEvent({
          agent_type: "opencode",
          session_id: resolveSessionID(opencodeSessionID),
          agent_session_id: opencodeSessionID,
          cwd,
          hook_event_name: payload.type,
          device,
          project: cwd,
          started_at: startedAt,
          properties: (payload.properties ?? {}) as Record<string, unknown>,
        })
      } catch (err) {
        try { console.error("[ai-beacon] event handler:", err) } catch {}
      }
    },
  }
}

export default { id: "ai-beacon", server }
