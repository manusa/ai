#!/usr/bin/env bash
# Thin wrapper - delegates to private implementation
[ -x "$AGENT_SESSION_NOTIFY_SCRIPT" ] && exec "$AGENT_SESSION_NOTIFY_SCRIPT" "$@"
exit 0
