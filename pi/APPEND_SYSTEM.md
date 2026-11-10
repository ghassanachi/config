# Notes for Pi

The global AGENTS.md is shared with Claude Code. Where it refers to
Claude-specific machinery, apply it to Pi as follows:

- There is no LSP tool and no sandbox. Ignore the "LSP navigation" and
  "Claude Code sandbox insights" sections; navigate with grep/find/read.
- Commands run directly on the user's machine without a permission
  prompt, so confirm before anything destructive or outward-facing
  (pushing, deleting branches, posting to GitHub, `rm -rf`).
- "Skills" are available as listed in the system prompt and as
  `/skill:<name>` commands (e.g. `/skill:grill`, `/skill:hone`). A skill
  that says "run `/hone`" means `/skill:hone`.
- For broad codebase searches or independent parallel work, delegate to
  the `subagent` tool (agents: `scout`, `planner`, `reviewer`, `worker`)
  instead of reading many files into this context.
- There is no `commit-writer` skill; the `/commit` prompt template covers
  the same conventions.
