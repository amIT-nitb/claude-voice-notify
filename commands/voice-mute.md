---
description: Time-bound mute for both voice + notifications (default 30m). --global for user scope.
argument-hint: "[duration] [--global]"
allowed-tools: Bash(mkdir:*), Bash(date:*), Bash(printf:*), Bash(test:*), Bash(rm:*)
---

Silence both voice **and** notifications for a set duration. Auto-expires; no need to remember to turn back on.

- Default duration: `30m`
- Accepts: `45s`, `30m`, `2h`, or a bare number (treated as seconds)
- **Project scope by default** — silences only this project. `--global` silences everything.

Run:

```bash
ARGS="$ARGUMENTS"
DURATION="30m"
SCOPE="project"
DIR="$PWD/.claude-callout"

for arg in $ARGS; do
  case "$arg" in
    --global|-g) SCOPE="user (global)"; DIR="$HOME/.claude/callout" ;;
    *)           DURATION="$arg" ;;
  esac
done

# Parse duration into seconds.
case "$DURATION" in
  *s)  N=$((${DURATION%s}))                   ;;
  *m)  N=$((${DURATION%m} * 60))              ;;
  *h)  N=$((${DURATION%h} * 3600))            ;;
  ''|*[!0-9]*)  echo "Invalid duration: $DURATION (try 45s / 30m / 2h)"; exit 1 ;;
  *)   N=$((DURATION))                        ;;  # bare number → seconds
esac

NOW=$(date +%s)
UNTIL=$((NOW + N))

mkdir -p "$DIR"
printf '%s\n' "$UNTIL" > "$DIR/mute-until"

# Human-readable until-time
UNTIL_HR=$(date -r "$UNTIL" '+%H:%M' 2>/dev/null || date -d "@$UNTIL" '+%H:%M' 2>/dev/null || echo "$UNTIL")
printf 'Muted (%s) until %s — scope: %s\n' "$DURATION" "$UNTIL_HR" "$SCOPE"
```

Then confirm to the user in one short line.

To unmute early: run `/voice-unmute` (project) or `/voice-unmute --global` (user).
