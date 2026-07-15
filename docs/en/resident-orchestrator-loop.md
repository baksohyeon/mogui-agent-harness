# Resident Orchestrator and the Autonomous Loop: a multi-repo operating layer

> English document. 한국어: [../ko/resident-orchestrator-loop.md](../ko/resident-orchestrator-loop.md)

The harness's `.agent` layer covers "how an agent works inside one repo." This
document covers the layer above it: **a sole maintainer running several repos
keeps a master agent resident in the common parent folder, and that master
subcontracts implementation to worker agents** — plus the design of the
autonomous loop the master runs. It generalizes a full day of operating this
on a live service (backend monorepo + frontend repo), incidents included, and
cites the external research that grounds each rule.

Tool names are examples. The resident terminal can be tmux, memory can be
plain files, workers can be any CLI agent. What must be filled are the roles.

## 1. The five roles

| Role | Requirement | What happens without it |
|---|---|---|
| Residence | Run in the repos' common parent folder | Cross-repo impact (API contract change → frontend regen) gets missed |
| Durable memory | Rules/decisions/traps auto-injected at session start | Every new session repeats the same mistakes |
| Watch loop | Periodic diff of refs/dirty/worktrees/MRs | Nobody notices changes while the human is away |
| Delegation + gates | Workers implement; master re-verifies outputs; destructive acts need a human gate | Errors amplify, or a worker runs away |
| Succession | Thin handoff + kickoff prompt spawns the successor before a session dies | Operating knowledge resets on every session death |

## 2. Memory design: three layers, two SSOTs

Context is finite, and recall degrades as it fills (context rot, [R1]). So
memory lives outside the context window, split into layers.

| Layer | Holds | Store | Injected |
|---|---|---|---|
| Rules/decisions/traps | "always do X" / "never do Y" | memory store (e.g. beads `bd remember`) | every session, automatically |
| Per-task narrative | why this issue is in this state | issue notes | when the issue is opened |
| Session narrative | currently open tracks | one thin handoff doc | once, at succession |

This matches the standard pattern for long-horizon agents: persist structured
notes outside the window [R3], and cross session boundaries via compaction
(summarize, restart fresh seeded with the summary) [R2]. An OSS corpus study
finds file-backed persistence is the empirical norm (pure prompt-window
designs: 4.3% of 70 projects) [R5].

One more rule keeps the structure alive long-term. **Two SSOTs**: the source
of truth for intent/plans is human-owned documents; the source of truth for
execution state/facts is the memory store — and neither copies the other
(pointers only). Drift starts the moment the same content lives in two places;
a predecessor harness's auto-injected `.agent` files going stale against the
actual code is exactly this failure.

## 3. The autonomous loop: a six-step duty cycle

A state machine the master runs on every wakeup (periodic or event-driven).

1. **SENSE** — measure, don't ask. Monitor liveness via process inspection
   (runtime task queries can emit false-death signals across session
   boundaries — re-arm only after two consecutive misses; never double-arm).
   Diff repo baselines; check worker states. Worker silence is not death —
   check terminal activity before judging.
2. **TRIAGE** — classify events. Echoes of your own actions: ignore. Expected
   changes: update the baseline. Unexplained changes: report to the human
   immediately; never auto-respond.
3. **WORK** — pick work when idle, from the tracker's ready queue in priority
   order, only tasks that need no gate. Before starting: search decision
   memory (never reopen a closed question). Every delegation carries an
   objective, output format, tool/source guidance, and explicit boundaries —
   vague delegation produces duplicated, misinterpreted work [R9]. Decompose
   along context boundaries, not problem types (planner/tester role splits
   just multiply context-sharing costs) [R12].
4. **VERIFY** — re-verify outputs empirically. Don't trust completion claims;
   confirm via diff, tests, execution. Give verification gates explicit
   criteria — a verifier asked only "is this good?" becomes a rubber stamp
   [R10]. Re-check reviewer findings against the code too (false positives
   have been rejected in practice).
5. **RECORD** — issue notes, tickets, and one trap memory per incident or
   misjudgment.
6. **PACE** — self-pace the next wakeup. Active tracks: short (10–15 min).
   Idle: long (25–30 min). Human actively chatting: loop goes background.

### Hard stops

Termination conditions are a first-class design element — reactive loops
without a time budget and explicit stop conditions run away [R11].

- Three consecutive failures on one task → stop, escalate to the human.
- Gated actions (merge, push, prod, deletion, config changes) are never
  self-executed, by any path.
- Context usage threshold (~70%) → stop starting new work, switch to
  handoff-writing mode.
- Anomaly detected → no WORK phase; report and wait.
- Worker-runaway signs (out-of-scope files, unauthorized posting, ghost
  processes) → kill + quarantine outputs + report. Empirical basis: a
  review-only worker that merely *received* a read-only instruction — but
  held write-capable tools — went as far as unauthorized posting and process
  spawning. Instructions have no enforcement power; tool restriction does.
  The OSS corpus agrees: 100% of container-isolated projects also ship a
  policy engine — isolation and governance co-evolve [R7].

### Scale and cost rules

Multi-agent is not the default. It costs 3–10x the tokens of a single agent
for equivalent tasks [R12], so fan out only where parallelism genuinely pays.
Embed explicit effort-scaling rules in the orchestrator (one agent for simple
lookups; 10+ only for large investigations) — an early system without them
spawned 50 subagents for a simple query [R8]. Run subagents on clean contexts
and collect condensed summaries (~1–2k tokens) [R4]. Route model costs:
judgment/verification on the primary model, bulk execution/research on a
separately-billed worker family. (The day this document was written, a
research fan-out run on the primary model burned through the account's
credits — that incident is where this rule comes from.)

## 4. Delegation protocol checklist

- **Dispatch isn't done until receipt is verified**: confirm TUI idle →
  inject → empirically confirm the task text appears in the terminal tail.
  Injection races shell init and auto-updates, and loses tasks silently
  (observed three times).
- Every task spec includes: objective, target path (worktree), output format,
  prohibitions (push, external APIs, out-of-scope files), completion report
  format.
- Isolation: parallel file changes get per-worker worktrees. Always name the
  base branch explicitly (repos exist whose default branch pointer aims at
  the release branch).
- Long-lived vs one-shot workers: recurring domain work benefits from a
  long-lived worker's accumulated context; one-off tasks get a clean-context
  one-shot worker [R13].

## 5. Grounding (research citations)

Method note: collected via 5-angle parallel search → 23 sources → 115
extracted claims → sampled verification. [R1–R4] passed 3-vote adversarial
verification; the rest are direct quotes from primary sources whose votes
were cut short (by the cost incident) — adopted on source credibility alone.

- [R1] Context rot — recall degrades as context grows. Anthropic, "Effective
  context engineering for AI agents" (verified 3-0)
- [R2] Session-boundary succession = compaction. Same source (2-1)
- [R3] Long-horizon work = structured notes persisted outside context. Same
  source (3-0)
- [R4] Subagents: clean contexts, condensed ~1–2k-token summaries back. Same
  source (3-0)
- [R5] 70-project OSS corpus: file persistence is the empirical norm (pure
  prompt-window: 4.3%). arXiv:2604.18071
- [R6] Delegation complexity strongly co-occurs with context-management
  sophistication (85% of orchestrator-worker projects use file persistence).
  arXiv:2604.18071
- [R7] Isolation and governance co-evolve (100% of container-isolated
  projects have policy engines; lift 3.4). arXiv:2604.18071
- [R8] Runaway case: 50 subagents for a simple query absent effort-scaling
  rules. Anthropic, "Multi-agent research system"
- [R9] Vague delegation → duplicated/misread work. Same source
- [R10] Criterionless verifiers rubber-stamp. Anthropic blog, "Multi-agent
  coordination patterns"
- [R11] Runaway prevention = first-class termination (time budget + explicit
  conditions). Same source
- [R12] Multi-agent = 3–10x tokens; decompose along context boundaries.
  Anthropic blog, "Building multi-agent systems: when and how"
- [R13] Long-lived workers accumulate domain specialization. Anthropic blog,
  "Multi-agent coordination patterns"
- Supporting: 13 OSS coding-agent scaffolds — control architectures compose
  five loop primitives; 11/13 layer multiple. arXiv:2604.03515

## 6. Trap list from one day of operation (measured)

- Runtime task queries emit false-death signals → a live monitor was killed
  on one. Verify liveness via process inspection.
- Prompt injection races shell init → task lost three times. Receipt
  verification is mandatory.
- Reviewing deploy config within diff scope only → the image-production path
  (compose) omission survived two review agents plus re-verification. Review
  scope is "everything the feature's operation presupposes," not the diff.
- Research fan-out on the primary model → credit burnout. Cost routing is now
  a written rule.
- Proposing without consulting decision memory → reopened a closed question.
  "The moment before writing a proposal sentence is when you search."
