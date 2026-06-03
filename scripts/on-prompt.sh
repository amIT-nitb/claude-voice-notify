#!/usr/bin/env bash
# Fires when the user submits a new prompt.
# - Cancel any pending "Claude ready" announcement — user is clearly active.
# - Record user_seen so subsequent idle pings on this session aren't suppressed.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

PAYLOAD="$(cat 2>/dev/null || true)"
SESSION_ID="$(json_field session_id "$PAYLOAD")"

rm -f "$PENDING_FILE" 2>/dev/null || true
record_user_seen "$SESSION_ID"
exit 0
