---
description: Announce voice even when terminal/IDE is focused (project scope by default; --global for user scope)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

By default the plugin **suppresses voice** when a terminal or editor is the foreground app — biggest noise reducer when you're actively at the keyboard. This command opts you in to voice **even** when focused, so announcements always speak regardless of which app is foremost.

**Project scope by default.** Pass `--global` for user scope.

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
rm -f "$DIR/voice-when-focused-disabled"
touch "$DIR/voice-when-focused-enabled"
printf 'Voice-when-focused: ON — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
