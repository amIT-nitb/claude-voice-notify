# Publish & Evangelize Reference

Quick reference for installing, testing, and submitting `claude-voice-notify` to the Claude Code community marketplace.

## Install from this repo

In any Claude Code session:

```
/plugin marketplace add amIT-nitb/claude-voice-notify
/plugin install claude-voice-notify@claude-voice-notify
/voice-test
```

If `/voice-test` fires the two announcements, the end-to-end install path works.

> Run this from a **fresh** terminal — not from inside the repo's working directory, where the plugin is already loaded locally.

After install, settings default to **project scope** — `/voice-on` enables voice for the current project only. Use `/voice-on --global` to enable for the whole user (all projects). Run `/voice-status` to see effective state and which scope set it.

## Submit to the official community marketplace

1. Open <https://claude.ai/settings/plugins/submit> (or <https://platform.claude.com/plugins/submit>).
2. Sign in with the Anthropic account you use for Claude Code.
3. Fill the form:
   - **Repository URL** — `https://github.com/amIT-nitb/claude-voice-notify`
   - **Plugin name** — `claude-voice-notify`
   - **Description** — *Voice + OS notifications when Claude is waiting on you or finished a turn. Cross-platform, focus-aware, with quiet hours and 60s debounce to keep noise low.*
   - **Category / keywords** — notifications, accessibility, hooks, tts
4. Submit. Approval is at Anthropic's discretion. Approved plugins land in [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community) pinned to a commit SHA.

## Optional discoverability boosters

| Improvement | Why |
|---|---|
| Demo gif / asciinema in README | Plugin listings with visuals get clicked |
| GitHub topics: `claude-code`, `claude-code-plugin`, `tts`, `notifications` | Repo discoverability via GitHub search (set via `gh repo edit` or the web UI) |
| `CHANGELOG.md` | Users care what changed when you bump versions |
| Tag a `v0.1.0` release | Marketplaces / installers can pin to it; signals "ready" |

## Plugin manifest reference

`.claude-plugin/plugin.json` — declares the plugin itself.
`.claude-plugin/marketplace.json` — declares the repo as a marketplace listing this plugin.

Both are required for `/plugin marketplace add <repo>` to work.

## Useful commands

```bash
# Validate manifest locally (catches schema errors before submitting)
claude plugin validate

# Tag a release
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0

# Add GitHub topics
gh repo edit amIT-nitb/claude-voice-notify --add-topic claude-code --add-topic claude-code-plugin --add-topic tts --add-topic notifications
```
