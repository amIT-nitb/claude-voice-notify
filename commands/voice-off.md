---
description: Disable voice announcements (notifications still fire if enabled)
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*)
---

Disable voice announcements. Notifications are unaffected — toggle those with `/notify-off`.

Run:

```bash
mkdir -p ~/.claude/voice-notify
rm -f ~/.claude/voice-notify/voice-enabled
touch ~/.claude/voice-notify/voice-disabled
echo "Voice announcements: OFF"
```

Then confirm to the user in one short line.
