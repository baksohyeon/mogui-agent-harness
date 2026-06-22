#!/usr/bin/env bash
# SessionStart hook: warn about docs/wiki/ pages whose last_verified_at exceeds 180 days.
#
# Same pattern as memory-health.sh but targets wiki frontmatter.
# Does not block. Informational only.
# Threshold is 180 days (adjustable).
#
# v2 standard = `last_verified_at:` (underscore). v1 `last-verified:` is also backward compatible.
# SSOT = docs/wiki/_schema/frontmatter.md.

set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
WIKI_DIR="$ROOT/docs/wiki"

[[ ! -d "$WIKI_DIR" ]] && exit 0

THRESHOLD_DAYS=180
TODAY_EPOCH=$(date +%s)

findings=""
while IFS= read -r file; do
    # Search only within frontmatter (between the first --- and the second ---)
    fm=$(awk '/^---$/{n++; next} n==1 { print }' "$file")
    [[ -z "$fm" ]] && continue

    # Prefer the v2 standard (last_verified_at); v1 (last-verified) for backward compat
    last_verified=$(echo "$fm" | grep -E '^last_verified_at:' | head -1 | awk '{print $2}' | tr -d '\r')
    [[ -z "$last_verified" ]] && last_verified=$(echo "$fm" | grep -E '^last-verified:' | head -1 | awk '{print $2}' | tr -d '\r')
    [[ -z "$last_verified" ]] && continue

    status=$(echo "$fm" | grep -E '^status:' | head -1 | awk '{print $2}' | tr -d '\r')
    # If not active, the stale check is meaningless (already archived/superseded)
    [[ "$status" != "active" ]] && continue

    last_epoch=$(date -j -f "%Y-%m-%d" "$last_verified" "+%s" 2>/dev/null || date -d "$last_verified" "+%s" 2>/dev/null) || continue
    days_old=$(( (TODAY_EPOCH - last_epoch) / 86400 ))

    if (( days_old > THRESHOLD_DAYS )); then
        findings+="  - ${file#$ROOT/}: ${days_old} days (last_verified_at: $last_verified)\n"
    fi
done < <(find "$WIKI_DIR" -name "*.md" -not -path "*/archive/*")

if [[ -n "$findings" ]]; then
    echo "[wiki-health] pages with last_verified_at older than ${THRESHOLD_DAYS} days:"
    echo -e "$findings"
fi

exit 0
