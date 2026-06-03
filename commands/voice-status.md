---
description: Show effective voice + notification state, mute, and per-layer breakdown
allowed-tools: Bash(ls:*), Bash(test:*), Bash(echo:*), Bash(printf:*), Bash(date:*), Bash(cat:*)
---

Report effective voice + notification state, plus per-layer breakdown so you can see *why* a setting is on or off, and any active mute.

Precedence: **mute** > project > user > env var > built-in default.

Run this script:

```bash
USER_DIR="$HOME/.claude/voice-notify"
PROJ_DIR="$PWD/.claude-voice-notify"
NOW=$(date +%s)

# Mute lookup — highest priority
MUTE_SCOPE=""
MUTE_REMAINING=0
for scope_dir in "$PROJ_DIR" "$USER_DIR"; do
  if [ -f "$scope_dir/mute-until" ]; then
    UNTIL=$(cat "$scope_dir/mute-until" 2>/dev/null || echo 0)
    if [ "$UNTIL" -gt "$NOW" ] 2>/dev/null; then
      [ "$scope_dir" = "$PROJ_DIR" ] && MUTE_SCOPE="project" || MUTE_SCOPE="user"
      MUTE_REMAINING=$((UNTIL - NOW))
      break
    fi
  fi
done

resolve() {
  local feature="$1" default="$2"
  local proj_state="-" user_state="-" env_state="unset"
  [ -f "$PROJ_DIR/${feature}-enabled" ]  && proj_state="on"
  [ -f "$PROJ_DIR/${feature}-disabled" ] && proj_state="off"
  [ -f "$USER_DIR/${feature}-enabled" ]  && user_state="on"
  [ -f "$USER_DIR/${feature}-disabled" ] && user_state="off"
  case "$feature" in
    voice)  [ -n "${CLAUDE_VOICE:-}" ]  && env_state="$CLAUDE_VOICE" ;;
    notify) [ -n "${CLAUDE_NOTIFY:-}" ] && env_state="$CLAUDE_NOTIFY" ;;
  esac

  local effective source
  if [ -n "$MUTE_SCOPE" ]; then
    effective="off"; source="muted ($MUTE_SCOPE)"
  elif [ "$proj_state" != "-" ]; then
    effective="$proj_state"; source="project"
  elif [ "$user_state" != "-" ]; then
    effective="$user_state"; source="user"
  elif [ "$env_state" != "unset" ]; then
    effective="$env_state"; source="env"
  else
    effective="$default"; source="default"
  fi
  printf '%s|%s|%s|%s|%s\n' "$effective" "$source" "$proj_state" "$user_state" "$env_state"
}

IFS='|' read -r v_eff v_src v_proj v_user v_env <<< "$(resolve voice off)"
IFS='|' read -r n_eff n_src n_proj n_user n_env <<< "$(resolve notify on)"

printf 'Voice:         %s (%s)\n' "$v_eff" "$v_src"
printf 'Notifications: %s (%s)\n' "$n_eff" "$n_src"
printf 'Quiet hours:   %s\n' "${CLAUDE_VOICE_QUIET:-none}"
printf 'Stop debounce: %ss\n' "${CLAUDE_VOICE_DEBOUNCE:-30}"
if [ -n "$MUTE_SCOPE" ]; then
  M=$((MUTE_REMAINING / 60)); S=$((MUTE_REMAINING % 60))
  printf 'Mute:          %s scope, %dm %ds remaining\n' "$MUTE_SCOPE" "$M" "$S"
fi
echo
echo "Resolution (highest precedence wins):"
printf '  Voice    project=%-3s  user=%-3s  env=%-5s  → %s\n' "$v_proj" "$v_user" "$v_env" "$v_eff"
printf '  Notify   project=%-3s  user=%-3s  env=%-5s  → %s\n' "$n_proj" "$n_user" "$n_env" "$n_eff"
echo
echo "Project state dir: $PROJ_DIR"
echo "User state dir:    $USER_DIR"
```

Show the output to the user as-is.
