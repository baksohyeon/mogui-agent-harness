---
type: workflow
status: active
tags: [workflow, loop, triage, automation]
updated: YYYY-MM-DD
---

# Workflow: Daily Triage (L1 read-only loop)

One run of the `daily-triage` loop. Loop definition, budget, and kill switch live in [`.agent/loops/LOOP.md`](../loops/LOOP.md). This workflow is the procedure; the loop file is the contract.

## L1 invariants (non-negotiable)

- **Read-only.** The only writes are `.agent/loops/daily-triage.STATE.md` and one new file under `.agent/loops/runs/`.
- No commits, no pushes, no PRs/MRs. Findings are reported as "suggested action" lines only.
- End every run with `git status`: any diff outside the state file / run log means the invariant broke — stop and escalate.

## Procedure

1. **Determine scope** — read `last processed commit` from `.agent/loops/daily-triage.STATE.md`; process only commits after it. If none, use the last 24h.

2. **Collect (all read-only)**

```bash
git log --oneline <last-sha>..origin/<default-branch>   # new commits
git branch --show-current
code-review-graph status                                 # branch-mismatch warning (skip if not installed)
code-review-graph detect-changes --brief                 # change signals (skip if not installed)
bash .claude/hooks/memory-health.sh                      # stale memory (>14d)
bash .claude/hooks/wiki-health.sh                        # stale wiki (>180d)
```

Open PRs/MRs via the repo's forge CLI, read-only: `gh pr list --base <branch>` (GitHub) or `glab mr list --target-branch <branch>` (GitLab). If the CLI is not authenticated for this host, skip and note it in STATE.

**Accuracy rule:** never report a tool as "missing / not configured" without actually attempting it. If an alternate tool is in scope (e.g. `glab` when `gh` fails), try it before judging. A skipped attempt reported as a finding is a false positive that erodes trust in the loop. (Learned in the first field dry-run: `gh` failed on a GitLab remote and the report said "needs glab auth" — but `glab` was already authenticated and was simply never run.)

3. **Triage** — normalize each signal into a one-line item:
`- [area] observation → suggested action` (areas: `commits` · `pr` · `graph` · `memory` · `wiki`).
Priority: graph branch-mismatch / CI-lag signals > stale docs > informational.

4. **Update STATE** — replace the `Latest run` section of `.agent/loops/daily-triage.STATE.md`: run timestamp, last processed commit (default-branch HEAD sha), triage items, delta vs previous run (new / resolved).

5. **Append run log** — one new file `.agent/loops/runs/daily-triage-YYYYMMDD-HHMM.md`: timestamp, scope, item count, spend (tokens / tool calls / wall-clock), pause status.

6. **Check kill switch** — full-stop pause criteria in [`LOOP.md`](../loops/LOOP.md) (3 consecutive unresolved / budget exceeded / diff outside state files). If any fires, stop and escalate with context. A **graph branch-mismatch is not a full stop**: per LOOP.md, treat graph signals as untrusted and skip only the graph-derived items until the graph is rebuilt — the rest of the run continues.

7. **L2 branch (only if the loop's Maturity is ≥ L2)** — pick triage items that fall inside the registry's `L2 propose scope` and run them through [`loop-l2-propose.md`](./loop-l2-propose.md) to open proposal PRs. Out-of-scope or ambiguous items stay report-only.

## Output contract

- One STATE file updated + one run-log file added. L2 proposals happen only on separate branches + PRs.
- Summarize findings to the user. No automatic fixes or commits in the collect/report stage.

## Promotion

Do not edit this workflow to add write behavior. L2 (propose + human gate) and L3 (unattended, allowlist) are separate procedures — [`loop-l2-propose.md`](./loop-l2-propose.md) and [`loop-l3-unattended.md`](./loop-l3-unattended.md) — gated by the promotion protocol in `LOOP.md`.
