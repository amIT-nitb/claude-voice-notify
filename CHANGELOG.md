# Changelog

All notable changes to `claude-callout` are documented here. Format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The plugin was originally published as **`claude-voice-notify`** and renamed to **`claude-callout`** in v0.5.0 to avoid confusion with Salesforce's internal `claude-notify` plugin. Older tags resolve via GitHub's automatic redirect from the old repo URL.

## [Unreleased]

## [0.5.1] — 2026-06-05

### Fixed
- **Install instructions** in the README pointed at `/plugin install /path/to/...` and `/plugin install https://...` — neither form is valid. `claude plugin install` only accepts `<plugin@marketplace>`. README now shows the actual marketplace flow.
- Stale `Wait 30s` mention in the what-it-does table → `Wait 10s` (the v0.4.0 default that one mention missed).
- Misleading `CLAUDE_VOICE_DEBOUNCE=60` example in the env-knobs block → `=20` with a comment showing the real `10s` default.

### Added
- `LICENSE` file (`plugin.json` already declared MIT but the file was missing).
- `Latest release` and `License: MIT` badges at the top of the README.
- README sub-sections for `update`, `uninstall`, and local development with `--plugin-dir`.

## [0.5.0] — 2026-06-04

### Changed
- **Renamed** plugin `claude-voice-notify` → `claude-callout`. Avoids confusion with Salesforce's internal `claude-notify` plugin.
- Renamed CLI binary `bin/claude-voice-notify` → `bin/claude-callout`.
- Project state dir `.claude-voice-notify/` → `.claude-callout/`.
- User state dir `~/.claude/voice-notify/` → `~/.claude/callout/`.
- GitHub repo renamed `amIT-nitb/claude-voice-notify` → `amIT-nitb/claude-callout`. Old URL 301-redirects.

### Migration
```
/plugin uninstall claude-voice-notify@claude-voice-notify
/plugin marketplace add amIT-nitb/claude-callout
/plugin install claude-callout@claude-callout
```

## [0.4.1] — 2026-06-04

### Added
- **Last assistant text snippet** in `Claude waiting` notifications. Mirrors the tool summary on `Stop` — banner now includes a quoted ≤80-char excerpt of what Claude was about to say, so the user knows the *context* of the request, not just that one is happening.
- New `last_assistant_text()` helper in `scripts/lib/common.sh`. Reads transcript tail, walks back from latest assistant turn until last user message, returns the most-recent text block (whitespace-collapsed, truncated with ellipsis).

## [0.4.0] — 2026-06-04

### Changed
- **Voice now ON by default** (was OFF). New users hear announcements out of the box.
- **Stop debounce default** 30s → 10s. Snappier on short turns; `CLAUDE_VOICE_DEBOUNCE` env var still overrides.

### Added
- **`voice-when-focused` flag.** Default OFF preserves current behavior — voice suppressed when terminal/IDE is foreground app. When ON, voice speaks regardless of focus. Same 4-layer precedence (project > user > env > default).
- New slash commands: `/voice-when-focused-on`, `/voice-when-focused-off` (both support `--global`).
- New CLI subcommands: `claude-callout when-focused-on / when-focused-off`.
- `/voice-status` now shows the third row + Resolution line for the new flag.
- `.claude-voice-notify/` (now `.claude-callout/`) gitignored to keep per-developer state out of the published tree.

## [0.3.1] — 2026-06-03

### Added
- **macOS layered fallback** for persistent banners: `alerter` (recommended for 15+/26+) → `terminal-notifier` (legacy, broken on 15+) → `osascript` (built-in safety net).

### Changed
- Where `terminal-notifier` was the only persistent option, the plugin now prefers `alerter` (signed + notarized for current macOS) when installed.

## [0.3.0] — 2026-06-02

### Added
- **Tool summary** in `Claude ready` Stop banner: `Claude ready — Bash×4, Edit×2 · session abcd1234`. Parsed from `transcript_path`.
- **Idle-ping suppression**: skips Claude Code's redundant `Notification` fired ~60s after every Stop. Per-session register tracks `last_stop_at` + `last_seen`.
- **Time-bound mute**: `/voice-mute 30m` silences both voice + notify for a window. Auto-expires. Project or user scope (`--global`).
- **Persistent + stackable notifications**: macOS uses `terminal-notifier -actions OK -ignoreDnD`, Linux uses `--urgency=critical`, Windows uses `BurntToast -SnoozeAndDismiss`. Each event stacks instead of replacing.
- **Side CLI** `bin/claude-voice-notify` (later renamed `claude-callout`) — drives the plugin from any shell. Subcommands: `status / on / off / notify-on / notify-off / mute / unmute / test / paths`.

### Changed
- Stop debounce default 60s → 30s (later reduced to 10s in v0.4.0).

## [0.2.0]

### Added
- **Per-project scope** for voice + notify settings. `/voice-on` etc. default to current project; `--global` flag opts back into user-wide. Settings resolve as: project > user > env > default.
- `/voice-status` shows effective value plus per-layer breakdown.

## [0.1.0]

### Added
- Initial release of `claude-voice-notify`.
- Hooks for `Notification`, `Stop`, `UserPromptSubmit`, `SessionStart`.
- Cross-platform voice + OS notifications (macOS, Linux, Windows).
- Stop debounce, focus skip, quiet hours.
- Slash commands for `/voice-on`, `/voice-off`, `/notify-on`, `/notify-off`, `/voice-status`, `/voice-test`.

[Unreleased]: https://github.com/amIT-nitb/claude-callout/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/amIT-nitb/claude-callout/releases/tag/v0.5.1
[0.5.0]: https://github.com/amIT-nitb/claude-callout/releases/tag/v0.5.0
[0.4.1]: https://github.com/amIT-nitb/claude-callout/releases/tag/v0.4.1
[0.4.0]: https://github.com/amIT-nitb/claude-callout/releases/tag/v0.4.0
[0.3.1]: https://github.com/amIT-nitb/claude-callout/releases/tag/v0.3.1
