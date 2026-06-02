---
description: Enable voice announcements (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Enable voice announcements. **Project scope by default** — affects only the current project (a `.claude-voice-notify/voice-enabled` sentinel is created at the project root). Pass `--global` to set it user-wide instead (writes to `~/.claude/voice-notify/`).

Project sentinels override user sentinels override env vars.

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
rm -f "$DIR/voice-disabled"
touch "$DIR/voice-enabled"
printf 'Voice announcements: ON — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
