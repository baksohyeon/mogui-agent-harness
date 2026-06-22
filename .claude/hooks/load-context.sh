#!/bin/bash
# load-context.sh: SessionStart hook. Auto-print only the single core context file.
#
# Prints only Context.md to stdout.
# Instructions.md / Memory.md are read directly by the agent per the router's
# "always read before answering" rule. Cat-ing all three files makes the hook
# output large and can bury signals like [AGENT-ASK].

set -e

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CTX="$REPO/.agent/Context.md"

if [[ -f "$CTX" ]]; then
  echo "=== .agent/Context.md (project context: read this first) ==="
  cat "$CTX"
  echo ""
  echo "=== Layer 2 additional SSOT (open directly with the Read tool when needed) ==="
  echo "  .agent/Instructions.md : Who You Are / Rules / Memory protocol"
  echo "  .agent/Memory.md       : preferences/corrections learning log"
fi

exit 0
