---
description: Disable OS desktop notifications
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*)
---

Disable OS desktop notifications.

Run:

```bash
mkdir -p ~/.claude/voice-notify
rm -f ~/.claude/voice-notify/notify-enabled
touch ~/.claude/voice-notify/notify-disabled
echo "Notifications: OFF"
```

Then confirm to the user in one short line.
