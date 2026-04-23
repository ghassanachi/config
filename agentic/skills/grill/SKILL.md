---
name: grill
description: Adversarial-but-substantive review of the current branch's changes. Familiarizes with the diff, generates a categorized review list in ./tmp/<session_id>/review.md, then works through items one at a time with the user. Loops until both agree the branch is in a good state, then hands off to /hone.
---

# grill

A structured review workflow for branch changes. Acts as a Teleport software engineer reviewing a colleague's work: the bar for raising an item is low, but every item must be actionable (not stylistic bikeshedding).

## Phase 1 — Familiarize

Goal: understand what changed and why before reviewing.

1. Determine scope:
   - Current branch: `git rev-parse --abbrev-ref HEAD`
   - Base branch: prefer `origin/master` if it exists and is ahead of or equal to local `master`; otherwise use `master`. If unsure, inspect `git log --oneline master..HEAD` vs `git log --oneline origin/master..HEAD` and pick the one matching the user's intended diff. Ask if still ambiguous.
   - `git log --oneline <base>..HEAD`
   - `git diff <base>...HEAD --stat`
2. Read the actual diff. For large diffs (>~500 lines or >3 commits), read commit messages first, then the files touched by each commit.
3. **Always** produce a short summary back to the user covering:
   - What the branch is doing (one paragraph)
   - Key files/areas touched
   - What I *think* is out of scope
   - Any ambiguity I spotted
4. Ask the user to confirm or correct. Ask targeted questions when something is unclear (intent, scope boundary, prior context, linked issues/PRs). For very large or unclear changes, use EnterPlanMode to think through the review scope.
5. Do **not** proceed to Phase 2 until the user explicitly confirms the summary.

## Phase 2 — Set up the review file

1. Compute `session_id`: `<YYYY-MM-DD>-<branch-slug>` where branch-slug is the current branch with `/` replaced by `-` and truncated to ~40 chars.
2. Check that `tmp/` is ignored:
   - Grep `.gitignore` for `tmp/` or `/tmp/`.
   - If not present, run `git ls-files tmp/ 2>/dev/null | head -5`. If anything is tracked, **stop and flag to the user** — do not write.
   - Otherwise, append `tmp/` to `.git/info/exclude` (local-only ignore).
3. Create `./tmp/<session_id>/review.md` using the template below.

## Phase 3 — Grill (generate items)

Review the diff as an adversarial-but-substantive Teleport engineer. For each item found, add a checkbox entry under the right category. Cover at minimum:

- **Code patterns** — naming, file/folder structure, consistency with surrounding code, adherence to repo idioms (Go conventions, RFD patterns, proto layout, etc.)
- **Completeness** — does the feature cover the full surface area, not just the happy path? Edge cases, error paths, all entry points (CLI/API/UI), migration/downgrade, audit events, metrics, feature flags, RBAC
- **Documentation** — godoc on exported symbols, RFD updates, CHANGELOG, user-facing docs, inline comments where the *why* is non-obvious
- **Security** — authz checks at every boundary, input validation, secret handling, log redaction, TOCTOU, injection, privilege escalation, tenant isolation
- **Correctness & typos** — bugs, off-by-one, nil deref, race conditions, goroutine leaks, context handling, typos in strings/identifiers/comments
- **Performance** — hot-path allocations, N+1 queries, unbounded goroutines, lock contention, cache invalidation. Flag tradeoffs explicitly; don't demand perf work on cold paths.
- **Other** — tests (coverage, flakiness, real-vs-mock), observability, backwards compatibility, API stability, anything a reviewer on the PR would flag

Each item: short title, **Why:** line, **File:** pointer when applicable. Keep items actionable.

Report to the user how many items landed in each category, then proceed to Phase 4.

## Phase 4 — Work through items

One item at a time, in rough priority order: security → correctness → completeness → patterns → docs → perf → other. Use judgment to deviate when coupling between items suggests a different order.

For each item:
1. Surface the item to the user, propose a fix.
2. Make the change once aligned.
3. Mark the item `- [x]` with a brief note on how it was resolved.
4. Scan the remaining list — if the change incidentally resolved other items, mark them `- [x]` with `— resolved as side effect of <item>`.

Do not batch multiple items into one change without the user's agreement.

## Phase 5 — Pass completion

When every item in the current pass is checked or withdrawn:

1. Tell the user the pass is done and summarize what changed.
2. Explicitly ask: *"Should we do another grill pass, or are we done?"*
3. If another pass: add a `## Pass N+1` section, re-read the diff (including new changes), and return to Phase 3 — but only raise items *not already addressed*.
4. If done: move to Phase 6.

## Phase 6 — Handoff

Before telling the user we're done, write `./tmp/<session_id>/context.md` so a fresh Claude session can pick up where we left off. The file should contain:

- **Branch & base** — branch name, base used (`master` vs `origin/master`), commit range.
- **What the branch does** — the one-paragraph summary from Phase 1, updated for anything that changed during grill.
- **Why it exists** — motivation, linked issues/RFDs/PRs, any constraints surfaced in conversation that aren't in the diff (deadlines, stakeholder asks, things deliberately out of scope).
- **Key files** — the handful of files a reviewer should read first, each with a one-line pointer to what matters in it.
- **Notable decisions from conversation** — anything the user told me that shaped the review and isn't derivable from the code (e.g. "we intentionally skipped X because Y").
- **Review outcome** — a short note on what grill raised and resolved, with a pointer to `review.md` for the full list.
- **Open items** — anything still unresolved or explicitly deferred.

Keep it tight: a fresh session should be able to read this file plus the diff and be productive, nothing more. Do not duplicate what's in the diff or `review.md`.

Then tell the user explicitly:

> Grill review is complete.
> - Review: `./tmp/<session_id>/review.md`
> - Context: `./tmp/<session_id>/context.md`
>
> When you're ready, run `/hone` to continue.

Do not invoke `/hone` automatically.

## review.md template

Use this as a starting point; adapt structure per task if a category is empty or a different grouping fits better.

```
# Grill Review — <branch>

- **Session:** <session_id>
- **Started:** <YYYY-MM-DD>
- **Base:** <base branch used, e.g. origin/master>
- **Commits:** <N> (`git log --oneline <base>..HEAD`)

## Summary

<One-paragraph description of what the branch does, confirmed with the user in Phase 1.>

## Pass 1

### Code patterns
- [ ] **<title>**
  - **Why:** <rationale>
  - **File:** `path/to/file.go:123`

### Completeness
- [ ] ...

### Documentation
- [ ] ...

### Security
- [ ] ...

### Correctness & typos
- [ ] ...

### Performance
- [ ] ...

### Other
- [ ] ...
```

## Item state notation

- `- [ ]` open
- `- [x] <title> — <how it was resolved>` completed
- `- [x] <title> — resolved as side effect of <other item>` completed incidentally
- `- [~] <title> — withdrawn: <reason>` withdrawn after discussion (kept for tracking)

## Notes

- Never mark an item complete unless the change actually lands.
- Re-read the diff between passes; don't rely on memory of the first read.
- The bar for raising an item is low; the bar for keeping it open after discussion is higher.
