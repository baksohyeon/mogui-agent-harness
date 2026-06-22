#!/usr/bin/env bash
# wiki-lint.sh: docs/wiki/ consistency check script.
#
# Run manually each quarter or after adding a new ADR/page.
# Complements the SessionStart hook's wiki-health.sh (stale detection).
#
# Checks:
#   1. Orphan pages: wiki files not in the wiki/index.md catalog
#   2. Broken links: whether files referenced by body markdown links actually exist
#   3. Duplicate frontmatter id
#   3b. id matches filename (decisions/ + postmortem/)
#   4. Missing last_verified_at (decisions/ + postmortem/ only)
#   5. Dangling relations[].id: whether the id referenced by relations exists in a real wiki file
#   6. Dangling code_refs[].file: whether the repo file referenced by code_refs actually exists
#   7. audit_log[] chronological order: whether the at: field is sorted in reverse
#   8. Vocabulary anti-pattern (bak- slang): Korean projects only. English projects can delete section 8.
#   9. Active operational doc stale guard: per-project list of retired terms (empty by default)
#
# Usage: bash scripts/wiki-lint.sh
#
# This script is stack-neutral. It only needs python3 (for frontmatter parsing).
# In a project with a package.json you can add a "wiki:lint": "bash scripts/wiki-lint.sh" alias.

set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 1
cd "$ROOT"

WIKI_DIR="docs/wiki"
INDEX_FILE="$WIKI_DIR/index.md"

errors=0
warnings=0

# ============================================================
# 1. Orphan pages (wiki files not in index.md)
# ============================================================
echo "[1] Checking orphan pages..."
all_pages=$(find "$WIKI_DIR" -name "*.md" \
    -not -path "*/archive/*" \
    -not -path "*/_schema/*" \
    -not -name "index.md" \
    -not -name "README.md" \
    | sort)

# Index decision: a page is considered indexed if (a) it is linked from index.md or any nested README.md/index.md, or
# (b) it lives under a "browse folder" that index.md links to as a folder (e.g. (postmortem/), (decisions/)).
orphans=$(python3 - "$ROOT" <<'PYORPH'
import sys, pathlib, re
root = pathlib.Path(sys.argv[1]); wiki = root / "docs" / "wiki"
def excluded(p): s = str(p); return "/archive/" in s or "/_schema/" in s
index = wiki / "index.md"
if not index.exists():
    print(""); sys.exit(0)
itext = index.read_text(encoding="utf-8", errors="ignore")
browse = set()
for m in re.findall(r'\(([^)]+/)\)', itext):          # folder links like (postmortem/)
    if m.startswith("http"): continue
    browse.add(str((index.parent / m).resolve()))
indexed = set()
for idx in list(wiki.rglob("README.md")) + list(wiki.rglob("index.md")):
    if excluded(idx): continue
    for link in re.findall(r'\(([^)]+\.md)\)', idx.read_text(encoding="utf-8", errors="ignore")):
        if link.startswith("http"): continue
        indexed.add(str((idx.parent / link).resolve()))
out = []
for p in sorted(wiki.rglob("*.md")):
    if excluded(p) or p.name in ("index.md", "README.md"): continue
    if p.name.endswith("template.md"): continue    # *template.md = scaffolding, not a catalog target
    if "/temp/" in str(p): continue                # temp/ holds transient snapshots
    rp = str(p.resolve())
    if rp in indexed: continue
    if any(rp.startswith(b.rstrip('/') + '/') for b in browse): continue
    out.append(str(p))
print("\n".join(out))
PYORPH
)
if [[ -n "$orphans" ]]; then
    echo "  WARN: pages not registered in index.md:"
    echo "$orphans" | sed 's/^/    - /'
    warnings=$((warnings + 1))
else
    echo "  PASS: all pages are registered in index.md"
fi

# ============================================================
# 2. Broken internal links (whether files referenced by markdown links exist)
# ============================================================
echo "[2] Checking internal links..."
broken_links=0
while IFS= read -r file; do
    grep -oE '\]\(\.{0,2}/[^)]+\.md\)' "$file" 2>/dev/null | while read -r link; do
        target=$(echo "$link" | sed -E 's/^\]\((.+)\)$/\1/')
        dir=$(dirname "$file")
        resolved=$(cd "$dir" && realpath -m "$target" 2>/dev/null || echo "")
        [[ -z "$resolved" ]] && continue
        if [[ ! -f "$resolved" ]]; then
            echo "  WARN: $file -> $target (target missing)"
            broken_links=$((broken_links + 1))
        fi
    done
done < <(find "$WIKI_DIR" .agent -name "*.md" 2>/dev/null)
[[ $broken_links -eq 0 ]] && echo "  PASS: no broken links"

# ============================================================
# 3. Duplicate frontmatter id
# ============================================================
echo "[3] Checking duplicate id..."
dup_ids=$(find "$WIKI_DIR" -name "*.md" \
    -not -path "*/archive/*" \
    -not -path "*/_schema/*" \
    -not -name "*.template.md" \
    -exec awk '
        /^---$/{n++; next}
        n==1 && /^id:/ { gsub(/[ \t]+/, " "); print $2 " " FILENAME }
    ' {} \; | sort | awk '{print $1}' | uniq -d)

if [[ -n "$dup_ids" ]]; then
    echo "  ERROR: duplicate id:"
    for id in $dup_ids; do
        echo "    - files using $id:"
        find "$WIKI_DIR" -name "*.md" -exec grep -l "^id: $id" {} \; | sed 's/^/      /'
    done
    errors=$((errors + 1))
else
    echo "  PASS: no duplicate id"
fi

# ============================================================
# 3b. id matches filename (decisions) and id/seq match filename (postmortem)
#       - decisions/D-NNN.md : id == filename stem (exact match)
#       - postmortem/NNN-... : id starts with postmortem-<NNN>- and seq == leading number
#     *.template.md is a placeholder, so it is excluded.
# ============================================================
echo "[3b] Checking id matches filename (decisions/ + postmortem/)..."
id_mismatch=0
for f in "$WIKI_DIR"/decisions/D-*.md; do
    [[ -e "$f" ]] || continue
    case "$f" in *.template.md) continue;; esac
    stem=$(basename "$f" .md)
    fid=$(awk '/^---$/{n++; next} n==1 && /^id:/{sub(/^id:[ \t]*/,""); gsub(/"/,""); sub(/[ \t]+$/,""); print; exit}' "$f")
    if [[ "$fid" != "$stem" ]]; then
        echo "  ERROR: $f : id '$fid' != filename '$stem'"
        id_mismatch=$((id_mismatch + 1))
    fi
done
for f in "$WIKI_DIR"/postmortem/[0-9]*.md; do
    [[ -e "$f" ]] || continue
    base=$(basename "$f" .md)
    num=$(echo "$base" | sed -E 's/^0*([0-9]+).*/\1/')
    pad=$(printf '%03d' "$num")
    fid=$(awk '/^---$/{n++; next} n==1 && /^id:/{sub(/^id:[ \t]*/,""); gsub(/"/,""); sub(/[ \t]+$/,""); print; exit}' "$f")
    fseq=$(awk '/^---$/{n++; next} n==1 && /^seq:/{sub(/^seq:[ \t]*/,""); sub(/[ \t]+$/,""); print; exit}' "$f")
    if [[ "$fid" != postmortem-"$pad"-* ]]; then
        echo "  ERROR: $f : id '$fid' does not start with 'postmortem-$pad-'"
        id_mismatch=$((id_mismatch + 1))
    fi
    if [[ -n "$fseq" && "$fseq" -ne "$num" ]]; then
        echo "  ERROR: $f : seq '$fseq' != filename number '$num'"
        id_mismatch=$((id_mismatch + 1))
    fi
done
if [[ $id_mismatch -gt 0 ]]; then
    echo "  NOTE: id/filename mismatch violates the ADR/postmortem primary key contract and must be fixed"
    errors=$((errors + 1))
else
    echo "  PASS: id/seq matches the filename"
fi

# ============================================================
# 4. Missing last_verified_at: decisions/ + postmortem/ only
#    (prose-area guides have no fixed verify cadence, so they are excluded)
# ============================================================
echo "[4] Checking last_verified_at field (decisions/ + postmortem/)..."
missing_lv=$(find "$WIKI_DIR/decisions" "$WIKI_DIR/postmortem" -name "*.md" \
    -not -path "*/archive/*" \
    -not -path "*/temp/*" \
    -not -name "README.md" 2>/dev/null | while read -r f; do
        if ! awk '/^---$/{n++} n==1 && /^last_verified_at:/{found=1; exit} END{exit !found}' "$f"; then
            echo "$f"
        fi
    done)

if [[ -n "$missing_lv" ]]; then
    echo "  WARN: last_verified_at missing:"
    echo "$missing_lv" | sed 's/^/    - /'
    warnings=$((warnings + 1))
else
    echo "  PASS: every page in decisions/ + postmortem/ has last_verified_at"
fi

# ============================================================
# 5-7. dangling relations[].id / code_refs[].file / audit_log[] chronological order
#
# Scans every wiki .md in a single python process and prints results in 3 categories.
# Check scope: docs/wiki/ (excluding archive / _schema / temp). Warn-only.
# ============================================================
echo "[5-7] Checking relations / code_refs / audit_log (python)..."
set +e
python3 - "$ROOT" <<'PY'
import os, re, sys, pathlib

root = pathlib.Path(sys.argv[1])
wiki = root / "docs" / "wiki"

def excluded(p: pathlib.Path) -> bool:
    s = str(p)
    return "/archive/" in s or "/_schema/" in s or "/temp/" in s

def parse_frontmatter(text: str):
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    fm = []
    for line in lines[1:]:
        if line.strip() == "---":
            break
        fm.append(line)
    return fm

def extract_id(fm):
    for line in fm:
        m = re.match(r'^id:\s*["\']?([^\s"\']+)', line)
        if m:
            return m.group(1)
    return None

def extract_block_items(fm, key, item_field):
    out = []
    in_block = False
    for line in fm:
        if re.match(rf'^{key}:\s*$', line) or re.match(rf'^{key}:\s*\[\s*\]\s*$', line):
            in_block = True
            continue
        if in_block:
            if re.match(r'^[a-zA-Z_]+:', line):
                in_block = False
                continue
            m = re.match(rf'^\s*-?\s*{item_field}:\s*["\']?([^\s"\']+)', line)
            if m:
                out.append(m.group(1))
    return out

def extract_audit_at(fm):
    out = []
    in_block = False
    for line in fm:
        if re.match(r'^audit_log:\s*$', line) or re.match(r'^audit_log:\s*\[\s*\]\s*$', line):
            in_block = True
            continue
        if in_block:
            if re.match(r'^[a-zA-Z_]+:', line):
                in_block = False
                continue
            m = re.search(r'at:\s*(\d{4}-\d{2}-\d{2})', line)
            if m:
                out.append(m.group(1))
    return out

def normalize(s: str) -> str:
    s2 = s.replace("-", "")
    s2 = re.sub(r'([A-Za-z]+)0+(\d)', r'\1\2', s2)
    return s2

def is_placeholder(s: str) -> bool:
    s = s.strip()
    if not s:
        return True
    if s[0] in "(<-~":
        return True
    if s.lower().startswith(("n/a", "tbd", "none")):
        return True
    if '가' <= s[0] <= '힯':
        return True
    return False

# Collecting known ids includes _schema/ too (relations may point to schema docs).
# Only archive/temp are excluded. The dangling-check *iteration* below skips _schema via excluded().
def collectable(p: pathlib.Path) -> bool:
    s = str(p)
    return "/archive/" not in s and "/temp/" not in s

known_raw = {}
known_norm = {}
for p in wiki.rglob("*.md"):
    if not collectable(p):
        continue
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    fm = parse_frontmatter(text)
    if not fm:
        continue
    rid = extract_id(fm)
    if rid:
        known_raw[rid] = str(p)
        known_norm[normalize(rid)] = str(p)

dangling_rel = []
dangling_cr = []
audit_bad = []

for p in wiki.rglob("*.md"):
    if excluded(p):
        continue
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    fm = parse_frontmatter(text)
    if not fm:
        continue

    # postmortem = point-in-time record (historical). relations/code_refs liveness applies to living docs only.
    if "/postmortem/" not in str(p):
        for ref_id in extract_block_items(fm, "relations", "id"):
            if ref_id in known_raw:
                continue
            if normalize(ref_id) in known_norm:
                continue
            dangling_rel.append((str(p), ref_id))

        for ref_file in extract_block_items(fm, "code_refs", "file"):
            if is_placeholder(ref_file):
                continue
            if not (root / ref_file).exists():
                dangling_cr.append((str(p), ref_file))

    ats = extract_audit_at(fm)
    for i in range(1, len(ats)):
        if ats[i] < ats[i-1]:
            audit_bad.append((str(p), ats[i-1], ats[i]))
            break

rel = "PASS"
if dangling_rel:
    print(f"  WARN: relations[].id dangling ({len(dangling_rel)} found):")
    for f, rid in dangling_rel[:30]:
        print(f"    - {f} -> {rid}")
    if len(dangling_rel) > 30:
        print(f"    ... and {len(dangling_rel)-30} more")
    rel = "WARN"
else:
    print("  PASS [5]: all relations[].id resolve")

cr = "PASS"
if dangling_cr:
    print(f"  WARN: code_refs[].file dangling ({len(dangling_cr)} found):")
    for f, rf in dangling_cr[:30]:
        print(f"    - {f} -> {rf}")
    if len(dangling_cr) > 30:
        print(f"    ... and {len(dangling_cr)-30} more")
    cr = "WARN"
else:
    print("  PASS [6]: all code_refs[].file exist")

al = "PASS"
if audit_bad:
    print(f"  WARN: audit_log[].at out of order ({len(audit_bad)} found):")
    for f, prev, cur in audit_bad[:30]:
        print(f"    - {f}: {prev} -> {cur}")
    if len(audit_bad) > 30:
        print(f"    ... and {len(audit_bad)-30} more")
    al = "WARN"
else:
    print("  PASS [7]: all audit_log[].at in chronological order")

status = 0
if rel == "WARN": status |= 1
if cr == "WARN":  status |= 2
if al == "WARN":  status |= 4
sys.exit(status)
PY

py_status=$?
set -e
(( py_status & 1 )) && warnings=$((warnings + 1)) || true
(( py_status & 2 )) && warnings=$((warnings + 1)) || true
(( py_status & 4 )) && warnings=$((warnings + 1)) || true

# ============================================================
# 8. Vocabulary anti-pattern: "bak-" English-calque slang (Korean projects only)
#    Delete this block for English projects.
# ============================================================
echo "[8] Checking vocabulary anti-pattern (bak- slang)..."
bak_hits=$(grep -rnE "(^|[^가-힣])(내리|들이|뒤|되|처|쳐)?박(는다|는|다|고|지|네|나|아서|아야|아도|아라|아두|아놓|아진|아졌|아버|아|어서|어야|어도|어|은|을|음|으면|으니|으려|으며|으세|으러|았다|았어|았고|았던|았지|았네|았으|았|겠|둔|혀서|혀요|혀있|혀버|혀두|혀놓|혀도|혀야|혀|혔다|혔어|혔고|혔던|혔지|혔|히다|히고|히면|히니|히는|히어|히었|히게|히며|히|힌|힘)" "$WIKI_DIR" .agent 2>/dev/null \
    | grep -v "korean-persona.md" \
    | grep -v "no_bak_slang" \
    | grep -v "/_schema/" \
    | grep -v "/postmortem/" || true)
if [[ -n "$bak_hits" ]]; then
    echo "  WARN: bak- slang found (replace with: 넣다 / 추가하다 / 적어두다 / 명시하다 / 들어있다 / 기록하다 / 끼워두다):"
    echo "$bak_hits" | sed 's/^/    /'
    warnings=$((warnings + 1))
else
    echo "  PASS: no bak- slang found"
fi

# ============================================================
# 9. Active operational doc stale guard
#
# Prevents retired terms/paths/tool names from lingering *as if they were current rules* in active operational docs.
# Add a regex to STALE_PATTERNS each time you make a retirement decision (e.g. an old script name, an old command).
# If a negative-context word like "폐기" (retired) is on the same line, it passes (the annotation is the intended result).
# The default is empty, so it passes.
# ============================================================
echo "[9] Active operational doc stale guard..."
STALE_PATTERNS=(
  # e.g. "old-script\.sh"
  # e.g. "deprecated-command"
)
active_targets=(
  README.md
  CLAUDE.md AGENTS.md .cursorrules .windsurfrules .cursor
  .agent
  docs/wiki/guides
  docs/wiki/index.md
  scripts/setup.sh
)
if [[ ${#STALE_PATTERNS[@]} -eq 0 ]]; then
    echo "  PASS: no stale patterns configured (checks run once the project adds retired terms)"
else
    pattern_re=$(IFS='|'; echo "${STALE_PATTERNS[*]}")
    existing_targets=()
    for t in "${active_targets[@]}"; do [[ -e "$t" ]] && existing_targets+=("$t"); done
    stale_hits=$(grep -rnE "$pattern_re" "${existing_targets[@]}" 2>/dev/null \
        | grep -Ev "폐기|쓰지 않는다|말하지 않는다|제거|not|stale|역사|옛|deprecated|superseded" || true)
    if [[ -n "$stale_hits" ]]; then
        echo "  ERROR: stale wording lingers as if it were a current rule in active operational docs:"
        echo "$stale_hits" | sed 's/^/    /'
        errors=$((errors + 1))
    else
        echo "  PASS: no stale wording in active operational docs"
    fi
fi

# ============================================================
# Result
# ============================================================
echo ""
echo "─────────────────────────────────────"
if (( errors > 0 )); then
    echo "FAIL: $errors error(s) (must fix)"
    exit 1
elif (( warnings > 0 )); then
    echo "WARN: $warnings warning(s) (review recommended)"
    exit 0
else
    echo "PASS: all checks passed"
fi
