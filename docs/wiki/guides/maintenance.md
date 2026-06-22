---
id: guide-maintenance
title: "Maintenance: Agentic System Health"
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
    note: "Initial maintenance guide from agentic-starter."
status: active
tags: [guide, maintenance, ssot, stale]
relations:
  - id: guide-host-runtime-and-hooks
    label: references
code_refs:
  - file: scripts/verify-agent-ssot.sh
    note: "Starter wiring and stale wording guard."
  - file: scripts/setup.sh
    note: "Idempotent setup entrypoint."
---

# Maintenance: Agentic System Health

The goal is not to make documents pretty. The goal is to prevent the next agent from believing stale rules.

## Regular Checks

```bash
bash scripts/setup.sh
bash scripts/verify-agent-ssot.sh
git diff --check
```

If this repo adds wiki lint, include it in the maintenance loop.

## What Counts As Stale

Active docs must describe current rules. Historical notes may preserve old facts, but current routers, `.agent`, active guides, setup scripts, and templates must not teach retired paths or old tool names.

Examples to guard:

- retired state files or merge-state automation
- old code-review-graph tool names
- removed host routers
- claims that all hosts have the same hook strength

## Health Checklist

- Routers point at `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`.
- Cursor has `.cursor/rules/agentic-router.mdc` and `.cursor/mcp.json`.
- Codex local files are ignored, but shared examples are tracked.
- `.planning/` and `docs/wiki/` skeleton directories keep `.gitkeep`.
- Important guide/ADR/postmortem changes get Review Gate Quiz.
- Long workflows get `docs/wiki/postmortem/temp/` snapshots.
