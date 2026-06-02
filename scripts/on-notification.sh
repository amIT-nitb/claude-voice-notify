#!/usr/bin/env bash
# Fires when Claude needs permission or has been idle ≥60s waiting on the user.
# Announce immediately — this is a real "Claude is blocked" signal.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# Read the JSON event payload from stdin.
PAYLOAD="$(cat 2>/dev/null || true)"

CWD="$(json_field cwd "$PAYLOAD")"
SESSION_ID="$(json_field session_id "$PAYLOAD")"
CLAUDE_MSG="$(json_field message "$PAYLOAD")"

TITLE="$(build_title "$CWD")"
# Always lead with "Claude waiting" so the notification matches the voice line.
# If Claude provided a specific message (e.g. "needs your permission"), append it.
if [ -n "$CLAUDE_MSG" ]; then
  HEADLINE="Claude waiting — $CLAUDE_MSG"
else
  HEADLINE="Claude waiting"
fi
BODY="$(build_body "$HEADLINE" "$SESSION_ID")"

announce waiting "Claude waiting" "$TITLE" "$BODY" "$CWD"
exit 0
