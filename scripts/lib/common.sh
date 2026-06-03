#!/usr/bin/env bash
# Shared helpers for claude-voice-notify hooks.
# Sourced by on-*.sh; do not execute directly.

STATE_DIR="${HOME}/.claude/voice-notify"
VOICE_FLAG="${STATE_DIR}/voice-enabled"
NOTIFY_FLAG="${STATE_DIR}/notify-enabled"
PENDING_FILE="${STATE_DIR}/stop-pending"
SESSIONS_DIR="${STATE_DIR}/sessions"

# Project-scope state lives next to the user's code. Hooks pass the
# session cwd in via the JSON payload; the per-project dir is computed
# from that. See voice_enabled / notify_enabled for the precedence.
PROJECT_STATE_SUBDIR=".claude-voice-notify"

mkdir -p "$STATE_DIR" "$SESSIONS_DIR" 2>/dev/null

# Resolve the project state directory for a given cwd. Empty cwd → empty.
# Caller is responsible for checking emptiness — we don't fall back to PWD,
# because a hook firing with no cwd is genuinely "no project context".
project_state_dir() {
  local cwd="$1"
  [ -z "$cwd" ] && return 0
  printf '%s/%s' "$cwd" "$PROJECT_STATE_SUBDIR"
}

# Returns 0 if a time-bound mute is currently active. Mute files contain a
# single line: an epoch-seconds expiry time. Reads project mute first, then
# user mute. Auto-cleans expired files so the state dir doesn't accumulate.
mute_active() {
  local cwd="${1:-}"
  local now
  now=$(date +%s)

  if [ -n "$cwd" ]; then
    local proj_mute="$(project_state_dir "$cwd")/mute-until"
    if [ -f "$proj_mute" ]; then
      local until
      until=$(cat "$proj_mute" 2>/dev/null || echo 0)
      if [ "$until" -gt "$now" ] 2>/dev/null; then return 0; fi
      rm -f "$proj_mute" 2>/dev/null  # expired — clean up
    fi
  fi

  local user_mute="${STATE_DIR}/mute-until"
  if [ -f "$user_mute" ]; then
    local until
    until=$(cat "$user_mute" 2>/dev/null || echo 0)
    if [ "$until" -gt "$now" ] 2>/dev/null; then return 0; fi
    rm -f "$user_mute" 2>/dev/null
  fi

  return 1
}

# Look up the active mute scope/expiry — used by /voice-status.
# Echoes "<scope>|<seconds-remaining>" or "" if no mute active.
mute_info() {
  local cwd="${1:-}"
  local now
  now=$(date +%s)

  if [ -n "$cwd" ]; then
    local proj_mute="$(project_state_dir "$cwd")/mute-until"
    if [ -f "$proj_mute" ]; then
      local until
      until=$(cat "$proj_mute" 2>/dev/null || echo 0)
      if [ "$until" -gt "$now" ] 2>/dev/null; then
        printf 'project|%d' $((until - now)); return 0
      fi
    fi
  fi
  local user_mute="${STATE_DIR}/mute-until"
  if [ -f "$user_mute" ]; then
    local until
    until=$(cat "$user_mute" 2>/dev/null || echo 0)
    if [ "$until" -gt "$now" ] 2>/dev/null; then
      printf 'user|%d' $((until - now)); return 0
    fi
  fi
  return 1
}

# Extract a top-level string field from a JSON blob.
# Usage: json_field <key> <json-string>
# Tries jq, then python3, then a sed fallback (handles simple unescaped values).
json_field() {
  local key="$1"
  local input="$2"
  [ -z "$input" ] && return 0
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    K="$key" printf '%s' "$input" | python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
    v = d.get(os.environ.get("K", ""), "")
    if v is not None:
        print(v)
except Exception:
    pass
' 2>/dev/null
  else
    printf '%s' "$input" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p"
  fi
}

# Build the notification title from a cwd path. "Claude · <folder-basename>".
# Falls back to "Claude" if cwd is empty.
build_title() {
  local cwd="$1"
  if [ -n "$cwd" ]; then
    printf 'Claude · %s' "$(basename "$cwd")"
  else
    printf 'Claude'
  fi
}

# Build a notification body. Format: "<headline> · session <short-id>"
# headline is event-specific; session ID is shortened to 8 chars.
build_body() {
  local headline="$1"
  local session_id="$2"
  if [ -n "$session_id" ]; then
    printf '%s · session %s' "$headline" "$(printf '%s' "$session_id" | cut -c1-8)"
  else
    printf '%s' "$headline"
  fi
}

# Detect OS once: macos | linux | windows | unknown
detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin*) echo "macos" ;;
    Linux*)  echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

# Resolve effective on/off for a feature.
# Precedence (highest first):
#   0. Active time-bound mute — silences both voice + notify until expiry
#   1. Project-scope sentinel (<cwd>/.claude-voice-notify/{voice,notify}-{enabled,disabled})
#   2. User-scope sentinel (~/.claude/voice-notify/...)
#   3. Env var (CLAUDE_VOICE / CLAUDE_NOTIFY)
#   4. Built-in default (voice off, notify on)
#
# voice_enabled and notify_enabled accept an optional cwd; pass "" to
# skip project resolution (e.g. for tooling that has no project context).
voice_enabled() {
  local cwd="${1:-}"
  mute_active "$cwd" && return 1
  local proj
  if [ -n "$cwd" ]; then
    proj="$(project_state_dir "$cwd")"
    [ -f "${proj}/voice-enabled" ] && return 0
    [ -f "${proj}/voice-disabled" ] && return 1
  fi
  [ -f "$VOICE_FLAG" ] && return 0
  [ -f "${STATE_DIR}/voice-disabled" ] && return 1
  [ "${CLAUDE_VOICE:-off}" = "on" ]
}

notify_enabled() {
  local cwd="${1:-}"
  mute_active "$cwd" && return 1
  local proj
  if [ -n "$cwd" ]; then
    proj="$(project_state_dir "$cwd")"
    [ -f "${proj}/notify-enabled" ] && return 0
    [ -f "${proj}/notify-disabled" ] && return 1
  fi
  [ -f "$NOTIFY_FLAG" ] && return 0
  [ -f "${STATE_DIR}/notify-disabled" ] && return 1
  [ "${CLAUDE_NOTIFY:-on}" = "on" ]
}

# Sanitize a session_id into a filesystem-safe slug.
# Only alphanumerics, dashes, underscores. Empty input → empty output.
safe_session_slug() {
  local sid="$1"
  [ -z "$sid" ] && return 0
  printf '%s' "$sid" | tr -cd 'a-zA-Z0-9-_'
}

# Per-session register: tracks last_stop_at + last_seen so we can
# de-duplicate Claude Code's redundant idle-Notification fired ~60s
# after every Stop. JSON for forward-compat.
session_register_path() {
  local sid="$1"
  local slug
  slug="$(safe_session_slug "$sid")"
  [ -z "$slug" ] && return 0
  printf '%s/%s.json' "$SESSIONS_DIR" "$slug"
}

# Record that we just announced a Stop for this session.
record_stop_announce() {
  local sid="$1"
  local path
  path="$(session_register_path "$sid")"
  [ -z "$path" ] && return 0
  local now
  now=$(date +%s)
  printf '{"last_stop_at":%d,"last_seen":%d}\n' "$now" "$now" > "$path" 2>/dev/null
}

# Record that the user just submitted a prompt. Future idle pings on this
# session can fire again because the user has interacted since the last Stop.
record_user_seen() {
  local sid="$1"
  local path
  path="$(session_register_path "$sid")"
  [ -z "$path" ] && return 0
  local now
  now=$(date +%s)
  # Preserve last_stop_at if present; just bump last_seen.
  if [ -f "$path" ]; then
    local existing
    existing=$(cat "$path" 2>/dev/null || echo '{}')
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$existing" | jq -c --arg ts "$now" '.last_seen = ($ts | tonumber)' > "$path.tmp" 2>/dev/null \
        && mv "$path.tmp" "$path" 2>/dev/null
    else
      # Fallback: just rewrite without preserving last_stop_at.
      printf '{"last_stop_at":0,"last_seen":%d}\n' "$now" > "$path" 2>/dev/null
    fi
  else
    printf '{"last_stop_at":0,"last_seen":%d}\n' "$now" > "$path" 2>/dev/null
  fi
}

# Returns 0 if a Notification looks like Claude Code's automatic idle ping
# (fires ~60s after a Stop) AND the user hasn't replied since that Stop.
# In that case the Stop banner already conveys the same info, so we skip.
# Returns 1 if the Notification should fire (permission prompts, real
# message-based notifications, or cases where the user has replied since).
is_redundant_idle_ping() {
  local sid="$1"
  local message="$2"
  [ -z "$sid" ] && return 1

  # Heuristic: if the message text looks idle-pingy.
  local lower
  lower=$(printf '%s' "$message" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *"waiting for your input"*|*"waiting for input"*|*"is idle"*) ;;
    *) return 1 ;;
  esac

  local path
  path="$(session_register_path "$sid")"
  [ -z "$path" ] || [ ! -f "$path" ] && return 1
  local content
  content=$(cat "$path" 2>/dev/null || echo '{}')
  local last_stop last_seen
  last_stop=$(json_field last_stop_at "$content")
  last_seen=$(json_field last_seen "$content")
  [ -z "$last_stop" ] && last_stop=0
  [ -z "$last_seen" ] && last_seen=0
  # Redundant if we recently announced a Stop AND user hasn't been seen since.
  [ "$last_stop" -gt 0 ] 2>/dev/null \
    && [ "$last_seen" -le "$last_stop" ] 2>/dev/null \
    && return 0
  return 1
}

# Read the tail of a Claude transcript file and return a summary of the
# tools the assistant called in the last assistant turn. Format:
# "Bash×4, Edit×2, Read×1" (top 3 by count). Empty if no tools / no file.
tool_summary() {
  local transcript="$1"
  [ -z "$transcript" ] || [ ! -f "$transcript" ] && return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$transcript" <<'PY' 2>/dev/null || return 0
import json, os, sys, collections
path = sys.argv[1]
counts = collections.Counter()
try:
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        f.seek(max(0, size - 200_000))
        tail = f.read().decode("utf-8", errors="replace").splitlines()
except Exception:
    sys.exit(0)
turn = []
for line in reversed(tail):
    if not line.strip():
        continue
    try:
        rec = json.loads(line)
    except Exception:
        continue
    role = rec.get("role") or (rec.get("message", {}) or {}).get("role")
    if role == "user":
        break
    turn.append(rec)
for rec in reversed(turn):
    msg = rec.get("message") or rec
    content = msg.get("content")
    if isinstance(content, list):
        for block in content:
            if block.get("type") == "tool_use":
                counts[block.get("name", "tool")] += 1
if counts:
    top = counts.most_common(3)
    print(", ".join(f"{n}×{c}" for n, c in top))
PY
}

# Quiet hours: CLAUDE_VOICE_QUIET="22-7" means 10pm–7am silent.
# Applies to voice only — notifications stay silent and remain useful.
in_quiet_hours() {
  local range="${CLAUDE_VOICE_QUIET:-}"
  [ -z "$range" ] && return 1
  local start="${range%-*}"
  local end="${range#*-}"
  local now
  now=$(date +%H)
  # Strip leading zero so arithmetic comparison works.
  now=$((10#$now))
  start=$((10#$start))
  end=$((10#$end))
  if [ "$start" -lt "$end" ]; then
    [ "$now" -ge "$start" ] && [ "$now" -lt "$end" ]
  else
    # Wraps midnight, e.g. 22-7
    [ "$now" -ge "$start" ] || [ "$now" -lt "$end" ]
  fi
}

# Returns 0 if a terminal/editor app is currently focused (skip voice).
# macOS only; on other OSes returns 1 (don't skip) — they'd need their own logic.
terminal_focused() {
  local os
  os=$(detect_os)
  [ "$os" != "macos" ] && return 1
  local front
  front=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null)
  case "$front" in
    Terminal|iTerm2|iTerm|Warp|Alacritty|kitty|WezTerm|Hyper|Ghostty) return 0 ;;
    Code|"Visual Studio Code"|Cursor|Xcode|"Sublime Text"|"IntelliJ IDEA"|PyCharm|WebStorm|GoLand) return 0 ;;
    *) return 1 ;;
  esac
}

# Speak a message via the OS-native TTS.
say_text() {
  local msg="$1"
  local os
  os=$(detect_os)
  case "$os" in
    macos) say "$msg" >/dev/null 2>&1 & ;;
    linux)
      if command -v spd-say >/dev/null 2>&1; then
        spd-say -- "$msg" >/dev/null 2>&1 &
      elif command -v espeak >/dev/null 2>&1; then
        espeak -- "$msg" >/dev/null 2>&1 &
      elif command -v festival >/dev/null 2>&1; then
        echo "$msg" | festival --tts >/dev/null 2>&1 &
      fi
      ;;
    windows)
      powershell -NoProfile -Command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$msg')" >/dev/null 2>&1 &
      ;;
  esac
}

# Play a short sound cue: ready | waiting
play_cue() {
  local kind="$1"
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      local snd="/System/Library/Sounds/Tink.aiff"
      [ "$kind" = "waiting" ] && snd="/System/Library/Sounds/Glass.aiff"
      [ -f "$snd" ] && afplay "$snd" >/dev/null 2>&1 &
      ;;
    linux)
      if command -v paplay >/dev/null 2>&1; then
        local snd="/usr/share/sounds/freedesktop/stereo/complete.oga"
        [ "$kind" = "waiting" ] && snd="/usr/share/sounds/freedesktop/stereo/message.oga"
        [ -f "$snd" ] && paplay "$snd" >/dev/null 2>&1 &
      fi
      ;;
    windows)
      local snd="SystemAsterisk"
      [ "$kind" = "waiting" ] && snd="SystemExclamation"
      powershell -NoProfile -Command "[System.Media.SystemSounds]::${snd}.Play()" >/dev/null 2>&1 &
      ;;
  esac
}

# Show an OS notification.
#
# Goal: persist until user dismisses, and stack instead of replacing.
#
# Per-OS strategy (layered fallback so the plugin works out of the box,
# better with optional binaries):
#   macOS  — alerter (preferred, signed + notarized for macOS 15+/26+):
#              persistent alert style, stacks, runs on current macOS.
#            terminal-notifier (older fallback): persistent on macOS ≤14;
#              often silently broken on 15+. Kept for users who already
#              have it installed.
#            osascript display notification (always available, built-in):
#              banner style, auto-dismisses, but works without any extra
#              install.
#            NEVER passes -group / --group, so each call stacks rather
#            than replacing the prior.
#   linux  — notify-send --urgency=critical (sticky on most DEs).
#   windows— BurntToast (sticky toast); balloon-tip fallback (30s).
notify_os() {
  local title="$1"
  local body="$2"
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      if command -v alerter >/dev/null 2>&1; then
        # --actions "OK" + default --timeout 0 → alert persists until clicked.
        # No --group → each notification stacks.
        alerter \
          --title "$title" \
          --message "$body" \
          --actions "OK" \
          --ignore-dnd \
          >/dev/null 2>&1 &
      elif command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier \
          -title "$title" \
          -message "$body" \
          -actions "OK" \
          -ignoreDnD \
          >/dev/null 2>&1 &
      else
        osascript -e "display notification \"${body//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1 &
      fi
      ;;
    linux)
      if command -v notify-send >/dev/null 2>&1; then
        # --urgency=critical makes the popup persistent on most desktop envs.
        # Each call gets a fresh ID so they stack instead of replacing.
        notify-send --urgency=critical "$title" "$body" >/dev/null 2>&1 &
      fi
      ;;
    windows)
      powershell -NoProfile -Command "
        try {
          Import-Module BurntToast -ErrorAction Stop
          New-BurntToastNotification -Text '$title','$body' -SnoozeAndDismiss
        } catch {
          Add-Type -AssemblyName System.Windows.Forms
          \$ni = New-Object System.Windows.Forms.NotifyIcon
          \$ni.Icon = [System.Drawing.SystemIcons]::Information
          \$ni.Visible = \$true
          \$ni.ShowBalloonTip(30000, '$title', '$body', 'Info')
        }
      " >/dev/null 2>&1 &
      ;;
  esac
}

# High-level dispatcher.
# announce <kind> <voice_message> [notify_title] [notify_body] [cwd]
#   kind: ready | waiting
#   voice_message: short phrase spoken aloud (kept terse on purpose)
#   notify_title / notify_body: optional richer content for the OS notification.
#     If unset, falls back to "Claude" / voice_message.
#   cwd: session cwd from the hook payload — used to resolve project-scoped
#     enable flags. Pass "" or omit if no project context.
announce() {
  local kind="$1"
  local voice_message="$2"
  local notify_title="${3:-Claude}"
  local notify_body="${4:-$voice_message}"
  local cwd="${5:-}"

  if notify_enabled "$cwd"; then
    notify_os "$notify_title" "$notify_body"
  fi

  if voice_enabled "$cwd" && ! in_quiet_hours && ! terminal_focused; then
    play_cue "$kind"
    say_text "$voice_message"
  fi
}
