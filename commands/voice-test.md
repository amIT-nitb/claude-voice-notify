---
description: Fire a test "Claude ready" + "Claude waiting" so you can verify sound, voice, and notifications
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/test-announce.sh)
---

Run the end-to-end test. Bypasses enable flags, quiet hours, and focus-skip so the announcements always fire regardless of current config.

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/test-announce.sh"
```

You should:
- Hear two chime + spoken-phrase pairs ("Claude ready", then "Claude waiting"), 3s apart
- See two desktop notifications titled `Claude · <folder>` with matching bodies. With **alerter** installed (recommended on macOS 15+/26+) the banners are persistent and stack; with `terminal-notifier` they persist on macOS ≤14; otherwise the built-in `osascript` fallback shows briefly and auto-dismisses.

If voice didn't play, check system audio and TTS install (`say` on macOS, `spd-say`/`espeak` on Linux, PowerShell `System.Speech` on Windows).

If notifications didn't show: on macOS, check System Settings → Notifications for the *sending* app — `alerter` if you've installed it, otherwise the terminal app that the `osascript` fallback impersonates. For persistent banners on macOS, install [alerter](https://github.com/vjeantet/alerter/releases).
