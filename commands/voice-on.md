---
description: Enable voice announcements (Claude waiting / Claude ready)
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(rm:*)
---

Enable voice announcements by creating the sentinel file.

Run:

```bash
mkdir -p ~/.claude/voice-notify
rm -f ~/.claude/voice-notify/voice-disabled
touch ~/.claude/voice-notify/voice-enabled
echo "Voice announcements: ON"
```

Then confirm to the user in one short line.
