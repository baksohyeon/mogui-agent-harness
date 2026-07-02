---
id: workflow-session-start
title: "Session Start: host router, Context stdout, required reads"
type: workflow
status: active
tags: [workflow, session, start, hooks]
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_verified_at: YYYY-MM-DD
created_by: "@git_author"
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: "@git_author"
    note: "Generic starter workflow."
relations:
  - id: D-20260101-dana-example
    label: implements
---

# Session Start: host router, Context stdout, required reads

A session start does not mean "all context loads automatically." The real behavior is narrower. The host router tells the agent to read `.agent/Instructions.md`, `.agent/Context.md`, and `.agent/Memory.md`, and a hook echoes only some of those to stdout.

In Claude Code the `SessionStart` hook runs. The key behavior is that `.agent/Context.md` arrives through hook stdout. `.agent/Instructions.md` and `.agent/Memory.md` are REQUIRED NEXT READS that the agent must read directly. Blur this distinction and the next session assumes "those were probably already loaded" and misses the Memory rules.

Codex reads `AGENTS.md`. You can attach adapters and skills under Codex too, but do not assume they carry the same enforcement as Claude Code hooks. In a Codex session, follow the `AGENTS.md` instructions to read the `.agent` files directly and run the verification commands you need.

## Start order

Read the host router first. Claude Code reads `CLAUDE.md`, Codex reads `AGENTS.md`, Cursor reads `.cursor/rules/agentic-router.mdc` with the legacy fallback `.cursorrules`, and Windsurf reads `.windsurfrules`. The four files `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, and `.windsurfrules` should hold the same content. Cursor's actual project-rule adapter is `.cursor/rules/agentic-router.mdc`, so do not claim `.cursorrules` alone guarantees the behavior.

Next read `.agent/Instructions.md` for the behavior rules. Read `.agent/Context.md` for the product and current-decision digest. Read `.agent/Memory.md` for user preferences, recurring mistakes, the Review Gate Quiz, and operating rules such as postmortem/temp.

If the work is code exploration, look at the code-review-graph MCP first. If the work is a documentation judgment, look at `docs/wiki/index.md` and `docs/wiki/decisions/README.md`. If the work is taking over GSD state, look at `.planning/README.md` and the relevant workstream.

## How to read hook stdout

Hook stdout is mostly guidance. But if a line carries the `[AGENT-ASK]` prefix, it is an action trigger, not guidance. When that line appears, the agent asks the user directly, and once the user approves, runs the command the hook wrote.

The SessionStart hook does not block. The thing that actually blocks file writes is the PreToolUse hook. In this repo the representative cases are emoji and translated-slang blocking.

## Anti-patterns

The most dangerous anti-pattern is assuming "Context showed up, so Instructions and Memory must have loaded too." The second is reading all of `docs/wiki/` indiscriminately. The third is reaching for `rg` first on a code-structure question. In this repo, code-structure questions look at code-review-graph first.

## Related

- [Query workflow](query.md): how to scope context after the SessionStart hook
- [Ingest workflow](ingest.md): where to store new knowledge
- [Lint workflow](lint.md): the quality-check checklist
- [Agentic architecture](../../docs/wiki/guides/02-agentic-architecture.md): the layer structure
