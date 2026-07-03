# Postmortem workflow

> SSOT for writing a postmortem or incident note. The `.agents/skills/postmortem/` skill and any host command are thin adapters that point here. Keep the canonical procedure in this file.

## When to use

- After debugging: capture what broke, how it was verified, what was ruled out, and why the fix or recommendation was chosen.
- Audience: junior engineers. Add short prerequisite blocks and avoid reasoning jumps.
- Default output language follows the repo language. Keep code paths, log lines, CI job names, config keys, and commands exactly as in the real system.

## Before writing

1. Collect evidence from the session and repo: symptom, environment, PR or issue numbers, commands run, relevant file paths.
2. Do not invent PR numbers, job URLs, timestamps, or log lines. Use placeholders like `PR #___` or `<run-url>` if unknown.
3. Use git author identity for author fields:

```bash
git config user.name
```

Use the lowercase handle form in filenames when practical. If the team uses another author handle policy, document it in `.agent/Instructions.md`.

4. Output path:
   - Permanent: `docs/wiki/postmortem/NNN-YYYYMMDD-<author>-<slug>.md`
   - Draft/snapshot: `docs/wiki/postmortem/temp/<YYYY-MM-DD>-<slug>.md`

5. Permanent filename convention:
   - `NNN`: next zero-padded sequence from `ls docs/wiki/postmortem/ | grep -oE '^[0-9]{3}' | sort -n | tail -1`
   - `YYYYMMDD`: incident or workflow date
   - `<author>`: git author handle, lowercase when practical
   - `<slug>`: short English kebab-case slug

## Required permanent frontmatter

```yaml
---
id: postmortem-NNN-<slug>
seq: <N>
title: "<short title>"
type: postmortem
date: YYYY-MM-DD
context: "<workstream, PR, incident, or branch that triggered this note>"
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
    note: "<why this was written>"
status: active
tags: [postmortem, incident]
relations: []
code_refs: []
---
```

Draft snapshots may use the same fields with `status: draft`.

## Body section order

1. Incident summary: cause and effect in one or two sentences.
2. Prerequisites: only concepts needed to read the note.
3. Symptom: what was observed, with exact errors or command output where useful.
4. First questions and hypotheses: table with `H1`, `H2`, ordered cheapest/highest-signal first.
5. Diagnosis: commands run, trimmed verbatim output, and which hypothesis each result supports or rejects.
6. Resolution or recommendation: what changed, what did not change, and why.
7. Prevention and operating notes: checklist, guard, test, guide, hook, or explicit "none". Each item is graduated in the Promotion step.
8. Timeline: short chronological bullets.
9. Promotion (graduation): pick a home for each prevention item, record the approval-free ones, link both ways, and todo the rest. Placed after the timeline, before the appendix.
10. Appendix: command cheat sheet if shell/CLI commands were important.

## Promotion (graduation)

Writing the postmortem is not the improvement; graduating its lessons to a durable home is. After the timeline and before the appendix, add a "Promotion (graduation)" section and run these four steps on every prevention item from the prevention section:

1. Pick a home: assign each item to one of `workflow-rule` (a rule added to `.agent/workflows/<name>.md`), `guide` (`docs/wiki/guides/`), `ADR` (`docs/wiki/decisions/D-*.md`), `hook`/`test` (automation under `.claude/hooks/` or the test suite), or `none` (by design).
2. Record it for real: for approval-free homes (workflow rule, hook, test, operational guide rule), make the change in that file now. Listing a candidate and stopping is not graduation.
3. Link both ways: add the rule path to the postmortem `relations:`, and add a back-link to this postmortem in the rule file. A one-way link is invisible to the next agent.
4. Do not drop the rest: items you cannot graduate now (especially approval-required ones) go to `.planning/todos/` so they are not lost. Only `none` (by design) closes without a todo.

Keep the approval gate. Meaning-changing wiki promotions (ADR, long-term context, memory) are not recorded in step 2 without user approval — hold them as a candidate plus a todo until approved. Only cheap-to-reverse homes (workflow rules, hooks, tests, operational guide rules) graduate immediately. For promotion criteria and procedure, follow [guide 05 (decisions and postmortems)](../../docs/wiki/guides/05-decisions-and-postmortems.md).

Draft snapshots in `postmortem/temp/` may omit the Promotion section; fill it in and run the four steps when moving to the permanent location.

## Writing rules

- Graduate, do not just list: every prevention item gets a home, a real change (for approval-free homes), and a two-way link.
- Observation, then interpretation, then next step. Do not skip reasoning links.
- Prefer primary sources: repo files, workflow YAML, CLI output, API responses.
- State explicitly what was not verified.
- For every decision, write the chosen option, the rejected alternative, and the evidence.
- No blame. Name systems and interfaces.
- Keep the note reusable for the next agent and for a junior teammate.

## Output contract

- Deliver one Markdown file unless the user asks for more.
- Do not add unrelated refactors or extra documentation files.
