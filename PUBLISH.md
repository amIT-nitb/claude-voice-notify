# Publish & Evangelize Reference

A walkthrough for getting `claude-voice-notify` from "pushed to GitHub" to "installable, discoverable, and used by other Claude Code engineers."

Every URL below is current and verified — none are speculative.

---

## Stage 0 — Self-test the install path

In a **fresh** terminal (not from inside this repo's working dir):

```bash
claude
```

Then inside Claude Code:

```
/plugin marketplace add amIT-nitb/claude-voice-notify
/plugin install claude-voice-notify@claude-voice-notify
/voice-test
```

Or non-interactively from your shell:

```bash
claude plugin marketplace add amIT-nitb/claude-voice-notify
claude plugin install claude-voice-notify@claude-voice-notify --scope user
```

If `/voice-test` fires the two announcements, the end-to-end install path works. **Don't move past stage 0 until this passes.**

After install, settings default to **project scope** — `/voice-on` enables voice for the current project only. Use `/voice-on --global` to enable for the whole user. Run `/voice-status` to see effective state and which scope set it.

---

## Stage 1 — Manifest hygiene + validation

Before submitting anywhere:

```bash
claude plugin validate /path/to/claude-voice-notify
```

This runs the same checks Anthropic's review pipeline runs. Treat all warnings as blockers.

Manifest checklist (`.claude-plugin/plugin.json`):

- [x] `name` (kebab-case, matches the directory name)
- [x] `version` (semver — bump on each release)
- [x] `description` (one clear sentence)
- [x] `author` with `name` (and `url` to your GitHub profile for disambiguation)
- [x] `homepage`, `repository` (full URLs)
- [x] `license` (e.g. `MIT`)
- [x] `keywords` (used in marketplace search)

Marketplace manifest (`.claude-plugin/marketplace.json`):

- [x] `name`, `description`, `owner.name`
- [x] `plugins[].source: "./"` for a single-plugin self-hosted repo (NOT a `{source: github, ...}` object — that form is for marketplaces that aggregate plugins from *other* repos)

---

## Stage 2 — GitHub repo hygiene (discoverability)

### Add the right topics

The convention the community has converged on:

```bash
gh repo edit amIT-nitb/claude-voice-notify \
  --add-topic claude-code \
  --add-topic claude-code-plugin \
  --add-topic claude-code-hooks \
  --add-topic tts \
  --add-topic notifications
```

These topics power:
- <https://github.com/topics/claude-code-plugin> — narrow, intentional plugin index (~2.8k repos)
- <https://github.com/topics/claude-code> — broader CC-related index (~33k repos)

GitHub's full-text search heavily weights topic membership.

### Tag a versioned release

```bash
git tag -a v0.2.0 -m "v0.2.0 — per-project scope for voice + notify settings"
git push origin v0.2.0
gh release create v0.2.0 --generate-notes
```

A versioned release lets installers pin to a stable SHA, gives you a CHANGELOG view, and signals "this is supported, not WIP."

### README polish

The README is the single biggest leverage point for both human discovery and Anthropic's review pipeline. Minimum bar:

- One-line value proposition above the fold
- `## Install` block — exact slash commands users will paste
- `## Usage` block — what each command does, with example output
- `## Demo` — a gif or asciinema cast showing the announcements firing. Plugin listings with visuals get clicked.

---

## Stage 3 — Submit to the official community marketplace

This is the highest-leverage move: getting your plugin into `claude-community`, which every Claude Code installation can add with one command.

### How submission actually works (verified in [docs](https://code.claude.com/docs/en/plugins#submit-your-plugin-to-the-community-marketplace))

It's an **in-app form**, not a PR. There is no `CONTRIBUTING.md` in `anthropics/claude-plugins-community` — the repo is a *read-only mirror* of approved submissions.

Use one of:

- <https://claude.ai/settings/plugins/submit>
- <https://platform.claude.com/plugins/submit>
- Or the short link <https://clau.de/plugin-directory-submission> (redirects to the docs anchor)

Sign in with the Anthropic account tied to your Claude Code install.

### What to submit

- **Repository URL** — `https://github.com/amIT-nitb/claude-voice-notify`
- **Plugin name** — `claude-voice-notify`
- **Description** — pull the plugin.json description verbatim
- **Category / keywords** — notifications, accessibility, hooks, tts

### What happens after

1. Anthropic runs `claude plugin validate` + automated safety screening on your repo.
2. A reviewer approves (timeline isn't publicly documented).
3. Your plugin is **pinned to a specific commit SHA** in the [community catalog](https://github.com/anthropics/claude-plugins-community/blob/main/.claude-plugin/marketplace.json).
4. CI bumps the pin automatically as you push new commits.
5. The public catalog syncs **nightly**, so there's a lag between approval and being installable as `@claude-community`.

To check whether your plugin has landed: search for `claude-voice-notify` in [marketplace.json](https://github.com/anthropics/claude-plugins-community/blob/main/.claude-plugin/marketplace.json).

Once it's there, anyone in the world can install with:

```
/plugin marketplace add anthropics/claude-plugins-community
/plugin install claude-voice-notify@claude-community
```

### What submission does NOT do

It does **not** add your plugin to `claude-plugins-official` — that's a separate, Anthropic-curated marketplace, no application process, inclusion at Anthropic's sole discretion.

---

## Stage 4 — Community-curated awesome lists

These are author-submitted lists with high SEO weight. PRs are the standard submission flow.

| List | Stars | What it tracks | URL |
|---|---|---|---|
| `awesome-claude-code` | 45k+ | Skills, hooks, slash-commands, plugins (all) | <https://github.com/hesreallyhim/awesome-claude-code> |
| `awesome-claude-code-subagents` | 21k+ | Subagent definitions — N/A for this plugin | <https://github.com/VoltAgent/awesome-claude-code-subagents> |
| `awesome-claude-skills` | 13k+ | Skill-shaped extensions | <https://github.com/travisvn/awesome-claude-skills> |

> Heads-up: as of 2026-06, `awesome-claude-code` is mid-reorganization (table of contents marked TODO). Open a PR anyway — when the new TOC ships, your entry will be migrated.

PR template for submission:

```markdown
- [claude-voice-notify](https://github.com/amIT-nitb/claude-voice-notify) —
  Voice + OS notifications when Claude is waiting on you or finished a turn.
  Cross-platform, focus-aware, with quiet hours and 60s debounce. Pure Bash hooks.
```

---

## Stage 5 — Direct evangelism

What I could verify:

- ❌ **No official Anthropic Discord / Discourse / Slack** with a documented "Show & Tell" channel for community plugins. The docs at [code.claude.com](https://code.claude.com) and Anthropic's release notes don't reference one.
- ❌ **No official "featured plugins" curated list** beyond the official marketplace itself.
- ❌ **No newsletter / blog** that systematically highlights community plugin releases.

What works in practice:

- **Show HN / Hacker News** — "Show HN" posts for self-contained dev-tooling do well; the audience overlaps heavily with Claude Code users.
- **r/ClaudeAI on Reddit** — community subreddit, plugin showcases land regularly.
- **Twitter/X** — tag `@AnthropicAI` and `#ClaudeCode`, especially when you have a demo gif.
- **dev.to / Hashnode** — write a "Why I built this" post; these rank well in Google for tool-discovery searches.
- **Internal Slack channels** — your team / org's tooling channel is the most direct path to first users.

---

## Useful commands cheatsheet

```bash
# Validate manifests (run before submission)
claude plugin validate /path/to/claude-voice-notify

# Tag a release
git tag -a v0.2.0 -m "v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --generate-notes

# Add GitHub topics
gh repo edit amIT-nitb/claude-voice-notify \
  --add-topic claude-code \
  --add-topic claude-code-plugin \
  --add-topic claude-code-hooks \
  --add-topic tts \
  --add-topic notifications

# Test install path locally (mimics what users will do)
claude plugin marketplace add amIT-nitb/claude-voice-notify
claude plugin install claude-voice-notify@claude-voice-notify --scope user
claude plugin list | grep claude-voice-notify

# Check whether you've landed in the community catalog
curl -sL https://raw.githubusercontent.com/anthropics/claude-plugins-community/main/.claude-plugin/marketplace.json \
  | grep -A2 claude-voice-notify || echo "Not yet listed"
```

---

## Plugin manifest reference (quick recap)

`.claude-plugin/plugin.json` — declares the plugin itself.
`.claude-plugin/marketplace.json` — declares the repo as a marketplace listing this plugin.

Both are required for `/plugin marketplace add <repo>` to work.

For full schema details: <https://code.claude.com/docs/en/plugins-reference#plugin-manifest-schema>
