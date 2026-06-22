---
id: workflow-lint
title: "Lint: verify wiki and agent wiring"
type: workflow
status: active
tags: [workflow, lint, health, stale, audit]
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_verified_at: YYYY-MM-DD
created_by: "@git_author"
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: "@git_author"
    note: "Generic starter workflow."
---

# Lint: verify wiki and agent wiring

When you change documentation or the operating system, check three things. Run `bash scripts/wiki-lint.sh` for wiki documents, `bash scripts/verify-agent-ssot.sh` for the host router and `.agent` wiring, and `git diff --check` for patch whitespace.

`wiki-lint.sh` checks for orphan pages, broken internal links, duplicate frontmatter ids, missing `last_verified_at`, dangling relations and code_refs, audit_log ordering, vocabulary anti-patterns, and stale operating phrasing in active docs.

The memory and wiki health from the SessionStart hook is advisory. The main protection that blocks a commit is gitleaks, frontmatter correction, and the PreToolUse emoji and translated-slang blocking.

Lint does not create decisions. New decisions are `D-YYYYMMDD-<author>-<slug>.md`; the author copies `D-template.md` and runs `bash scripts/decisions-index.sh`.

When hunting stale phrasing, separate active operating docs from historical records. Old phrasing inside decisions, postmortems, archives, or prior milestone artifacts may have been true at the time. Fix old phrasing that remains in the present tense in the root README, the router, `.agent`, active guides, setup, or templates.

## Related

- [Session start workflow](session-start.md): how the SessionStart hook works
- [Query workflow](query.md): the search order
- [Ingest workflow](ingest.md): where to store new knowledge
- [Maintenance guide](../../docs/wiki/guides/maintenance.md): the broader upkeep routine
