# Planning Workflow

`.planning/` holds GSD execution state. It does not replace the LLM wiki.

## Structure

| Path | Purpose |
|---|---|
| `quick/` | Small tasks below phase level that you cannot afford to lose |
| `todos/pending/` | Candidates to run that have not started yet |
| `todos/doing/` | Small execution items in progress |
| `todos/done/` `todos/completed/` | Finished items |
| `threads/` | Discussions whose conclusion is still open |
| `seeds/` | Low-confidence ideas |
| `workstreams/` | Large work flows that span multiple phases |

## Promotion criteria

GSD outputs are execution state. Promote closed decisions to `docs/wiki/decisions/`, recurring operational rules to `docs/wiki/guides/`, and incidents and lessons to `docs/wiki/postmortem/`.

When a question stays open, do not turn it into an ADR. Put it in `threads/` first.
