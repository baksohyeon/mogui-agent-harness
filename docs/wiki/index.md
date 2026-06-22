---
id: wiki-index
title: "Wiki Index"
type: index
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
    note: "agentic-starter skeleton"
status: active
tags: [wiki, index]
relations: []
code_refs: []
---

# Wiki Index

This wiki is long-term knowledge that the next session and other AI hosts will read again.

| Area | Location | Criteria |
|---|---|---|
| Decisions | [decisions/README.md](decisions/README.md) | Closed decisions that are expensive to reverse |
| Guides | [guides/README.md](guides/README.md) | Operating rules you follow repeatedly |
| Postmortems | `postmortem/` | Incidents, friction, lessons from long workflows |
| Temp snapshots | `postmortem/temp/` | Handoff snapshots for long-running work |
| Schema | [_schema/frontmatter.md](_schema/frontmatter.md) | Wiki frontmatter standard |
| Archive | [archive/README.md](archive/README.md) | Bundles of merged or retired files |

For code structure, check the code-review-graph MCP first. This wiki covers the reasoning behind decisions and operating rules.

Guides to read first:

1. [Onboarding](guides/01-onboarding.md)
2. [Agentic Architecture](guides/02-agentic-architecture.md)
3. [Host Runtime and Hooks](guides/03-host-runtime-and-hooks.md)
4. [GSD + LLM Wiki Agent Flow](guides/04-gsd-llm-wiki-agent-flow.md)
5. [Decisions and Postmortems](guides/05-decisions-and-postmortems.md)
6. [Maintenance](guides/maintenance.md)
