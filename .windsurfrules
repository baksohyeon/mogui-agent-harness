# Project Instructions: {{product-name}}

> This file is a **router**. It points to where to read, not the content itself. Keep it under 100 lines.
> Claude Code reads `CLAUDE.md`, Codex reads `AGENTS.md`. Cursor uses `.cursor/rules/agentic-router.mdc` as its project rule adapter.
> `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, and `.windsurfrules` share identical content.

## Always read before answering

- [`.agent/Instructions.md`](./.agent/Instructions.md): Who/What/Rules/Outputs
- [`.agent/Context.md`](./.agent/Context.md): product, team, stack, and decisions SoT
- [`.agent/Memory.md`](./.agent/Memory.md): preferences/corrections learning log

Automatic memory update: "remember / don't forget / from now on / don't do" triggers an immediate write to Memory.md (protocol = Instructions.md § Memory Update Protocol).

## First-entry autonomous bootstrap

If `.setup-done` is missing, or the project's context files still contain unfilled template placeholders, setup has not been completed. (Detect placeholders in the project content — do not treat the example tokens in this contract as unresolved.) Run the appropriate flow yourself instead of telling the human to type commands:

- Empty/greenfield target: run `bash scripts/setup.sh`, then fill the remaining placeholders by asking the user (see `PROMPTS.md` #1). `setup.sh` writes `.setup-done` when it completes.
- Existing project target: from a **separate clone of this starter**, run `bash scripts/ingest.sh <target-repo-path>` (non-destructive; it refuses to run when SOURCE and TARGET resolve to the same directory). Then report the gap report and any `*.starter` conflicts for the human to adjudicate, and after merging run `bash scripts/setup.sh` in the target to finalize `.setup-done` (see `PROMPTS.md` #2).

This contract is host-agnostic: Claude Code and Codex must behave identically here, with no Claude-specific tooling assumed. After either flow, still read `.agent/Instructions.md`, `.agent/Context.md`, and `.agent/Memory.md` before answering.

## Required and recommended tools

| Tool | Verify | Install |
|------|--------|---------|
| **code-review-graph** | `code-review-graph status` | `uvx code-review-graph serve` or see the MCP config |
| **GSD** | `which gsd-tools` | `npx @opengsd/gsd-core@latest` |
| **gstack** | `test -d ~/.claude/skills/gstack/bin` | `git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` |
| **Superpowers** | check the host plugin manager | install per host |

Workflow definitions live in [`.agent/workflows/triple-crown.md`](./.agent/workflows/triple-crown.md).

## Code safety (load-bearing, fill in per project)

- {{e.g. run the apply command after adding a migration}}
- {{e.g. never print or commit secrets/credentials}}
- {{stack-specific silent failure pattern}}

## GSD and the LLM wiki

- `.planning/` = GSD execution state. Use `workstreams` for large efforts, `workspace` for isolation, `thread` for open discussions, `quick` for small recording tasks, `fast` for trivial changes, and `capture` for collecting input.
- `docs/wiki/` = long-term knowledge. Decisions go in `decisions/D-*.md`, operational guides in `guides/`, retrospectives in `postmortem/`.
- GSD does not supersede the LLM wiki. GSD holds execution state; the wiki holds long-term knowledge.
- `code-review-graph` MCP = a map of the code structure. Use it first when exploring code or checking the impact of a change. Do not treat it as a document search engine.

## Directory conventions

- `.agent/` (singular) = Layer 2 context (Instructions/Context/Memory/workflows). Change it freely.
- `.agents/` (plural) = external skill library. Do not rename it.
- `docs/wiki/` = Layer 3 wiki (decisions/postmortem/guides).

## Documentation operations

- Decisions are `D-YYYYMMDD-<author>-<slug>.md` (copy `D-template.md`). After writing one, run `bash scripts/decisions-index.sh` to regenerate the index.
- Keep open questions in `.planning/threads/` instead of locking them into an ADR.
- After writing an important guide/ADR/postmortem, run a Review Gate Quiz of up to 3 questions before commit/push/PR.
- After a long workflow, leave a handoff snapshot in `docs/wiki/postmortem/temp/`.

## Branch policy

- Work on a `feat|fix|docs|chore/<topic>` branch, then open a PR into `dev`.
- Do not commit directly to `dev` (it is the integration branch).
- Promote `dev` to `main` only at release time.

## Optional: Korean-language projects

These rules apply only when the project writes in Korean. Skip them for English-only projects.

- Avoid English-to-Korean calque slang. Use the approved alternatives in `.agent/korean-persona.md`.
- Match the Korean voice and tone defined in `.agent/korean-persona.md`.
- No emojis in committed files (a hook blocks them).

---

*Keep the router under 100 lines. Move the body to `.agent/` if it grows.*
