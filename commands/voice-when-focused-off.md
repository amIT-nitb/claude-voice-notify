---
description: Restore the default focus-skip (voice silent when terminal/IDE is focused)
argument-hint: "[--global]"
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*), Bash(printf:*), Bash(test:*)
---

Disables the voice-when-focused override. Voice goes back to the default behavior: silent when a terminal or editor is the foreground app, audible otherwise.

**Project scope by default.** Pass `--global` for user scope.

Run:

```bash
ARGS="$ARGUMENTS"
if [ "$ARGS" = "--global" ] || [ "$ARGS" = "-g" ]; then
  DIR="$HOME/.claude/callout"
  SCOPE="user (global)"
else
  DIR="$PWD/.claude-callout"
  SCOPE="project ($PWD)"
fi
mkdir -p "$DIR"
rm -f "$DIR/voice-when-focused-enabled"
touch "$DIR/voice-when-focused-disabled"
printf 'Voice-when-focused: OFF (focus-skip restored) — scope: %s\n' "$SCOPE"
```

Then confirm to the user in one short line.
