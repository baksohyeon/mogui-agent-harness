---
id: workflow-ingest
title: "Ingest: classify new input and promote to the wiki"
type: workflow
status: active
tags: [workflow, ingest, wiki, gsd, promotion]
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_verified_at: YYYY-MM-DD
created_by: "@git_author"
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: "@git_author"
    note: "Generic starter workflow. Consolidates ingest and docs-workflow."
relations:
  - id: guide-gsd-llm-wiki-agent-flow
    label: implements
  - id: D-20260101-dana-example
    label: implements
---

# Ingest: classify new input and promote to the wiki

When a new fact, decision, pattern, or piece of feedback arrives, do not write it straight into the wiki. First split it into execution state, long-term knowledge, or an open question. Meeting notes, QA results, PM artifacts, long free text, and GSD phase artifacts are not wiki truth on arrival.

## Step 1: classify the raw context

Keep long input that you may revisit later as a thread or a GSD capture. Very short input you can handle immediately can finish as a fast task.

## Step 2: choose the GSD slot

Handle small, immediately actionable work as fast. Put small work you must not lose next session in `.planning/quick/`. Put closed decisions that are execution candidates in `.planning/todos/`. Put open or recurring discussions in `.planning/threads/`. Put low-confidence candidates in `.planning/seeds/`. Raise large execution flows to a GSD workstream or phase. If the decision is not closed at this step, do not write it as an ADR.

## Step 3: decide on wiki promotion

Promote a hard-to-reverse decision to `docs/wiki/decisions/D-*.md`. Promote a procedure you must follow repeatedly to a guide. Promote an incident and its lessons to a postmortem. Before promoting, search the existing wiki and `.agent`, and verify any code-structure claim with the code-review-graph MCP.

### New ADR numbering

Decisions are named `D-YYYYMMDD-<author>-<slug>.md`. List the existing ones, then use today's date for a new one:

```bash
ls docs/wiki/decisions/D-*.md
```

Name the new file `D-YYYYMMDD-<author>-<slug>.md` (today's date, git handle, short slug). Do not hand-edit the index. After writing the ADR, run `bash scripts/decisions-index.sh` to regenerate the index.

## Step 4: approval

Do not directly change documents whose meaning shifts, `.agent/Context.md`, `.agent/Memory.md`, ADRs, or active guides without user approval. After approval, briefly report which files you changed and why.

`.agent/Memory.md` is not a meeting-notes store. Follow the Memory Update Protocol in `.agent/Instructions.md` only when the user states a recurring behavior rule such as "remember," "do not," "from now on," or "next time."

## Step 5: review the GSD slots before closing

When a task finishes, when you prepare a PR, or when you close a long session, sweep `quick/`, `todos/`, `threads/`, `seeds/`, and the current workstream again. Put finished items up as close candidates with their PR, commit, ADR, or guide as evidence, and propose each open thread as one of ADR, guide, quick, todo, phase, or keep. This review is part of the workflow, not a side task waiting for a human to remember it.

## Step 6: verify

Run `bash scripts/wiki-lint.sh` for documentation changes, `bash scripts/verify-agent-ssot.sh` for host router or `.agent` changes, and `git diff --check` on every patch, scoped to what you changed.

## Related

- [Session start workflow](session-start.md): how to scope context after the SessionStart hook
- [Query workflow](query.md): the search order
- [Lint workflow](lint.md): the quality-check checklist
- [GSD and LLM wiki agent flow](../../docs/wiki/guides/04-gsd-llm-wiki-agent-flow.md): the boundary between execution state and long-term knowledge
