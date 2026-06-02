#!/usr/bin/env bash
# Fires when the user submits a new prompt.
# Cancel any pending "Claude ready" announcement — user is clearly active.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${SCRIPT_DIR}/lib/common.sh"

cat >/dev/null 2>&1 || true

rm -f "$PENDING_FILE" 2>/dev/null || true
exit 0
