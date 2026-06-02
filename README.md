# claude-voice-notify

A Claude Code plugin that announces — by voice and OS notification — when Claude is **waiting on you** or has **finished a turn**. Cross-platform (macOS / Linux / Windows), focus-aware, with quiet hours and a debounce to keep noise down.

## What it does

| Event | Trigger | Behavior |
|---|---|---|
| **Claude waiting** | Permission prompt or 60s idle waiting on the user (Claude Code `Notification` hook) | Announce immediately |
| **Claude ready** | Turn finishes (Claude Code `Stop` hook) | Wait 60s — announce only if you haven't replied |

Both events fire an OS desktop notification (silent, dismissible) and — if voice is enabled — a short sound cue plus a spoken message.

### Notification content

Notifications include the working folder and a short session ID so you can tell sessions apart at a glance. Voice stays terse on purpose ("Claude ready" / "Claude waiting") — it's not chatty.

The notification body always **leads with the same phrase as the voice line** ("Claude ready" / "Claude waiting") so the visual and audible cues match — extra context is appended after.

| Event | Title | Body | Voice |
|---|---|---|---|
| Stop | `Claude · <folder>` | `Claude ready · session <8-char id>` | "Claude ready" |
| Notification (Claude provided a message) | `Claude · <folder>` | `Claude waiting — <message> · session <8-char id>` | "Claude waiting" |
| Notification (no message) | `Claude · <folder>` | `Claude waiting · session <8-char id>` | "Claude waiting" |

Example:
- Title: `Claude · CentroQueries`
- Body: `Claude waiting — Claude needs your permission to use Bash · session abcd1234`

`<folder>` is the basename of the session's `cwd`. `<8-char id>` is the first 8 characters of Claude's session ID — enough to disambiguate parallel sessions without filling the notification.

The hook reads Claude Code's standard JSON event payload from stdin (`session_id`, `cwd`, and `message` for `Notification` events). Parsed with `jq` if available, falling back to `python3`, then a `sed` parser — works on a fresh box.

## Install

### As a local plugin

```bash
# Inside Claude Code
/plugin install /path/to/claude-voice-notify
```

Or from a git remote once published:

```bash
/plugin install https://github.com/<you>/claude-voice-notify
```

### Manual (no plugin system)

Copy `hooks/hooks.json` into your `~/.claude/settings.json` `hooks` section, replacing `${CLAUDE_PLUGIN_ROOT}` with the absolute path to this repo.

## Enable

Voice is **off by default**, notifications are **on by default**. Toggle from inside Claude Code:

```
/voice-on        # enable voice announcements
/voice-off       # disable voice (notifications still fire)
/notify-on       # enable OS notifications
/notify-off      # disable OS notifications
/voice-status    # show current state
/voice-test      # fire a test announcement (sound + voice + notification)
```

Or via env vars in your shell rc (slash-command sentinel files override env vars):

```bash
export CLAUDE_VOICE=on            # default: off
export CLAUDE_NOTIFY=on            # default: on
export CLAUDE_VOICE_QUIET="22-7"   # silent 10pm–7am (voice only)
export CLAUDE_VOICE_DEBOUNCE=60    # seconds to wait after Stop
```

## Noise-reduction features

- **60s debounce on `Stop`** — if you reply within 60s, the "Claude ready" announcement is cancelled. Only fires when you've genuinely walked away.
- **Focus skip** — on macOS, voice is suppressed when a terminal/editor is the foreground app. Notification still fires silently. Single biggest noise reducer.
- **Quiet hours** — `CLAUDE_VOICE_QUIET="22-7"` silences voice between 10pm and 7am. Notifications unaffected.
- **Split flags** — voice (audible) and notifications (silent) toggle independently.
- **Distinct cues** — different system sounds for "ready" vs "waiting".

The `Notification` event always fires immediately (no debounce) — when Claude needs permission, you should know now.

## Per-OS dependencies

| OS | Voice | Notifications |
|---|---|---|
| macOS | `say` (built-in) | `osascript` (built-in), or `terminal-notifier` if installed |
| Linux | `spd-say`, `espeak`, or `festival` (whichever is found) | `notify-send` (`libnotify`) |
| Windows | PowerShell `System.Speech` (built-in) | [BurntToast](https://github.com/Windos/BurntToast) PowerShell module, or balloon-tip fallback |

If a TTS or notification binary isn't available, the corresponding output is silently skipped — the hook never errors out a Claude turn.

## File layout

```
.claude-plugin/plugin.json   # plugin manifest
hooks/hooks.json             # registers Notification, Stop, UserPromptSubmit, SessionStart
scripts/
  on-notification.sh         # immediate "Claude waiting"
  on-stop.sh                 # 60s-debounced "Claude ready"
  on-prompt.sh               # cancels pending Stop announcement on user reply
  on-session-start.sh        # clears stale state on new session
  lib/common.sh              # OS detection, flag/quiet-hours/focus checks, dispatch
commands/
  voice-on.md voice-off.md
  notify-on.md notify-off.md
  voice-status.md
```

State files live under `~/.claude/voice-notify/`.

## How the debounce works

1. `Stop` writes a unique token to `~/.claude/voice-notify/stop-pending` and spawns a detached watcher.
2. Watcher sleeps `CLAUDE_VOICE_DEBOUNCE` seconds (default 60), then checks the token still matches.
3. If the user submitted a prompt, `UserPromptSubmit` deleted the file → watcher does nothing.
4. If a newer `Stop` ran, it overwrote the token → older watcher does nothing.
5. Otherwise, announce.

Tokens are per-event, so overlapping turns can't race into duplicate announcements.

## License

MIT.
