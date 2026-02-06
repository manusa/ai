#!/bin/bash
# Called by SessionStart hook
# Writes Claude's transcript_path to our metadata file

INPUT=$(cat)

# Get our session ID from environment (set by wrapper)
[ -z "$AGENT_SESSION_ID" ] && exit 0

# Extract transcript_path from hook input
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
[ -z "$TRANSCRIPT_PATH" ] && exit 0

# Update metadata file with transcript_path
METADATA_FILE="/tmp/agent-session-$AGENT_SESSION_ID.json"
[ ! -f "$METADATA_FILE" ] && exit 0

# Read existing metadata and add transcript_path
METADATA=$(cat "$METADATA_FILE")
echo "$METADATA" | jq --arg tp "$TRANSCRIPT_PATH" '. + {transcript_path: $tp}' > "$METADATA_FILE"

exit 0