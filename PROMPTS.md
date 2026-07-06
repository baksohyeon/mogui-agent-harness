# agentic-starter prompts

This file collects the runnable prompts you paste into an AI host after copying the starter into a new repo.

> To preview the conversation that actually happens after you paste, see [`docs/bootstrap-walkthrough.md`](./docs/bootstrap-walkthrough.md) (worked example).

## Pick by situation

| Situation | Prompt to use |
|---|---|
| First time on an empty new project | **1. greenfield init** |
| Adopting it on an existing project that already has code and docs | **2. ingest existing project** |
| A new coworker cloning a team repo / adding a member | **3. coworker onboarding + add member** |
| Confirming the agent actually understands the system | **4. self-orientation check** |

## 1. Apply to a new project (greenfield init)

> Assumes the starter files are already copied to your new project root (copy and setup live in the README Quick Start). `setup.sh` runs `git init` automatically if it isn't a git repo.

**Copy the block below whole and paste it into your AI host.** The AI then reads the files, asks you about the product, team, and stack, and fills the `{{...}}` placeholders. You don't have to edit files by hand before pasting. Put the product name and one-line intro in the first-line parentheses so the AI asks less and fills faster.

```text
Apply agentic-starter to this repo. (My project: {{product-name}}, {{one-line-intro}})

First read the current host router, then read `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md` directly. Then replace the `{{...}}` placeholders and `YYYY-MM-DD` based on this company project.

The four routers (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`) must stay byte-identical. Fill the placeholders in one of them, then copy the result over the other three so all four match. `verify-agent-ssot.sh` fails on router drift.

Replace `@git_author` based on `git config user.name`. Also state that postmortem filenames and frontmatter authors follow the git author or the team's handle policy, not a hardcoded personal name.

Detect this project's primary working language from how I write to you, and ask me if it is unclear. Then configure the language-specific hooks:
- If the project language is NOT Korean: remove the `no-bak-slang-check` and `remind-korean-style` hooks from `.claude/settings.json` and `.codex/hooks.example.json`, delete `.agent/korean-persona.md`, and drop the "Optional: Korean-language projects" section from the four routers. For prose quality instead, if a de-slop skill such as `stop-slop` (github.com/hardikpandya/stop-slop) is installed on this host, use it when writing docs; otherwise keep prose plain and avoid em dashes.
- If the project language IS Korean: keep those two hooks and `.agent/korean-persona.md`. If I want Korean guides, mirror `docs/wiki/guides/` into `docs/wiki/guides/ko/`.
- Keep `no-emoji-check` either way. It is language-agnostic.

Create meaningful decisions as `docs/wiki/decisions/D-YYYYMMDD-<author>-<slug>.md` by copying `D-template.md` (today's date, git author handle, short slug). After writing one, run `bash scripts/decisions-index.sh` to regenerate the index table. Put questions that aren't resolved yet in `.planning/threads/`, not in an ADR.

When older decisions merge into one logical decision, create a consolidating decision and set the originals to `status: collapsed`, `collapsed_to: <id>`. There is no sequential number to manage; date-prefixed ids sort chronologically by name.

Set up code-review-graph MCP as the required tool for navigating code structure. Don't describe it like a document search engine; write that it's the tool you use to see code structure and impact range.

After writing an important guide/ADR/postmortem or making a large edit, run a Review Gate Quiz of three questions or fewer. After long work, leave a snapshot in `docs/wiki/postmortem/temp/` for the next agent to pick up.

At the end, report the results of `bash scripts/setup.sh`, `bash scripts/verify-agent-ssot.sh`, and `git diff --check`.
```

## 2. Ingest into an existing project

For adopting it on a repo that already has code and docs piled up. **Overwriting everything with `cp -R .../. .` wipes out your existing `README.md`, `CLAUDE.md`, and `.gitignore`.** Copy conflicting files separately and merge them by hand.

```text
Ingest the agentic-starter structure into this existing project. Don't overwrite existing files.

Order:
1. Run `bash scripts/ingest.sh <path-to-this-existing-project>` from the starter repo root (add `--dry-run` first if you want to preview). It resolves SOURCE as the starter repo root itself, copies the skeleton non-destructively, and never overwrites a file that already exists in the target. Anything that already exists and differs (`CLAUDE.md`/`AGENTS.md`/`README.md`/`.gitignore`/`.agent` files/etc.) is written beside the original as `*.starter`.
2. Read the gap report `ingest.sh` printed: which files were added, which were staged as `*.starter` (need manual merge), and which were already present and identical. Report the differences to me. I decide whether to merge each `*.starter` file.
3. For the router, if a `CLAUDE.md` already exists, merge only the starter's "always read before answering" section into it, and sync your router to `AGENTS.md`/`.cursorrules`/`.windsurfrules`.
4. Propose a classification of the existing scattered docs into layers (I confirm): behavior rules and preferences → `.agent/`, work in progress → `.planning/`, closed decisions, guides, and retrospectives → `docs/wiki/`. Show me a mapping table before moving any originals.
5. Fill `.agent/Context.md` and `.agent/Memory.md` as drafts by reading from the existing README and notes, but leave anything uncertain as `{{...}}` and ask me.
6. If decisions have already been made informally, present two options: back-fill them as ADRs (named `D-YYYYMMDD-<author>-<slug>`), or stack only new decisions as ADRs and keep old ones as references. I choose.
7. Warning before setup: `setup.sh` changes the hook path with `git config core.hooksPath .githooks`. `ingest.sh` already warns you if it detects an existing husky/lefthook setup and will not touch `core.hooksPath` itself. If that warning fired, skip hook installation and merge only the frontmatter automation from `.githooks/pre-commit` into your existing hook chain. Otherwise run `bash scripts/setup.sh`, `bash scripts/verify-agent-ssot.sh`, `git diff --check` and report. If router sync verification DRIFTs from existing content, that's normal during ingest; reconcile it again after the merge.

Never do: overwrite existing files without permission, move existing docs to the wiki without confirmation.
```

## 3. Co-worker onboarding + add member

For a new coworker who cloned a team repo that already uses this system. (a) onboarding themselves, (b) the team adding them as a member.

```text
I'm a new collaborator who just cloned this repo for the first time. Help me with two things.

(a) My onboarding:
1. Read the host router (`CLAUDE.md` etc.) and `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`, then summarize how this team works in three lines.
2. Give me an environment setup checklist: set `git config user.name`/`user.email`, run `bash scripts/setup.sh`, (if Codex) copy `.codex/*.example` locally, (if Cursor) confirm the three `.agent` files were read in a new chat.
3. From `docs/wiki/decisions/` and `docs/wiki/guides/`, pick the three core "why we do it this way" decisions I should read first.

(b) Add me as a member:
4. Propose a diff that adds a one-line role for me to Key People (or the team composition) in `.agent/Context.md`.
5. Check this team's author identity rule: frontmatter `@git_author` is auto-replaced with the git identity at commit time, so if I commit with my git identity it's reflected automatically. If the team uses a handle policy, find that rule in `.agent/Instructions.md` and tell me how to write my handle.
6. After the changes, run `bash scripts/verify-agent-ssot.sh` and `git diff --check` and report.
```

## 4. Self-orientation check (does the agent understand?)

For a person verifying, after publishing, "can the agent understand this system from the files alone." Paste it into a fresh-session agent and check whether the answers are accurate.

```text
Answer using only the files in this repo (no outside knowledge).
1. What is this system, and what's the difference between the three layers `.agent/`, `.planning/`, `docs/wiki/`?
2. When I say "build feature X," what do you read first before answering, and where do you leave the results?
3. Where do you put closed decisions versus open questions?
4. If anything wasn't covered by the files and you had to guess, tell me as is (this matters most).
```

## Starting point per host

| host | router read first | Notes |
|---|---|---|
| Claude Code | `CLAUDE.md` | If a `.claude/settings.json` hook exists, SessionStart/PreToolUse/PostToolUse can run. |
| Codex | `AGENTS.md` | `.codex/hooks.json` and `.codex/config.toml` are local files. Copy them from the examples. |
| Cursor | `.cursor/rules/agentic-router.mdc` | `.cursorrules` is the legacy fallback. Confirm the three `.agent` files were read in a new chat. |
| Windsurf | `.windsurfrules` | Only the router is provided by default. |

## Operations check prompt

```text
Check the agentic starter wiring.

What to verify:
- whether the 4 routers have the same content
- whether the Cursor project rule `.cursor/rules/agentic-router.mdc` and `.cursor/mcp.json` exist
- whether `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md` were replaced with the current project info
- whether `.codex/hooks.example.json` references only `.codex/hooks/*.sh` files that actually exist
- whether the `.planning/` and `docs/wiki/` skeletons are preserved with `.gitkeep`
- whether `.agents/skills/postmortem/SKILL.md` exists and its author basis is the git author
- whether `docs/wiki/_schema/frontmatter.md` describes the decision/guide/postmortem/temp snapshot fields
- whether code-review-graph MCP is described as a tool for code structure
- whether the Review Gate Quiz and `docs/wiki/postmortem/temp/` snapshot rules are in a guide

Verification commands:
`bash scripts/verify-agent-ssot.sh`
`git diff --check`
```

## Review Gate Quiz example

After creating an important document, ask at most three questions before commit/push/PR.

```text
Review Gate Quiz:
1. What core decision did this document settle?
2. What, if misunderstood, would break the agentic system?
3. Where should the next action be recorded?
```
