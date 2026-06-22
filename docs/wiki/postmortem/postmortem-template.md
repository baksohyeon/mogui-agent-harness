---
id: postmortem-template
seq: 0
title: "Postmortem Template"
type: postmortem
date: YYYY-MM-DD
context: "<workstream, PR, incident, or branch>"
audience: junior engineers
length: step-by-step
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
    note: "Template copied for a new postmortem."
status: draft
tags: [postmortem]
relations: []
code_refs: []
---

# Postmortem Template

## One-line incident summary

State the cause and impact in one or two sentences.

## 0. Prerequisites

Summarize only the concepts needed to read this.

## 1. Symptoms

What you observed: behavior, errors, logs, command output.

## 2. First questions and hypotheses

| Hypothesis | Why it could be true | How to confirm it |
|---|---|---|
| H1 |  |  |

## 3. Diagnosis: check the actual state

The commands and output, and which hypotheses they support or reject.

## 4. Conclusion / resolution

State the option chosen, the alternatives dropped, and the rationale.

## 5. Prevention / operational notes

A hook, guide, test, checklist, or an explicit "none".

## 6. Timeline

- YYYY-MM-DD HH:MM: observed.

## Appendix: command list

If CLI diagnostics mattered, regroup them by purpose.
