---
type: workflow
status: active
tags: [workflow, automation, feature-dev, hotfix, review, daily-report]
updated: YYYY-MM-DD
---

# Workflow: Automation Patterns, 4 Recurring Tasks

This file formalizes frequently recurring task patterns as workflow templates. Once [`/scope`](../../.claude/commands/scope.md) judges the task type, it branches into one of the 4 patterns below.

Where [`triple-crown.md`](./triple-crown.md) runs a 5-phase cycle by size, this file sorts work into 4 patterns by task character. The two complement each other: size decides how far to run, character decides which pattern to take.

## Trigger: 4 Workflow Patterns

| Pattern | Triggering user instruction | Triple Crown mapping |
|---|---|---|
| 1. Feature development pipeline | "build feature X" | full Triple Crown (extra large) or large |
| 2. Bug hotfix | "[urgent] bug X" | Phase 1 condensed → Phase 3 → Phase 4 (urgent mode) |
| 3. Code review automation | "review PR #N" | Phase 4 only |
| 4. Daily progress report | "today's status" | report only (no code changes) |

## Pattern 1: Feature Development Pipeline

**Input**: "build feature X (support Y and Z, plus a W screen)"

**Phase 1: Research + design (can run in parallel)**

| Track | Command / output |
|---|---|
| Technical research | candidate libraries / stack comparison → research note in the appropriate place under `docs/wiki/` |
| UI design | wireframe / component draft → the project's design artifact location |

**Phase 2: Architecture design**

Use the research and UI output as input, then write a design note in `docs/wiki/`. Include API endpoints, data model, and flow.

**Phase 3: Implementation**

Apply Triple Crown Phase 3. Prefer `superpowers:test-driven-development` when test infrastructure exists.

**Phase 4: Review**

Run `/review` and `/qa` (if gstack is installed). Check security, performance, and error handling.

**Phase 5: Report**

Print the work summary, key files, review results, and commit message to the user.

## Pattern 2: Bug Hotfix

**Input**: "[urgent] bug X. The user did Y but Z didn't work"

**Phase 1: Root cause analysis (immediate)**

| Step | Command |
|---|---|
| 1.1 Check recent commits | `git log --since='3 days ago' -- <related-path>` |
| 1.2 Search error logs | `rg <related-keyword> logs/` or the ops dashboard |
| 1.3 Trace code flow | `code-review-graph` MCP `get_impact_radius_tool` or `get_affected_flows_tool` |

When you find the cause, report immediately and enter Phase 2.

**Phase 2: Hotfix implementation**

Branch name: `fix/<short-desc>`. Fix plus a regression test, required.

**Phase 3: Urgent review**

`/review` focused on side effects (if gstack is installed). Add `/cso` if there is a security concern.

**Phase 4: Deploy approval**

Give the user a one-line deploy approval request: cause, fix, review, branch.

## Pattern 3: Code Review Automation

**Input**: "review PR #N" or "review this diff"

**Phase 1: Change analysis (parallel)**

| Track | Command |
|---|---|
| Changes | `gh pr diff <N>` or `git diff <base>...HEAD` |
| Code review | `/review` (gstack) or `code-review-graph` MCP `get_affected_flows_tool` |

**Phase 2: Synthesis**

Print the review results as change summary, findings, and suggestions. Submit to a PR comment or the user conversation.

## Pattern 4: Daily Progress Report

**Input**: "summarize today's status"

**Phase 1: Collection**

In a solo setup, check session history, git log, and `.planning/` state:

- `git log --since=yesterday --author=$(git config user.email)`
- check open work in `.planning/workstreams/`
- session activity (if needed, write one retrospective of the prior work with `/postmortem` and extract from it)

**Phase 2: Synthesis**

Use this format:

```text
Today's work
- <work item 1>
- <work item 2>

In progress
- <open workstream or unfinished task>

Planned for tomorrow
- <next step>
```

## Adapting to a Solo Setup

The original form of this workflow assumes a multi-person team plus terminal multiplexer dispatch. Adjustments for a solo setup:

- Skip all terminal dispatch (`tmux send-keys` and the like). Run the same tracks sequentially via the AI.
- Call `superpowers:dispatching-parallel-agents` (Triple Crown Phase 3) only when parallelism is actually needed.
- Do not use team setup scripts (`setup-team.sh` and the like).
- Saving workflow templates as shell scripts for frequently used patterns still applies in a solo setup.

## Subagent Commit Discipline

When you fan work out to subagents (Triple Crown Phase 3 / `superpowers:dispatching-parallel-agents`):

- **Subagents write files; the orchestrator commits.** For any multi-file or transactional change, have subagents produce files only and let the orchestrator verify, then commit atomically. A subagent that dies mid-run loses its in-process state, but files already written to disk survive — a half-finished commit made by the subagent does not, and it lands a broken intermediate in history.
- **If a subagent must commit, each commit must stand on its own.** Splitting one logical change across commits (e.g. "rename files" then "fix the references to them") leaves broken links if the run is interrupted between the two. Keep interdependent edits in a single commit.
- **On resume after a failed or backgrounded task, never assume it landed.** Verify actual state before continuing: `git log` (which commits exist), `git show --stat <sha>` (a commit's real file scope), and a completion-invariant check — grep for the very pattern the task was meant to eliminate and require zero matches.

## Never Do

- Assuming a crashed or backgrounded subagent's work landed without checking commit scope (`git show --stat`) and a completion invariant. "There is a commit" is not "the task finished."
- Slipping a code change into Pattern 4 (daily report). The report stays read-only.
- Skipping Phase 1 (root cause analysis) in Pattern 2 (hotfix) and jumping straight to Phase 2 (fix). That is the symptom band-aid trap.
- Running team-dispatch commands (`tmux send-keys`) in a solo setup.

## Related

- Slash command: [`.claude/commands/scope.md`](../../.claude/commands/scope.md)
- Triple Crown body: [`triple-crown.md`](./triple-crown.md)
