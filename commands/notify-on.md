---
description: Enable OS desktop notifications (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Enable OS desktop notifications. **Project scope by default** — only this project gets notifications. Pass `--global` to set it user-wide.

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
rm -f "$DIR/notify-disabled"
touch "$DIR/notify-enabled"
printf 'Notifications: ON — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
