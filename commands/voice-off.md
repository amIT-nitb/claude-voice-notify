---
description: Disable voice announcements (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Disable voice announcements. **Project scope by default** — only this project goes silent. Pass `--global` to silence voice user-wide. Notifications are unaffected (toggle those with `/notify-off`).

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
rm -f "$DIR/voice-enabled"
touch "$DIR/voice-disabled"
printf 'Voice announcements: OFF — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
