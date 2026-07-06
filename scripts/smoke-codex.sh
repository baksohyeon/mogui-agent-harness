#!/usr/bin/env bash
# smoke-codex.sh: Codex parity smoke check.
#
# Verifies, statically and without network, that the Codex wiring under
# .codex/ actually drives the same first-entry autonomous bootstrap contract
# as the other three routers. This is the Codex-side counterpart to
# scripts/verify-agent-ssot.sh (which already checks that .codex/hooks/*
# referenced in hooks.example.json exist and that hooks.example.json parses
# as JSON). This script reuses that style but focuses specifically on the
# Codex parity question, plus an optional live behavioral smoke via
# `codex exec`.
#
# Usage:
#   bash scripts/smoke-codex.sh          # static checks only
#   bash scripts/smoke-codex.sh --live   # also run codex exec
#
# Exit code is non-zero if any static check fails. The optional live Codex
# behavioral smoke never affects the exit code: it either runs and reports
# its result, or degrades gracefully to a printed manual command. It never
# waits on interactive input.

# Intentionally no -e: this script must continue past a failing check to
# accumulate failures[] and capture the guarded codex exec exit code.
set -uo pipefail

RUN_LIVE=0
case "${1:-}" in
  "")
    ;;
  --live)
    RUN_LIVE=1
    ;;
  -h|--help)
    sed -n '/^# Usage:/,/^$/p' "$0"
    exit 0
    ;;
  *)
    echo "Usage: bash scripts/smoke-codex.sh [--live]" >&2
    exit 2
    ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || { echo "FATAL: could not cd to repo root: $REPO_ROOT" >&2; exit 1; }

failures=()

ok() { echo "  [PASS] $1"; }
fail() { failures+=("$1"); echo "  [FAIL] $1"; }

echo "==> Codex parity smoke check"

# ============================================================================
# Check 1: hooks.example.json references only hook scripts that exist
# ============================================================================
if [[ -f .codex/hooks.example.json ]] && command -v python3 >/dev/null 2>&1; then
  missing_refs="$(python3 - <<'PY'
import json
import re
import sys

with open(".codex/hooks.example.json", encoding="utf-8") as fh:
    text = fh.read()

try:
    data = json.loads(text)
except json.JSONDecodeError as exc:
    print(f"JSON_PARSE_ERROR: {exc}")
    sys.exit(0)

missing = []
# Commands may be a bare hook script path, or a longer shell command that
# happens to reference a .codex/hooks/*.sh path. Scan every string value in
# the structure for .codex/hooks/ references.
pattern = re.compile(r"\.codex/hooks/[A-Za-z0-9_.\-]+")

def walk(node):
    if isinstance(node, dict):
        for v in node.values():
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)
    elif isinstance(node, str):
        for ref in pattern.findall(node):
            import os
            if not os.path.exists(ref):
                missing.append(ref)

walk(data)
for m in sorted(set(missing)):
    print(m)
PY
)"
  json_check_exit=$?
  if [[ "$json_check_exit" -ne 0 ]]; then
    fail ".codex/hooks.example.json validator crashed (python3 exit $json_check_exit); treating as failed, not passed"
  elif [[ "$missing_refs" == JSON_PARSE_ERROR:* ]]; then
    fail ".codex/hooks.example.json JSON parse: ${missing_refs#JSON_PARSE_ERROR: }"
  elif [[ -n "$missing_refs" ]]; then
    fail ".codex/hooks.example.json references missing hook script(s): $(echo "$missing_refs" | tr '\n' ' ')"
  else
    ok ".codex/hooks.example.json references only existing .codex/hooks/* scripts"
  fi
elif [[ ! -f .codex/hooks.example.json ]]; then
  fail ".codex/hooks.example.json missing"
else
  fail "python3 not available; cannot validate .codex/hooks.example.json"
fi

# ============================================================================
# Check 2: config.example.toml is valid TOML-ish (light parse)
# ============================================================================
if [[ -f .codex/config.example.toml ]]; then
  if command -v python3 >/dev/null 2>&1; then
    toml_result="$(python3 - <<'PY'
import re

path = ".codex/config.example.toml"
with open(path, encoding="utf-8") as fh:
    lines = fh.readlines()

errors = []
in_array = False  # tracks a 'key = [' opened on an earlier line, not yet closed
for lineno, raw in enumerate(lines, start=1):
    line = raw.rstrip("\n")
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue

    if in_array:
        # Inside a multi-line array: any line is fine until the closing bracket.
        if "]" in stripped:
            in_array = False
        continue

    is_table = re.match(r"^\[[^\]]+\]$", stripped) or re.match(r"^\[\[[^\]]+\]\]$", stripped)
    if is_table:
        continue
    if "=" not in stripped:
        errors.append(f"line {lineno}: expected 'key = value' or a [table] header: {stripped!r}")
        continue
    key, _, value = stripped.partition("=")
    if not key.strip():
        errors.append(f"line {lineno}: empty key before '=': {stripped!r}")
        continue
    value = value.strip()
    if not value:
        errors.append(f"line {lineno}: empty value after '=': {stripped!r}")
        continue
    if value.startswith("[") and "]" not in value:
        # Multi-line array opened here; suppress checks until it closes.
        in_array = True

if in_array:
    errors.append("unterminated array: a '[' was opened but never closed with ']'")

for e in errors:
    print(e)
PY
)"
    toml_check_exit=$?
    if [[ "$toml_check_exit" -ne 0 ]]; then
      fail ".codex/config.example.toml validator crashed (python3 exit $toml_check_exit); treating as failed, not passed"
    elif [[ -n "$toml_result" ]]; then
      fail ".codex/config.example.toml light parse found issues: $(echo "$toml_result" | tr '\n' '; ')"
    else
      ok ".codex/config.example.toml light parse (no obvious syntax error)"
    fi
  else
    fail "python3 not available; cannot light-parse .codex/config.example.toml"
  fi
else
  fail ".codex/config.example.toml missing"
fi

# ============================================================================
# Check 3: AGENTS.md exists and contains the First-entry autonomous
# bootstrap section added in Task 2
# ============================================================================
if [[ -f AGENTS.md ]]; then
  ok "AGENTS.md exists"
  if grep -q "^## First-entry autonomous bootstrap" AGENTS.md; then
    ok "AGENTS.md contains the 'First-entry autonomous bootstrap' section"
  else
    fail "AGENTS.md is missing the 'First-entry autonomous bootstrap' section"
  fi
  # A section check alone can pass while AGENTS.md has drifted from the other
  # routers (only verify-agent-ssot.sh checked byte-identity before this).
  # Cross-check here too so a PASS actually means Codex reads the same
  # contract as Claude Code, not just a similarly-named section.
  if [[ ! -f CLAUDE.md ]]; then
    fail "CLAUDE.md missing; cannot verify AGENTS.md router parity"
  else
    agents_hash="$(shasum AGENTS.md 2>/dev/null | awk '{print $1}')"
    claude_hash="$(shasum CLAUDE.md 2>/dev/null | awk '{print $1}')"
    if [[ -z "$agents_hash" || -z "$claude_hash" ]]; then
      fail "could not hash AGENTS.md/CLAUDE.md for router parity check"
    elif [[ "$agents_hash" == "$claude_hash" ]]; then
      ok "AGENTS.md is byte-identical to CLAUDE.md (real router parity, not just a matching section)"
    else
      fail "AGENTS.md has drifted from CLAUDE.md (not byte-identical) - run scripts/verify-agent-ssot.sh for the full router-sync report"
    fi
  fi
else
  fail "AGENTS.md missing"
fi

# ============================================================================
# Check 4: the three .agent core files exist
# ============================================================================
for f in .agent/Instructions.md .agent/Context.md .agent/Memory.md; do
  if [[ -f "$f" ]]; then
    ok "$f exists"
  else
    fail "$f missing"
  fi
done

# ============================================================================
# Static summary
# ============================================================================
echo ""
if [[ "${#failures[@]}" -gt 0 ]]; then
  echo "Static checks: FAIL"
  for f in "${failures[@]}"; do echo "  - $f"; done
  static_exit=1
else
  echo "Static checks: PASS"
  static_exit=0
fi

# ============================================================================
# Optional live Codex behavioral smoke (PROMPTS.md #4 self-orientation check)
#
# This section never changes the script's exit code. It is a best-effort
# behavioral confirmation, gated on:
#   - the `codex` CLI being installed
#   - `codex exec` supporting a non-interactive, sandboxed, read-only,
#     no-approval-prompt invocation (verified against codex-cli 0.142.5:
#     `codex exec --sandbox read-only --skip-git-repo-check` runs with
#     approval policy defaulting to "never" under `exec`, reads stdin
#     from /dev/null so it cannot block on a TTY, and returns promptly)
#   - a hard timeout so it can never hang the script
#
# If any of this is not available, the script prints the exact manual
# command instead and moves on.
# ============================================================================
echo ""
echo "==> Optional live Codex behavioral smoke (PROMPTS.md #4)"

SELF_ORIENTATION_PROMPT='Answer using only the files in this repo (no outside knowledge).
1. What is this system, and what'"'"'s the difference between the three layers .agent/, .planning/, docs/wiki/?
2. When I say "build feature X," what do you read first before answering, and where do you leave the results?
3. Where do you put closed decisions versus open questions?
4. If anything wasn'"'"'t covered by the files and you had to guess, tell me as is (this matters most).'

manual_command() {
  cat <<EOF
Run this manually to perform the live Codex behavioral smoke:

  codex exec --sandbox read-only --skip-git-repo-check -C "$REPO_ROOT" -- "\$(cat <<'PROMPT'
$SELF_ORIENTATION_PROMPT
PROMPT
)"

EOF
}

LIVE_TIMEOUT_SECS=150

if [[ "$RUN_LIVE" != "1" ]]; then
  echo "  [SKIP] live behavioral smoke is opt-in; rerun with --live to execute codex exec."
  manual_command
elif ! command -v codex >/dev/null 2>&1; then
  echo "  [SKIP] codex CLI not installed; live behavioral smoke must be run manually."
  manual_command
elif ! command -v timeout >/dev/null 2>&1 && ! command -v gtimeout >/dev/null 2>&1; then
  echo "  [SKIP] no 'timeout' (or 'gtimeout') binary available; refusing to run codex exec without a hard timeout."
  manual_command
else
  TIMEOUT_BIN="timeout"
  command -v timeout >/dev/null 2>&1 || TIMEOUT_BIN="gtimeout"

  live_out="$(mktemp -t smoke-codex-live.XXXXXX)"
  live_last="$(mktemp -t smoke-codex-last.XXXXXX)"

  "$TIMEOUT_BIN" "$LIVE_TIMEOUT_SECS" codex exec \
    --sandbox read-only \
    --skip-git-repo-check \
    -C "$REPO_ROOT" \
    -o "$live_last" \
    "$SELF_ORIENTATION_PROMPT" \
    < /dev/null > "$live_out" 2>&1
  live_exit=$?

  if [[ "$live_exit" -eq 0 && -s "$live_last" ]]; then
    echo "  [PASS] codex exec ran non-interactively and returned a response:"
    echo ""
    sed 's/^/      /' "$live_last"
    echo ""
    echo "  Review the answers above by hand against PROMPTS.md #4 expectations"
    echo "  (this script does not grade the answers, only that Codex responded)."
  elif [[ "$live_exit" -eq 124 ]]; then
    echo "  [SKIP] codex exec exceeded the ${LIVE_TIMEOUT_SECS}s hard timeout; treating as unavailable in this environment."
    manual_command
  else
    echo "  [SKIP] codex exec did not complete successfully (exit $live_exit), likely missing auth/network in this environment."
    echo "  Full output:"
    sed 's/^/      /' "$live_out"
    echo ""
    manual_command
  fi

  rm -f "$live_out" "$live_last"
fi

exit "$static_exit"
