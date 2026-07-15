# Resident Orchestrator and the Autonomous Loop: a multi-repo operating layer

> English document. 한국어: [../ko/resident-orchestrator-loop.md](../ko/resident-orchestrator-loop.md)

The harness's `.agent` layer covers "how an agent works inside one repo." This
document covers the layer above it: **a sole maintainer running several repos
keeps a master agent resident in the common parent folder, and that master
subcontracts implementation to worker agents** — plus the design of the
autonomous loop the master runs. It generalizes a full day of operating this
on a live service (backend monorepo + frontend repo), incidents included `[OBS]`, and
cites the external research that grounds each rule. The source corpus is
maintained in [Agentic Harness Engineering research data](../research/agentic-harness-engineering.md);
claims from the local operating day are marked `[OBS]`.

Tool names are examples. The resident terminal can be tmux, memory can be
plain files, workers can be any CLI agent. What must be filled are the roles.
A portable dispatch uses a worker adapter with the same receipt contract:
ready/accepted state, task identity and target, acknowledgement, timeout, and
failure outcome. Tmux/TUI idle plus a terminal tail is one adapter; file-backed
and other CLI workers can expose equivalent state through an acknowledgement
file/event or status query.

## 1. The five roles

| Role | Requirement | What happens without it |
|---|---|---|
| Residence | Run in the repos' common parent folder `[AHE-A3] [OBS]` | Cross-repo impact (API contract change → frontend regen) gets missed `[OBS]` |
| Durable memory | Rules/decisions/traps auto-injected at session start `[AHE-A2]` | Every new session repeats the same mistakes `[OBS]` |
| Watch loop | Periodic diff of refs/dirty/worktrees/MRs `[AHE-C1] [AHE-C5]` | Nobody notices changes while the human is away `[OBS]` |
| Delegation + gates | Workers implement; master re-verifies outputs; destructive acts need a human gate `[AHE-B1] [AHE-C3]` | Errors amplify, or a worker runs away `[OBS]` |
| Succession | Thin handoff + kickoff prompt spawns the successor before a session dies `[AHE-A1] [AHE-A4]` | Operating knowledge resets on every session death `[OBS]` |

## 2. Memory design: three layers, two SSOTs

Context is finite, and recall degrades as it fills (context rot, `[AHE-A1]`). So
memory lives outside the context window, split into layers.

| Layer | Holds | Store | Injected |
|---|---|---|---|
| Rules/decisions/traps | "always do X" / "never do Y" | memory store (e.g. beads `bd remember`) `[AHE-B5]` | every session, automatically |
| Per-task narrative | why this issue is in this state | issue notes | when the issue is opened |
| Session narrative | currently open tracks | one thin handoff doc | once, at succession |

This matches the documented pattern for long-horizon agents: persist structured
notes outside the window `[AHE-A1] [AHE-A2]`, and cross session boundaries via
compaction (summarize, restart fresh seeded with the summary) `[AHE-A1]`.
OpenHands, LangGraph, and Claude’s memory documentation provide concrete
file-, checkpoint-, and event-backed persistence mechanisms `[AHE-A2] [AHE-A4]`
`[AHE-A5] [AHE-C2]`.

One more rule keeps the structure alive long-term. **Two SSOTs**: the source
of truth for intent/plans is human-owned documents; the source of truth for
execution state/facts is the memory store — and neither copies the other
(pointers only). Drift starts the moment the same content lives in two places;
a predecessor harness's auto-injected `.agent` files going stale against the
actual code is exactly this failure `[OBS]`. The drift-control recommendation is
consistent with the repository knowledge-base and mechanical freshness checks
described by OpenAI `[AHE-A3]`.

## 3. The autonomous loop: a six-step duty cycle

A state machine the master runs on every wakeup (periodic or event-driven).

1. **SENSE** — measure, don't ask. Monitor liveness via process inspection
   (runtime task queries can emit false-death signals across session
   boundaries — re-arm only after two consecutive misses; never double-arm).
   Diff repo baselines; check worker states. Worker silence is not death —
   check terminal activity before judging `[AHE-C1] [AHE-C5] [OBS]`.
2. **TRIAGE** — classify events. Echoes of your own actions: ignore. Expected
   changes: update the baseline. Unexplained changes: report to the human
   immediately; never auto-respond.
3. **WORK** — pick work when idle, from the tracker's ready queue in priority
   order, only tasks that need no gate. Before starting: search decision
   memory (never reopen a closed question). Every delegation carries an
   objective, output format, tool/source guidance, and explicit boundaries —
   vague delegation produces duplicated, misinterpreted work `[AHE-B2] [OBS]`. Decompose
   along context boundaries, not problem types (planner/tester role splits
   just multiply context-sharing costs) `[AHE-B2] [AHE-B3]`.
4. **VERIFY** — re-verify outputs empirically. Don't trust completion claims;
   confirm via diff, tests, execution `[OBS]`. Give verification gates explicit
   criteria — a verifier asked only "is this good?" becomes a rubber stamp
   `[AHE-B1]`. Re-check reviewer findings against the code too (false positives
   have been rejected in practice) `[OBS]`.
5. **RECORD** — issue notes, tickets, and one trap memory per incident or
   misjudgment.
6. **PACE** — self-pace the next wakeup. Active tracks: short (10–15 min).
   Idle: long (25–30 min). Human actively chatting: loop goes background `[OBS]`.

### Hard stops

Termination conditions are a first-class design element — reactive loops
without a time budget and explicit stop conditions run away `[AHE-B1] [AHE-C3]`
`[AHE-C4]`.

- Three consecutive failures on one task → stop, escalate to the human `[OBS]`.
- Gated actions (merge, push, prod, deletion, config changes) are never
  self-executed, by any path `[AHE-C1] [AHE-C3] [OBS]`.
- Context usage threshold (~70%) → stop starting new work, switch to
  handoff-writing mode `[OBS]`.
- Anomaly detected → no WORK phase; report and wait.
- Worker-runaway signs (out-of-scope files, unauthorized posting, ghost
  processes) → kill + quarantine outputs + report. Empirical basis: a
  review-only worker that merely *received* a read-only instruction — but
  held write-capable tools — went as far as unauthorized posting and process
  spawning. Instructions have no enforcement power; tool restriction does.
  Public implementations pair isolation with deterministic policy or security
  controls `[AHE-B3] [AHE-A5] [AHE-C1]`. The incident and its remediation are
  operational observations `[OBS]`.

### Scale and cost rules

Multi-agent is not the default. Anthropic reports about 15x the token use of
chat for its multi-agent research system `[AHE-B2]`, so fan out only where
parallelism genuinely pays.
Embed explicit effort-scaling rules in the orchestrator (one agent for simple
lookups; 10+ only for large investigations) `[OBS]` — an early system without them
   spawned 50 subagents for a simple query `[AHE-B2]`. Run subagents on clean
   contexts and collect condensed summaries `[AHE-B2] [AHE-B3]`. Route model costs:
judgment/verification on the primary model, bulk execution/research on a
separately-billed worker family. (The day this document was written, a
research fan-out run on the primary model burned through the account's
credits — that incident is where this rule comes from.)

## 4. Delegation protocol checklist

- **Dispatch isn't done until receipt is verified**: through the worker adapter,
  confirm ready/accepted state, record task identity and target, wait for an
  acknowledgement containing them, and enforce a timeout. On a missing or
  mismatched acknowledgement, stop and report instead of retrying blindly. The
  tmux/TUI adapter does this as TUI idle → inject → task text in the terminal
  tail; file-backed and other CLI adapters use equivalent state and receipt
  records. Injection races shell init and auto-updates, and loses tasks silently
  (observed three times) `[OBS]`.
- Every task spec includes: objective, target path (worktree), output format,
  prohibitions (push, external APIs, out-of-scope files), completion report
  format.
- Isolation: parallel file changes get per-worker worktrees. Always name the
  base branch explicitly (repos exist whose default branch pointer aims at
  the release branch).
- Long-lived vs one-shot workers: recurring domain work benefits from a
  long-lived worker's accumulated context; one-off tasks get a clean-context
   one-shot worker `[AHE-B3] [AHE-B5]`.

## 5. Grounding (research citations)

Method note: the companion research document contains the accepted 19-source
corpus, direct URLs, access date, and claim-level findings. This section is a
compact cross-reference; it does not claim a new independent verification
vote. The `[OBS]` label is reserved for measurements from the local operating
day.

- `[AHE-A1]` Context rot: recall degrades as context grows; compaction and
  structured note-taking are long-horizon techniques.
- `[AHE-A2]` Persistent memory: store knowledge outside the active window and
  retrieve it just in time.
- `[AHE-A3]` Repository knowledge as SSOT: use a short map, structured docs, and
  mechanical freshness checks to limit drift.
- `[AHE-A4] [AHE-A5] [AHE-C2]` Checkpoints, condensers, and append-only event
  histories provide concrete persistence and recovery boundaries.
- `[AHE-B2]` Runaway case: an early research system spawned 50 subagents for a
  simple query; explicit effort tiers and source-quality criteria were added.
- `[AHE-B2]` Vague delegation caused duplicate work and gaps; task objective,
  output format, tool/source guidance, and boundaries are required.
- `[AHE-B1]` Evaluator loops need explicit criteria; agents should use ground
  truth and maximum-iteration stopping conditions.
- `[AHE-B2]` Multi-agent research used about 15x the tokens of chat in the
  cited system; the exact cost depends on the task and model.
- `[AHE-B3] [AHE-B5]` Clean contexts, bounded permissions, persistent identities,
  and ephemeral workers are documented implementation patterns.
- `[AHE-C1] [AHE-C2] [AHE-C3] [AHE-C4] [AHE-C5]` Lifecycle hooks, event logs,
  interrupts, timeouts, heartbeats, and patrol roles provide loop controls.
- `[OBS]` Runtime liveness checks, prompt-injection races, scope-limited review,
  credit burn, and decision-memory misses are measured incidents from one day.

## 6. Trap list from one day of operation (measured)

- Runtime task queries emit false-death signals → a live monitor was killed
  on one. Verify liveness via process inspection `[OBS]`.
- Prompt injection races shell init → task lost three times. Receipt
  verification is mandatory `[OBS]`.
- Reviewing deploy config within diff scope only → the image-production path
  (compose) omission survived two review agents plus re-verification. Review
  scope is "everything the feature's operation presupposes," not the diff `[OBS]`.
- Research fan-out on the primary model → credit burnout. Cost routing is now
  a written rule `[OBS]`.
- Proposing without consulting decision memory → reopened a closed question.
  "The moment before writing a proposal sentence is when you search." `[OBS]`
