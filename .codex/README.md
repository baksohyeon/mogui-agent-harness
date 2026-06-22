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
