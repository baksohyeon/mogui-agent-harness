---
name: daily-triage
description: Read-only L1 daily triage loop. Sweeps default-branch commits, open PRs/MRs, code-review-graph signals, and stale memory/wiki, then writes a structured one-line-item report to the loop state file. Use when running the daily-triage loop or when the user asks for a repo triage or health sweep.
user-invocable: true
argument-hint: "[--dry-run]"
---

# Daily Triage

This skill is a thin adapter. The canonical procedure lives in the `.agent/` SSOT so the system does not depend on this skill directory.

Read and follow [`.agent/workflows/daily-triage.md`](../../../.agent/workflows/daily-triage.md). The loop contract (budget, kill switch, maturity level) is [`.agent/loops/LOOP.md`](../../../.agent/loops/LOOP.md) — the collect/report stage is read-only: the only writes are the loop state file and one run-log file. If the loop's Maturity is ≥ L2, proposal PRs go through [`.agent/workflows/loop-l2-propose.md`](../../../.agent/workflows/loop-l2-propose.md) only.
