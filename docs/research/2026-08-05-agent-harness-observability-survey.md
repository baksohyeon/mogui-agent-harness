# Survey: observability surface of mogui-agent-harness (before any move-in)

> English document. Investigation only — no skills moved, no README edited, no directories created.
>
> Contract: `mogui-master-ops/contracts/2026-08-05-agent-harness-observability-survey.md` (sha `58284757` per dispatch).
> Worktree first action (measured 2026-08-05):
>
> - worktree path contains `.orca/worktrees` (verified); branch `feat/harness-survey-0805`
> - `git rev-parse HEAD origin/main` (at survey start) = `d7daf316e35ee85fca9732667bc2e44422521b01` / `d7daf316e35ee85fca9732667bc2e44422521b01`

## Framing measured here

This repository is a **copy-paste, vendor-neutral operating layer** for new repos (`README.md` L1–L7). Judgments below treat “long-running ops workspace value” and “fresh project skeleton cost” as different defaults. Where measurement contradicted the contract’s wording, the measurement wins and the mismatch is called out in § Contradictions.

Document placement: this repo already ships analysis-style work under `docs/research/` (e.g. `docs/research/agentic-harness-engineering.md`). That convention is reused. No new directory invented.

---

## 1. What observability exists here today?

**One-line answer:** The harness ships *durable knowledge + session learning + loop run logs + wiki frontmatter audit*, not session transcripts, travelogs, or a dispatch ledger.

### Enumerated surfaces (path → what it records → wired vs present)

| Path | Genre / role | Wired? | Evidence |
|---|---|---|---|
| `.agent/Memory.md` | Session learning log (preferences, corrections, patterns) | **Wired by instruction** — agent updates on explicit user phrases; not an automatic host hook that writes the file | `.agent/Instructions.md` § Memory Update Protocol; `.agent/Memory.md` skeleton |
| `.agent/Context.md` / `.agent/Instructions.md` | Compressed product context + rules (not a history log) | **Wired** via host routers + SessionStart `load-context.sh` (prints Context only) | `CLAUDE.md` router; `.claude/hooks/load-context.sh`; `.claude/settings.json` SessionStart |
| `docs/wiki/decisions/D-*.md` | Closed decisions (ADR) | **Present as skeleton**; filled by people/agents over time | `docs/wiki/decisions/D-template.md`; routing table in `README.md` L99–L109 |
| `docs/wiki/postmortem/` | Incident / lesson records | **Present as skeleton** + skill adapter | `postmortem-template.md`; `.agents/skills/postmortem/SKILL.md` → `.agent/workflows/postmortem.md` |
| `docs/wiki/postmortem/temp/` | Handoff snapshots for long workflows | **Present as skeleton** (template only) | `snapshot-template.md`; `Instructions.md` rule 9; `README.md` L162 |
| Wiki frontmatter `audit_log[]` | Per-doc append-only change history | **Wired** by git hooks when files already have `audit_log` | `.githooks/prepare-commit-msg` (auto-append); `.githooks/pre-commit` (`@git_author` / `updated_at`); `docs/wiki/_schema/frontmatter.md` L55–L63 |
| `.agent/loops/LOOP.md` | Loop registry (budgets, kill switch, maturity) | **Present** (template registry; daily-triage status = “template — enable per repo”) | `.agent/loops/LOOP.md` Loop: daily-triage Status row |
| `.agent/loops/<loop>.STATE.md` | Loop summary state | **Present** for daily-triage only | `.agent/loops/daily-triage.STATE.md` |
| `.agent/loops/runs/` | Append-only per-run execution log | **Present** (README + convention; no sample run files shipped) | `.agent/loops/runs/README.md` |
| Host hooks (Claude/Codex) | Health / bootstrap / style — **warnings to the session**, not durable records | **Wired** in `.claude/settings.json` / `.codex/hooks.example.json` | SessionStart: setup-check, memory-health, load-context, wiki-health; UserPromptSubmit: memory-selfcheck, remind-korean-style |
| `scripts/wiki-lint.sh` | Integrity check including `audit_log[].at` order | **Wired** as a verify script (not automatic on every session) | `scripts/wiki-lint.sh` checks 5–7 |
| `scripts/verify-agent-ssot.sh` / `scripts/smoke-codex.sh` | Harness wiring / Claude–Codex parity probes | **Wired** as entrypoints; invoked by `setup.sh` step 4 (verify only) | `scripts/setup.sh` L120–L129; `scripts/smoke-codex.sh` header |
| `docs/en/resident-orchestrator-loop.md` | Design essay on multi-repo master/worker + RECORD step | **Document only** — no runtime dispatcher shipped | File present under `docs/en/`; no matching scripts/skills for dispatch |

### Explicitly absent (searched, not found)

Commands run: `find . -iname '*travelog*' -o -iname '*agent-journey*' -o -iname '*field-note*'`; `rg -n -i 'transcript|jsonl|session.?log|ledger' .` (excluding `.git`).

- No `docs/travelog/`, `docs/agent-journey/`, `docs/field-notes/`, `docs/retro/`, `docs/blame/`, `docs/observability/`
- No transcript capture/store path
- No dispatch ledger or acknowledgement-record store in-repo
- No “journal” genre directory

### Genre map (what this harness actually records)

```text
session learning     → .agent/Memory.md          (manual/instruction-driven)
execution state      → .planning/**              (GSD slots; not observational narrative)
approved knowledge   → docs/wiki/**              (decisions/guides/postmortems + frontmatter audit_log)
loop ops             → .agent/loops/**           (state + append-only run logs; L1 template)
session handoff      → docs/wiki/postmortem/temp/ (template; agent-instructed)
host health signals  → hooks stdout              (ephemeral in the agent turn)
```

---

## 2. Is there a `travelog`, and does it overlap with `agent-journey`?

**One-line answer:** This harness does **not** carry travelog. Overlap with `agent-journey` is real only in the **ops instance** genres, where both are itinerary-style behavioural traces at different grain — and ops already dropped journey as too costly.

### Measurement: harness

- `find` for travelog / agent-journey / field-notes under this worktree: **zero paths**.
- README, guides, skills, scripts: no travelog skill or directory.

### Measurement: ops instance (for comparison only — not shipped here)

Sources:

- `mogui-master-ops/docs/travelog/README.md` (live file)
- `mogui-master-ops/docs/observability/README.md` (genre table)
- `git show 6b0f9b8:skills/agent-journey/SKILL.md` (pre-delete content; deleted in `6094e061`)
- Retire commit message `6094e061` (2026-08-05)

| Dimension | Travelog (ops genre) | agent-journey (retired ops skill) |
|---|---|---|
| Home | `docs/travelog/gen-<N>.md` | `docs/agent-journey/YYYY-MM-DD-<slug>/TRAVELOG.md` |
| Cadence | Append per generation, as events happen | On-demand skill; not automatic |
| Captures | Where the master went, commands run, what came back | Turn-level harness dissection: forced/shaped/judged chain, tools order, user interrupts, negative space |
| Grain | Generation / itinerary | Single turn or small turn bundle |
| Shared SSOT | `docs/observability/README.md` legend | Same legend required by the skill text |
| Origin note | Ops genre table row | Skill header: “원본: Dorito의 travelog 스킬” — journey is a **port of a travelog-style skill**, specialized for harness self-observation |

**Overlap evidence (not preference):**

1. Both claim the “what actually ran / what shaped behaviour” layer that git and the tracker do not hold (`docs/observability/README.md` opening + travelog README; agent-journey “찍는 것 / 못 찍는 것”).
2. agent-journey’s own description cross-routes “세대 일지” to `docs/travelog/` and names itself as harness-passage tracing — so the **authors already separated** generation itinerary vs turn dissection, but both remain behavioural traces with the same integrity tags.
3. Ops observability index (post-retirement) states that a plain-language digest and a turn-level harness dissection were **dropped for token cost**, keeping retro + travelog as the standing suite. That is a measured product decision, not a preference of this survey.

**Subsumption:** Neither fully subsumes the other on evidence.

- Travelog does **not** require the fixed 0–8 section harness dissection or component-class table of agent-journey.
- agent-journey does **not** replace per-generation append-only itinerary files.
- They **duplicate the middle**: “what tools/commands ran and what came back,” with different templates and cadence.

**In this harness:** there is nothing for agent-journey to overlap *with* unless someone first imports travelog or the full observability suite. Importing agent-journey alone would introduce a second “itinerary-ish” narrative on top of existing handoff snapshots and loop run logs (partial thematic overlap only — see §1).

---

## 3. Where would the two skills actually go?

**One-line answer:** Skills land under `.agents/skills/<name>/SKILL.md` (adapters); as-is content is **ops-hardcoded** and needs path rewrites plus missing `docs/observability` (and output dirs) — `setup.sh` does not install skills beyond shipping files and SSOT verify.

### Skill host mechanism in this repo (measured)

| Piece | Path | Role |
|---|---|---|
| Skill files | `.agents/skills/{postmortem,scope,daily-triage}/SKILL.md` | Host-discoverable skill entrypoints |
| Procedure SSOT | `.agent/workflows/<name>.md` | Skills here are **thin adapters** that point at workflows |
| Claude slash (one example) | `.claude/commands/scope.md` | Only `scope` has a command adapter; postmortem/daily-triage do not |
| Required by SSOT verify | `.agents/skills/postmortem/SKILL.md`, `daily-triage/SKILL.md` | **`scope` is listed in README but not in `verify-agent-ssot.sh` required_files** |
| `setup.sh` skill wiring | none | Steps: git hooks → router hash check → optional tool presence → `verify-agent-ssot.sh`. No skill install step |

Host discovery of `.agents/skills/` is assumed by shipping files there (Claude Code / Codex project skills convention). This survey **did not** measure live host auto-load behaviour after a fresh clone on every host; only what the repo ships.

### Exact destination if they belonged here

```text
.agents/skills/agent-journey/SKILL.md
.agents/skills/field-notes/SKILL.md
```

Optional, matching local pattern (not required by current verify list):

```text
.agent/workflows/agent-journey.md   # if thinned to adapter+SSOT like the others
.agent/workflows/field-notes.md
```

Optional slash adapters (only if a host needs them; only scope currently has one):

```text
.claude/commands/agent-journey.md
.claude/commands/field-notes.md
```

### Wiring a new repo would need after `bash scripts/setup.sh`

`setup.sh` alone is **not enough** for these skills to work as written. Measured gaps:

1. **Output path rewrite** — skill bodies hardcode ops paths:
   - agent-journey: `mogui-master-ops/docs/agent-journey/YYYY-MM-DD-<slug>/TRAVELOG.md`
   - field-notes: `mogui-master-ops/docs/field-notes/YYYY-MM-DD-<slug>.md`
2. **Shared legend dependency** — both point at `docs/observability/README.md` as SSOT for tags/integrity. That tree **does not exist** in this harness.
3. **Cross-genre paths** — agent-journey references `docs/retro/`, `docs/travelog/`, blame-agent skill. None ship here. field-notes prefers `mcp__ctx__search` for transcript verification; this harness has **no ctx MCP config** (only code-review-graph in `.cursor/mcp.json` / `.codex/config.example.toml`).
4. **Hook inventory mismatch** — agent-journey procedure lists ops SessionStart signals (`master-bootstrap-live`, `bd prime`, `compaction-probe`). This harness’s SessionStart is setup-check / memory-health / load-context / wiki-health / code-review-graph status (`.claude/settings.json`). Copy-paste without rewrite would invent firings.
5. **Index files** — agent-journey requires `docs/agent-journey/README.md` matrix; not present.
6. **SSOT gate** — if they become “required,” `scripts/verify-agent-ssot.sh` must list them; today it does not know them.
7. **README inventory** — owner docs would need an inventory row; out of scope for this investigation (prohibited edit).

### Can the skill mechanism host them as-is?

**No.** The directory convention can host the files, but the **content is ops-instance-bound**. Hosting as-is would:

- write outside a consumer repo’s intended layout (`mogui-master-ops/...` paths), or fail when those paths do not exist
- cite missing observability SSOT and sibling genres
- describe hooks and tools this skeleton does not run

What is missing for a faithful port (measurement only — not implementing): path-neutral output roots, either import or slim replacement of `docs/observability` legend, and harness-accurate hook/tool evidence lists. Whether those belong in a *copy-paste new-repo harness* is a cost question (§5), not a skill-placement question.

### Source commits (ops)

| Commit | Meaning |
|---|---|
| `6b0f9b8` | skills present (`skills/agent-journey/SKILL.md` 102 lines; `skills/field-notes/SKILL.md` 30 lines) |
| `6094e061` | both deleted; session card rerouted to `docs/observability/` genres |

---

## 4. README accuracy (EN + KO)

**One-line answer:** Core architecture claims largely match the tree; inventory and Verify blurbs under-list shipped docs/scripts, EN/KO have drifted on smoke-codex and one KO-only section, and KO mentions a guides path that does not exist.

Method: line-by-line claim checks against `find docs`, `ls scripts`, and `scripts/smoke-codex.sh`. No README edits performed.

### Matches (representative)

| Claim | Location | Reality |
|---|---|---|
| Two-stage greenfield: script then AI fill | EN L9–L14; KO L15–L18 | `setup.sh` asks no product questions; placeholders remain |
| Host routers must stay identical | EN L126 | `verify-agent-ssot.sh` + setup step 2 enforce hash equality |
| `.agents/skills` for postmortem/scope/daily-triage | EN L131; KO L146 | Three skill dirs present |
| Loop layer + daily-triage | EN L130; KO L145 | `.agent/loops/` + skill + workflow present |
| Git hooks for frontmatter + audit log | EN L134; KO L149 | pre-commit + prepare-commit-msg measured |
| Ingest non-destructive | EN L49–L63; KO L64–L78 | Matches `scripts/ingest.sh` design comments |

### Mismatches (line → claim → measured reality)

| File:line | Claim | Measured reality |
|---|---|---|
| EN `README.md:140` | `docs/ko/` = “Korean versions of this README, `PROMPTS.md`, and the walkthrough” | Also ships `docs/ko/resident-orchestrator-loop.md` and `docs/ko/research/agentic-harness-engineering.md` |
| KO `docs/ko/README.md:155` | Same inventory claim (KO) | Same undercount |
| EN `README.md:139` | What’s inside lists only `docs/en/bootstrap-walkthrough.md` under English docs | Also ships `docs/en/resident-orchestrator-loop.md` |
| EN `README.md:137` / KO `:152` | `scripts/` role line lists setup, hook install, wiring verify, ingest, Codex smoke | Also ships `wiki-lint.sh`, `decisions-index.sh`, `install-obsidian-plugins.sh` (wiki-lint appears later under Verify, but not in the inventory role line) |
| EN `README.md:131` vs `scripts/verify-agent-ssot.sh:23` | README treats three skills as first-class inventory | SSOT required_files requires postmortem + daily-triage only; **scope skill is not required by the gate** |
| KO `docs/ko/README.md:207` | smoke-codex: “`codex` CLI가 있으면 라이브 동작 확인도 **제안**하고, 없으면 정적 검사만” | Script is static-only by default; live is **opt-in** via `--live` and never affects exit code (`scripts/smoke-codex.sh` L14–L18, L234–L273). EN L192 states this correctly → **EN/KO drift** |
| KO `docs/ko/README.md:38–47` | Extra “init commit을 분리하고 싶을 때” section | **Absent from EN README** — bilingual structural drift (not false, but not mirrored) |
| KO `docs/ko/README.md:11` | “한국어 가이드가 더 필요하면 `docs/wiki/guides/ko/`에 추가” | Path **does not exist** in the skeleton (`ls docs/wiki/guides/ko` → No such file). The claim is advisory (“if needed, add”), not “ships with,” but a new-repo reader may expect the folder |
| EN L5 / KO L7 | Lists Claude/Codex hooks, Cursor rule, code-review-graph | Accurate for shipped adapters; **does not** claim travelog/journey (no false positive there) |

### EN/KO drift as a finding

- KO explicitly says English is canonical if they disagree (`docs/ko/README.md` L3). Smoke-codex is a concrete place where KO is softer/wrong relative to the script and EN.
- KO has an extra operational tip (init commit split) not present in EN — inventory parity is incomplete both ways.
- Line counts: EN 192 lines, KO 207 lines (structural addition, not pure translation).

### What was not line-audited exhaustively

Full prose parity of every sentence between EN and KO was **not** measured. The table above is claim-vs-tree and EN-vs-KO on inventory/Verify/structure. Unchecked remaining prose may hide more drift — marked unmeasured rather than asserted clean.

---

## 5. Transcript + ledger + dispatch records — cost, not taste

**One-line answer:** Each of the three needs new stores and write paths this skeleton lacks; a new repo without them loses ops-grade reconstruction, not day-one coding ability; **default-on cost lands on every copy**, author cost is only design/docs unless you force defaults.

Framing from ops (measured, for contrast): `docs/observability/README.md` already argues travelog is redundant if a workspace keeps a **verbatim session transcript**, and that retro is the genre that “earns its cost.” Retirement commit `6094e061` states journey/field-notes cost real tokens and should not ship into someone else’s workspace by default.

### A. Logging transcripts

| | |
|---|---|
| **What it would require in this harness** | A durable store path (gitignored or redacted); a host-specific capture hook or external tool (e.g. ctx/jsonl); redaction rules for secrets; retention policy; size budget. None of these exist here (search: no transcript pipeline). |
| **What a new repo loses without it** | Verbatim recovery of prompts/tool I/O after compaction. Still keeps Memory, wiki decisions, handoff snapshots, loop run logs, git history. |
| **Who pays** | **Every project** if default-on (disk, privacy review, token use when agents re-read logs). **Author only** if documented as optional external tooling. |
| **Measurement gap** | Exact token/disk cost of full transcripts **not measured** in this survey (no workload sample run). |

### B. A ledger (judgment / retro-style standing ledger)

| | |
|---|---|
| **What it would require** | Genre directory + legend SSOT (ops uses `docs/retro/` + `docs/observability/README.md`), write discipline, index maintenance, agent skill or workflow to produce entries. |
| **What a new repo loses without it** | Structured “why we chose / what we almost did” history. Partial substitutes: Memory corrections, postmortems, decision ADRs (different questions). |
| **Who pays** | **Every project** pays token + doc rot if agents are told to write retro on every track. **Author** pays design once if optional. Ops index claims retro is the high-value genre — that claim is **ops experience**, not re-measured here. |

### C. Dispatch records

| | |
|---|---|
| **What it would require** | Receipt schema (`worker_id`, `task_id`, … per `docs/en/resident-orchestrator-loop.md` L125–L132), a store, writer on dispatch, reader on reap/verify. This repo ships the **essay**, not the machinery. Live dispatch in the owner’s stack is outside this repo (Orca orchestration / master-ops) — **not re-instrumented here**. |
| **What a new repo loses without it** | Multi-agent dispatch audit (“was the task accepted?”). Solo single-agent new repos lose almost nothing day one. Multi-repo masters lose silent-loss detection described in the essay (`[OBS]` injection races). |
| **Who pays** | **Only multi-agent consumers** need it. Shipping empty ledger files + mandatory skills into every greenfield copy still costs **attention and false obligation** on solo projects. |

### Combined recommendation (cost-shaped, optional)

- **Do not default-on** transcript + ledger + dispatch inside a copy-paste new-repo harness. Cost multiplies by every clone; benefit concentrates in long-running multi-agent ops (the seat that just retired two experimental skills for that reason).
- **Author-side** can document optional genres and link to ops patterns without shipping write paths.
- If anything moves: prefer **opt-in**, path-neutral, and aligned with existing loop run-log / handoff snapshot machinery rather than a parallel suite.
- Preference without cost data was not used; absolute token numbers remain **unmeasured**.

---

## 6. Worker probe angle

**One-line answer:** This repo has **verify/smoke/loop** entrypoints a human or agent can run, but **no dispatched-worker runtime path** that already executes on every worker; an observability probe would need a new obligation or an external orchestrator preamble.

### What a “worker” can already run here

| Entrypoint | Automatic on dispatch? | Role |
|---|---|---|
| `bash scripts/setup.sh` | No (one-time / re-run) | Hooks + SSOT verify |
| `bash scripts/verify-agent-ssot.sh` | Called from setup step 4 | Skeleton wiring gate |
| `bash scripts/smoke-codex.sh` | No | Claude/Codex parity (static; `--live` optional) |
| `bash scripts/wiki-lint.sh` | No | Wiki integrity |
| daily-triage skill / workflow | No (manual / scheduled by human) | L1 read-only health report → state + run log |
| Host SessionStart hooks | Yes **for interactive host sessions** in a repo that installed settings | Health/bootstrap — not worker-dispatch specific |

### Dispatched-worker path?

- In-repo: **no** dispatch gate, no worker receipt writer, no contract runner under `scripts/`.
- `docs/en/resident-orchestrator-loop.md` describes dispatch/receipt as a **protocol checklist** for a multi-repo master, not code in this skeleton.
- External (ops/Orca): workers receive injected contracts and report status — **that path is not part of this repository’s shipped surface**. This survey did not re-measure Orca preamble injection contents beyond the current task’s human-visible contract.

### Could an observability probe ride an existing path without new machinery?

| Path | Fit | Constraint |
|---|---|---|
| SessionStart hooks | Could print a one-line “probe: write X” | Fires for every interactive session, not only workers; adds token load by default; still no durable write unless the agent complies |
| `verify-agent-ssot.sh` | Could assert probe files exist | Wrong layer: wiring verify ≠ behavioural trace; fails greenfield until probe outputs exist |
| daily-triage | Could include an observability checklist item | Cadence is daily health, not per-task; L1 must not write outside state/run log |
| Worker contract text (external) | **Yes, without harness code changes** — master can require a short TRAVELOG/probe section in the completion report | Cost is per dispatch; harness remains thin. This is already how the current survey was tasked |

**Conclusion:** Doubling skills as “worker probes” needs either (a) orchestrator-level contract text (no harness change), or (b) new harness machinery. There is **no** existing in-repo path that every dispatched worker already runs where a probe can be bolted on without new obligation.

---

## Contradictions with the contract’s framing

Follow measurement over the contract text:

1. **“Four things… and a fifth open question”** (contract Why) vs **six numbered questions** in the Questions section. This document answers all **six** numbered questions. The Why paragraph’s count is inconsistent with its own list.
2. **“This repository is that home”** is an owner judgment in the contract. Measurement shows the harness is a **new-repo skeleton** with no observability suite directories; ops still holds `docs/observability/`, travelog, retro, blame. Whether the *skills* should live here is open; the *genre suite* is not already here.
3. **Travelog overlap suspicion** assumed travelog might exist in-harness. Measurement: **it does not**. Overlap analysis required the ops instance.
4. **Worker probe** assumed a worker execution path inside the harness. Measurement: probes exist as **scripts/hooks for the adopting repo’s agents**, not as a dispatch lifecycle.

---

## Evidence index (commands / commits)

```text
pwd; git branch --show-current; git rev-parse HEAD origin/main
find . -type f ... | sort          # full tree inventory
find . -iname '*travelog*' ...     # absence
rg -n -i 'transcript|ledger|dispatch|travelog|agent-journey|field-notes'
sed/rg on README.md and docs/ko/README.md
cat scripts/setup.sh, verify-agent-ssot.sh, smoke-codex.sh headers
cat .claude/settings.json; ls .agents/skills; ls .agent/loops
# ops
git -C mogui-master-ops show 6b0f9b8:skills/agent-journey/SKILL.md
git -C mogui-master-ops show 6b0f9b8:skills/field-notes/SKILL.md
git -C mogui-master-ops show 6094e061  # retire commit
read mogui-master-ops/docs/observability/README.md
read mogui-master-ops/docs/travelog/README.md
```

### Unmeasured (deliberately blank)

- Live host skill auto-discovery after clone on every vendor host
- Token/$ cost of journey vs travelog vs transcript under a fixed workload
- Whether Orca’s default worker preamble already includes observability instructions beyond this task
- Full sentence-level EN↔KO README translation audit beyond inventory/Verify/structure
- Runtime behaviour of daily-triage against a real multi-day repo history (template only)

---

## End state for the owner

No skills moved. No README rewritten. No new directories. One survey document under the existing `docs/research/` convention. Next actions (import, rewrite, reject, opt-in only) are **owner decisions** based on the six answers above.
