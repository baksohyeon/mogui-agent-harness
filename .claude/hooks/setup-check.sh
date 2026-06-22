#!/bin/bash
# setup-check.sh: SessionStart hook. Auto-correct and notify when scripts/setup.sh has not run.
#
# Intent:
#   - Even if you forget to run setup.sh on a new machine or fresh clone, at least git hooks get enabled automatically.
#   - The rest (backups, plugins, etc.) need a user decision, so only notify.
#
# Run time: ~30ms. Product-agnostic. Copy as is.

set -e

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO" || exit 0

# 1) Auto-enable hooksPath. Lightweight and safe.
current_hooks=$(git config --get core.hooksPath 2>/dev/null || echo "")
if [[ "$current_hooks" != ".githooks" && -d ".githooks" ]]; then
  chmod +x .githooks/* 2>/dev/null || true
  git config core.hooksPath .githooks
  echo "[setup-check] git hooks auto-enabled (core.hooksPath = .githooks)"
fi

# 2) Notify when .setup-done is missing.
#    [AGENT-ASK] prefix = an action signal the agent must immediately raise with the user (.agent/Instructions.md § Rules).
if [[ ! -f ".setup-done" ]]; then
  echo "[setup-check] ./scripts/setup.sh has not run. Some additional setup may be missing."
  echo "[AGENT-ASK] Claude/Codex: ask the user 'Should I run setup.sh now?', and if yes, run 'bash scripts/setup.sh'."
fi

exit 0
