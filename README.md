# claude-callout

[![Latest release](https://img.shields.io/github/v/release/amIT-nitb/claude-callout?label=release)](https://github.com/amIT-nitb/claude-callout/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Claude Code plugin that announces — by voice and OS notification — when Claude is **waiting on you** or has **finished a turn**. Cross-platform (macOS / Linux / Windows), focus-aware, with quiet hours and a debounce to keep noise down.

## What it does

| Event | Trigger | Behavior |
|---|---|---|
| **Claude waiting** | Permission prompt or idle Notification (Claude Code `Notification` hook) | Announce immediately. Suppresses Claude Code's redundant ~60s "still waiting" duplicate fired right after every Stop. |
| **Claude ready** | Turn finishes (Claude Code `Stop` hook) | Wait 10s — announce only if you haven't replied. Notification body includes a **tool summary** (e.g. `Bash×4, Edit×2`) parsed from the transcript. |

Both events fire an OS desktop notification (silent, dismissible) and — if voice is enabled — a short sound cue plus a spoken message.

### Notification content

Notifications include the working folder and a short session ID so you can tell sessions apart at a glance. Voice stays terse on purpose ("Claude ready" / "Claude waiting") — it's not chatty.

The notification body always **leads with the same phrase as the voice line** ("Claude ready" / "Claude waiting") so the visual and audible cues match — extra context is appended after.

| Event | Title | Body | Voice |
|---|---|---|---|
| Stop (no tools used) | `Claude · <folder>` | `Claude ready · session <8-char id>` | "Claude ready" |
| Stop (with tool summary) | `Claude · <folder>` | `Claude ready — Bash×4, Edit×2 · session <8-char id>` | "Claude ready" |
| Notification (with CC message + transcript snippet) | `Claude · <folder>` | `Claude waiting — <message> — "<last 80 chars Claude said>" · session <id>` | "Claude waiting" |
| Notification (CC message only, no transcript) | `Claude · <folder>` | `Claude waiting — <message> · session <8-char id>` | "Claude waiting" |
| Notification (bare) | `Claude · <folder>` | `Claude waiting · session <8-char id>` | "Claude waiting" |

Example:
- Title: `Claude · claude-callout`
- Body: `Claude ready — Bash×3, Edit×1 · session abcd1234`
- Or: `Claude waiting — needs your permission to use Bash — "Let me run the test suite to verify…" · session abcd1234`

`<folder>` is the basename of the session's `cwd`. `<8-char id>` is the first 8 characters of Claude's session ID — enough to disambiguate parallel sessions without filling the notification.

The hook reads Claude Code's standard JSON event payload from stdin (`session_id`, `cwd`, and `message` for `Notification` events). Parsed with `jq` if available, falling back to `python3`, then a `sed` parser — works on a fresh box.

## Install

### From this repo's marketplace

Inside Claude Code:

```
/plugin marketplace add amIT-nitb/claude-callout
/plugin install claude-callout@claude-callout
```

Or from your shell (without launching Claude Code):

```bash
claude plugin marketplace add amIT-nitb/claude-callout
claude plugin install claude-callout@claude-callout
```

Then verify with:

```
/voice-test
```

### Update later

```bash
claude plugin update claude-callout@claude-callout
```

Restart Claude Code (full quit + relaunch) for an active session to pick up the new code — `${CLAUDE_PLUGIN_ROOT}` is resolved at session start, so a running session keeps using the version it was launched with.

### Uninstall

```bash
claude plugin uninstall claude-callout@claude-callout
claude plugin marketplace remove claude-callout
```

### Local development

To test changes to a clone of this repo without going through the marketplace, point Claude Code at the directory directly:

```bash
claude --plugin-dir /path/to/claude-callout
```

### Manual (no plugin system)

Copy `hooks/hooks.json` into your `~/.claude/settings.json` `hooks` section, replacing `${CLAUDE_PLUGIN_ROOT}` with the absolute path to this repo.

## Enable

**Voice and notifications are both ON by default** — out of the box, every finished turn announces. Toggle from inside Claude Code — settings apply to the **current project** by default:

```
/voice-on              # enable voice for THIS project (default: on)
/voice-off             # disable voice for THIS project
/voice-on --global     # enable voice user-wide (all projects)
/voice-off --global    # disable voice user-wide
/notify-on / off       # same idea for OS notifications (with --global)
/voice-when-focused-on        # speak even when terminal/IDE is focused (default: off)
/voice-when-focused-off       # restore default focus-skip
/voice-mute 30m        # silence both voice + notify for 30 minutes (auto-expires)
/voice-mute 2h --global  # mute everywhere for 2 hours
/voice-unmute          # cancel an active mute
/voice-status          # show effective state + mute + per-layer breakdown
/voice-test            # fire a test announcement (sound + voice + notification)
```

Or from any shell (without launching Claude Code):

```bash
${CLAUDE_PLUGIN_ROOT}/bin/claude-callout status
${CLAUDE_PLUGIN_ROOT}/bin/claude-callout mute 1h --global
${CLAUDE_PLUGIN_ROOT}/bin/claude-callout off                       # disable voice in cwd
${CLAUDE_PLUGIN_ROOT}/bin/claude-callout when-focused-on --global  # speak even at keyboard
${CLAUDE_PLUGIN_ROOT}/bin/claude-callout test
```

Symlink it onto your `$PATH` if you want it as a regular command:

```bash
ln -s "${CLAUDE_PLUGIN_ROOT}/bin/claude-callout" ~/.local/bin/claude-callout
```

### Scopes & precedence

Settings resolve in this order (**highest wins**):

| Layer | Where | Set via |
|---|---|---|
| 0. **Mute** (time-bound) | `mute-until` (epoch sec) at project or user scope | `/voice-mute [duration]` (`--global` for user) |
| 1. Project | `<project>/.claude-callout/{voice,notify}-{enabled,disabled}` | `/voice-on`, `/voice-off`, `/notify-on`, `/notify-off` (no flag) |
| 2. User | `~/.claude/callout/{voice,notify}-{enabled,disabled}` | the same commands with `--global` |
| 3. Env var | `CLAUDE_VOICE`, `CLAUDE_NOTIFY` in your shell | `export CLAUDE_VOICE=on` |
| 4. Default | hardcoded | voice **on**, notifications on, voice-when-focused off |

`/voice-status` shows effective value + every layer so you can see *why* it's on or off, including any active mute and remaining time.

Mute auto-expires — files are cleaned up the next time the gating helpers are consulted, so you never need to remember to "turn it back on."

> **Tip:** add `.claude-callout/` to your project's `.gitignore` if you don't want each collaborator to inherit your local toggles.

### Other knobs (env-only)

```bash
export CLAUDE_VOICE_QUIET="22-7"   # silent 10pm–7am (voice only)
export CLAUDE_VOICE_DEBOUNCE=20    # seconds to wait after Stop (default: 10)
```

## Noise-reduction features

- **10s debounce on `Stop`** — if you reply within 10s, the "Claude ready" announcement is cancelled. Only fires when you've genuinely walked away.
- **Idle-ping suppression** — Claude Code fires a redundant "still waiting" Notification ~60s after every Stop. The plugin recognizes that and skips the duplicate, so you don't double-buzz.
- **Time-bound mute** — `/voice-mute 30m` silences everything for a window. Auto-expires. Works at project or user scope.
- **Focus skip** (default on) — on macOS, voice is suppressed when a terminal/editor is the foreground app. Notification still fires silently. Single biggest noise reducer. Disable with `/voice-when-focused-on` if you want voice even at the keyboard.
- **Quiet hours** — `CLAUDE_VOICE_QUIET="22-7"` silences voice between 10pm and 7am. Notifications unaffected.
- **Split flags** — voice (audible) and notifications (silent) toggle independently.
- **Distinct cues** — different system sounds for "ready" vs "waiting".

The `Notification` event for **permission prompts and other non-idle messages** always fires immediately — when Claude needs your input, you should know now.

## Persistent, stackable notifications

The plugin asks the OS for **persistent** (sticky-until-dismissed) and **stackable** (one banner per event, not "the latest replaces the old") notifications. It works out of the box with the OS's built-in tools, and gets better with one optional install.

### macOS — layered fallback (alerter > terminal-notifier > osascript)

The plugin tries each in order and uses the first one available:

| Tool | Behavior | Install |
|---|---|---|
| **`alerter`** *(recommended)* | Persistent alert until clicked, stacks. Signed + notarized for macOS 15+/26+. | Download the signed `.pkg` from [vjeantet/alerter releases](https://github.com/vjeantet/alerter/releases/latest), then `sudo installer -pkg ~/Downloads/alerter-*.pkg -target /` |
| **`terminal-notifier`** *(legacy)* | Persistent on macOS ≤ 14; silently broken on 15+ (last released 2017). | `brew install terminal-notifier` |
| **`osascript`** *(built-in)* | Banner style, auto-dismisses after a few seconds. Always works — no install. | — |

Each event is a separate banner — no `--group` flag means they stack rather than replace.

### Linux

`notify-send --urgency=critical` — sticky on most desktop environments (GNOME, KDE).

### Windows

`BurntToast -SnoozeAndDismiss` — sticky toast with action buttons. Falls back to a 30-second balloon tip if BurntToast isn't installed.

## Per-OS dependencies

| OS | Voice | Notifications |
|---|---|---|
| macOS | `say` (built-in) | [`alerter`](https://github.com/vjeantet/alerter) (recommended for 15+) → `terminal-notifier` → `osascript` (built-in) |
| Linux | `spd-say`, `espeak`, or `festival` (whichever is found) | `notify-send` (`libnotify`) |
| Windows | PowerShell `System.Speech` (built-in) | [BurntToast](https://github.com/Windos/BurntToast) PowerShell module, or balloon-tip fallback |

If a TTS or notification binary isn't available, the corresponding output is silently skipped — the hook never errors out a Claude turn.

## File layout

```
.claude-plugin/plugin.json   # plugin manifest
hooks/hooks.json             # registers Notification, Stop, UserPromptSubmit, SessionStart
bin/
  claude-callout        # side CLI: status / on / off / mute / unmute / test / paths
scripts/
  on-notification.sh         # immediate "Claude waiting" (with idle-ping suppression)
  on-stop.sh                 # 10s-debounced "Claude ready" + tool summary
  on-prompt.sh               # cancels pending Stop, records user_seen
  on-session-start.sh        # clears stale state on new session
  lib/common.sh              # OS detection, gating, dispatch, mute, tool_summary
commands/
  voice-on.md                # /voice-on (project; --global for user)
  voice-off.md               # /voice-off
  notify-on.md               # /notify-on
  notify-off.md              # /notify-off
  voice-when-focused-on.md   # /voice-when-focused-on (default off)
  voice-when-focused-off.md  # /voice-when-focused-off
  voice-mute.md              # /voice-mute [duration]
  voice-unmute.md            # /voice-unmute
  voice-status.md            # /voice-status — layered breakdown
  voice-test.md              # /voice-test — fire test announcements
```

State files live under `~/.claude/callout/` (user scope) and `<project>/.claude-callout/` (project scope, when set).

## How the debounce works

1. `Stop` writes a unique token to `~/.claude/callout/stop-pending` and spawns a detached watcher.
2. Watcher sleeps `CLAUDE_VOICE_DEBOUNCE` seconds (default 10), then checks the token still matches.
3. If the user submitted a prompt, `UserPromptSubmit` deleted the file → watcher does nothing.
4. If a newer `Stop` ran, it overwrote the token → older watcher does nothing.
5. Otherwise, announce — *and record the timestamp in the per-session register* so the next idle ping ~60s later can be detected as redundant.

Tokens are per-event, so overlapping turns can't race into duplicate announcements.

## How idle-ping suppression works

Claude Code fires a `Notification` event ~60s after every `Stop` with text like "Claude Code is waiting for your input". That's a duplicate of the "Claude ready" the Stop hook just played. To skip it:

1. After the Stop watcher announces, it records `last_stop_at = now` in `~/.claude/callout/sessions/<session_id>.json`.
2. `UserPromptSubmit` records `last_seen = now` in the same file.
3. When `Notification` fires with idle-pingy message text, the script reads the register: if `last_stop_at > 0` and `last_seen ≤ last_stop_at`, the user hasn't engaged since the Stop → suppress. Otherwise, fire (it's a real new event).

Permission prompts and other non-idle Notifications fire unconditionally because their message text doesn't match the idle pattern.

## License

MIT.
