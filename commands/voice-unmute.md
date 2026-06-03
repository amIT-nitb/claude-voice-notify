---
description: Cancel an active mute (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Cancel an active time-bound mute. If no mute is active, this is a no-op.

Run:

```bash
ARGS="$ARGUMENTS"
if [ "$ARGS" = "--global" ] || [ "$ARGS" = "-g" ]; then
  DIR="$HOME/.claude/voice-notify"
  SCOPE="user (global)"
else
  DIR="$PWD/.claude-voice-notify"
  SCOPE="project ($PWD)"
fi

if [ -f "$DIR/mute-until" ]; then
  rm -f "$DIR/mute-until"
  printf 'Unmuted — scope: %s\n' "$SCOPE"
else
  printf 'No active mute at %s scope.\n' "$SCOPE"
fi
```

Then confirm to the user in one short line.
