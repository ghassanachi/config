---
description: Draft and create a git commit for the staged (or current) changes, following my commit conventions
---
Create a git commit for the current changes. Extra instructions: $@

1. Run `git status`, `git diff --staged` and `git log --oneline -10` to see what is being committed and the repo's message style. If nothing is staged, show me the unstaged changes and ask what to stage; do not `git add -A` blindly.
2. Draft the message:
   - Title follows semantic commit conventions (`feat(scope): ...`, `fix: ...`, `chore: ...`), imperative mood, wrapped to 72 columns or less.
   - Body wrapped at ~72 columns. Explain *why* the change is made and any non-obvious trade-offs in the design or implementation, not a restatement of the diff.
   - Types and short snippets in backticks; full lines or multi-line code as indented code blocks.
3. Show me the drafted message and wait for my approval before running `git commit`.
4. Never commit on `master`/`main` without asking; never push.
