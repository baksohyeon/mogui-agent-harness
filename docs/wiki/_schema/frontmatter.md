---
id: schema-frontmatter
title: "Frontmatter Standard"
type: schema
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
    note: "Initial wiki frontmatter schema."
status: active
tags: [schema, frontmatter, wiki]
relations: []
code_refs:
  - file: .githooks/pre-commit
    note: "Updates updated_at and substitutes @git_author in staged docs."
---

# Frontmatter Standard

This file is the SSOT for `docs/wiki/` metadata. Keep it generic for this repo. Do not copy another project's people, product facts, or historical decisions into new frontmatter. Use the placeholders below (`@git_author`, `YYYY-MM-DD`, `<slug>`, `D-YYYYMMDD-<author>-<slug>`) and let real values accrete as the wiki grows.

## Author Rule

Use git author identity for wiki author fields unless the team defines a stricter handle policy.

```bash
git config user.name
git config user.email
```

Templates use `@git_author`. The starter git hook replaces `@git_author` in staged docs frontmatter with `git config user.name`. It does not touch document body text. If a different person commits, their name is substituted. This is the collaboration automation.

## Full Schema

```yaml
---
id: <type-NNN, or D-YYYYMMDD-<author>-<slug> for decisions>  # matches the filename
title: "<human-readable title>"
type: <decision | architecture | guide | service | schema | index | postmortem | archive>

# Create / update tracking (_at and _by split)
created_at: YYYY-MM-DD
created_by: @git_author             # git author name, or @git_author placeholder
updated_at: YYYY-MM-DD
updated_by: @git_author
last_verified_at: YYYY-MM-DD
last_verified_by: @git_author

# Change history (chronological action log)
audit_log:
  - action: created                 # created | updated | verified | superseded | archived
    at: YYYY-MM-DD
    by: @git_author
    note: "Optional. One line on why."
  - action: updated
    at: YYYY-MM-DD
    by: @git_author

# State
status: <active | superseded | collapsed | pending | deprecated | archived | draft>

# Classification
tags: [tag1, tag2]

# Cross-document links (explicit, standardized labels)
relations:
  - id: guide-onboarding            # another document id (filename-based)
    label: related                  # one of the relations labels below
    note: "Optional one-liner"      # optional
  - docs/wiki/guides/some-guide.md  # OR a plain path string for a loose reference

# Code file references (recommended for decision / service docs)
code_refs:
  - file: scripts/verify-agent-ssot.sh
    note: "What this file proves or implements"
---
```

## Required vs Optional

| field | required | note |
|---|---|---|
| `id` | required | Matches filename (`D-YYYYMMDD-<author>-<slug>`, `arch-NNN`, `guide-<slug>`). Do not reuse after deletion. |
| `title` | required | |
| `type` | required | Document family. Drives linting and reading order. |
| `created_at` / `created_by` | required | |
| `updated_at` / `updated_by` | required | Last meaningful edit. |
| `last_verified_at` / `last_verified_by` | recommended | Required by lint for decisions and postmortems. |
| `audit_log` | recommended | Append-only change history. |
| `status` | required | |
| `tags` | recommended | At least one. |
| `relations` | optional | Empty array `[]` is fine. |
| `code_refs` | optional | Recommended for decision / service docs. |

## Field Meaning

| field | meaning |
|---|---|
| `id` | Stable machine-readable id. |
| `type` | Document family. Drives linting and reading order. |
| `status` | Whether the page is current truth, draft, superseded, collapsed, pending, deprecated, or archived. |
| `last_verified_at` | Last date the claims were checked against source files or commands. |
| `audit_log` | Append-only change history for meaningful updates. |
| `relations` | Links to decisions, guides, workstreams, PRs, or incident notes that explain context. |
| `code_refs` | Source files, scripts, hooks, workflows, or config files that prove or implement the claim. |

## `type` Values and id Patterns

| type | id pattern | example |
|---|---|---|
| `decision` | `D-YYYYMMDD-<author>-<slug>` | `D-20260622-alex-money-cents` |
| `architecture` | `arch-NNN` | `arch-001` |
| `guide` | `guide-<slug>` | `guide-onboarding` |
| `service` | `svc-<slug>` | `svc-spec-01` |
| `schema` | `schema-<slug>` | `schema-frontmatter` |
| `index` | `<scope>-index` | `wiki-index`, `decisions-index` |
| `postmortem` | `postmortem-NNN-<slug>` | `postmortem-001-<slug>` (file `NNN-YYYYMMDD-<author>-<slug>.md`) |
| `archive` | free | `_legacy-<scope>` |

## `status` Values

| value | meaning |
|---|---|
| `active` | Current truth. |
| `superseded` | Replaced by a later document (pair with `relations[].label: superseded-by`). |
| `collapsed` | Folded into a larger summary decision. Pair with `collapsed_to: <id>`. |
| `pending` | Parked until more evidence or a final approval exists. |
| `deprecated` | Kept for history, no longer used. |
| `archived` | Moved to `docs/wiki/archive/`. Pair with archive manifest fields. |
| `draft` | In progress. |

## `audit_log` Actions

| action | when |
|---|---|
| `created` | New file. |
| `updated` | Body or frontmatter meaning changed. |
| `verified` | Consistency check done (content unchanged, only `last_verified_at` bumped). |
| `superseded` | Replaced by another document (on status change). |
| `archived` | Moved to the archive folder. |

## `relations` Labels

Use either a plain path/id string or an object with `id` + `label` (and optional `note`). Prefer the object form when the relation is semantic.

| label | meaning |
|---|---|
| `related` | General reference. |
| `supersedes` | This document replaces another. |
| `superseded-by` | Another document replaces this one (pair with `status: superseded`). |
| `partially-superseded-by` | Only part of this is replaced; `status` may stay `active`. |
| `narrowed-by` | A later decision narrows this scope. |
| `supplemented-by` | A later decision adds options in the same area. |
| `references` | Citation / external reference. |
| `depends-on` | This decision depends on another decision. |

```yaml
relations:
  - id: D-YYYYMMDD-<author>-<slug>
    label: depends-on
  - id: guide-host-runtime-and-hooks
    label: references
```

## `code_refs` Shape

```yaml
code_refs:
  - file: scripts/verify-agent-ssot.sh
    note: "Verifies router, hook, and stale-wording guard."
```

Only cite files that exist in the repo, unless the point is explicitly about an external tool or user-local path.

## Decision Page (`type: decision`)

Use `docs/wiki/decisions/D-YYYYMMDD-<author>-<slug>.md` (today's date, git author handle, short slug). The filesystem is the SSOT; there is no sequential number to coordinate.

Decision frontmatter adds:

```yaml
id: D-YYYYMMDD-<author>-<slug>
type: decision
status: active
decision_area: docs-governance     # single primary classification
decision_subjects: [example-subject]   # lowercase-kebab free tags
decision_cluster: example-cluster      # stable grouping key, or null
collapsed_to: null                 # target <id> when status: collapsed
supersedes: []                     # id list this decision collapses or replaces
```

`decision_area` is the single primary classification. Overlapping themes go in `decision_subjects`.

| `decision_area` | meaning |
|---|---|
| `product-domain` | Product direction, domain language, scope, positioning. |
| `ux-flow` | User flow, screen behavior, copy policy. |
| `data-model` | DB structure, RPC schema, migration, normalization. |
| `security-rls` | Row-level security, auth, permissions, admin guards, abuse boundaries. |
| `agentic-ops` | Agent operating system (`.agent`, GSD, host runtime, code graph). |
| `docs-governance` | Wiki / docs knowledge system (ADR numbering, frontmatter, routing). |
| `sequence-meta` | Numbering and placeholder management (deprecated slots, compression). |

`decision_subjects` is a list of lowercase-kebab-case free tags. To point at real code files, use `code_refs` instead of inventing a new field. `decision_cluster` groups decisions that can later be compressed into one summary decision; classify with frontmatter and index views, not subfolders.

Decision `status` values reuse the common set above. `pending` means parked until evidence or approval. Open questions are not decisions, so keep them under `.planning/threads/` until closed.

Decision ids are date-prefixed (`D-YYYYMMDD-<author>-<slug>`), so they sort chronologically by name and need no width management. If the log gets long or noisy, create a summary decision, set older related decisions to `status: collapsed`, and point them at the summary with `collapsed_to`. Do not create classification subfolders under `decisions/`; classify with frontmatter and index views.

## Guide Page (`type: guide`)

Guide pages explain repeatable operating rules.

```yaml
id: guide-<slug>
type: guide
audience: <humans | agents | team | junior engineers>
```

Active guide pages must describe current rules. Historical or superseded rules belong in decisions, postmortems, archive, or raw evidence, not active guide prose.

## Postmortem Page (`type: postmortem`)

Permanent postmortems use:

```yaml
id: postmortem-NNN-<slug>
seq: <N>
type: postmortem
date: YYYY-MM-DD
context: "<workstream, PR, incident, or branch>"
audience: junior engineers
length: step-by-step
```

Filename:

```text
docs/wiki/postmortem/NNN-YYYYMMDD-<author>-<slug>.md
```

`<author>` comes from git author identity or the team handle policy. Postmortems also carry the common create/update/verify fields and `audit_log`; lint requires `last_verified_at` for this type.

### Temp Snapshot

Use `docs/wiki/postmortem/temp/` for long workflow handoff snapshots. These are not permanent incident records until promoted.

```yaml
type: postmortem
status: draft
tags: [snapshot, handoff]
context: "<long workflow or interrupted session>"
```

## Archive Manifest (`type: archive`)

Decision files stay in `docs/wiki/decisions/` even when collapsed. Non-decision files that leave active paths during a merge move to an archive bundle at `docs/wiki/archive/A-YYYYMMDD-<slug>/`. The bundle manifest `README.md` uses `type: archive`, `status: archived`, and adds:

```yaml
archive_prefix: A-YYYYMMDD-<slug>
archive_reason: "<why these files left active paths>"
archived_paths:
  - old_path: docs/wiki/guides/old-guide.md
    archive_path: docs/wiki/archive/A-YYYYMMDD-<slug>/files/old-guide.md
    replaced_by: docs/wiki/guides/current-guide.md
```

Active document links point at the new SSOT path, not the archive path. The archive bundle is for audit and recovery.

## Verification

After wiki or agentic system changes:

```bash
bash scripts/verify-agent-ssot.sh
git diff --check
```

Run `bash scripts/wiki-lint.sh` to validate this frontmatter (orphan pages, broken links, duplicate ids, dangling relations/code_refs, audit_log ordering).
