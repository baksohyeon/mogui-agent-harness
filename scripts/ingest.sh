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

if [ -d "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
elif [ "$DRY_RUN" -eq 1 ]; then
  # Dry-run must make zero filesystem changes. Resolve the parent's realpath
  # and keep the not-yet-existent leaf as a string, so we never mkdir.
  echo "==> --dry-run: target '$TARGET' does not exist yet, would be created"
  parent="$(dirname "$TARGET")"
  leaf="$(basename "$TARGET")"
  if [ -d "$parent" ]; then
    TARGET="$(cd "$parent" && pwd)/$leaf"
  fi
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

if [ "$SOURCE" = "$TARGET" ]; then
  echo "error: target path resolves to the same directory as this starter repo ($SOURCE)" >&2
  exit 1
fi

echo "==> mogui-agent-harness ingest"
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

# Conflict-prone matching is anchored to the literal root-relative path only.
# A nested file that happens to share a basename (e.g. .codex/README.md,
# docs/wiki/decisions/README.md) is an ordinary file and must copy normally.
is_conflict_prone() {
  local rel="$1"
  for c in "${CONFLICT_PRONE[@]}"; do
    [ "$rel" = "$c" ] && return 0
  done
  return 1
}

RSYNC_EXCLUDE_ARGS=()
for e in "${EXCLUDES[@]}"; do
  RSYNC_EXCLUDE_ARGS+=(--exclude "$e")
done
# Leading slash anchors the exclude to the transfer root, so nested files with
# the same basename are not excluded.
for c in "${CONFLICT_PRONE[@]}"; do
  RSYNC_EXCLUDE_ARGS+=(--exclude "/$c")
done

# ============================================================================
# Gap report accumulators
# ============================================================================
ADDED=()
STARTER_STAGED=()
SKIPPED_IDENTICAL=()
STARTER_PRESERVED=()

record_add() { ADDED+=("$1"); }
record_starter() { STARTER_STAGED+=("$1"); }
record_skip() { SKIPPED_IDENTICAL+=("$1"); }
record_starter_preserved() { STARTER_PRESERVED+=("$1"); }

# Stage the starter version of a conflicting file as <name>.starter, but never
# clobber an existing *.starter (non-destructive constraint #4). Returns via
# the accumulators only. Args: <rel> <starter_file>
stage_starter() {
  local rel="$1"
  local starter_file="$2"
  if [ -e "$starter_file" ]; then
    record_starter_preserved "$rel"
    echo "  [WARN] $starter_file already exists; leaving it untouched (not re-staged)"
    return 0
  fi
  [ "$DRY_RUN" -eq 0 ] && cp "$SOURCE/$rel" "$starter_file"
  record_starter "$rel"
}

# ============================================================================
# Snapshot which files already existed in TARGET before we copy anything.
# The "other pre-existing conflicts" pass below uses this to distinguish a
# genuine pre-existing file (rsync --ignore-existing skipped it) from a file
# this run just added (which must not be re-reported as skipped-identical).
# newline-delimited list of root-relative paths; matched with exact grep -Fx.
# ============================================================================
PRE_EXISTING=""
if [ -d "$TARGET" ]; then
  PRE_EXISTING="$(cd "$TARGET" && find . -type f -print 2>/dev/null | sed 's|^\./||')"
fi

target_pre_existed() {
  # Args: <root-relative path>. True if it was present before this run.
  [ -n "$PRE_EXISTING" ] || return 1
  printf '%s\n' "$PRE_EXISTING" | grep -Fxq -- "$1"
}

# ============================================================================
# Copy step
# ============================================================================
# The gap report (added / skipped / *.starter) is computed below from a
# filesystem comparison against the PRE_EXISTING snapshot, NOT from rsync's
# --itemize-changes output. openrsync (macOS default) and GNU rsync itemize
# differently between a --dry-run and a real run, which made --dry-run
# under-report conflicts. Deriving the report from the snapshot makes dry-run
# and real report the identical set by construction. rsync/cp here only
# performs (or, in dry-run, skips) the actual copy.
if command -v rsync >/dev/null 2>&1; then
  echo "==> Copying skeleton (rsync -a --ignore-existing)"
  RSYNC_ARGS=(-a --ignore-existing "${RSYNC_EXCLUDE_ARGS[@]}")
  if [ "$DRY_RUN" -eq 1 ]; then
    # Dry-run writes nothing; itemize quirks between openrsync/GNU rsync are
    # irrelevant because the report is derived from the snapshot below.
    RSYNC_ARGS+=(--dry-run)
    rsync "${RSYNC_ARGS[@]}" "$SOURCE/" "$TARGET/" >/dev/null 2>&1 || true
  else
    # A real run must NOT swallow rsync failures: the gap report is derived from
    # the PRE_EXISTING snapshot, so a partial/failed copy would still be reported
    # as "added" while those files were never transferred. Abort instead, keeping
    # the non-destructive contract honest.
    if ! rsync "${RSYNC_ARGS[@]}" "$SOURCE/" "$TARGET/" >/dev/null 2>&1; then
      echo "error: rsync failed while copying skeleton; target may be partially populated. Aborting before the gap report to avoid claiming files were added that were not." >&2
      exit 1
    fi
  fi
else
  echo "==> rsync not found, falling back to cp -Rn"
  # cp -Rn has no dry-run mode; only actually copy when not a dry run.
  # `"$SOURCE"/*` does not match dotfiles without `shopt -s dotglob`, which
  # would silently skip the real payload (.agent/, .codex/, .claude/,
  # .githooks/, .planning/). Enumerate top-level entries with find instead so
  # dotfiles are included, and skip CONFLICT_PRONE here too (the dedicated
  # loop below owns those so they are never bulk-copied by this fallback).
  if [ "$DRY_RUN" -eq 0 ]; then
    while IFS= read -r -d '' entry; do
      base="$(basename "$entry")"
      skip=0
      for e in "${EXCLUDES[@]}"; do
        [ "$base" = "$e" ] && skip=1 && break
      done
      [ "$skip" -eq 1 ] && continue
      is_conflict_prone "$base" && continue
      cp -Rn "$entry" "$TARGET/" 2>/dev/null || true
    done < <(find "$SOURCE" -mindepth 1 -maxdepth 1 -print0)
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
    stage_starter "$rel" "$dst_file.starter"
  fi
done

# ============================================================================
# Classify every (non-excluded, non-conflict-prone) source file against the
# PRE_EXISTING snapshot. This is the single source of truth for the report and
# runs identically in dry-run and real mode:
#   - did NOT pre-exist  -> added by this run
#   - pre-existed, same  -> skipped (identical)
#   - pre-existed, diff   -> staged as *.starter (conflict)
# ============================================================================
echo "==> Classifying copied and pre-existing files"
while IFS= read -r -d '' src_file; do
  rel="${src_file#"$SOURCE"/}"

  # EXCLUDES are passed to rsync as bare (unanchored) --exclude patterns, so
  # rsync drops them at ANY depth (e.g. docs/.DS_Store), not just at the
  # transfer root. Match that here with a component-wise check, or a nested
  # excluded file gets classified as "added" when rsync never copied it.
  skip=0
  for e in "${EXCLUDES[@]}"; do
    case "$rel" in
      "$e"|"$e"/*|*/"$e"|*/"$e"/*) skip=1 ;;
    esac
  done
  [ "$skip" -eq 1 ] && continue
  is_conflict_prone "$rel" && continue

  if target_pre_existed "$rel"; then
    dst_file="$TARGET/$rel"
    [ -f "$dst_file" ] || continue
    if cmp -s "$src_file" "$dst_file"; then
      record_skip "$rel"
    else
      stage_starter "$rel" "$dst_file.starter"
    fi
  else
    # Not present before this run -> this run adds it (real: copied above;
    # dry-run: would be copied). Mode-independent by construction.
    record_add "$rel"
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
# lefthook (and some husky setups) can be wired without a package.json entry, via
# a standalone config file. Detect those too, or setup.sh's core.hooksPath switch
# would silently hijack an existing chain the package.json grep never saw.
for hookcfg in lefthook.yml lefthook.yaml .lefthook.yml .lefthook.yaml lefthook.toml .lefthook.toml lefthook.json lefthook.jsonc .lefthook.json .lefthook.jsonc; do
  if [ -f "$TARGET/$hookcfg" ]; then
    HOOK_WARNING=1
    break
  fi
done
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
if [ "${#STARTER_PRESERVED[@]}" -gt 0 ]; then
  echo ""
  echo "Left untouched, a *.starter already existed ($(( ${#STARTER_PRESERVED[@]} )) file(s)):"
  for f in "${STARTER_PRESERVED[@]}"; do
    echo "  ! $f.starter (pre-existing, not overwritten)"
  done
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
