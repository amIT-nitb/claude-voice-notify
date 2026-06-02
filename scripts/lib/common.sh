#!/usr/bin/env bash
# Shared helpers for claude-voice-notify hooks.
# Sourced by on-*.sh; do not execute directly.

STATE_DIR="${HOME}/.claude/voice-notify"
VOICE_FLAG="${STATE_DIR}/voice-enabled"
NOTIFY_FLAG="${STATE_DIR}/notify-enabled"
PENDING_FILE="${STATE_DIR}/stop-pending"

# Project-scope state lives next to the user's code. Hooks pass the
# session cwd in via the JSON payload; the per-project dir is computed
# from that. See voice_enabled / notify_enabled for the precedence.
PROJECT_STATE_SUBDIR=".claude-voice-notify"

mkdir -p "$STATE_DIR" 2>/dev/null

# Resolve the project state directory for a given cwd. Empty cwd → empty.
# Caller is responsible for checking emptiness — we don't fall back to PWD,
# because a hook firing with no cwd is genuinely "no project context".
project_state_dir() {
  local cwd="$1"
  [ -z "$cwd" ] && return 0
  printf '%s/%s' "$cwd" "$PROJECT_STATE_SUBDIR"
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
#   1. Project-scope sentinel (<cwd>/.claude-voice-notify/{voice,notify}-{enabled,disabled})
#   2. User-scope sentinel (~/.claude/voice-notify/...)
#   3. Env var (CLAUDE_VOICE / CLAUDE_NOTIFY)
#   4. Built-in default (voice off, notify on)
#
# voice_enabled and notify_enabled accept an optional cwd; pass "" to
# skip project resolution (e.g. for tooling that has no project context).
voice_enabled() {
  local cwd="${1:-}"
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

# Show a silent OS notification.
notify_os() {
  local title="$1"
  local body="$2"
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "$title" -message "$body" >/dev/null 2>&1 &
      else
        osascript -e "display notification \"${body//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1 &
      fi
      ;;
    linux)
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$body" >/dev/null 2>&1 &
      fi
      ;;
    windows)
      powershell -NoProfile -Command "
        try {
          Import-Module BurntToast -ErrorAction Stop
          New-BurntToastNotification -Text '$title','$body'
        } catch {
          Add-Type -AssemblyName System.Windows.Forms
          \$ni = New-Object System.Windows.Forms.NotifyIcon
          \$ni.Icon = [System.Drawing.SystemIcons]::Information
          \$ni.Visible = \$true
          \$ni.ShowBalloonTip(3000, '$title', '$body', 'Info')
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
