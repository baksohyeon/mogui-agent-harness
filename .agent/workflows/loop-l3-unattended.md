---
type: workflow
status: active
tags: [workflow, loop, l3, unattended, allowlist]
updated: YYYY-MM-DD
---

# Workflow: Loop L3 — unattended runs (allowlist only)

The procedure for an unattended run of a maturity-L3 loop. **A loop cannot enter L3 without an L2 track record** — preconditions are the promotion/demotion protocol in [`.agent/loops/LOOP.md`](../loops/LOOP.md) plus the loop's own L3 checklist.

## Preconditions (all required)

- ≥1 week at L2, ≥5 accepted proposal PRs, rejection rate ≤20%
- An explicit **path allowlist** in the registry (globs — not prose like "roughly the docs folder")
- Kill switch and budget finalized from measured L2 actuals; escalation channel decided
- Scheduled trigger registered, with a human checking the run log daily for the first week

## L3 invariants

- **Writes stay inside the allowlist.** Before committing, diff `git diff --name-only` against the allowlist — a single out-of-allowlist path means abort immediately, escalate, and **demote to L2**.
- Direct commits to the default branch stay forbidden. Even allowlisted changes go through a branch + PR/MR. Auto-merge only for loops a human explicitly opted in, and only when guards are green.
- Maker/checker split, attempt caps, and run logs stay identical to L2. Unattended does not mean less verification.
- **Demote-first principle** — if a judgment call is even slightly ambiguous, do not act; hand it down to the L2 procedure (human gate). L3's default answer is "don't".

## Procedure

1. Scheduled trigger → L1 collect + triage (reuse [`daily-triage.md`](./daily-triage.md))
2. Split items: solvable inside the allowlist → step 3. Outside or ambiguous → L2 proposal or report-only.
3. Implement the minimal diff (maker) → separate checker verifies → run repo guards
4. Check invariant 1 (`git diff --name-only` vs allowlist) → on pass, commit on a branch and open the PR/MR
5. If the loop has auto-merge enabled, merge on green guards; otherwise record as awaiting gate
6. Update STATE + run log, record measured spend vs budget

## Demotion

- One invariant violation → immediate demotion to L2, with a one-line reason recorded in LOOP.md
- 3 consecutive runs ending in escalation → pause the loop (a human decides on resumption)
- Demotion and pauses are not failures — they are the kill switch doing its job. Record them; never quietly revert.
