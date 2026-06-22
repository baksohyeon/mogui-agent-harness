---
type: system
status: active
tags: [layer-2, context, project]
related: ["[[Instructions]]", "[[Memory]]"]
updated: YYYY-MM-DD
---

# Context

> The compressed reference context for {{product-name}}. The AI always reads this first, alongside [Memory.md](./Memory.md), before answering.

---

## About This Project

|  |  |
|--|--|
| **Product** | {{product-name}} |
| **Repo** | {{repo}} |
| **One line** | {{what the product does}} |
| **Current stage** | {{e.g. in MVP development}} |
| **Hosting** | {{e.g. Vercel}} |

**Why we build it**: {{one paragraph}}

---

## Key People

- **{{name}}**: {{role}}

---

## Tools & Stack

### Frontend
- {{framework / build}}

### Backend
- {{DB · Auth}}

### AI workflow
- **Claude Code / Codex**: the main tools for work in this repo. The root `CLAUDE.md` / `AGENTS.md` hold the rules.
- **Layer 2 master folder**: `.agent/` (tool-neutral)
- **code-review-graph MCP**: for checking code structure and impact radius. Not a document search engine.

---

## Key Decisions Summary

> SSOT = `docs/wiki/decisions/D-*.md`. Index = `docs/wiki/decisions/README.md`.

| D | Decision | Meaning |
|---|------|------|
| `D-YYYYMMDD-<author>-<slug>` | {{first decision}} | {{meaning}} |

---

## What It Does Not Do (Deliberately)

| Not doing | Reason (D number) |
|-------|-------------|
| {{out-of-scope item}} | {{D-number}} |
