---
id: guide-agentic-architecture
title: "Agentic Architecture: .agent · .planning · docs/wiki"
type: guide
created_at: YYYY-MM-DD
created_by: @git_author
updated_at: YYYY-MM-DD
updated_by: @git_author
last_verified_at: YYYY-MM-DD
last_verified_by: @git_author
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: @git_author
    note: "Initial architecture guide from agentic-starter."
status: active
tags: [guide, architecture, agentic-system, llm-wiki]
relations:
  - id: guide-onboarding
    label: references
code_refs:
  - file: .agent/Instructions.md
    note: "Session behavior rules."
  - file: .planning/README.md
    note: "Execution-state layer."
  - file: docs/wiki/index.md
    note: "Long-term knowledge layer."
---

# Agentic Architecture: .agent · .planning · docs/wiki

This system does not expect the AI to remember on its own. It separates session rules, execution state, and long-term knowledge across the file system.

```text
host router
  -> .agent/      session operating rules and compressed context
  -> .planning/   GSD execution state and handoff slots
  -> docs/wiki/   human-approved long-term knowledge
  -> code-review-graph MCP  code structure graph
```

## `.agent/`

`.agent/` defines how the agent behaves in the current session. Do not put original product decisions or long meeting notes here.

| file | role |
|---|---|
| `.agent/Instructions.md` | behavior rules, safety rules, memory protocol |
| `.agent/Context.md` | product/team/stack/current decisions summary |
| `.agent/Memory.md` | user preferences and repeated corrections |
| `.agent/workflows/` | reusable operating workflows |

## `.agents/` (plural, thin adapters)

`.agents/skills/` holds invocable skill adapters (`postmortem`, `scope`). They are deliberately thin: the canonical procedure lives in `.agent/workflows/` (the SSOT), and each skill file just points there. This keeps the system from depending on the `.agents/` directory, which some hosts auto-create. The router files follow the same pattern: thin entrypoints, SSOT in `.agent/`. Do not confuse `.agents/` (plural, optional skill adapters) with `.agent/` (singular, the context SSOT), and do not rename `.agents/`.

## `.planning/`

`.planning/` is execution state. GSD workstreams, quick, todo, thread, and seed go here. A plan in progress is not wiki truth.

## `docs/wiki/`

`docs/wiki/` is human-approved long-term knowledge.

| path | role |
|---|---|
| `decisions/` | closed decisions |
| `guides/` | repeatable rules and operating guides |
| `postmortem/` | incidents, debugging notes, workflow lessons |
| `postmortem/temp/` | handoff snapshots |
| `_schema/` | metadata contracts |

## code-review-graph MCP

code-review-graph MCP is not a document search engine. It is a tool for seeing code structure, imports, call relationships, and the impact range of a change. Find decision rationale and operating rules in the wiki.

## Common Failure Modes

- Leaving an important decision only in chat.
- Locking an open question into an ADR.
- Treating a plan in progress as wiki truth.
- Leaving stale guide text as if it were the current rule.
- Ending a long session without leaving a temp snapshot.
