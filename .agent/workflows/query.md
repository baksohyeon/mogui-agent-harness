---
id: workflow-query
title: "Query Workflow: search order"
type: workflow
created_at: YYYY-MM-DD
created_by: "@git_author"
updated_at: YYYY-MM-DD
last_verified_at: YYYY-MM-DD
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: "@git_author"
    note: "Generic starter workflow."
status: active
tags: [workflow, query, search, wiki]
relations: []
code_refs: []
---

# Workflow: Query: knowledge, code, and decision search order

The search order to follow when answering about knowledge, code, or decisions.

Search-tool selection principle:

- No cloud indexer. This is a small project, so avoid external dependencies.
- The active search paths in this repo are the code-review-graph MCP, the wiki frontmatter and links, and ripgrep.
- Narrow in this order: **code-review-graph (code structure) + docs/wiki (decisions and operating knowledge) + ripgrep (last resort)**.

---

## 1. Code structure, symbols, dependencies: `code-review-graph` MCP

| Question type                              | MCP tool                                          |
| ------------------------------------------ | ------------------------------------------------- |
| "Is the graph up to date?"                 | `list_graph_stats_tool`                           |
| "Impact radius of changing X"              | `get_impact_radius`                               |
| "Which flows does this change touch?"      | `get_affected_flows_tool`                         |
| "I need the detail of a specific flow"     | `get_flow_tool`                                   |
| "Find something by name in the repo graph" | `cross_repo_search_tool`                          |
| "Show me large functions or files"         | `find_large_functions_tool`                       |
| "Show me structural gaps"                  | `get_knowledge_gaps_tool`                         |
| "The graph needs refreshing"               | `build_or_update_graph_tool`                      |

---

## 2. Decisions and design rationale: `docs/wiki/`

| Question type                              | Location                                             |
| ------------------------------------------ | ---------------------------------------------------- |
| "Why was X decided?"                       | `docs/wiki/decisions/D-*.md`                       |
| "Full index or catalog?"                   | `docs/wiki/decisions/README.md`                      |
| "Agentic architecture?"                    | `docs/wiki/guides/02-agentic-architecture.md`        |
| "How GSD connects to the wiki?"            | `docs/wiki/guides/04-gsd-llm-wiki-agent-flow.md`     |
| "Host hook differences?"                   | `docs/wiki/guides/03-host-runtime-and-hooks.md`      |
| "Domain terms or one-page summary?"        | `.agent/Context.md` Glossary plus the related decision  |
| "Decisions and postmortems?"               | `docs/wiki/guides/05-decisions-and-postmortems.md`   |

Entry point: the [`docs/wiki/index.md`](../../docs/wiki/index.md) catalog, then Read the narrowed page.

---

## 3. Only when 1 and 2 fail: grep / find / Read

- `rg -n "<term>" src` (last resort)
- `find src -name "<pattern>"`: search by file name
- Read the file you found above

---

## Never

- `find /` or `rg /`: full-system scans (forbidden)
- Editing `.code-review-graph/wiki/*.md` directly: auto-generated, refreshes itself when code changes
- Calling cloud search tools (Pinecone, Weaviate, PageIndex SaaS): avoid external dependencies on a small project

---

## When writing the answer

- Cite the source: "per `src/...:42`, ..."
- When citing an ADR, use the `D-YYYYMMDD-<author>-<slug>` id (greppable even if a URL breaks)
- When proposing a code change, confirm the impact radius first with code-review-graph's `get_impact_radius_tool`

---

## Related

- [Session start workflow](session-start.md): how to scope context after the SessionStart hook
- [Ingest workflow](ingest.md): where to store new knowledge
- [Lint workflow](lint.md): the quality-check checklist
- [Agentic architecture](../../docs/wiki/guides/02-agentic-architecture.md): the layer structure
