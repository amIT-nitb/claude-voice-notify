---
description: Disable OS desktop notifications (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Disable OS desktop notifications. **Project scope by default** — only this project goes silent. Pass `--global` to silence notifications user-wide.

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
mkdir -p "$DIR"
rm -f "$DIR/notify-enabled"
touch "$DIR/notify-disabled"
printf 'Notifications: OFF — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
