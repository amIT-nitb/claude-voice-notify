#!/usr/bin/env bash
# Manual test: fires both "Claude ready" and "Claude waiting" announcements
# end-to-end (sound + voice + OS notification), bypassing the enable flags
# and focus-skip so the user can verify the install regardless of current state.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

# Override the gate functions for this test run only.
voice_enabled() { return 0; }
notify_enabled() { return 0; }
in_quiet_hours() { return 1; }
terminal_focused() { return 1; }

CWD="${PWD}"
SESSION_ID="testsession$(date +%s)"
TITLE="$(build_title "$CWD")"

echo "Firing: Claude ready"
BODY="$(build_body "Claude ready" "$SESSION_ID")"
announce ready "Claude ready" "$TITLE" "$BODY"

# Brief gap so the two cues don't blur together.
sleep 3

echo "Firing: Claude waiting"
BODY="$(build_body "Claude waiting — test message" "$SESSION_ID")"
announce waiting "Claude waiting" "$TITLE" "$BODY"

echo "Done. You should have seen 2 notifications and heard 2 chime+voice pairs."
echo "If voice didn't play: check system audio, and on macOS make sure Terminal has not muted."
echo "If notification didn't show:"
echo "  - macOS: check System Settings > Notifications for the sending app"
echo "    (alerter if installed; otherwise your terminal app that osascript impersonates)."
echo "  - For persistent banners on macOS 15+, install alerter:"
echo "    https://github.com/vjeantet/alerter/releases"
