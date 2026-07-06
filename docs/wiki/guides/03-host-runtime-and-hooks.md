---
id: guide-host-runtime-and-hooks
title: "Host Runtime and Hooks"
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
    note: "Initial host runtime guide from mogui-agent-harness."
status: active
tags: [guide, runtime, hooks, claude-code, codex, cursor]
relations:
  - id: guide-agentic-architecture
    label: references
code_refs:
  - file: .claude/settings.json
    note: "Claude Code hook wiring."
  - file: .codex/hooks.example.json
    note: "Codex hook example wiring."
  - file: .cursor/rules/agentic-router.mdc
    note: "Cursor project rule adapter."
---

# Host Runtime and Hooks

Host differences are about runtime contracts, not model intelligence. They differ in which files they read automatically, which hooks they run, and at what point they can block.

## Entrypoints

| host | stable entrypoint | caveat |
|---|---|---|
| Claude Code | `CLAUDE.md`, `.claude/settings.json` | hooks can print, block, and post-process |
| Codex | `AGENTS.md`, `.codex/` local config | behavior depends on current tools and host config |
| Cursor | `.cursor/rules/agentic-router.mdc`, `.cursor/mcp.json` | no Claude hook chain; verify in a fresh Cursor chat |
| Windsurf/other | `.windsurfrules` or prompt | manual verification required |

`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules` are thin routers. Keep them in sync and under 100 lines. Cursor’s primary adapter is `.cursor/rules/agentic-router.mdc`; `.cursorrules` is legacy fallback.

## Claude Code

Claude Code can run `SessionStart`, `PreToolUse`, and `PostToolUse` hooks. In this starter, `load-context.sh` prints `.agent/Context.md` and tells the agent to read `.agent/Instructions.md` and `.agent/Memory.md` directly.

## Codex

Codex reads `AGENTS.md` and uses the tools available in the current session. Do not claim Claude Code hook behavior is guaranteed in Codex. The reliable contract is: read the router, read `.agent`, run verification commands.

## Cursor

Cursor uses project rules. This starter includes `.cursor/rules/agentic-router.mdc` with `alwaysApply: true` and `.cursor/mcp.json` for code-review-graph. Because Cursor behavior can vary by version and workspace setting, verify a fresh Cursor chat by asking which `.agent` files it read.

## Hook Output

If a hook prints an action-trigger prefix, treat it as an action, not a normal log line. `[AGENT-ASK]`: ask the user, then run the proposed command if approved. `[AGENT-BOOTSTRAP]`: the autonomous case — run the router's First-entry bootstrap flow yourself, no yes/no prompt.

## Verification

```bash
bash scripts/verify-agent-ssot.sh
git diff --check
```
