// Butler opencode bridge.
//
// Stowed from the ai repo to ~/.config/opencode/plugins/automated-tasks.ts.
// Mirrors ai-beacon's pkg/plugin/opencode/embed/ai-beacon.ts; resync that
// file's logic here when it changes meaningfully. Reads AGENT_DASHBOARD_URL
// (and optional AI_BEACON_AUTH_TOKEN) from the shell environment.

import type { Plugin } from "@opencode-ai/plugin"
import { hostname as osHostname } from "node:os"

type State = "idle" | "working" | "awaiting_permission"

// BusPayload is the runtime shape opencode publishes on its event bus at
// v1.14.35: { id, type, properties }. The v1 SDK's Event union types only a
// subset and aliases permission.asked as "permission.updated" (see audit
// §C); rather than fight the SDK type union, we pull only what each handled
// event needs and leave the rest as `unknown`.
type BusPayload =
  | SessionStatusEvent
  | SessionIdleEvent
  | PermissionAskedEvent
  | PermissionRepliedEvent
  | SessionCreatedEvent
  | SessionDeletedEvent
  | { type: string; properties?: { sessionID?: string } & Record<string, unknown> }

type StatusType = "busy" | "retry" | "idle"
type SessionStatusEvent = {
  type: "session.status"
  properties: { sessionID: string; status: { type: StatusType } }
}
type SessionIdleEvent = {
  type: "session.idle"
  properties: { sessionID: string }
}
type PermissionAskedEvent = {
  type: "permission.asked"
  properties: { sessionID: string }
}
type PermissionRepliedEvent = {
  type: "permission.replied"
  properties: { sessionID: string }
}
type SessionCreatedEvent = {
  type: "session.created"
  properties: { sessionID: string }
}
type SessionDeletedEvent = {
  type: "session.deleted"
  properties: { sessionID: string }
}

type HeartbeatPayload = {
  session_id: string
  agent_session_id: string
  device: string
  project: string
  started_at: string
  state: State
}

const HEARTBEAT_PATH = "/api/v1/agent/sessions/heartbeat"
const DELETE_PATH = "/api/v1/agent/sessions"
// HTTP timeout — short enough that a wedged dashboard doesn't hang the
// opencode event loop, long enough to absorb LAN latency to a self-hosted
// dashboard. Tunable via env if a future user needs more headroom.
const HTTP_TIMEOUT_MS = 5000

const dashboardURL = (): string =>
  process.env.AGENT_DASHBOARD_URL ??
  process.env.AI_BEACON_URL ??
  "http://localhost:8080"

const authToken = (): string => process.env.AI_BEACON_AUTH_TOKEN ?? ""

// resolveSessionID — wrapper mode (AGENT_SESSION_ID set) keys the dashboard
// record on the wrapper UUID so a single record absorbs both wrapper and
// plugin updates. Standalone mode uses opencode's own session UUID.
const resolveSessionID = (opencodeSessionID: string): string =>
  process.env.AGENT_SESSION_ID || opencodeSessionID

// resolveState maps an opencode bus event to ai-beacon's state taxonomy.
// Returns null when the event does not flip state — caller skips the
// heartbeat in that case so it doesn't blank an existing state.
const resolveState = (event: BusPayload): State | null => {
  switch (event.type) {
    case "session.status": {
      const t = (event as SessionStatusEvent).properties.status.type
      if (t === "busy" || t === "retry") return "working"
      if (t === "idle") return "idle"
      return null
    }
    case "session.idle":
      // Deprecated upstream at v1.14.35 but still emitted; treat as idle.
      return "idle"
    case "permission.asked":
      return "awaiting_permission"
    case "permission.replied":
      // Reply landed; opencode will emit the next session.status with the
      // post-reply state. Return null so we don't override prematurely.
      return null
    case "session.created":
      return "idle"
    default:
      return null
  }
}

const buildHeaders = (): Record<string, string> => {
  const headers: Record<string, string> = { "Content-Type": "application/json" }
  const token = authToken()
  if (token) headers["Authorization"] = `Bearer ${token}`
  return headers
}

const post = async (path: string, body: HeartbeatPayload): Promise<void> => {
  const url = dashboardURL().replace(/\/$/, "") + path
  const res = await fetch(url, {
    method: "POST",
    headers: buildHeaders(),
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  })
  if (!res.ok) {
    // Surface non-2xx so a misconfigured dashboard URL or expired auth
    // token shows up in opencode's stderr instead of vanishing silently.
    console.error(`[ai-beacon] heartbeat ${url} → HTTP ${res.status} ${res.statusText}`)
  }
}

const del = async (path: string, sessionID: string): Promise<void> => {
  const url = dashboardURL().replace(/\/$/, "") + path + "/" + encodeURIComponent(sessionID)
  const headers: Record<string, string> = {}
  const token = authToken()
  if (token) headers["Authorization"] = `Bearer ${token}`
  const res = await fetch(url, {
    method: "DELETE",
    headers,
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  })
  if (!res.ok) {
    console.error(`[ai-beacon] delete ${url} → HTTP ${res.status} ${res.statusText}`)
  }
}

const server: Plugin = async ({ project, directory }) => {
  const startedAt = new Date().toISOString()
  const device = osHostname()
  return {
    event: async ({ event }) => {
      // opencode's plugin loader silently swallows event-hook rejections, so
      // an uncaught throw here just vanishes — wrap the body so a network
      // error or unexpected payload shape leaves at least one breadcrumb on
      // stderr instead of debugging-by-tea-leaves.
      try {
        const payload = event as unknown as BusPayload
        const opencodeSessionID = payload.properties?.sessionID
        if (payload.type === "session.deleted" && opencodeSessionID) {
          await del(DELETE_PATH, resolveSessionID(opencodeSessionID))
          return
        }
        if (!opencodeSessionID) return
        const state = resolveState(payload)
        if (state == null) return
        await post(HEARTBEAT_PATH, {
          session_id: resolveSessionID(opencodeSessionID),
          agent_session_id: opencodeSessionID,
          device,
          project: directory ?? project?.worktree ?? "",
          started_at: startedAt,
          state,
        })
      } catch (err) {
        try { console.error("[ai-beacon] event handler:", err) } catch {}
      }
    },
  }
}

export default { id: "ai-beacon", server }
