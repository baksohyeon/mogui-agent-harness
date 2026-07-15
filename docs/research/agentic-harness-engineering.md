# Agentic Harness Engineering

## Research question

What are the current best practices for designing a long-lived, resident AI coding-agent harness?

The review is organized around four axes:

1. Memory and context persistence: session succession, memory curation, single-source-of-truth (SSOT) management, and drift control.
2. Multi-agent delegation: orchestrator-worker structures, verification gates, and runaway prevention.
3. Autonomous operating loops: idle-work selection, polling and event triggers, heartbeats, self-pacing, and safe stop conditions.
4. Industry and open-source implementations and failure cases: Claude Code, Codex, OpenHands, SWE-agent, Devin, and Gas Town/Beads-style systems.

This document is vendor-neutral. Vendor and project names identify publicly documented implementations, not recommendations or endorsements.

## Method

The supplied subagent JSONL files were read as read-only candidate material. They contained deployment-review output rather than verifiable sources for this question, so none of their claims or URLs were promoted into the evidence corpus.

Web searches were used to discover primary sources. A source was accepted only when all three conditions held:

- It was an official engineering blog, product/developer document, OSS repository/documentation page, or research paper.
- The URL was opened successfully on 2026-07-15 and its content was available.
- The finding attributed to it is supported by the page itself, with inference labeled as inference.

The accepted corpus contains 19 sources. Three candidate classes were discarded: secondary explainers or mirrors, search-result snippets without an opened source page, and claims that could not be tied to a primary-source passage. Access date is recorded per source below. “Observed” statements in the companion resident-loop document are operational measurements, not claims established by this web corpus.

## Findings by axis

### 1. Memory, context persistence, and SSOT

1. Context is a finite attention budget, not an unlimited transcript. Anthropic describes context rot and recommends curating the smallest high-signal set of tokens; just-in-time retrieval and progressive disclosure keep working context focused. [A1]
2. Long-horizon continuity needs an external write path. Compaction, structured note-taking, and multi-agent context separation are complementary techniques; a memory tool can persist files across conversations and retrieve them only when needed. [A1][A2]
3. A short entry-point file should route to deeper, versioned sources of truth. OpenAI’s harness report describes a short `AGENTS.md`, a structured `docs/` knowledge base, indexed plans, and mechanical freshness checks; it also records that a monolithic instruction file became stale and hard to verify. [A3]
4. Durable execution and memory need a stable cursor and replay boundary. LangGraph checkpoints state by thread and supports fault-tolerant resume, time travel, and human inspection; OpenHands models the agent as an event-driven component that reads history and emits new events. [A4][A5]
5. Practical implication: separate durable rules and decisions, task-state narrative, and session handoff narrative. Keep one authoritative owner for each fact, record freshness or verification status, and use links rather than copying the same rule into several instruction files. The last sentence is an engineering inference from [A1][A2][A3][A4], not a claim that the sources prescribe this exact three-layer layout.

### 2. Multi-agent delegation and verification

1. Orchestrator-worker is useful when subtasks are not predictable in advance; evaluator-optimizer is useful when acceptance criteria are explicit and iterative improvement is measurable. [B1]
2. Workers should have focused contexts and bounded permissions. Claude Code documents isolated subagent context windows, custom tool access, permission modes, worktree isolation, and concise summaries returned to the parent; this reduces context pollution but does not remove the need for verification. [B3]
3. Delegation contracts need an objective, output format, tool/source guidance, and boundaries. Anthropic reports that vague instructions led to duplicate searches and gaps, while explicit effort tiers controlled how many agents and tool calls were used. [B2]
4. Central ownership and handoff are different control shapes. OpenAI’s Agents SDK distinguishes a manager that keeps the final answer and guardrails from a handoff in which a specialist becomes the active agent; code-driven orchestration is more deterministic for cost and sequence control. [B4]
5. Multi-agent fan-out has a real cost and coordination limit. Anthropic reports roughly 15x the token use of chat for its multi-agent research system, and documents early failures such as spawning 50 agents for a simple query or searching endlessly for nonexistent sources. This supports effort budgets and explicit stop criteria, not a universal agent-count recommendation. [B2]
6. Gas Town is a concrete OSS example of role separation: a Mayor coordinates, Polecats execute, and persistent work state is carried through hooks and Beads. Its architecture demonstrates one viable operating model; its README is not an independent efficacy evaluation. [B5]

### 3. Autonomous operating loops

1. A reliable loop has explicit lifecycle events and observable state transitions. Claude Code hooks expose session, tool, subagent, notification, stop, compaction, and file/configuration events; hooks are deterministic controls rather than instructions the model may or may not follow. [C1]
2. Event logs provide a useful substrate for monitoring and resumption. OpenHands describes an append-only, typed event history, atomic interruptible steps, context condensation, and a security-analysis step before action execution. [C2]
3. A safe pause is a first-class state, not an exception hidden in a prompt. LangGraph persists graph state before an interrupt, waits for external input, and resumes with the same thread ID; this is a direct pattern for human gates around destructive or ambiguous work. [C3]
4. The model/tool loop should expose execution controls such as command timeouts and a plan/update mechanism. OpenAI’s Codex loop write-up shows shell tools with explicit `timeout_ms` and a first-class plan tool; the source documents mechanics, while the recommendation to enforce a timeout budget is an engineering inference. [C4]
5. Heartbeats and patrol are separate from task completion. Gas Town gives the Deacon a persistent monitoring role and the Witness responsibility for worker health, nudging, and cleanup. A resident loop should therefore record liveness signals, worker activity, and terminal outcomes separately. [C5]
6. Self-pacing intervals and the exact three-failure threshold in the companion document are operational choices marked `[OBS]`; the external corpus supports event-driven control, checkpoints, budgets, and human interrupts, but does not establish those exact numbers. [C1][C2][C3][C4][C5]

### 4. Implementations and failure cases

1. Codex’s public harness report treats repository-local knowledge as the system of record, uses a short routing file, enforces architecture mechanically, and feeds review findings and bugs back into documentation or tooling. It also reports long runs and the need for observability feedback loops. These are documented implementation lessons, not a controlled comparison against other harnesses. [A3]
2. Claude Code exposes concrete control surfaces for a resident harness: isolated subagents, independent permissions, optional worktree isolation, lifecycle hooks, and deterministic pre-tool/stop controls. The documentation describes capabilities and configuration, not a guarantee that a given deployment will be safe. [B3][C1]
3. OpenHands separates agent reasoning, event history, tools, workspace/runtime, security analysis, and remote server concerns. Its published system paper describes the open platform and runtime approach; the current SDK documentation shows the more explicit stateless, event-driven design. [A5][C2][D1]
4. SWE-agent demonstrates that the agent-computer interface itself is a major harness design variable: tuned commands, file viewing, editing, repository search, and test execution affected benchmark outcomes. The result is evidence for investing in tool contracts and feedback shape, not evidence that one ACI generalizes to every coding task. [D2]
5. Devin’s public documentation positions it as an autonomous coding agent, recommends explicit completion criteria and well-scoped tasks, and acknowledges that difficult work should be split into smaller isolated sessions. Its release notes also record fixes for crashing, stuck, and hanging sessions. This is a practical boundary condition: autonomy is paired with scoping and verification, not treated as unlimited delegation. [D3][D4]
6. Gas Town/Beads shows the OSS direction toward persistent identities, role-specific monitors, worktree-backed state, and dependency-aware work tracking. The same architecture also illustrates a risk: more roles and state stores increase coordination surfaces, so the orchestrator needs ownership, liveness, and cleanup rules. The risk statement is an inference from the documented architecture. [B5][C5]

## Design synthesis for a resident harness

The evidence supports the following portable design rules:

| Rule | Evidence-backed rationale |
|---|---|
| Keep the entry point short and route to deeper sources | Long prompts crowd out task context; structured, indexed repository knowledge is easier to inspect and refresh. [A1][A3] |
| Persist facts outside the active context | Memory files, checkpoints, and event histories make succession, replay, and recovery possible. [A2][A4][A5][C2] |
| Assign one owner to each class of state | Copying rules across files creates stale contradictions; this is an inference from the documented drift and context-management failures. [A3] |
| Delegate only bounded, independently useful work | Orchestrator-worker and manager-as-tool patterns preserve synthesis while clean contexts reduce noise. [B1][B2][B3][B4] |
| Make verification criteria explicit | Evaluator loops, tool feedback, tests, and human gates need observable pass/fail conditions. [B1][B2][C3] |
| Treat liveness, progress, and completion as different signals | Hooks, event logs, heartbeats, and patrol roles expose different lifecycle facts. [C1][C2][C5] |
| Put budgets and stop states in the runtime | Multi-agent costs grow quickly; timeouts, interrupts, checkpoints, and explicit effort tiers prevent open-ended work. [B2][C3][C4] |
| Increase autonomy only after observability and rollback exist | Public implementations pair autonomous execution with sandboxing, security checks, review loops, or scoped sessions. [A3][A5][C2][D3] |

## Source list

All sources below were opened successfully on 2026-07-15. Summaries are paraphrases; no source is treated as a blanket endorsement of the design synthesized here.

### Axis 1 sources

#### [A1] Anthropic — Effective context engineering for AI agents

URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents

- Defines context as a finite resource with diminishing returns and describes context rot.
- Recommends just-in-time retrieval, progressive disclosure, compaction, and structured note-taking for long-horizon tasks.
- Supports treating memory and context selection as runtime engineering rather than prompt-writing alone.

Access checked: 2026-07-15.

#### [A2] Anthropic — Memory tool

URL: https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool

- Describes file operations that persist across conversations and sessions.
- Uses just-in-time retrieval so the active context does not contain the entire memory store.
- Makes storage client-controlled and calls out path restrictions as a security boundary.

Access checked: 2026-07-15.

#### [A3] OpenAI — Harness engineering: leveraging Codex in an agent-first world

URL: https://openai.com/index/harness-engineering/

- Reports a production-like internal experiment in which Codex generated the product and its supporting artifacts.
- Treats structured repository documentation as the system of record and uses a short `AGENTS.md` as a map.
- Describes mechanical linting, feedback loops, observability, stale-document cleanup, and explicit architectural boundaries.

Access checked: 2026-07-15.

#### [A4] LangChain — LangGraph persistence

URL: https://docs.langchain.com/oss/python/langgraph/persistence

- Saves graph state as checkpoints organized by a stable thread identifier.
- Uses persistence for memory, human-in-the-loop review, time-travel debugging, and fault-tolerant resume.
- Documents pending-write recovery so successful work in a failed super-step need not be repeated.

Access checked: 2026-07-15.

#### [A5] OpenHands — Agent architecture

URL: https://docs.openhands.dev/sdk/arch/agent

- Defines an autonomous reasoning-action loop that combines LLM queries, tools, context management, and security validation.
- Uses a stateless, event-driven step model that can be paused and resumed.
- Includes a condenser for history compression as context limits approach.

Access checked: 2026-07-15.

### Axis 2 sources

#### [B1] Anthropic — Building effective AI agents

URL: https://www.anthropic.com/engineering/building-effective-agents

- Describes orchestrator-worker and evaluator-optimizer patterns with explicit fit criteria.
- Emphasizes ground truth from tool results, checkpoints for human feedback, and maximum-iteration stopping conditions.
- Recommends simplicity, transparency, and careful agent-computer interfaces before adding orchestration complexity.

Access checked: 2026-07-15.

#### [B2] Anthropic — How we built our multi-agent research system

URL: https://www.anthropic.com/engineering/multi-agent-research-system

- Reports lead-agent and parallel-subagent architecture, including separate context windows and condensed handoffs.
- Records failure modes such as 50-agent over-spawning, duplicate work, endless searches, and coordination complexity.
- Gives concrete effort tiers, source-quality evaluation criteria, artifact handoffs, and a measured token-cost tradeoff.

Access checked: 2026-07-15.

#### [B3] Claude Code — Create custom subagents

URL: https://code.claude.com/docs/en/sub-agents

- Provides isolated context windows, custom prompts, tool allow/deny lists, permission modes, and optional worktree isolation.
- Recommends subagents for noisy side work so only a summary returns to the parent context.
- States that subagents cannot recursively spawn other subagents, making the delegation graph bounded by the parent.

Access checked: 2026-07-15.

#### [B4] OpenAI Agents SDK — Agent orchestration

URL: https://openai.github.io/openai-agents-python/multi_agent/

- Distinguishes LLM-directed orchestration from code-directed orchestration.
- Compares manager-style agents-as-tools with handoffs to a specialist that takes over.
- Lists code-level chaining, evaluator loops, and parallel execution as deterministic orchestration options.

Access checked: 2026-07-15.

#### [B5] Gas Town — multi-agent workspace manager

URL: https://github.com/gastownhall/gastown

- Documents a Mayor coordinator, Polecat workers, Witness/Deacon monitoring, and worktree-backed hooks.
- Integrates Beads as structured, persistent work tracking and describes Convoys for grouped assignments.
- Presents an OSS operating model with persistent identities and ephemeral worker sessions; it does not provide an independent efficacy evaluation.

Access checked: 2026-07-15.

### Axis 3 sources

#### [C1] Claude Code — Automate actions with hooks

URL: https://code.claude.com/docs/en/hooks-guide

- Exposes deterministic lifecycle hooks for session start, tool calls, notifications, subagents, compaction, and stop.
- Allows hooks to format, audit, inject context, block actions, or notify a human.
- Separates deterministic command hooks from model-based judgment hooks.

Access checked: 2026-07-15.

#### [C2] OpenHands — Events architecture

URL: https://docs.openhands.dev/sdk/arch/events

- Models events as immutable, typed records in an append-only history.
- Separates recoverable tool errors from terminal conversation errors and exposes pause/condensation events.
- Lets observers monitor the same event stream without mutating agent state.

Access checked: 2026-07-15.

#### [C3] LangChain — LangGraph interrupts

URL: https://docs.langchain.com/oss/python/langgraph/interrupts

- Pauses graph execution at a dynamic interrupt and persists state before waiting.
- Resumes by reusing a thread identifier and supplying an external decision.
- Calls out idempotence and replay considerations for side effects around interrupts.

Access checked: 2026-07-15.

#### [C4] OpenAI — Unrolling the Codex agent loop

URL: https://openai.com/index/unrolling-the-codex-agent-loop/

- Shows the shell tool contract, including a working directory and command timeout field.
- Describes a first-class plan tool and the input items inserted before a user message.
- Provides a public implementation-level view of the tool loop rather than only a product description.

Access checked: 2026-07-15.

#### [C5] Gas Town — Architecture

URL: https://docs.gastownhall.ai/design/architecture/

- Separates town-level coordination beads from rig-level project implementation beads.
- Assigns persistent roles to Mayor, Deacon, Witness, and Refinery, with ephemeral Polecat workers.
- Makes liveness monitoring, nudging, cleanup, and merge verification explicit responsibilities.

Access checked: 2026-07-15.

### Axis 4 sources

#### [D1] OpenHands — An Open Platform for AI Software Developers as Generalist Agents

URL: https://arxiv.org/abs/2407.16741

- Presents an open platform for agents that write code, use a command line, and browse the web.
- Describes an event-stream architecture separating agent logic, state, and runtime interaction.
- Provides a research implementation reference for sandboxed software-engineering agents, not a guarantee of production reliability.

Access checked: 2026-07-15.

#### [D2] SWE-agent — Agent-Computer Interfaces Enable Automated Software Engineering

URL: https://arxiv.org/abs/2405.15793

- Treats the agent-computer interface as a first-class design variable for coding agents.
- Evaluates repository navigation, editing, and test execution on SWE-bench and HumanEvalFix.
- Shows that tool and feedback design can materially change agent outcomes, while benchmark results remain task- and setup-dependent.

Access checked: 2026-07-15.

#### [D3] Devin — Introducing Devin

URL: https://docs.devin.ai/get-started/devin-intro

- Describes an autonomous software engineer that writes, runs, tests, and reviews code.
- Recommends explicit completion criteria, verifiable outcomes, and well-scoped task decomposition.
- States that complex work is harder and should be split into smaller isolated sessions; the documentation also labels Devin as a junior engineer with limitations.

Access checked: 2026-07-15.

#### [D4] Devin — 2024 release notes

URL: https://docs.devin.ai/release-notes/2024

- Records product changes for planning mode, multi-session APIs, and parallel Devin sessions.
- Explicitly records fixes for crashing, stuck, and hanging Devins as an operational failure class.
- Shows why release notes are useful evidence for lifecycle reliability, while not supplying an independent failure-rate estimate.

Access checked: 2026-07-15.

## Limitations and unverified areas

- Vendor sources are partly self-reported engineering guidance, so measured improvements are not directly comparable across vendors.
- The corpus does not establish that a resident master/worker design is optimal for every repository, team size, model, or risk profile.
- Exact pacing values, context thresholds, heartbeat intervals, and three-failure circuit-breakers in the companion document are operational choices marked `[OBS]`, not externally validated constants.
- No independent longitudinal study here verifies memory drift rates, handoff fidelity, cost break-even points, or the safety of autonomous merge/deploy behavior.
- OSS architecture documents describe intended roles and control flow; they do not prove that all deployments preserve those boundaries under failure or adversarial input.
- The supplied JSONL material was intentionally not used as evidence because it was unrelated to this research question and had not been source-verified.
