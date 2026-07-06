---
id: guide-onboarding
title: "Onboarding: Starting Point for People and New AI Sessions"
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
    note: "Initial onboarding guide from mogui-agent-harness."
status: active
tags: [guide, onboarding, first-session, agentic-system]
relations:
  - id: guide-agentic-architecture
    label: next
code_refs:
  - file: CLAUDE.md
    note: "Claude Code router."
  - file: AGENTS.md
    note: "Codex router."
  - file: .cursor/rules/agentic-router.mdc
    note: "Cursor project rule adapter."
---

# Onboarding: Starting Point for People and New AI Sessions

This document puts new teammates and new AI sessions on the same starting line. You do not need to memorize GSD, ADR, or wiki workflow. When you make a request in natural language, the agent should first recommend a work size and a storage location.

## Fresh Clone

```bash
bash scripts/setup.sh
```

Add project-specific dependency install commands to fit this repo.

## Startup Order for a New AI Session

1. Read the current host router.
2. Read `.agent/Instructions.md`, `.agent/Context.md`, and `.agent/Memory.md` directly.
3. For code structure questions, check code-review-graph MCP first.
4. For decision rationale or operating rules, check `docs/wiki/decisions/` and `docs/wiki/guides/`.
5. To pick up execution state, check `.planning/README.md` and the relevant workstream or thread.

## Per-Host Starting Points

| host | entrypoint |
|---|---|
| Claude Code | `CLAUDE.md`, `.claude/settings.json`, hooks |
| Codex | `AGENTS.md`, `.codex/` local config |
| Cursor | `.cursor/rules/agentic-router.mdc`, `.cursor/mcp.json`, `.cursorrules` fallback |
| Windsurf/other | `.windsurfrules` or explicit prompt |

Cursor does not run the Claude Code hook chain. `.cursor/rules/agentic-router.mdc` takes that role. This project rule adapter makes Cursor read the three `.agent` files. In a fresh Cursor chat, confirm which `.agent` files were read.

## When the User Says Anything at All

The agent first recommends one of the following.

| input type | storage/execution location |
|---|---|
| small change that finishes right away | direct or fast |
| small task you must not forget | `.planning/quick/` |
| execution candidate | `.planning/todos/` |
| question with an open conclusion | `.planning/threads/` |
| low-confidence idea | `.planning/seeds/` |
| multi-step work | `.planning/workstreams/` |
| closed decision | `docs/wiki/decisions/D-*.md` |
| repeated operating rule | `docs/wiki/guides/` |
| incident, debugging, long lesson | `docs/wiki/postmortem/` |
| long session handoff | `docs/wiki/postmortem/temp/` |

## Adding a New Member

When a new collaborator joins:

1. Set their own git identity: `git config user.name` / `user.email`. After that, when they commit, the frontmatter author fills in automatically (no registration step).
2. Add a one-line role to Key People in `.agent/Context.md`.
3. If the team uses a handle policy, follow the format defined in `.agent/Instructions.md` § Author identity & handle policy.

Copy-paste prompts for onboarding and adding members live in `PROMPTS.md` "3. Co-worker onboarding + add member".

## Check After Work

```bash
bash scripts/verify-agent-ssot.sh
bash scripts/wiki-lint.sh
git diff --check
```

`wiki-lint.sh` checks `docs/wiki/` consistency (requires python3). After important guides, ADRs, or postmortems, run a Review Gate Quiz of up to three questions.
