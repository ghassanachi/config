# Pi

Config for [Pi](https://pi.dev) (`@earendil-works/pi-coding-agent`),
with all inference routed through Teleport Beams. `install.sh` links
these into `~/.pi/agent/`.

## Setup

    npm install -g @earendil-works/pi-coding-agent
    ./install.sh

## Daily use

    export BEAMS_TENANT=<tenant>.beams.sh   # or rely on the active tsh profile
    beams-proxy            # start both proxies in the background
    pi                     # in any repo
    beams-proxy stop       # when finished

`beams-proxy status` / `beams-proxy logs <openai|anthropic>` help when a
request hangs. Logs and pidfiles live in `~/.local/state/beams-proxy/`.

## What's here, and the Claude Code equivalent

| File | Purpose | Claude Code analogue |
| --- | --- | --- |
| `models.json` | `beams-*` providers on the local proxy ports (18443 OpenAI, 18444 Anthropic) | n/a |
| `settings.json` | Default model (`beams-anthropic/claude-opus-5-5`, high thinking); shares `~/.claude/skills` | `claude/settings.json` |
| `../claude/CLAUDE.md` | Linked as `~/.pi/agent/AGENTS.md` — one source of personal instructions | `~/.claude/CLAUDE.md` |
| `APPEND_SYSTEM.md` | Maps the Claude-only parts of CLAUDE.md onto Pi | n/a |
| `extensions/subagent/` | `subagent` tool, vendored from Pi's examples | Agent tool |
| `agents/` | `scout`, `planner`, `reviewer`, `worker` | Explore, Plan, review, general-purpose |
| `prompts/` | `/implement`, `/scout-and-plan`, `/implement-and-review`, `/commit` | slash commands |

Skills (`grill`, `hone`) come from `agentic/skills` via `~/.claude/skills`
and run as `/skill:grill`, `/skill:hone`.

## Gotchas

- **No permission prompts.** Pi runs every tool call directly; the proxy
  is not a sandbox. `APPEND_SYSTEM.md` asks the model to confirm
  destructive actions, but nothing enforces it.
- **Anthropic thinking.** The Beams endpoint only accepts adaptive
  thinking for the Claude 5 models, and Pi only sends that for model IDs
  it recognises, so `models.json` sets `compat.forceAdaptiveThinking`.
  Without it, any thinking level other than `off` fails with
  `"thinking.type.enabled" is not supported for this model`.
- **`settings.json` is live.** Pi writes `/model` and `/settings` changes
  through the symlink into this repo; review before committing.
- **Model availability is per tenant.** Check with
  `tctl get app_servers` (`spec.app.spec.inference.models`) and update
  `models.json` to match.
