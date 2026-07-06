---
type: workflow
status: active
tags: [workflow, loop, l2, propose, gate]
updated: YYYY-MM-DD
---

# Workflow: Loop L2 — propose + human gate

The shared procedure a maturity-L2 (or higher) loop uses to turn report items into actual change proposals (PRs/MRs). The per-loop contract (maturity, propose scope, budget, kill switch) lives in the [`.agent/loops/LOOP.md`](../loops/LOOP.md) registry — that file is the SSOT.

## L2 invariants

- Every change happens on a `feat|fix|docs|chore/loop-<loop>-<slug>` branch. No direct commits to the default branch (same as the repo rule).
- **The loop never merges.** The human gate is PR/MR review. Auto-merge is L3-only, and even then only when a human explicitly enabled it for that loop in the registry.
- **Maker/checker split** — the agent that implements never verifies. Verification is done by a separate agent (code-reviewer class) that defaults to rejection.
- **Attempt cap: 3 per item.** Past the cap, escalate to a human with full context.
- Never touch files outside the registry's `L2 propose scope`. Out-of-scope findings stay report-only.

## Procedure

1. **Select items** — only triage items from the loop STATE whose `suggested action` is unambiguous and whose diff will be small. When in doubt, do not propose (staying report-only is the default).
2. **Isolate** — one branch and one PR/MR per item. Never bundle items — bundling dilutes the review gate. Use worktree isolation for parallel work.
3. **Implement the minimal diff (maker)** — exactly the suggested action. No scope creep.
4. **Verify (checker)** — a separate agent reviews the diff. On rejection, fix and re-verify within the attempt cap. At the cap, leave the branch and escalate.
5. **Run repo guards** — whichever apply to the change (e.g. `bash scripts/wiki-lint.sh`, `bash scripts/verify-agent-ssot.sh`, `git diff --check`).
6. **Open the PR/MR** — base = default branch, title prefix `loop(<loop>):`, body cites the originating STATE item, the run log, and the checker result.
7. **Record** — update the STATE item to `→ PR #N (awaiting gate)` and append the proposal to the run log.

## Kill switch (L2 additions)

- 3 unreviewed loop PRs accumulated → stop proposing (signal that human throughput is exceeded)
- The same item rejected twice → drop it from L2 scope and promote it to a discussion thread (it needs a human decision, not a patch)
- New-proposal cap per run (registry budget table) exceeded → carry over to the next run
