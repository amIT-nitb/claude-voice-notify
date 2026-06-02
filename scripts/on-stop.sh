#!/usr/bin/env bash
# Fires when Claude finishes a turn.
# 60s debounce: only announce if the user hasn't replied in that window.
# Mechanism: write a token to PENDING_FILE, spawn a detached watcher that
# announces if the token is still there after 60s. UserPromptSubmit clears it.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

PAYLOAD="$(cat 2>/dev/null || true)"

CWD="$(json_field cwd "$PAYLOAD")"
SESSION_ID="$(json_field session_id "$PAYLOAD")"

TITLE="$(build_title "$CWD")"
BODY="$(build_body "Claude ready" "$SESSION_ID")"

# Generate a unique token per Stop event so a stale watcher can't fire
# after a newer turn has already started.
TOKEN="$(date +%s)-$$-$RANDOM"
echo "$TOKEN" > "$PENDING_FILE"

DEBOUNCE_SECS="${CLAUDE_VOICE_DEBOUNCE:-60}"

# Detached watcher. Captures TITLE/BODY/TOKEN by closure via env export.
(
  sleep "$DEBOUNCE_SECS"
  if [ -f "$PENDING_FILE" ]; then
    current=$(cat "$PENDING_FILE" 2>/dev/null || echo "")
    if [ "$current" = "$TOKEN" ]; then
      rm -f "$PENDING_FILE"
      . "${SCRIPT_DIR}/lib/common.sh"
      announce ready "Claude ready" "$TITLE" "$BODY"
    fi
  fi
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
