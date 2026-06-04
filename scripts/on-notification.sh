#!/usr/bin/env bash
# Fires when Claude needs permission or has been idle ≥60s waiting on the user.
# Announce immediately — this is a real "Claude is blocked" signal.
#
# Exception: Claude Code fires a redundant idle Notification ~60s after
# every Stop, with message text like "Claude Code is waiting for your input".
# The Stop banner already covered that, so we suppress the duplicate when
# the user hasn't replied since the last announced Stop.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# Read the JSON event payload from stdin.
PAYLOAD="$(cat 2>/dev/null || true)"

CWD="$(json_field cwd "$PAYLOAD")"
SESSION_ID="$(json_field session_id "$PAYLOAD")"
CLAUDE_MSG="$(json_field message "$PAYLOAD")"
TRANSCRIPT="$(json_field transcript_path "$PAYLOAD")"

# Skip Claude Code's redundant idle ping that fires ~60s after every Stop.
# Permission prompts and other real Notifications still fire because their
# message text doesn't match the idle pattern.
if is_redundant_idle_ping "$SESSION_ID" "$CLAUDE_MSG"; then
  exit 0
fi

TITLE="$(build_title "$CWD")"
# Always lead with "Claude waiting" so the notification matches the voice line.
# If Claude provided a specific message (e.g. "needs your permission"), append it.
if [ -n "$CLAUDE_MSG" ]; then
  HEADLINE="Claude waiting — $CLAUDE_MSG"
else
  HEADLINE="Claude waiting"
fi
# Append a short snippet of what Claude just said (last text in the latest
# assistant turn) so the user knows the *context* of the request, not just
# the generic "needs your permission". Empty if no transcript / no text.
SNIPPET="$(last_assistant_text "$TRANSCRIPT")"
[ -n "$SNIPPET" ] && HEADLINE="$HEADLINE — \"$SNIPPET\""
BODY="$(build_body "$HEADLINE" "$SESSION_ID")"

announce waiting "Claude waiting" "$TITLE" "$BODY" "$CWD"
exit 0
