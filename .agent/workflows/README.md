---
id: workflow-index
title: ".agent workflows index"
type: workflow-index
status: active
updated: YYYY-MM-DD
---

# .agent workflows index

`.agent/workflows/` holds procedures the agent runs repeatedly. This folder is repo operating procedure, not a skill library. A new agent reads only the workflow it needs.

- `session-start.md`: what a new session loads automatically versus what the agent must read directly. The key point is that Context arrives via hook stdout while Instructions and Memory are required next reads.
- `query.md`: the search order for code, decisions, and operating knowledge. Check the code-review-graph MCP first for code structure, the wiki for decisions and rules, and ripgrep last.
- `ingest.md`: where to put new input. It splits intake into GSD slots (quick/todo/thread/seed/workstream) and wiki promotion (ADR/guide/postmortem).
- `lint.md`: which checks to run after doc or wiring changes (`bash scripts/wiki-lint.sh`, `bash scripts/verify-agent-ssot.sh`, `git diff --check`).
- `triple-crown.md`: the larger workflow that uses gstack, GSD, and Superpowers together. It scales by size (fast, quick, phase, workstream) and does not force GSD on every task.
- `automation-patterns.md`: how hooks and automation support agent behavior, by work type.
- `daily-triage.md`: one run of the read-only L1 triage loop. The loop contract (registry, budgets, kill switch, L1→L3 maturity ladder) lives in [`.agent/loops/LOOP.md`](../loops/LOOP.md).

Three procedures also live as invocable skill adapters in `.agents/skills/`, with their canonical content here:

- `postmortem.md`: how to write an evidence-based incident note.
- `scope.md`: how to judge work size and recommend an operating unit.
- `daily-triage.md`: read-only repo health sweep on a cadence (loop engineering, L1).
