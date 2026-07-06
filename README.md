# agentic-starter: copy-paste agentic ops boilerplate

> English document. 한국어: [README-ko.md](./README-ko.md)

This folder sets up a full agentic operating layer in a new repo: an `.agent` context layer, an LLM wiki, GSD planning scaffolding, Claude/Codex hooks, a Cursor rule adapter, and a code-review-graph MCP convention.

Copy the contents of this folder into a new project root, run `bash scripts/setup.sh`, and you get an empty skeleton of the operating layer the source repo uses. None of the source project's product decisions or postmortems come along. A new repo starts stacking its own decisions.

## Quick Start (empty new project)

The flow has **two stages**. The part people get wrong first:

- **Stage 1 (the script) asks nothing.** It only lays down the empty skeleton. Product details stay as placeholders like `{{product-name}}`.
- **Stage 2 (the AI host) is where the AI asks you** about your product, team, and stack and fills those placeholders. So you don't hand-edit the blanks yourself.

> "Project init" is not a separate wizard command. Stage 1 = the script, Stage 2 = paste a prompt into your AI host and it fills the rest through conversation.

### Stage 1: lay the skeleton (script, zero questions)

Run this in the new repo root. `setup.sh` runs `git init` if the directory is not a git repo, so you don't have to `git init` first.

```bash
rsync -a --exclude .git <source-repo>/ .
chmod +x scripts/*.sh .claude/hooks/*.sh .githooks/* 2>/dev/null || true
bash scripts/setup.sh
```

`setup.sh` only does git init + git hook install + skeleton verification. This stage does not ask for any product information.

> If `setup.sh`'s "Verify AI tools" step finds gstack, GSD, or code-review-graph missing, it prints a warning. **That is a warning, not a failure.** The starter skeleton works without those tools. Install only the ones you use, via the Install commands in `CLAUDE.md`.

On a machine that uses Codex, create the local config files. Both are `.gitignore`d.

```bash
cp .codex/hooks.example.json .codex/hooks.json
cp .codex/config.example.toml .codex/config.toml
```

### Stage 2: fill the content (the AI asks you)

Copy the **"1. greenfield init"** prompt from `PROMPTS.md` and paste it whole into your current AI host (Claude Code / Codex / Cursor, etc.). The AI then reads the router and the `.agent/` files, **asks you about your product, team, stack, and first decision**, fills the `{{...}}` placeholders, and creates its first decision. You don't pre-edit the blanks by hand.

To preview *what the conversation looks like* after you paste, read `docs/bootstrap-walkthrough.md` (a worked example).

### Existing project? Use ingest instead (non-destructive)

The `cp -R` above is for an empty repo. On a repo that already has code and docs, do not run it as-is: it overwrites your existing `README.md`, `CLAUDE.md`, and `.gitignore`. Use `scripts/ingest.sh` instead:

```bash
bash <path-to-starter-repo>/scripts/ingest.sh <path-to-your-existing-project>
```

Add `--dry-run` to preview the gap report without writing anything. Or paste the **"2. ingest into an existing project"** prompt from `PROMPTS.md` and let your AI host run it and walk you through the merge. What it does, and why it is safe:

- **Your git history is untouched.** `ingest.sh` never touches the target's git history, and it never runs `git config core.hooksPath` itself.
- **Existing files are never overwritten.** Ingest copies the skeleton with `rsync -a --ignore-existing` (or `cp -Rn`), so anything you already have stays as-is and only the missing pieces get added.
- **A `docs/` name clash is fine.** The starter only contributes `docs/wiki/` and `docs/bootstrap-walkthrough.md`. With `--ignore-existing`, your existing `docs/` files are kept and the starter's `docs/wiki/` is added next to them. If you already have a `docs/wiki/`, the starter copy is placed as `*.starter` beside yours with a diff, so you decide what to merge.
- **Conflicting top-level files** (`CLAUDE.md`, `README.md`, `.gitignore`, `.agent`) are placed as `*.starter` next to yours, never over them. You merge them by hand.
- **If you already use husky or lefthook**, `ingest.sh` detects it and prints a warning instead of touching hooks. `setup.sh` would otherwise repoint `core.hooksPath` to `.githooks` and hijack your chain, so in that case skip hook installation and merge only `.githooks/pre-commit`'s frontmatter automation into your existing hooks.

A teammate who cloned a repo that already uses this system uses **"3. coworker onboarding"** instead.

## How it works

The system does not rely on the AI remembering things between sessions. It splits session rules, execution state, and long-term knowledge into separate places on disk, and the host router points the agent at each one.

```text
host router (CLAUDE.md / AGENTS.md / .cursorrules / .windsurfrules)
  -> .agent/      session operating rules + compressed context
  -> .planning/   GSD execution state + handoff slots
  -> docs/wiki/   human-approved long-term knowledge
  -> code-review-graph MCP   code structure graph
```

Each part has one job:

- **`.agent/`** sets how the agent behaves in the current session: rules, the compressed product/team/stack context, and learning memory. It is not where decision records or long meeting notes go.
- **`.planning/`** holds execution state: GSD workstreams, quick tasks, todos, open threads, seeds. A plan in flight is not wiki truth.
- **`docs/wiki/`** holds knowledge a human has approved: closed decisions (`decisions/D-*.md`), repeatable rules (`guides/`), incidents and lessons (`postmortem/`).
- **code-review-graph MCP** is for code structure (imports, call graph, change impact), not document search. The reasons behind a decision live in the wiki.

### What a session does with a request

When you give an unstructured request, the agent classifies it before it writes anything:

```text
request
  -> read existing decisions/guides + .agent context
  -> judge size and certainty
  -> route the work (see table)
  -> execute, or ask the smallest necessary question
  -> verify and close, or leave a handoff snapshot
```

| The work is | It goes to |
|---|---|
| a small direct edit | direct / fast |
| small but worth keeping | `.planning/quick/` |
| executable but not now | `.planning/todos/` |
| an unresolved decision | `.planning/threads/` |
| a low-confidence idea | `.planning/seeds/` |
| multi-step work | `.planning/workstreams/` |
| a closed decision | `docs/wiki/decisions/D-*.md` |
| a repeatable rule | `docs/wiki/guides/` |
| an incident or a lesson | `docs/wiki/postmortem/` |

## Guides

The deeper docs live in `docs/wiki/guides/`. The section above is the summary; these go into detail.

- [Onboarding](./docs/wiki/guides/01-onboarding.md): the starting point for a person or a new AI session
- [Agentic Architecture](./docs/wiki/guides/02-agentic-architecture.md): the `.agent` / `.planning` / `docs/wiki` split in depth
- [Host Runtime and Hooks](./docs/wiki/guides/03-host-runtime-and-hooks.md): how Claude Code, Codex, and Cursor load context and run hooks
- [GSD + LLM Wiki Agent Flow](./docs/wiki/guides/04-gsd-llm-wiki-agent-flow.md): how the agent routes a request between execution state and long-term knowledge
- [Decisions and Postmortems](./docs/wiki/guides/05-decisions-and-postmortems.md): how to write an ADR (`D-YYYYMMDD-<author>-<slug>`) and a postmortem
- [Maintenance](./docs/wiki/guides/maintenance.md): keeping the agentic system healthy over time

## What's inside

| Path | Role |
|---|---|
| `CLAUDE.md` `AGENTS.md` `.cursorrules` `.windsurfrules` | The 4 host routers. Their content must stay identical. |
| `.cursor/rules/agentic-router.mdc` `.cursor/mcp.json` | Cursor project rule adapter and code-review-graph MCP config |
| `.agent/` | Session operating rules, compressed context, learning memory |
| `.agent/workflows/` | Internal workflows the agent follows repeatedly (`triple-crown.md` 5-phase by scale, `automation-patterns.md` 4 patterns by type) |
| `.agent/loops/` | Loop-engineering layer: `LOOP.md` loop registry (budgets, kill switch, L1-L3 maturity ladder) plus the `daily-triage` read-only L1 loop (state file + append-only run log) |
| `.agents/skills/postmortem/` `.agents/skills/scope/` `.agents/skills/daily-triage/` | Evidence-based postmortem skill, work-sizing scope skill, daily-triage loop skill. Author = git author. |
| `.claude/` | Claude Code hook adapter and the `.claude/commands/scope.md` slash command |
| `.codex/` | Codex hook/MCP adapter templates |
| `.githooks/` | Helper hooks for wiki frontmatter and the audit log |
| `.planning/` | GSD execution-state skeleton |
| `docs/wiki/` | LLM wiki skeleton. Includes decisions/guides/postmortem/schema. |
| `scripts/` | setup, git hook install, starter wiring verify |
| `PROMPTS.md` | First-run and ops-check prompts |
| `docs/bootstrap-walkthrough.md` | A worked example following one session from empty repo to first decision |
| `README-ko.md` | Korean version of this README |

## Slots that get filled (usually by the Stage 2 AI)

These are the slots the greenfield prompt asks you about and fills. You can edit them by hand, but you don't have to fill them all manually. Stage 2 handles it through conversation. This list is a checklist of *what* gets filled.

- `{{product-name}}`, `{{repo}}`, `{{team}}`, `{{stack}}`, `{{domain}}` (product name, repo, team, stack, domain)
- `YYYY-MM-DD`
- `@git_author`: in staged docs frontmatter, a git hook substitutes `git config user.name` for you. Verify it on first run.
- Initial preferences/corrections in `.agent/Memory.md`
- Product scope, team members, tech stack, and first decision in `.agent/Context.md`
- Code-safety rules, branch policy, and verify commands in `CLAUDE.md`
- `{{rules-1-to-4}}` in `.claude/hooks/memory-selfcheck.sh`
- If you use Cursor, confirm in a new chat that `.agent/Instructions.md`, `.agent/Context.md`, and `.agent/Memory.md` were read.

## Operating rules

- `.agent/` is the session operating layer. Don't put meeting notes or long execution state here.
- `.planning/` is GSD execution state. Open questions go to `threads/`, small tasks to `quick/`, low-confidence ideas to `seeds/`, and large work to `workstreams/`.
- `docs/wiki/` is long-term knowledge. Closed decisions go to `decisions/D-*.md`, recurring rules to `guides/`, and incidents and lessons to `postmortem/`.
- code-review-graph MCP is for code structure. Don't describe it as a document search engine.
- After writing an important guide/ADR/postmortem, run a Review Gate Quiz of at most three questions.
- After long work, leave a hand-off snapshot in `docs/wiki/postmortem/temp/`.
- The postmortem author is the git author, not a hardcoded personal name. If the team has a separate handle policy, record it in `.agent/Instructions.md`.

## Hook options

The greenfield init prompt (`PROMPTS.md`) detects your project's language and configures the Korean-only hooks for you: it keeps them for a Korean project and removes them otherwise. The table below is the manual reference.

| hook | default | description |
|---|---|---|
| `load-context.sh` | keep | At SessionStart, prints only `.agent/Context.md` and points the agent to read Instructions/Memory directly. |
| `setup-check.sh` | keep | If `.setup-done` is missing, prompts to run setup via `[AGENT-ASK]`. |
| `memory-health.sh` | recommended | Warns on the repo-name-based archive path and stale Memory state. |
| `memory-selfcheck.sh` | recommended | Surfaces load-bearing feedback rules each turn. Placeholder substitution required. |
| `wiki-health.sh` | recommended | Warns only when an active wiki doc's `last_verified_at` is over 180 days. |
| `no-emoji-check.sh` | optional | Blocks emoji and pushes text alternatives. |
| `no-bak-slang-check.sh` | optional (Korean projects) | Blocks literal-translation Korean slang. Remove it from settings if this isn't a Korean project. |
| `remind-korean-style.sh` | optional (Korean projects) | Korean-response self-check reminder. Remove it from settings if this isn't a Korean project. |

## Verify

```bash
bash scripts/setup.sh
bash scripts/verify-agent-ssot.sh
bash scripts/wiki-lint.sh
git diff --check
```

`wiki-lint.sh` checks `docs/wiki/` integrity (orphans, broken links, duplicate ids, dangling relations, etc.). It only needs python3. If you have a `package.json`, you can add a `"wiki:lint": "bash scripts/wiki-lint.sh"` alias.
