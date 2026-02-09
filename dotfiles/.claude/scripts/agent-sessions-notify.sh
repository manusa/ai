#!/usr/bin/env bash
# Thin wrapper - delegates to private implementation
[ -z "$AGENT_SESSION_ID" ] && exit 0
[ -n "$AGENT_HEARTBEAT_CMD" ] && $AGENT_HEARTBEAT_CMD "$@" 2>/dev/null || true
exit 0
