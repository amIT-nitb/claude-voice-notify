---
description: Show current voice + notification state (project + user + env, with effective value)
allowed-tools: Bash(ls:*), Bash(test:*), Bash(echo:*), Bash(printf:*), Bash(date:*)
---

Report effective voice + notification state, plus a per-layer breakdown so you can see *why* a setting is on or off.

Precedence: project > user > env var > built-in default.

Run this script:

```bash
USER_DIR="$HOME/.claude/voice-notify"
PROJ_DIR="$PWD/.claude-voice-notify"

# Layer-1 (project), Layer-2 (user), Layer-3 (env), Layer-4 (default)
resolve() {
  local feature="$1" default="$2"
  local proj_state="-" user_state="-" env_state="unset"
  if [ -f "$PROJ_DIR/${feature}-enabled" ]; then proj_state="on"
  elif [ -f "$PROJ_DIR/${feature}-disabled" ]; then proj_state="off"
  fi
  if [ -f "$USER_DIR/${feature}-enabled" ]; then user_state="on"
  elif [ -f "$USER_DIR/${feature}-disabled" ]; then user_state="off"
  fi

  local env_var
  case "$feature" in
    voice)  env_var="${CLAUDE_VOICE:-}" ;;
    notify) env_var="${CLAUDE_NOTIFY:-}" ;;
  esac
  [ -n "$env_var" ] && env_state="$env_var"

  local effective source
  if [ "$proj_state" != "-" ]; then
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
printf 'Stop debounce: %ss\n' "${CLAUDE_VOICE_DEBOUNCE:-60}"
echo
echo "Resolution (highest precedence wins):"
printf '  Voice    project=%-3s  user=%-3s  env=%-5s  → %s\n' "$v_proj" "$v_user" "$v_env" "$v_eff"
printf '  Notify   project=%-3s  user=%-3s  env=%-5s  → %s\n' "$n_proj" "$n_user" "$n_env" "$n_eff"
echo
echo "Project state dir: $PROJ_DIR"
echo "User state dir:    $USER_DIR"
```

Show the output to the user as-is.
