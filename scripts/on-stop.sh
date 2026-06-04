#!/usr/bin/env bash
# Fires when Claude finishes a turn.
# 10s debounce: only announce if the user hasn't replied in that window.
# Mechanism: write a token to PENDING_FILE, spawn a detached watcher that
# announces if the token is still there after 10s. UserPromptSubmit clears it.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

PAYLOAD="$(cat 2>/dev/null || true)"

CWD="$(json_field cwd "$PAYLOAD")"
SESSION_ID="$(json_field session_id "$PAYLOAD")"
TRANSCRIPT="$(json_field transcript_path "$PAYLOAD")"

TITLE="$(build_title "$CWD")"

# Generate a unique token per Stop event so a stale watcher can't fire
# after a newer turn has already started.
TOKEN="$(date +%s)-$$-$RANDOM"
echo "$TOKEN" > "$PENDING_FILE"

DEBOUNCE_SECS="${CLAUDE_VOICE_DEBOUNCE:-10}"

# Detached watcher. Captures TITLE/TOKEN/SESSION_ID/CWD/TRANSCRIPT
# via env-style closure (subshells inherit shell vars).
(
  sleep "$DEBOUNCE_SECS"
  if [ -f "$PENDING_FILE" ]; then
    current=$(cat "$PENDING_FILE" 2>/dev/null || echo "")
    if [ "$current" = "$TOKEN" ]; then
      rm -f "$PENDING_FILE"
      . "${SCRIPT_DIR}/lib/common.sh"
      # Build the body NOW (not at queue-time) so the tool summary
      # reflects whatever the transcript captured during the wait.
      HEADLINE="Claude ready"
      SUMMARY="$(tool_summary "$TRANSCRIPT")"
      [ -n "$SUMMARY" ] && HEADLINE="$HEADLINE — $SUMMARY"
      BODY="$(build_body "$HEADLINE" "$SESSION_ID")"
      announce ready "Claude ready" "$TITLE" "$BODY" "$CWD"
      record_stop_announce "$SESSION_ID"
    fi
  fi
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
