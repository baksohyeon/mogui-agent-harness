#!/bin/bash
# memory-health.sh: SessionStart hook. One-line summary of Layer 2 memory system health.
# Run time: ~50ms. The archive directory is derived automatically from the repo name. Product-agnostic.

set -e

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMORY="$REPO/.agent/Memory.md"
ARCHIVE_DIR="$HOME/Documents/$(basename "$REPO")-archive"
TODAY_TS=$(date +%s)
WARN=()

# 1. Memory.md last updated (frontmatter)
mem_age="?"
if [[ -f "$MEMORY" ]]; then
  mem_date=$(awk '/^---$/{n++} n==1 && /^updated:/{print $2; exit}' "$MEMORY" 2>/dev/null | tr -d '\r')
  if [[ -n "$mem_date" ]]; then
    mem_ts=$(date -j -f "%Y-%m-%d" "$mem_date" "+%s" 2>/dev/null || date -d "$mem_date" "+%s" 2>/dev/null || echo "")
    if [[ -n "$mem_ts" ]]; then
      mem_age=$(( (TODAY_TS - mem_ts) / 86400 ))
      if [[ $mem_age -gt 14 ]]; then
        WARN+=("Memory.md ${mem_age}d stale: dogfooding recommended")
      fi
    fi
  fi
fi

# 2. Last archive
arc_age="never"
if [[ -d "$ARCHIVE_DIR" ]]; then
  latest=$(ls -1 "$ARCHIVE_DIR" 2>/dev/null | grep -E '^agent_[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort -r | head -1)
  if [[ -n "$latest" ]]; then
    arc_date="${latest#*_}"
    arc_ts=$(date -j -f "%Y-%m-%d" "$arc_date" "+%s" 2>/dev/null || date -d "$arc_date" "+%s" 2>/dev/null || echo "")
    if [[ -n "$arc_ts" ]]; then
      arc_age=$(( (TODAY_TS - arc_ts) / 86400 ))
      if [[ $arc_age -gt 8 ]]; then
        WARN+=("Archive ${arc_age}d ago: check backups")
      fi
    fi
  fi
fi

# Output
echo "[layer-2] Memory: ${mem_age}d ago | Archive: ${arc_age}"
if [[ ${#WARN[@]} -gt 0 ]]; then
  for w in "${WARN[@]}"; do
    echo "  WARN: $w"
  done
fi

exit 0
