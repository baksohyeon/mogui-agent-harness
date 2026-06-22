#!/usr/bin/env bash
# install-hooks.sh: wire up .githooks/ as the project's hook directory
#
# Run once. Hooks added under .githooks/ will run automatically after this.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Ensure hooks executable
chmod +x .githooks/* 2>/dev/null || true

# Wire git to use .githooks/
git config core.hooksPath .githooks

echo "Git hooks enabled: core.hooksPath = .githooks"
echo ""
echo "Active hooks:"
ls .githooks/ | sed 's/^/  - /'
echo ""
echo "Test: edit a docs/*.md file, then git add + git commit. The updated field should change automatically."
