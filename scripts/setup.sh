#!/usr/bin/env bash
# setup.sh: one-time setup after a fresh clone. Safe to re-run.
# Add or remove steps to fit your new project.

set -euo pipefail

# Every git hook and verification in the starter assumes a git repo. To make it
# work right away even in an empty new project that has not run git init yet,
# initialize the repo here if it is not one.
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "==> Not a git repository, running 'git init'"
  git init -q
  echo "  git repository initialized"
  echo ""
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ============================================================================
# 1/4 Install git hooks
# ============================================================================
echo "==> 1/4 Install git hooks"
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x .githooks/* 2>/dev/null || true
if [ -f scripts/install-hooks.sh ]; then
  ./scripts/install-hooks.sh
else
  git config core.hooksPath .githooks
  echo "  git hooks enabled (core.hooksPath = .githooks)"
fi

# ============================================================================
# 2/4 Multi-host router verify (CLAUDE.md == AGENTS.md == ...)
# ============================================================================
echo ""
echo "==> 2/4 Multi-host router verify"
CLAUDE_HASH=$(shasum CLAUDE.md | awk '{print $1}')
DRIFT=()
for f in AGENTS.md .cursorrules .windsurfrules; do
  if [ ! -e "$f" ]; then
    DRIFT+=("$f (missing)")
  else
    H=$(shasum "$f" | awk '{print $1}')
    [ "$H" != "$CLAUDE_HASH" ] && DRIFT+=("$f")
  fi
done
if [ ${#DRIFT[@]} -eq 0 ]; then
  echo "  [OK] host instruction files in sync"
else
  echo "  [DRIFT] ${DRIFT[*]}: run: cp CLAUDE.md AGENTS.md .cursorrules .windsurfrules"
fi

# ============================================================================
# 3/4 Verify required AI tools
# ============================================================================
echo ""
echo "==> 3/4 Verify AI tools (optional; the starter skeleton works without them)"
[ -d "$HOME/.claude/skills/gstack/bin" ] && echo "  [OK] gstack" || {
  echo "  [CHECK] gstack missing. Install:"
  echo "          git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && (cd ~/.claude/skills/gstack && ./setup)"
}
command -v gsd-tools >/dev/null 2>&1 && echo "  [OK] GSD (gsd-tools)" || {
  echo "  [CHECK] GSD missing. Install:"
  echo "          npx @opengsd/gsd-core@latest"
}
command -v code-review-graph >/dev/null 2>&1 && echo "  [OK] code-review-graph" || {
  echo "  [CHECK] code-review-graph missing. Install/serve:"
  echo "          uvx code-review-graph serve   (then wire .cursor/mcp.json or your host MCP config)"
}
echo "  [NOTE] Superpowers: install via your host plugin manager (see CLAUDE.md tools table)."

# ============================================================================
# 4/4 Agent starter wiring verify
# ============================================================================
echo ""
echo "==> 4/4 Agent starter wiring verify"
if [ -x scripts/verify-agent-ssot.sh ]; then
  scripts/verify-agent-ssot.sh
else
  echo "  [SKIP] scripts/verify-agent-ssot.sh not executable"
fi

touch .setup-done

echo ""
echo "Setup complete. Next: read CLAUDE.md (or AGENTS.md), then start a session."
