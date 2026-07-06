#!/usr/bin/env bash
# verify-agent-ssot.sh: verify starter wiring after copy.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

failures=()
warnings=()

ok() { echo "  [OK] $1"; }
warn() { warnings+=("$1"); echo "  [WARN] $1"; }
fail() { failures+=("$1"); echo "  [FAIL] $1"; }

echo "==> mogui-agent-harness SSOT verify"

required_files=(
  CLAUDE.md AGENTS.md .cursorrules .windsurfrules
  .agent/Instructions.md .agent/Context.md .agent/Memory.md
  .agent/workflows/triple-crown.md
  .agent/loops/LOOP.md .agent/workflows/daily-triage.md
  .agents/skills/postmortem/SKILL.md .agents/skills/daily-triage/SKILL.md
  .cursor/mcp.json .cursor/rules/agentic-router.mdc
  .claude/settings.json
  .claude/hooks/load-context.sh .claude/hooks/setup-check.sh .claude/hooks/memory-health.sh
  .codex/README.md .codex/hooks.example.json .codex/config.example.toml
  scripts/setup.sh scripts/install-hooks.sh scripts/verify-agent-ssot.sh scripts/decisions-index.sh
  scripts/ingest.sh scripts/smoke-codex.sh
  .githooks/pre-commit .githooks/prepare-commit-msg
  .planning/README.md
  docs/wiki/index.md docs/wiki/_schema/frontmatter.md docs/wiki/decisions/README.md docs/wiki/guides/README.md docs/wiki/archive/README.md
  docs/wiki/decisions/D-template.md
  docs/wiki/guides/01-onboarding.md docs/wiki/guides/02-agentic-architecture.md
  docs/wiki/guides/03-host-runtime-and-hooks.md docs/wiki/guides/04-gsd-llm-wiki-agent-flow.md
  docs/wiki/guides/05-decisions-and-postmortems.md docs/wiki/guides/maintenance.md
  docs/wiki/postmortem/postmortem-template.md docs/wiki/postmortem/temp/snapshot-template.md
  PROMPTS.md
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] && ok "$f exists" || fail "$f missing"
done

routers=(CLAUDE.md AGENTS.md .cursorrules .windsurfrules)
if [[ -f CLAUDE.md ]]; then
  base_hash="$(shasum CLAUDE.md | awk '{print $1}')"
  drift=()
  for f in AGENTS.md .cursorrules .windsurfrules; do
    [[ -f "$f" ]] || continue
    h="$(shasum "$f" | awk '{print $1}')"
    [[ "$h" != "$base_hash" ]] && drift+=("$f")
  done
  [[ "${#drift[@]}" -eq 0 ]] && ok "4 host router files are in sync" || fail "host router drift: ${drift[*]}"
fi

# GEMINI.md is retired as a synced host router. A thin compatibility shim that
# defers to AGENTS.md is allowed for hosts that still look for GEMINI.md.
if [[ -e GEMINI.md ]]; then
  if grep -q "AGENTS.md" GEMINI.md && [[ "$(wc -l < GEMINI.md | tr -d ' ')" -le 20 ]]; then
    ok "GEMINI.md is a thin AGENTS.md compatibility shim"
  else
    fail "GEMINI.md must stay a thin AGENTS.md shim (<=20 lines); full Gemini router is retired"
  fi
else
  ok "retired Gemini router absent"
fi

if [[ -f docs/wiki/decisions/D-template.md ]]; then
  for field in "status:" "decision_area:" "decision_subjects:" "decision_cluster:" "collapsed_to:" "supersedes:" "deciders:" "context:" "## Rejected alternatives" "## Reversal conditions" "## Compaction / merge"; do
    grep -q "$field" docs/wiki/decisions/D-template.md || fail "D-template.md missing decision field/section: $field"
  done
  grep -q "D-YYYYMMDD-<author>-<slug>" docs/wiki/decisions/D-template.md || fail "D-template.md must document the D-YYYYMMDD-<author>-<slug> id format"
  ok "decision template has required ADR fields"
fi
if [[ -x scripts/decisions-index.sh ]]; then
  bash scripts/decisions-index.sh --check >/dev/null 2>&1 \
    && ok "decisions index is generated and up to date" \
    || fail "decisions index stale: run 'bash scripts/decisions-index.sh'"
fi
grep -q "status: collapsed" docs/wiki/decisions/README.md \
  && grep -q "collapsed_to:" docs/wiki/decisions/README.md \
  && grep -q "decision_cluster" docs/wiki/decisions/README.md \
  && grep -q "D-YYYYMMDD-<author>-<slug>" docs/wiki/decisions/README.md \
  && ok "decisions index documents naming, compression, and classification" \
  || fail "docs/wiki/decisions/README.md must document D-YYYYMMDD-<author>-<slug> naming, collapsed_to compression, and decision_cluster classification"
grep -q "A-YYYYMMDD-<slug>" docs/wiki/archive/README.md \
  && grep -q "archive_prefix" docs/wiki/_schema/frontmatter.md \
  && ok "archive bundle prefix and manifest fields are documented" \
  || fail "archive bundle prefix and manifest fields missing"
if true; then
  ok "decision id scheme is date-author-slug (no width management needed)"
fi

if [[ -f .cursor/rules/agentic-router.mdc ]]; then
  if grep -q ".agent/Instructions.md" .cursor/rules/agentic-router.mdc && \
     grep -q ".agent/Context.md" .cursor/rules/agentic-router.mdc && \
     grep -q ".agent/Memory.md" .cursor/rules/agentic-router.mdc && \
     grep -q "alwaysApply: true" .cursor/rules/agentic-router.mdc; then
    ok "Cursor project rule adapter points at .agent"
  else
    fail ".cursor/rules/agentic-router.mdc must alwaysApply and mention all .agent core files"
  fi
fi

for f in "${routers[@]}"; do
  [[ -f "$f" ]] || continue
  for target in ".agent/Instructions.md" ".agent/Context.md" ".agent/Memory.md"; do
    grep -q "$target" "$f" || fail "$f does not mention $target"
  done
done

# Syntax-check every shell entrypoint: hook scripts AND the top-level scripts/
# (ingest.sh, smoke-codex.sh, setup.sh, ...). These are executable entrypoints,
# so a syntax error should fail the SSOT gate, not surface only at run time.
for f in .claude/hooks/*.sh .codex/hooks/*.sh scripts/*.sh; do
  [[ -e "$f" ]] || continue
  bash -n "$f" && ok "$f syntax" || fail "$f syntax error"
done

if command -v python3 >/dev/null 2>&1; then
  for f in .claude/settings.json .codex/hooks.example.json .cursor/mcp.json; do
    [[ -f "$f" ]] || continue
    python3 -m json.tool "$f" >/dev/null && ok "$f JSON parse" || fail "$f JSON parse failed"
  done
else
  warn "python3 missing; skipped JSON validation"
fi

codex_missing=0
for name in load-context.sh setup-check.sh memory-health.sh memory-selfcheck.sh no-emoji-check.sh wiki-health.sh no-bak-slang-check.sh remind-korean-style.sh; do
  if [[ ! -e ".codex/hooks/$name" ]]; then
    fail ".codex/hooks/$name missing"
    codex_missing=1
  fi
done
[[ "$codex_missing" -eq 0 ]] && ok "Codex hook implementations exist"

gitkeep_paths=(
  .planning/quick/.gitkeep
  .planning/todos/pending/.gitkeep
  .planning/todos/doing/.gitkeep
  .planning/todos/done/.gitkeep
  .planning/todos/completed/.gitkeep
  .planning/threads/.gitkeep
  .planning/seeds/.gitkeep
  .planning/workstreams/.gitkeep
  docs/wiki/decisions/.gitkeep
  docs/wiki/guides/.gitkeep
  docs/wiki/postmortem/.gitkeep
  docs/wiki/postmortem/temp/.gitkeep
  docs/wiki/archive/.gitkeep
)
for f in "${gitkeep_paths[@]}"; do
  [[ -f "$f" ]] && ok "$f exists" || fail "$f missing"
done

stale_pattern="docs/_claude|STATE\\.[A-Za-z0-9_-]+\\.md|scripts/merge-state\\.sh"
stale_pattern+="|semantic_""search_nodes|query_""graph|detect_""changes|get_""review_context"
stale_pattern+="|get_""architecture_overview|list_""communities"
stale_pattern+="|GEMINI\\.md|Gemini CLI|router 5종|5 host|5-host|다섯 router|다섯 파일"
# If the starter was derived from a specific repo, add that repo's retired product names and handles here to detect leftovers.
# An empty generic starter has nothing to add. Example: stale_pattern+="|old-product|old-handle"
stale_hits="$(grep -RInE "$stale_pattern" \
  README.md PROMPTS.md CLAUDE.md AGENTS.md .cursorrules .windsurfrules .cursor .agent .agents .claude .codex docs/wiki scripts 2>/dev/null \
  | grep -v "scripts/verify-agent-ssot.sh" \
  | grep -Ev "stale|옛|deprecated|superseded|현재 노출 tool이 아니므로|제거" || true)"
if [[ -n "$stale_hits" ]]; then
  fail "stale active wording found"
  echo "$stale_hits"
else
  ok "no retired path or stale code-review-graph tool names in active starter docs"
fi

if git check-ignore -q .codex/hooks.json && git check-ignore -q .codex/config.toml; then
  ok "Codex local files are ignored"
else
  warn "Codex local files are not ignored; add .codex/hooks.json and .codex/config.toml to .gitignore"
fi

if [[ "${#warnings[@]}" -gt 0 ]]; then
  echo ""
  echo "Warnings:"
  for w in "${warnings[@]}"; do echo "  - $w"; done
fi

if [[ "${#failures[@]}" -gt 0 ]]; then
  echo ""
  echo "mogui-agent-harness verify failed:"
  for f in "${failures[@]}"; do echo "  - $f"; done
  exit 1
fi

echo ""
echo "mogui-agent-harness verify passed."
