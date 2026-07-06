---
id: guide-gsd-llm-wiki-agent-flow
title: "GSD + LLM Wiki Agent Flow"
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
    note: "Initial GSD/wiki flow guide from mogui-agent-harness."
status: active
tags: [guide, gsd, llm-wiki, workflow]
relations:
  - id: guide-agentic-architecture
    label: references
code_refs:
  - file: .planning/README.md
    note: "Planning slot definitions."
---

# GSD + LLM Wiki Agent Flow

GSD and the LLM wiki do not replace each other.

| layer | responsibility |
|---|---|
| GSD / `.planning` | execution state, handoff, open work |
| LLM wiki / `docs/wiki` | long-term decisions, rules, lessons |

## Natural Language Intake

When the user gives an unstructured request, the agent should classify it before writing files.

```text
request
  -> check existing decisions/guides
  -> decide size and certainty
  -> direct / quick / todo / thread / seed / workstream / ADR / guide / postmortem
  -> execute or ask the smallest necessary question
  -> verify and close or snapshot
```

## Routing Rules

| condition | route |
|---|---|
| small direct edit | direct / fast |
| small but should not be lost | `.planning/quick/` |
| executable but not immediate | `.planning/todos/` |
| unresolved decision question | `.planning/threads/` |
| low-confidence idea | `.planning/seeds/` |
| multi-step work | `.planning/workstreams/` |
| closed decision | `docs/wiki/decisions/D-*.md` |
| repeatable rule | `docs/wiki/guides/` |
| incident or workflow lesson | `docs/wiki/postmortem/` |
| long handoff | `docs/wiki/postmortem/temp/` |

## Promotion

Planning output becomes wiki truth only after review. A thread can become an ADR when the decision closes. A repeated correction can become a guide. A debugging session can become a postmortem.

## Review Gate Quiz

After important guide, ADR, or postmortem changes, ask up to three questions:

1. What decision or rule did this document establish?
2. What misunderstanding would break the system?
3. Where should the next action or open question live?
