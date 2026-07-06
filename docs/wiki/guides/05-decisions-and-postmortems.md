---
id: guide-decisions-and-postmortems
title: "Decisions and Postmortems"
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
    note: "Initial decision/postmortem guide from mogui-agent-harness."
status: active
tags: [guide, decisions, postmortem, adr]
relations:
  - id: schema-frontmatter
    label: references
code_refs:
  - file: docs/wiki/_schema/frontmatter.md
    note: "Metadata schema."
  - file: .agents/skills/postmortem/SKILL.md
    note: "Postmortem writing procedure."
---

# Decisions and Postmortems

Decisions and postmortems are long-term knowledge. They should be written only when the conclusion or lesson is useful beyond the current chat.

## ADR Rules

- Decisions are named `docs/wiki/decisions/D-YYYYMMDD-<author>-<slug>.md` (today's date, git author handle, short slug). No sequential number, so parallel branches never collide.
- The filesystem is the ADR SSOT.
- Open questions go to `.planning/threads/`, not ADR.
- Copy `docs/wiki/decisions/D-template.md` when creating a new decision; set the `id` and heading to match the filename.
- After writing the file, run `bash scripts/decisions-index.sh` to regenerate the index table. You do not hand-edit the index.
- ADRs should state context, decision, options, rejected alternatives, consequences, verification, reversal conditions, and follow-up actions.

Required decision fields:

```yaml
status: draft
collapsed_to: null
supersedes: []
decision_area: docs-governance
decision_subjects: [mogui-agent-harness]
decision_cluster: mogui-agent-harness
date: YYYY-MM-DD
deciders: [@git_author]
context: "<workstream, thread, PR, or incident>"
```

## Decision Compression

Date-prefixed ids need no width management. Files sort chronologically by name, and `scripts/decisions-index.sh` regenerates the index in date order.

Do not create classification subfolders under `decisions/`. Use `decision_area`, `decision_subjects`, `decision_cluster`, and index views.

When older decisions can be treated as one logical decision, create a new summary decision and set the old files to:

```yaml
status: collapsed
collapsed_to: <id of the consolidating decision>
```

The summary decision should list the old ids in `supersedes`. Do not delete or rename old decision files; they remain history, while the summary decision becomes the active SSOT.

Non-decision files removed during the same merge use an archive bundle:

```text
docs/wiki/archive/A-YYYYMMDD-<slug>/
  README.md
  files/
```

The bundle manifest records old path, archive path, and replaced_by. Active docs should link to the replacement SSOT, not to archive files.

## Prefix Convention

| prefix | path | meaning |
|---|---|---|
| `D-YYYYMMDD-<author>-<slug>` | `docs/wiki/decisions/` | closed decision |
| `guide-<slug>` | `docs/wiki/guides/` | repeatable operating rule |
| `postmortem-NNN-<slug>` | `docs/wiki/postmortem/` | incident or lesson |
| `snapshot-YYYYMMDD-<slug>` | `docs/wiki/postmortem/temp/` | handoff snapshot |
| `A-YYYYMMDD-<slug>` | `docs/wiki/archive/` | merged or retired file bundle |

## Postmortem Rules

- Use `.agents/skills/postmortem/SKILL.md` when writing a real postmortem.
- Permanent path: `docs/wiki/postmortem/NNN-YYYYMMDD-<author>-<slug>.md`.
- `<author>` comes from git author identity unless the team defines another handle policy.
- Include evidence, hypotheses, diagnosis, resolution, prevention, and timeline.

## Temp Snapshots

Use `docs/wiki/postmortem/temp/` when a long workflow needs handoff but is not a permanent incident record yet. A temp snapshot should state:

- current goal
- verified facts
- changed files
- remaining risks
- next actions
- closed decisions and open questions

## Review Gate Quiz

After important guide, ADR, or postmortem changes, ask up to three questions before commit/push/PR:

1. What did this document decide or teach?
2. What wrong assumption would cause a repeat failure?
3. Where should unresolved work go next?
