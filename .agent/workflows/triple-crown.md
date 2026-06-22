---
type: workflow
status: active
tags: [workflow, triple-crown, gstack, gsd, superpowers]
updated: YYYY-MM-DD
---

# Workflow: Triple Crown, 5-Phase Cycle

This protocol chains three tools (gstack for strategy, GSD for structure, Superpowers for quality) across 5 phases: strategy, structuring, implementation, verification, and completion. Task size sets how far through the phases a task runs.

## Trigger: Recommended Combinations by Task Size

| Size | Signal | Tool combination | Phases applied |
|------|------|----------|-----------|
| Small (1 hour) | one-liner, typo, config | do it directly, no tools | Phase 0 only |
| Medium (half day) | bug fix, small feature | gstack | 3, 4, 5 condensed |
| Large (1-3 days) | new feature module, API | gstack + Superpowers | 1, 3, 4, 5 |
| Extra large (1 week+) | new service, large refactor | full Triple Crown | 1 through 5 |

The size call can be overridden by the user.

## Phase 0: Immediate Judgment (Common Entry)

One line of questions: what kind of change, what is the impact radius, what is the cost to revert, what is the size. If the answers are obvious (small/medium), start work immediately; if ambiguous, go to Phase 1.

## Phase 1: Strategy (gstack)

| Step | Command | Output |
|------|------|------|
| Value and security review | `/cso` (security audit), `/plan-ceo-review` (value) | priority and scope adjustment |
| Auto-generate plan | `/autoplan` | task breakdown per phase |

## Phase 2: Structuring (GSD)

| Step | Command | Output |
|------|------|------|
| Create project | `/gsd-new-project` or the equivalent GSD call on the current host | `.planning/PROJECT.md` |
| Plan phase | `/gsd-plan-phase <N>` or the equivalent GSD call on the current host | `.planning/phases/<N>/PLAN.md` |

## Phase 3: Implementation (GSD + Superpowers)

| Step | Command |
|------|------|
| Execute phase | `/gsd-execute-phase <N>` or the equivalent GSD call on the current host |
| TDD for new features | `superpowers:test-driven-development` |
| Bug analysis | `superpowers:systematic-debugging` |

## Phase 4: Verification (GSD + gstack)

| Step | Command |
|------|------|
| GSD verification | `/gsd-validate-phase <N>`, `/gsd-verify-work` or the equivalent GSD call on the current host |
| Code review | `/review` → `/simplify` → `/review-pr` |
| QA | `/qa` |

GSD verification = "did we do everything we planned" / gstack verification = "does what we built actually work". Both are needed.

## Phase 5: Completion (gstack + GSD)

| Step | Command |
|------|------|
| Prepare for deploy | `/ship` (open a PR after confirming the base branch) |
| Update progress | `/gsd-progress`, `/gsd-complete-milestone` or the equivalent GSD call on the current host |
| Decide on ADR promotion | (human judgment) lock-in decision → `docs/wiki/decisions/D-*.md` |
| Retrospective (recommended) | `/postmortem` |

## Never Do

- Auto-start Phases 1 through 5 without sizing the task. Running the full Triple Crown on a small task is a loss.
- Forcing TDD in Phase 3 when there is no test infrastructure. State a manual test fallback.
