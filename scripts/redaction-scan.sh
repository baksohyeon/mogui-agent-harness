#!/usr/bin/env bash
# redaction-scan.sh — fail-closed pre-push / CI scan for secrets and internal identifiers.
#
# gitleaks is the matching engine. This script is what gitleaks does not do: scope
# the scan to tracked or index content, scan commit messages, translate the
# organization rules file into a gitleaks config, and state what was covered.
#
# Usage:
#   scripts/redaction-scan.sh                 # all tracked files (default)
#   scripts/redaction-scan.sh --staged        # index blobs only (not worktree)
#   scripts/redaction-scan.sh --range A..B    # files changed in a range, and those commits' messages
#   scripts/redaction-scan.sh --commit-messages A..B   # message scan in any mode
#   scripts/redaction-scan.sh --help
#
# Exit: 0 clean, 1 findings, 2 cannot decide (missing tool, missing/unusable rules, usage)
#
# Organization-specific rules (REDACTION_EXTRA_PATTERNS)
#   Real company, product, and personal identifiers are deliberately not committed
#   here: this repository is public, so committing them would publish what they
#   protect. Supply them per checkout, one rule per line:
#
#     id|description|regex
#
#   Blank lines and lines beginning with # are skipped. Only the first two pipes
#   separate fields, so a regex may contain a pipe. Every regex must compile.
#   If any rule line is unusable, the scan exits 2 (reduced coverage is not a pass).
#   With REDACTION_REQUIRE_EXTRA=1, a missing or empty file exits 2 instead of
#   scanning with generic rules only.
#
# Exemptions use gitleaks' own mechanisms: a .gitleaksignore fingerprint for one
# finding, or config/gitleaks.toml for a whole class.
#
# Coverage disclosure (always printed): this gate states what is in scope and
# what is not, the same way commit-messages=not-scanned already does. The
# uuid_session rule catches bare 8-4-4-4-12 hex UUID shapes; placeholders and
# path exceptions printed on the scope line are read from config/gitleaks.toml.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BASE_CONFIG="${REPO_ROOT}/config/gitleaks.toml"
LEGACY_ALLOWLIST="${REDACTION_ALLOWLIST:-${SCRIPT_DIR}/redaction-allowlist.txt}"
MODE="tracked"
RANGE=""
COMMIT_RANGE=""
VERBOSE=0
REQUIRE_EXTRA="${REDACTION_REQUIRE_EXTRA:-0}"
COMMIT_MESSAGES_SCANNED="not-scanned"
EXTRA_RULE_COUNT=0
EXTRA_UNUSABLE=0
EXTRA_CONSIDERED=0

usage() {
  # Leading comment block through the blank line before set -euo (coverage
  # disclosure included). Range is derived from the file, not a fixed end line.
  sed -n '2,/^set -euo pipefail$/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) MODE="staged"; shift ;;
    --range)
      MODE="range"
      RANGE="${2:-}"
      if [[ -z "${RANGE}" || "${RANGE}" != *..* ]]; then
        echo "redaction-scan: --range requires A..B" >&2
        exit 2
      fi
      shift 2
      ;;
    --commit-messages)
      COMMIT_RANGE="${2:-}"
      if [[ -z "${COMMIT_RANGE}" ]]; then
        echo "redaction-scan: --commit-messages requires a git range" >&2
        exit 2
      fi
      shift 2
      ;;
    --allowlist)
      if [[ $# -lt 2 || -z "${2}" ]]; then
        echo "redaction-scan: --allowlist requires a path" >&2
        exit 2
      fi
      LEGACY_ALLOWLIST="${2}"
      shift 2
      ;;
    --require-extra) REQUIRE_EXTRA=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "redaction-scan: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "redaction-scan: FAIL — gitleaks is not on PATH; install it (brew install gitleaks) or see https://gitleaks.io" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "redaction-scan: FAIL — python3 is not on PATH; install Python 3 (e.g. brew install python or apt install python3)" >&2
  exit 2
fi
if [[ ! -f "${BASE_CONFIG}" ]]; then
  echo "redaction-scan: FAIL — missing ${BASE_CONFIG}" >&2
  exit 2
fi

# The previous allowlist format is no longer interpreted. Refuse loudly rather
# than ignore it: an installation whose exemptions stopped applying should hear it
# from the gate, not discover it when a finding it had accepted comes back.
if [[ -f "${LEGACY_ALLOWLIST}" ]] \
  && grep -qvE '^[[:space:]]*(#|$)' "${LEGACY_ALLOWLIST}" 2>/dev/null; then
  echo "redaction-scan: FAIL — ${LEGACY_ALLOWLIST} has entries in the retired format." >&2
  echo "redaction-scan: migrate each to a .gitleaksignore fingerprint, or to an allowlist in config/gitleaks.toml, then empty this file." >&2
  exit 2
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
CONFIG="${BASE_CONFIG}"

# Translate the organization rules file into a gitleaks config that extends the
# committed one. The operator-facing format does not change, so no host has to
# convert anything, and the patterns stay outside version control.
if [[ -n "${REDACTION_EXTRA_PATTERNS:-}" ]]; then
  if [[ ! -f "${REDACTION_EXTRA_PATTERNS}" ]]; then
    echo "redaction-scan: FAIL — REDACTION_EXTRA_PATTERNS is set but not a readable file" >&2
    exit 2
  fi
  ORG_CONFIG="${WORK_DIR}/org.toml"
  if python3 - "${REDACTION_EXTRA_PATTERNS}" "${BASE_CONFIG}" "${ORG_CONFIG}" > "${WORK_DIR}/counts" <<'PY'
import re
import sys

source, base, target = sys.argv[1], sys.argv[2], sys.argv[3]
rules, unusable, considered = [], 0, 0
with open(source, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        considered += 1
        parts = line.split("|", 2)
        if len(parts) != 3:
            unusable += 1
            continue
        rule_id, description, regex = (part.strip() for part in parts)
        try:
            re.compile(regex)
        except re.error:
            unusable += 1
            continue
        rules.append((rule_id or f"org_rule_{len(rules)}", description, regex))

with open(target, "w", encoding="utf-8") as out:
    out.write('title = "organization rules"\n\n')
    out.write('[extend]\npath = "%s"\n\n' % base)
    for rule_id, description, regex in rules:
        out.write("[[rules]]\n")
        out.write('id = "%s"\n' % rule_id.replace('"', ""))
        out.write('description = "%s"\n' % description.replace('"', ""))
        out.write("regex = '''%s'''\n\n" % regex)

# Only literal characters can express native script in a rule that actually
# scans: this loader's re.compile gate rejects RE2's brace and property forms
# (backslash x brace, backslash p brace), and the engine canary rejects
# Python's backslash u form, so no escape spelling survives both gates.
native = sum(
    1 for _, _, regex in rules if any(ord(ch) > 127 for ch in regex)
)

# Counts only. This file's contents are what the scan protects, so nothing from it
# is printed here or anywhere else.
print(f"{len(rules)} {unusable} {considered} {native}")
PY
  then
    read -r EXTRA_RULE_COUNT EXTRA_UNUSABLE EXTRA_CONSIDERED EXTRA_NATIVE < "${WORK_DIR}/counts"
  else
    echo "redaction-scan: FAIL — could not read the organization rules file" >&2
    exit 2
  fi
  if [[ "${EXTRA_UNUSABLE}" -gt 0 ]]; then
    # Reduced coverage is not a pass. An unusable required rule must not green
    # a scan that no longer sees what the rule was meant to catch.
    echo "redaction-scan: FAIL — ${EXTRA_UNUSABLE} of ${EXTRA_CONSIDERED} organization rule lines are unusable; cannot load full ruleset" >&2
    exit 2
  fi
  if [[ "${EXTRA_RULE_COUNT}" -gt 0 ]]; then
    CONFIG="${ORG_CONFIG}"
  else
    # The count describes what was loaded, never what the file happened to hold.
    EXTRA_RULE_COUNT=0
  fi
  if [[ "${EXTRA_RULE_COUNT}" -gt 0 && "${EXTRA_NATIVE:-0}" -eq 0 ]]; then
    # A romanization only rule set misses the same identifier in its native
    # spelling; measured live when a Korean name passed a scan whose rules
    # only knew its romanization.
    echo "redaction-scan: WARNING — organization rules contain no native script pattern; romanization only identifier rules miss native spellings" >&2
  fi
fi

# The organization rules were validated by Python's re, and Python is not the
# engine. gitleaks compiles RE2, which rejects constructs Python accepts
# (lookarounds, most visibly), and it rejects them by panicking at config load.
# Every scan under a panicking config finds nothing, which reads as clean.
# Measured live: a lookbehind rule turned the whole scan into a green no-op
# while the summary reported the rules as loaded. So the merged config is
# proven against the actual engine before anything is scanned, and a failure
# names the rule ids only, never the patterns they protect.
if [[ "${CONFIG}" != "${BASE_CONFIG}" ]]; then
  if ! printf 'redaction-scan engine self-test\n' \
    | gitleaks stdin --config "${CONFIG}" --no-banner --exit-code 0 >/dev/null 2>&1; then
    # One Python pass isolates the offending rules: it reuses the same parse
    # the translator applied and probes each rule alone through gitleaks, so
    # the rules file format lives in one shape and an id indented with a tab cannot
    # slip the net. Ids only, never patterns.
    bad_ids=$(python3 - "${REDACTION_EXTRA_PATTERNS}" "${WORK_DIR}" <<'PY'
import subprocess
import sys

source, work_dir = sys.argv[1], sys.argv[2]
bad = []
with open(source, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        rule_id, _description, regex = (part.strip() for part in parts)
        single = f"{work_dir}/single-rule.toml"
        with open(single, "w", encoding="utf-8") as out:
            out.write('title = "single rule probe"\n\n')
            out.write("[[rules]]\n")
            out.write('id = "%s"\n' % rule_id.replace('"', ""))
            out.write('description = "probe"\n')
            out.write("regex = '''%s'''\n" % regex)
        probe = subprocess.run(
            ["gitleaks", "stdin", "--config", single, "--no-banner", "--exit-code", "0"],
            input="x\n", capture_output=True, text=True,
        )
        if probe.returncode != 0:
            bad.append(rule_id)
print(" ".join(bad))
PY
)
    bad_ids="${bad_ids:+ ${bad_ids}}"
    echo "redaction-scan: FAIL — the merged config crashes the engine; organization rule(s) not supported by RE2:${bad_ids:- (rule not isolated; test the file rule by rule)}" >&2
    echo "redaction-scan: rewrite those regexes without lookarounds or other non-RE2 constructs, then re-run." >&2
    exit 2
  fi
fi

# A green scan must not imply coverage it does not have.
if [[ "${EXTRA_RULE_COUNT}" -eq 0 ]]; then
  echo "redaction-scan: WARNING — organization-specific rules not loaded (REDACTION_EXTRA_PATTERNS unset or empty); this scan covers generic patterns only" >&2
  if [[ "${REQUIRE_EXTRA}" == "1" ]]; then
    echo "redaction-scan: FAIL — required organization rules were not loaded" >&2
    exit 2
  fi
fi

list_scan_files() {
  case "${MODE}" in
    tracked) git ls-files -z ;;
    staged)  git diff --cached --name-only -z --diff-filter=ACMR ;;
    range)   git diff --name-only -z --diff-filter=ACMR "${RANGE}" ;;
  esac
}

# A range neither end of which resolves is not an empty range. git prints a
# fatal to stderr and this script used to keep going with zero files and zero
# messages, which read as clean. Measured with an unresolvable left side: OK,
# exit 0. A range that cannot be enumerated is exit 2.
if [[ -n "${RANGE}" ]] && ! git rev-list --max-count=0 "${RANGE}" >/dev/null 2>&1; then
  echo "redaction-scan: FAIL — range does not resolve in this repository: ${RANGE}" >&2
  exit 2
fi
if [[ -n "${COMMIT_RANGE}" && "${COMMIT_RANGE}" != "${RANGE}" ]] \
  && ! git rev-list --max-count=0 "${COMMIT_RANGE}" >/dev/null 2>&1; then
  echo "redaction-scan: FAIL — message range does not resolve: ${COMMIT_RANGE}" >&2
  exit 2
fi

REPORTS="${WORK_DIR}/reports"
SCAN_TREE="${WORK_DIR}/scan-tree"
mkdir -p "${REPORTS}" "${SCAN_TREE}"
report_index=0

# Materialise exactly the bytes we intend to scan into a private tree, then run
# one gitleaks process over that tree. Per-file process spawn was O(N) engine
# startups and timed out as trees grew; a whole-directory scan of the live
# worktree would also pick up untracked scratch. Staged mode reads index blobs
# (git show :path), not worktree files, so a secret staged then deleted from
# the worktree still fails the gate.
materialise_scan_tree() {
  local path dest_dir
  file_count=0
  while IFS= read -r -d '' path; do
    [[ -z "${path}" ]] && continue
    case "${MODE}" in
      staged)
        if ! git cat-file -e ":${path}" 2>/dev/null; then
          continue
        fi
        dest_dir="$(dirname "${SCAN_TREE}/${path}")"
        mkdir -p "${dest_dir}"
        # Only blob index entries are file content. gitlinks/submodules and
        # other types can make `git show` succeed with non-file metadata; that
        # must not materialise as a clean scan of "file content".
        if [[ "$(git cat-file -t ":${path}" 2>/dev/null || true)" != "blob" ]] \
          || ! git show ":${path}" > "${SCAN_TREE}/${path}" 2>/dev/null; then
          echo "redaction-scan: FAIL — cannot read index blob for ${path}" >&2
          exit 2
        fi
        ;;
      *)
        dest_dir="$(dirname "${SCAN_TREE}/${path}")"
        mkdir -p "${dest_dir}"
        if [[ -L "${path}" ]]; then
          # Do not follow the link into target file bytes. Materialise the link
          # text itself (readlink) as a regular scan file so secrets in the
          # target path string (e.g. absolute home paths) still hit the gate.
          if ! readlink "${path}" > "${SCAN_TREE}/${path}" 2>/dev/null; then
            echo "redaction-scan: FAIL — cannot read symlink text for ${path}" >&2
            exit 2
          fi
        else
          [[ -f "${path}" ]] || continue
          # Hardlink when possible to avoid copying large trees; fall back to cp.
          if ! ln "${path}" "${SCAN_TREE}/${path}" 2>/dev/null; then
            cp "${path}" "${SCAN_TREE}/${path}"
          fi
        fi
        ;;
    esac
    file_count=$((file_count + 1))
  done < <(list_scan_files)
}

scan_materialised_tree() {
  report_index=$((report_index + 1))
  local report_path="${REPORTS}/${report_index}.json"
  # Empty tree: write an empty report and skip the engine (no paths to leak).
  if [[ "${file_count}" -eq 0 ]]; then
    printf '[]\n' > "${report_path}"
    return 0
  fi
  # Scan from inside the materialised tree with "." so File and Fingerprint are
  # repository-relative (leak.txt:rule:1), matching .gitleaksignore entries.
  # Passing the absolute SCAN_TREE path makes fingerprints use the temp root and
  # silently disables every existing exemption — measured, not theoretical.
  # Point --gitleaks-ignore-path at the real checkout so the repo's ignore file
  # applies even though the engine cwd is the private tree.
  if ! (
    cd "${SCAN_TREE}"
    gitleaks dir . \
      --config "${CONFIG}" \
      --gitleaks-ignore-path "${REPO_ROOT}" \
      --no-banner \
      --redact \
      --exit-code 0 \
      --report-format json \
      --report-path "${report_path}"
  ) >/dev/null 2>&1; then
    echo "redaction-scan: FAIL — gitleaks failed on materialised scan tree (engine error, not a finding)" >&2
    exit 2
  fi
  # Normalize paths and fingerprints to repo-relative form. Match both the
  # literal SCAN_TREE string the engine was given and its resolved form so
  # macOS /var vs /private/var (and similar symlink roots) cannot leave a
  # temp-path prefix in place. Any remaining absolute path is undecidable.
  if ! python3 - "${report_path}" "${SCAN_TREE}" <<'PY'
import json
import os
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
scan_tree_arg = sys.argv[2]
if not report_path.exists() or report_path.stat().st_size == 0:
    report_path.write_text("[]\n", encoding="utf-8")
    raise SystemExit(0)
try:
    rows = json.loads(report_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"redaction-scan: FAIL — unreadable gitleaks report: {exc}", file=sys.stderr)
    raise SystemExit(1)
if not isinstance(rows, list):
    print("redaction-scan: FAIL — gitleaks report is not a JSON array", file=sys.stderr)
    raise SystemExit(1)

prefixes = []
for candidate in (scan_tree_arg, os.path.realpath(scan_tree_arg), str(Path(scan_tree_arg).resolve())):
    if not candidate:
        continue
    for form in (candidate, candidate.rstrip("/") + "/"):
        if form not in prefixes:
            prefixes.append(form)


def to_repo_relative(path: str) -> str:
    if not path or path == ".":
        return path or "."
    for prefix in prefixes:
        if path == prefix.rstrip("/"):
            return "."
        if prefix.endswith("/") and path.startswith(prefix):
            return path[len(prefix) :]
        if not prefix.endswith("/") and path.startswith(prefix + "/"):
            return path[len(prefix) + 1 :]
    return path


for row in rows:
    file_path = to_repo_relative(row.get("File") or "")
    if file_path.startswith("/") or (len(file_path) > 1 and file_path[1] == ":"):
        print(
            "redaction-scan: FAIL — finding path still absolute after rewrite; "
            "cannot map to repository path for ignore fingerprints",
            file=sys.stderr,
        )
        raise SystemExit(1)
    row["File"] = file_path
    fingerprint = row.get("Fingerprint") or ""
    if fingerprint:
        # Fingerprint is "path:rule:line" (and optional commit). Rewrite only the
        # path segment(s) before the rule id when the engine left a temp prefix.
        parts = fingerprint.split(":")
        if len(parts) >= 3:
            # rule id is the segment that matches RuleID when present; path may
            # itself contain colons on Windows. Prefer RuleID from the row.
            rule = row.get("RuleID") or ""
            if rule and rule in parts:
                idx = parts.index(rule)
                path_part = to_repo_relative(":".join(parts[:idx]))
                row["Fingerprint"] = ":".join([path_part, *parts[idx:]])
            else:
                row["Fingerprint"] = to_repo_relative(parts[0]) + ":" + ":".join(parts[1:])
report_path.write_text(json.dumps(rows), encoding="utf-8")
PY
  then
    exit 2
  fi
}

scan_commit_messages() {
  # gitleaks does not read commit messages: a key present only in a message
  # returns no findings while the same key in file content is found. Measured,
  # which is why this loop exists.
  local range="$1"
  local count=0 sha
  while IFS= read -r sha; do
    [[ -z "${sha}" ]] && continue
    report_index=$((report_index + 1))
    if ! git log -1 --format=%B "${sha}" \
      | gitleaks stdin \
          --config "${CONFIG}" \
          --no-banner \
          --redact \
          --exit-code 0 \
          --report-format json \
          --report-path "${REPORTS}/${report_index}.json" \
          >/dev/null 2>&1; then
      echo "redaction-scan: FAIL — gitleaks failed on commit ${sha:0:12} message (engine error, not a finding)" >&2
      exit 2
    fi
    if [[ -s "${REPORTS}/${report_index}.json" ]]; then
      if ! python3 - "${REPORTS}/${report_index}.json" "commit:${sha:0:12}" <<'PY'
import json
import sys

path, label = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as handle:
        rows = json.load(handle)
except (OSError, json.JSONDecodeError) as exc:
    print(f"redaction-scan: FAIL — unreadable gitleaks report: {exc}", file=sys.stderr)
    raise SystemExit(3)
for row in rows:
    row["File"] = label
with open(path, "w", encoding="utf-8") as handle:
    json.dump(rows, handle)
PY
      then
        exit 2
      fi
    fi
    count=$((count + 1))
  done < <(git log --format=%H "${range}" 2>/dev/null || true)
  COMMIT_MESSAGES_SCANNED="${count}"
}

if [[ -z "${COMMIT_RANGE}" && "${MODE}" == "range" ]]; then
  COMMIT_RANGE="${RANGE}"
fi
if [[ -n "${COMMIT_RANGE}" ]]; then
  scan_commit_messages "${COMMIT_RANGE}"
fi

file_count=0
materialise_scan_tree
scan_materialised_tree

FINDINGS_FILE="${WORK_DIR}/findings.txt"
# Match text never leaves this process. Public CI logs get file, line, rule, and
# description only — the gate must not print the value it exists to stop shipping.
if ! python3 - "${REPORTS}" "${FINDINGS_FILE}" <<'PY'
import json
import pathlib
import sys

reports, out_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
lines = set()
for report in sorted(reports.glob("*.json")):
    try:
        text = report.read_text(encoding="utf-8")
        if not text.strip():
            rows = []
        else:
            rows = json.loads(text)
    except (OSError, json.JSONDecodeError) as exc:
        print(
            f"redaction-scan: FAIL — unreadable gitleaks report {report.name}: {exc}",
            file=sys.stderr,
        )
        raise SystemExit(3)
    if not isinstance(rows, list):
        print(
            f"redaction-scan: FAIL — gitleaks report {report.name} is not a JSON array",
            file=sys.stderr,
        )
        raise SystemExit(3)
    for row in rows:
        lines.add(
            "  {file}:{line}  [{rule}] {desc}".format(
                file=row.get("File", "?"),
                line=row.get("StartLine", 0),
                rule=row.get("RuleID", "?"),
                desc=row.get("Description", ""),
            )
        )
out_path.write_text("".join(f"{line}\n" for line in sorted(lines)), encoding="utf-8")
PY
then
  echo "redaction-scan: FAIL — could not aggregate findings (undecidable; fail-closed)" >&2
  exit 2
fi

FINDINGS="$(wc -l < "${FINDINGS_FILE}" | tr -d ' ')"

# Scope line: always printed so a green exit cannot hide what was not covered.
# uuid_session path exceptions are read from the active config (rule allowlist),
# not hard-coded here, so the printed scope cannot drift from what the engine uses.
# Written to a file rather than captured via $(heredoc): nested quoted heredocs
# inside command substitution trip bash 3.2 quote parsing on macOS.
SCOPE_FILE="${WORK_DIR}/scope.txt"
# Always pass the committed base config as well as the active CONFIG: when org
# rules are loaded, CONFIG is a generated org.toml that only [extend]s the base,
# so uuid_session path exceptions live in BASE_CONFIG, not in the generated file.
if ! python3 - "${CONFIG}" "${BASE_CONFIG}" "${COMMIT_MESSAGES_SCANNED}" "${SCOPE_FILE}" <<'PY'
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
base_config = Path(sys.argv[2])
commit_messages = sys.argv[3]
out_path = Path(sys.argv[4])
marker = 'id = "uuid_session"'


def load_text_with_extends(path, seen=None):
    """Return config text that includes uuid_session, following [extend] path."""
    if seen is None:
        seen = set()
    resolved = str(path.resolve())
    if resolved in seen:
        return ""
    seen.add(resolved)
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return ""
    if marker in text:
        return text
    # org.toml form: [extend]\npath = "/abs/or/rel/base.toml"
    match = re.search(
        r"\[extend\][^\[]*?path\s*=\s*\"([^\"]+)\"",
        text,
        flags=re.S,
    )
    if match:
        ext = Path(match.group(1))
        if not ext.is_absolute():
            ext = path.parent / ext
        return load_text_with_extends(ext, seen)
    return text


# Prefer the active config chain; fall back to the committed base so a generated
# org overlay cannot print path-excused=none while the engine still inherits it.
text = load_text_with_extends(config_path)
if marker not in text:
    text = load_text_with_extends(base_config)
if marker not in text:
    print(
        "redaction-scan: FAIL — uuid_session rule not found in config chain (undecidable)",
        file=sys.stderr,
    )
    raise SystemExit(1)

paths = []
placeholders = []
id_at = text.find(marker)
start = text.rfind("[[rules]]", 0, id_at)
if start < 0:
    start = id_at
rest = text[start + 2 :]
next_rule = rest.find("\n[[rules]]")
next_allow = rest.find("\n[allowlist]")
end_rel = len(rest)
for candidate in (next_rule, next_allow):
    if candidate >= 0:
        end_rel = min(end_rel, candidate)
block = text[start : start + 2 + end_rel]
paths_block = re.search(r"paths\s*=\s*\[(.*?)\]", block, flags=re.S)
if paths_block:
    triple = chr(39) * 3
    found = re.findall(
        triple + r"(.*?)" + triple + r"|\"(.*?)\"",
        paths_block.group(1),
    )
    paths = [a or b for a, b in found]
placeholders = sorted(set(re.findall(r"<[A-Za-z0-9_-]+>", block)))
path_note = ",".join(paths) if paths else "none"
ph_note = "|".join(placeholders) if placeholders else "angle-bracket-forms"
line = (
    "redaction-scan: scope — "
    f"commit-messages={commit_messages} "
    "uuid_session=bare-8-4-4-4-12-hex "
    f"(placeholders={ph_note} out-of-scope; path-excused={path_note})"
)
out_path.write_text(line + "\n", encoding="utf-8")
print(line)
PY
then
  echo "redaction-scan: FAIL — could not build scope line from config (undecidable)" >&2
  exit 2
fi

if [[ "${VERBOSE}" -eq 1 ]]; then
  echo "redaction-scan: mode=${MODE} range=${RANGE:-none} files=${file_count} commit-messages=${COMMIT_MESSAGES_SCANNED} org-rules=${EXTRA_RULE_COUNT} config=$(basename "${CONFIG}") engine=$(gitleaks version 2>/dev/null | head -1)"
fi

if [[ "${FINDINGS}" -gt 0 ]]; then
  echo "redaction-scan: FAIL — ${FINDINGS} finding(s) (fail-closed)" >&2
  cat "${FINDINGS_FILE}" >&2
  echo "redaction-scan: fix, or exempt with a .gitleaksignore fingerprint, then re-run." >&2
  exit 1
fi

echo "redaction-scan: OK — 0 findings (mode=${MODE}, files=${file_count}, commit-messages=${COMMIT_MESSAGES_SCANNED}, org-rules=${EXTRA_RULE_COUNT})"
exit 0
