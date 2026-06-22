---
id: D-template
title: "First decision title"
type: decision
status: draft
collapsed_to: null
supersedes: []
decision_area: docs-governance
decision_subjects: [agentic-starter]
decision_cluster: agentic-starter
date: YYYY-MM-DD
deciders: [@git_author]
context: "<which task or discussion produced this decision>"
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
    note: "Initial decision record."
tags: [decision, adr]
relations: []
code_refs: []
---

# D-YYYYMMDD-<author>-<slug>: First decision title

> Copy this file to `D-YYYYMMDD-<author>-<slug>.md` (today's date, your git handle, a short slug), then fill it in and run `bash scripts/decisions-index.sh`. Set the `id` and the heading to match the filename.

## Decision

State what was settled.

## Background

State why this decision is needed now. If there are related workstreams, threads, PRs, or guides, link them in `relations` too.

## Options

| Option | Description | Pros | Cons |
|---|---|---|---|
| A |  |  |  |
| B |  |  |  |

## Rationale

State why this option was chosen and which alternatives were dropped.

## Rejected alternatives

| Alternative | Reason for rejection |
|---|---|
|  |  |

## Impact

State which code, docs, and operational procedures depend on this decision.

## Verification

State the evidence that confirms the decision matches the actual files, commands, and user agreement.

## Reversal conditions

State what evidence would prompt a revisit.

## Compaction / merge

If this later merges into a larger consolidating decision, change `status: collapsed` and fill in `collapsed_to: <id of the consolidating decision>`. Do not change this document's filename.

## Follow-up actions

- [ ] TODO
