---
name: hone
description: Finalize a branch for PR submission after /grill. Loads the grill context, drafts ./tmp/<session_id>/PR.md matching Teleport's PR template exactly (CI-validated structure), iterates with the user on the description, then walks through manual test cases one at a time. Ends by handing over a ready-to-submit PR body and the gh command — does not open the PR.
---

# hone

Sharpens a branch into a submittable PR after `/grill` has scrubbed it. Follows Teleport's PR template exactly so CI checks (`changelog.yaml`, `manual-test-plan.yaml`) pass.

## Phase 1 — Load context

1. Identify the session:
   - If the current conversation already has an active `session_id` from grill, use it.
   - Otherwise, list `./tmp/` and pick the most recent `<YYYY-MM-DD>-<branch-slug>` dir whose slug matches the current branch. If ambiguous or missing, ask the user.
2. Always read `./tmp/<session_id>/context.md` and `./tmp/<session_id>/review.md`. Skim if the content is already in conversation memory; read in full otherwise.
3. If `context.md` is missing (e.g. user skipped grill), ask whether to proceed without it or to build one first — a missing context file is a red flag that the branch hasn't been through grill yet.
4. Confirm the current git state:
   - Branch: `git rev-parse --abbrev-ref HEAD`
   - Base: same logic as grill (`origin/master` preferred, else `master`; ask if unclear)
   - Commit range: `git log --oneline <base>..HEAD`
   - Any uncommitted changes: `git status --short` — flag to the user if the tree is dirty.

## Phase 2 — Draft PR.md scaffolding

The PR body must match `.github/PULL_REQUEST_TEMPLATE.md` exactly because two required CI jobs validate it:

- **`changelog.yaml`** requires a line `Changelog: <text>` in the PR body, OR a `no-changelog` label on the PR.
- **`manual-test-plan.yaml`** runs a validator bot on non-docs PRs that expects `## Manual Test Plan` → `### Test Environment` → `### Test Cases` with checkbox items.

Before writing: ask the user whether this PR warrants a changelog entry. Suggest based on the diff:
- User-visible feature, bugfix, behavior change, security fix → changelog entry.
- Internal refactor, test-only, build-only, docs-only → likely `no-changelog` label.
State your recommendation and let the user decide.

Create `./tmp/<session_id>/PR.md` in this shape:

```
# <Human-readable PR title — clearer than the commit subject>

<Summary paragraph — what and why, for a reviewer who hasn't seen the branch.>

## What changed
- <bullet>
- <bullet>

## Why
<Macro-level motivation: the broader problem this PR addresses and how
it relates to the linked issue/RFD. Not a recap of "what changed" — a
reviewer should come away understanding why this work matters at the
project/product level, not just the mechanics of the diff.>

<Issue reference — chosen with the user in Phase 3. Use one of:
  Closes #<issue>      — this PR fully resolves the issue
  Fixes #<issue>       — same as Closes; pick whichever the user prefers
  Relates to #<issue>  — partial progress, or context-only link
Omit entirely if no issue applies.>

Depends on #<pr>
<!-- Omit unless this PR cannot land before another. Less important within a stack where ordering is implicit. -->

Changelog: <one-line user-facing description>
<!-- If no-changelog: omit this line and note the label under Submission notes below. -->

## Manual Test Plan
### Test Environment

### Test Cases
- [ ] <placeholder — filled in Phase 4>

---

## Submission notes
<!-- Not part of the PR body. Kept here for handoff convenience. -->

- **Target base:** <e.g. master>
- **Labels:** <e.g. no-changelog, if applicable>
- **gh command:**
  ```
  gh pr create --base <base> --title "<title>" --body-file ./tmp/<session_id>/PR.md
  ```
  (Strip everything from the `---` separator down before submitting, or split the body.)
```

Everything above the `---` separator is the PR body that will be submitted; everything below is local-only handoff metadata.

## Phase 3 — Iterate on high-level PR info

Work through these with the user, one at a time, with explicit checkpoints:

1. **Title** — propose a human-readable title (not just the commit subject). Confirm.
2. **Linked issue** — always include a GitHub issue reference when one applies. Check `context.md`, the branch name, and recent commit messages for a candidate issue. If none is obvious but the work plausibly maps to one, ask the user before omitting it. Do **not** assume `Closes` — whether a PR closes the issue vs. only relates to it is the user's call. Propose a reference and ask which form to use:
   - `Closes #N` / `Fixes #N` — fully resolves the issue
   - `Relates to #N` — partial progress or context-only link
   Default to asking rather than guessing; closing an issue prematurely is harder to undo than adding `Closes` later.
3. **Dependencies** — if this PR can't land before another (API/schema change in another PR, shared refactor, etc.), add a `Depends on #<pr>` line. Less important inside a stack where ordering is implicit, but still call it out if a reviewer would otherwise be confused.
4. **Summary / What changed / Why** — draft from context.md + the diff. User edits. Iterate until they sign off.
   - The **Why** section must be macro-level: explain the underlying problem and how this PR relates to the linked issue, not a re-statement of the diff. If you find yourself paraphrasing "What changed", push higher — what is the user/product/system-level reason this work is happening?
5. **Changelog line** (or `no-changelog` decision) — confirm the exact wording; it's user-facing release-notes copy.

Do not proceed to Phase 4 until the user says the high-level section is good.

## Phase 4 — Outline the test plan

Before running anything, agree on *what* will be tested.

1. **Test Environment** — ask the user what environments will be used. Typical answers: local `make` build, Teleport Cloud tenant, a specific dev cluster, kind/minikube, specific OS targets, specific Teleport version for upgrade scenarios. Record versions/hostnames where relevant.
2. **Test Cases** — propose a list of cases covering:
   - Happy path for the main change
   - Edge cases surfaced during grill
   - Regression checks on areas the diff could affect
   - Upgrade/downgrade or migration paths if schema/proto/config changed
   - RBAC / multi-role behavior if authz was touched
   - Failure modes (what should break, and how)

   Draft the list, then iterate with the user. Keep each case as one checkbox `- [ ]` with a short, testable statement. Update `PR.md` with the agreed list.

Do not proceed to Phase 5 until the test list is confirmed.

## Phase 5 — Work through test cases

One case at a time, in the order agreed. For each:

1. Describe the test: what we're verifying and expected outcome.
2. Provide what's needed to run it:
   - **Run myself** (read-only, local): greps, reading configs, checking files, `go build` dry checks, anything non-destructive I can do without touching shared state.
   - **Hand to user**: anything interactive, destructive, touching a remote/shared cluster, requiring sudo, or requiring a browser/TUI session. Provide copy-pasteable commands and what to look for.
3. User reports outcome: shares output, says "passed", or reports a failure.
4. If passed: mark `- [x]` with a brief note on what confirmed it (e.g. the command run, the observed output).
5. If failed: do not mark complete. Investigate the failure with the user — it may surface a new grill-style item. Options:
   - Fix in-place and retry (mark when it passes).
   - Add a new item to `review.md` and loop back through the grill flow if the fix is non-trivial.
   - Withdraw the test case with `- [~]` and a justification if it turns out to be invalid.
6. After each case, re-confirm the next case is still the right one to run — ordering can change based on what we just learned.

Keep going until every test case is resolved (passed or withdrawn).

## Phase 6 — Wrap up

1. Show the user the final PR body (everything in `PR.md` above the `---` separator).
2. Show the submission notes section separately: base branch, labels to apply, the `gh pr create` command.
3. If a `no-changelog` label is needed, remind the user it has to be applied on the PR *after* creation (or via `--label no-changelog` if their `gh` setup allows).
4. Tell the user explicitly:

   > PR is ready to submit.
   > - Body: `./tmp/<session_id>/PR.md` (everything above `---`)
   > - Submission notes: below `---` in the same file
   >
   > I have not opened the PR. Run the `gh` command when you're ready.

Never invoke `gh pr create` automatically, even after confirmation-style prompts. The user opens the PR themselves.

## Notes

- `PR.md` is the source of truth for the submitted body. Every iteration edit lands in the file, not just the conversation.
- If the user edits `PR.md` directly between turns, re-read it before proposing further changes.
- Test case checkboxes in `PR.md` are what CI will validate — don't reformat them or add extra structure the bot might reject.
- If the branch picks up new commits mid-hone (e.g. the user pushes a fixup), re-read the diff before continuing; test cases may need to change.
