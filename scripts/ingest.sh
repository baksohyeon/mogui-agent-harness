#!/usr/bin/env bash
# ingest.sh: non-destructively copy this starter's skeleton into an existing
# project (the "existing project? use ingest instead" path from README.md /
# PROMPTS.md #2).
#
# Unlike Stage 1 of the greenfield flow (`cp -R <source>/. .`), this script
# never overwrites a file that already exists in the target. Anything that
# would conflict is written beside the original as `<name>.starter` so a
# human (or the calling agent) can merge it by hand.
#
# SOURCE is always this starter repo's root (the parent directory of
# scripts/). There is no separate copy-source subdirectory in this repo;
# the starter content lives at the repo root.
#
# Usage:
#   bash scripts/ingest.sh <target-repo-path> [--dry-run]
#   bash scripts/ingest.sh --dry-run <target-repo-path>
#
# This script never touches the target's git history and never runs
# `git config core.hooksPath`. If the target already has a hook system
# (husky/lefthook), it prints a warning instead of installing hooks.

set -euo pipefail

# ============================================================================
# Argument parsing
# ============================================================================
DRY_RUN=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      echo "Usage: bash scripts/ingest.sh <target-repo-path> [--dry-run]"
      exit 0
      ;;
    *)
      if [ -n "$TARGET" ]; then
        echo "error: unexpected extra argument '$arg'" >&2
        exit 1
      fi
      TARGET="$arg"
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: bash scripts/ingest.sh <target-repo-path> [--dry-run]" >&2
  exit 1
fi

# ============================================================================
# Resolve SOURCE and TARGET
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$TARGET" ]; then
  [ "$DRY_RUN" -eq 1 ] && echo "==> --dry-run: target '$TARGET' does not exist yet, would be created"
  mkdir -p "$TARGET"
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ "$SOURCE" = "$TARGET" ]; then
  echo "error: target path resolves to the same directory as this starter repo ($SOURCE)" >&2
  exit 1
fi

echo "==> agentic-starter ingest"
echo "  SOURCE: $SOURCE"
echo "  TARGET: $TARGET"
[ "$DRY_RUN" -eq 1 ] && echo "  MODE:   dry-run (no files will be written)"
echo ""

# ============================================================================
# Excludes: never copy the starter's own dev-only or VCS state
# ============================================================================
EXCLUDES=(.git .superpowers .worktrees node_modules .DS_Store)

# ============================================================================
# Known conflict-prone routers/config: handled exclusively by the dedicated
# block below (never by the bulk copy), so they are also excluded from rsync.
# ============================================================================
CONFLICT_PRONE=(CLAUDE.md AGENTS.md README.md .gitignore .cursorrules .windsurfrules)

is_conflict_prone() {
  local rel="$1"
  local name
  name="$(basename "$rel")"
  for c in "${CONFLICT_PRONE[@]}"; do
    [ "$rel" = "$c" ] && return 0
    [ "$name" = "$c" ] && return 0
  done
  return 1
}

RSYNC_EXCLUDE_ARGS=()
for e in "${EXCLUDES[@]}"; do
  RSYNC_EXCLUDE_ARGS+=(--exclude "$e")
done
for c in "${CONFLICT_PRONE[@]}"; do
  RSYNC_EXCLUDE_ARGS+=(--exclude "$c")
done

# ============================================================================
# Gap report accumulators
# ============================================================================
ADDED=()
STARTER_STAGED=()
SKIPPED_IDENTICAL=()

record_add() { ADDED+=("$1"); }
record_starter() { STARTER_STAGED+=("$1"); }
record_skip() { SKIPPED_IDENTICAL+=("$1"); }

# ============================================================================
# Copy step
# ============================================================================
if command -v rsync >/dev/null 2>&1; then
  echo "==> Copying skeleton (rsync -a --ignore-existing)"
  RSYNC_ARGS=(-a --ignore-existing "${RSYNC_EXCLUDE_ARGS[@]}")
  [ "$DRY_RUN" -eq 1 ] && RSYNC_ARGS+=(--dry-run)
  # --itemize-changes so we can classify added files from output. Each line is
  # "<11-char itemize code> <path>"; only ">f......." lines are new/changed
  # regular files (skip directory entries "cd+++++++" from the report).
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    code="${line%% *}"
    rel="${line#* }"
    case "$code" in
      '>f'*) record_add "$rel" ;;
      *) ;;
    esac
  done < <(rsync "${RSYNC_ARGS[@]}" --itemize-changes "$SOURCE/" "$TARGET/" || true)
else
  echo "==> rsync not found, falling back to cp -Rn"
  # cp -Rn has no dry-run mode; only actually copy when not a dry run. In
  # dry-run mode without rsync we can only report intent at the top level.
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] would run: cp -Rn $SOURCE/. $TARGET/ (excludes applied by not descending into: ${EXCLUDES[*]})"
  else
    for entry in "$SOURCE"/. "$SOURCE"/*; do
      base="$(basename "$entry")"
      skip=0
      for e in "${EXCLUDES[@]}"; do
        [ "$base" = "$e" ] && skip=1 && break
      done
      [ "$skip" -eq 1 ] && continue
      [ "$base" = "." ] && continue
      cp -Rn "$entry" "$TARGET/" 2>/dev/null || true
    done
  fi
fi

# ============================================================================
# Conflict-prone files: never overwrite, stage as <name>.starter if different
# ============================================================================
echo ""
echo "==> Checking conflict-prone routers/config"
for rel in "${CONFLICT_PRONE[@]}"; do
  src_file="$SOURCE/$rel"
  [ -f "$src_file" ] || continue
  dst_file="$TARGET/$rel"
  if [ ! -e "$dst_file" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      record_add "$rel"
    else
      mkdir -p "$(dirname "$dst_file")"
      cp "$src_file" "$dst_file"
      record_add "$rel"
    fi
  elif cmp -s "$src_file" "$dst_file"; then
    record_skip "$rel"
  else
    starter_file="$dst_file.starter"
    if [ "$DRY_RUN" -eq 0 ]; then
      cp "$src_file" "$starter_file"
    fi
    record_starter "$rel"
  fi
done

# ============================================================================
# Any other file that differs between SOURCE and TARGET after the rsync pass
# (rsync --ignore-existing already skipped writing over it; this loop makes
# the conflict visible in the report and stages a *.starter copy).
# ============================================================================
echo "==> Checking for other pre-existing conflicts"
while IFS= read -r -d '' src_file; do
  rel="${src_file#"$SOURCE"/}"

  skip=0
  for e in "${EXCLUDES[@]}"; do
    case "$rel" in
      "$e"|"$e"/*) skip=1 ;;
    esac
  done
  [ "$skip" -eq 1 ] && continue
  is_conflict_prone "$rel" && continue

  dst_file="$TARGET/$rel"
  [ -e "$dst_file" ] || continue
  [ -f "$dst_file" ] || continue

  if cmp -s "$src_file" "$dst_file"; then
    record_skip "$rel"
  else
    starter_file="$dst_file.starter"
    if [ "$DRY_RUN" -eq 0 ] && [ ! -e "$starter_file" ]; then
      cp "$src_file" "$starter_file"
    fi
    record_starter "$rel"
  fi
done < <(find "$SOURCE" -type f -print0)

# ============================================================================
# Existing hook system detection
# ============================================================================
echo ""
echo "==> Checking for existing hook system in target"
HOOK_WARNING=0
if [ -d "$TARGET/.husky" ]; then
  HOOK_WARNING=1
fi
if [ -f "$TARGET/package.json" ] && grep -Eq '"(husky|lefthook)"' "$TARGET/package.json" 2>/dev/null; then
  HOOK_WARNING=1
fi
if [ "$HOOK_WARNING" -eq 1 ]; then
  echo "  [WARNING] target already uses a hook system (husky/lefthook)."
  echo "            Do NOT run 'git config core.hooksPath .githooks' (setup.sh's"
  echo "            hook install step) -- it would hijack the existing chain."
  echo "            Instead, merge only the frontmatter automation from"
  echo "            .githooks/pre-commit into the existing hook chain by hand."
else
  echo "  [OK] no existing husky/lefthook detected"
fi

# ============================================================================
# Gap report
# ============================================================================
echo ""
echo "==> Gap report"
echo ""
echo "Added ($(( ${#ADDED[@]} )) file(s)):"
if [ "${#ADDED[@]}" -eq 0 ]; then
  echo "  (none)"
else
  printf '  + %s\n' "${ADDED[@]}"
fi
echo ""
echo "Staged as *.starter, needs manual merge ($(( ${#STARTER_STAGED[@]} )) file(s)):"
if [ "${#STARTER_STAGED[@]}" -eq 0 ]; then
  echo "  (none)"
else
  for f in "${STARTER_STAGED[@]}"; do
    echo "  ~ $f -> $f.starter"
  done
fi
echo ""
echo "Skipped, already present and identical ($(( ${#SKIPPED_IDENTICAL[@]} )) file(s)):"
if [ "${#SKIPPED_IDENTICAL[@]}" -eq 0 ]; then
  echo "  (none)"
else
  printf '  = %s\n' "${SKIPPED_IDENTICAL[@]}"
fi

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. No files were written. Re-run without --dry-run to apply."
else
  echo "Ingest complete."
  echo "Next: review *.starter files and merge by hand, then run:"
  echo "  bash scripts/verify-agent-ssot.sh"
  echo "  git diff --check"
fi
