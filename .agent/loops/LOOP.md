# LOOP.md — loop registry

Single source of truth for agent loops running in this repo. Append a section per loop.

Background: "loop engineering" means designing systems that prompt your agents on a cadence, instead of prompting them by hand. Each loop is a recursive goal: define a purpose, let the agent iterate (with sub-agents, verification, and external state) until done or handed off to a human. References: [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering) (patterns, maturity levels, anti-patterns), [earendil-works/pi](https://github.com/earendil-works/pi) (harness/runtime side of the same idea).

## Common discipline (all loops)

- **One state file per loop** — never append loop state to `.planning/` (GSD) state or to a shared file. State rot and ghost items follow otherwise.
- **Append-only run log** — execution history goes to `.agent/loops/runs/`, separate from the state file. No history means no way to debug past decisions.
- **Maturity ladder** — L1 (report only, read-only) → L2 (agent proposes, human gates) → L3 (unattended on an explicit path allowlist). Promote one level at a time; run L1 read-only for at least a week and check triage accuracy before promoting. Procedures: L2 = [`loop-l2-propose.md`](../workflows/loop-l2-propose.md), L3 = [`loop-l3-unattended.md`](../workflows/loop-l3-unattended.md).
- **Maker/checker split** — the agent that implements is never the agent that verifies. Verifier defaults to rejection.
- **Attempt cap** — hard limit (default 3) per item; then escalate to a human with full context. No infinite fix loops.
- **Read-only connectors first** — MCP/forge access starts read-only; write scopes come only after demonstrated reliability.
- **Kill switch** — every loop documents pause criteria and a budget below. If any trigger fires, stop and escalate; do not push through.
- **Commits/PRs follow repo rules** — loops never push or open PRs/MRs unless the human explicitly asked. From L2 on, proposal PRs are part of the loop's contract, but merging stays human-gated (L3 auto-merge only with explicit per-loop opt-in).

## Promotion / demotion protocol

| Transition | Criteria |
| --- | --- |
| L1 → L2 | ≥1 week of dry-runs, acceptable false-positive/miss rate, budget actuals stable, L2 propose scope agreed |
| L2 → L3 | ≥1 week at L2 + ≥5 accepted proposal PRs + rejection rate ≤20%, path allowlist finalized, kill switch/budget set from measured actuals, scheduled trigger registered |
| Demotion | One invariant violation = drop one level immediately + record the reason in this file. 3 consecutive runs ending in escalation = pause the loop |

A promotion is recorded by editing the loop's Maturity row plus a one-line reason. Silent promotions (no edit to this file) are forbidden.

## Loop: daily-triage

| Field | Value |
| --- | --- |
| Status | template — enable per repo |
| Cadence | 1×/day (first week: run manually, dry-run) |
| Maturity | L1 — report only, no repo writes |
| Procedure | [`.agent/workflows/daily-triage.md`](../workflows/daily-triage.md) |
| State file | `.agent/loops/daily-triage.STATE.md` |
| Run log | `.agent/loops/runs/daily-triage-YYYYMMDD-HHMM.md` |
| Allowlist | **none** — no file writes except state file + run log |
| L2 propose scope (fill at promotion) | e.g. small unambiguous doc/ops fixes (frontmatter, stale links, index gaps) — never product code |
| L3 allowlist (fill at promotion) | e.g. `.agent/loops/**` — explicit globs only |

### Scope (all read-only)

- New commits on the default branch since the last run (`git log`)
- Open PRs/MRs targeting the default branch (forge CLI: `gh pr list --base <branch>` or `glab mr list --target-branch <branch>`, read-only)
- `code-review-graph status` / `detect-changes --brief` (branch-mismatch and change signals; skip if not installed)
- Stale memory/wiki — reuse `.claude/hooks/memory-health.sh` (>90d) and `.claude/hooks/wiki-health.sh` (>180d)

### Kill switch / pause criteria

- Same item unresolved for 3 consecutive runs → escalate to human (retry-storm guard)
- A run exceeds the budget below → stop immediately
- Any diff outside the state file / run log → **L1 invariant violated, stop** (verify with `git status`)
- 3 unreviewed loop PRs accumulated → stop proposing (L2+)
- code-review-graph built on a different branch → graph signals untrusted; skip those items until rebuilt

### Budget template (measure during dry-run week, then tighten)

| Item | Cap (initial) |
| --- | --- |
| Output tokens per run | ~15k |
| Tool calls per run | ~25 |
| Wall-clock per run | ~3 min |
| L2: new proposal PRs per run | ≤2 |

### Promotion criteria (L1 → L2)

- ≥1 week of dry-runs with acceptable false-positive/miss rate in the triage report
- Budget actuals stable
- L2 propose scope decided (fill the registry row above)

### Promotion criteria (L2 → L3)

- See the protocol table above; additionally fill the L3 allowlist registry row with explicit globs before flipping the Maturity row
