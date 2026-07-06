# Codex Adapter

`.agent/` is the Layer 2 SSOT. This directory only adapts that SSOT to Codex.

Tracked:

- `hooks/*.sh`: shared hook implementations. Keep in sync with `.claude/hooks/*.sh`.
- `hooks.example.json`: portable template for local Codex hook config.
- `config.example.toml`: portable template for local Codex MCP config.

Ignored (add to `.gitignore`):

- `hooks.json`: local Codex hook config. May contain absolute paths.
- `config.toml`: local Codex MCP config.

Local setup:

```bash
cp .codex/hooks.example.json .codex/hooks.json
cp .codex/config.example.toml .codex/config.toml
```

Machine-specific absolute paths go in the ignored `hooks.json`, never in the tracked template.

## Codex parity check

`scripts/smoke-codex.sh` is the Codex parity smoke check. It verifies, without
requiring network access, that:

- `.codex/hooks.example.json` references only hook scripts that exist under
  `.codex/hooks/`.
- `.codex/config.example.toml` is valid TOML-ish (a light structural parse).
- `AGENTS.md` (Codex's router) exists and contains the `First-entry
  autonomous bootstrap` section.
- The three `.agent/` core files (`Instructions.md`, `Context.md`,
  `Memory.md`) exist.

It prints PASS/FAIL per check and exits non-zero if any static check fails.

If the `codex` CLI is installed and authenticated, the script also attempts a
live, non-interactive behavioral smoke using the PROMPTS.md #4
self-orientation prompt (`codex exec --sandbox read-only
--skip-git-repo-check`, run with a hard timeout and stdin redirected from
`/dev/null` so it can never hang or prompt interactively). This live portion
is best-effort and never affects the script's exit code: if `codex` is
missing, unauthenticated, offline, or the invocation times out, the script
prints the exact manual command to run instead.

Run it with:

```bash
bash scripts/smoke-codex.sh
```
