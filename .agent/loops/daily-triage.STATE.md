# daily-triage — STATE

State owned by the daily-triage loop only. Kept separate from `.planning/` (GSD) state. Holds the latest run's report; history lives in `runs/`.
Definition: [`LOOP.md`](./LOOP.md) · Procedure: [`../workflows/daily-triage.md`](../workflows/daily-triage.md).

## Format rules

- Each item is **one line**: `- [area] observation → suggested action`
- Area tags: `commits` · `pr` · `graph` · `memory` · `wiki`
- Show the **delta** vs the previous run (new / resolved) in its own section
- Items promoted to an L2 proposal are marked `→ PR #N (awaiting gate)`
- The collect/report stage writes only this file and `runs/`. Any other write goes through the L2 procedure (branch + PR).

---

## Latest run

_No runs yet. Filled in by the first dry-run._

- last-run: (none)
- last processed commit: (none)

### Triage items

(none)

### Delta (vs previous run)

(none)

### L2 proposals

(none)
