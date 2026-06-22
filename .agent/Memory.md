---
type: system
status: active
tags: [layer-2, memory, auto-updated]
related: ["[[Instructions]]", "[[Context]]"]
updated: YYYY-MM-DD
---

# Memory

> The learning memory log the AI updates automatically.
> Accumulates user corrections, preferences, and patterns.
> Update rules: [Instructions.md § Memory Update Protocol](./Instructions.md#memory-update-protocol)

---

## Preferences

> User preferences the AI must always follow when answering.

- YYYY-MM-DD: After writing or editing an important ADR, guide, or postmortem, and before commit/push/PR, run a Review Gate Quiz of up to 3 questions. The questions confirm the key decision, the dangerous misreading, and the next action.
- YYYY-MM-DD: After a long workflow, leave a handoff snapshot in `docs/wiki/postmortem/temp/` for the next agent.

<!-- e.g. YYYY-MM-DD: answer in Korean first, short and direct -->

---

## Corrections

> Patterns the user has explicitly flagged. Prevents repeating the same mistake.

<!-- e.g. YYYY-MM-DD: do not write "X", use "Y" instead -->

---

## Patterns

> Recurring ways of working and preferences. Unlike Corrections, these are habit-level.

<!-- e.g. YYYY-MM-DD: when adding a decision, always update the index too -->

---

## Personal Context

> Each team member's own info. Role and environment.

<!-- identify who you are by git user at session start -->
