---
description: Show current voice + notification state and config
allowed-tools: Bash(ls:*), Bash(test:*), Bash(echo:*), Bash(printf:*), Bash(date:*)
---

Report the current effective state for voice and notifications.

Run this script to gather state:

```bash
STATE_DIR="$HOME/.claude/voice-notify"

voice="off"
if [ -f "$STATE_DIR/voice-enabled" ]; then
  voice="on (sentinel)"
elif [ -f "$STATE_DIR/voice-disabled" ]; then
  voice="off (sentinel)"
elif [ "${CLAUDE_VOICE:-off}" = "on" ]; then
  voice="on (env)"
fi

notify="on"
if [ -f "$STATE_DIR/notify-enabled" ]; then
  notify="on (sentinel)"
elif [ -f "$STATE_DIR/notify-disabled" ]; then
  notify="off (sentinel)"
elif [ "${CLAUDE_NOTIFY:-on}" = "on" ]; then
  notify="on (env default)"
else
  notify="off (env)"
fi

printf "Voice:         %s\n" "$voice"
printf "Notifications: %s\n" "$notify"
printf "Quiet hours:   %s\n" "${CLAUDE_VOICE_QUIET:-none}"
printf "Stop debounce: %ss\n" "${CLAUDE_VOICE_DEBOUNCE:-60}"
```

Show the output to the user as-is.
