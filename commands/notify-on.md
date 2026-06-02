---
description: Enable OS desktop notifications
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*)
---

Enable OS desktop notifications.

Run:

```bash
mkdir -p ~/.claude/voice-notify
rm -f ~/.claude/voice-notify/notify-disabled
touch ~/.claude/voice-notify/notify-enabled
echo "Notifications: ON"
```

Then confirm to the user in one short line.
