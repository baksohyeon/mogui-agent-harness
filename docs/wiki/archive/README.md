---
id: archive-index
title: "Archive Index"
type: index
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
    note: "Initial archive index from mogui-agent-harness."
status: active
tags: [archive, wiki]
relations: []
code_refs: []
---

# Archive Index

Archive is not the active wiki. It stores merged, retired, or evidence files so the team can audit or recover them later.

## Prefix Convention

Archive bundle prefix: `A-YYYYMMDD-<slug>`.

```text
docs/wiki/archive/A-YYYYMMDD-<slug>/
  README.md
  files/
```

## Bundle Manifest

Each bundle `README.md` records:

| field | meaning |
|---|---|
| `archive_prefix` | bundle id |
| `archive_reason` | why files left active paths |
| `archived_paths` | old path, archive path, replacement path |

Active docs should point at the replacement SSOT, not at archive files.
