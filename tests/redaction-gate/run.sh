#!/usr/bin/env bash
# Regression tests for the redaction gate.
# Synthetic values only. No real credentials, no real home paths.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCANNER="${ROOT}/scripts/redaction-scan.sh"
CONFIG="${ROOT}/config/gitleaks.toml"

# Synthetic fixtures only. Path allowlist covers this tests/ tree so the
# fixtures here do not trip the repository's own gate when scanned.
# UUID is a made-up hex shape, never a live session identifier.
SYN_HOME="/Users/exampleuser/project/notes"
SYN_TOKEN="ghp_$(printf 'A%.0s' {1..36})"
SYN_AWS="AKIA$(printf 'Z%.0s' {1..16})"
SYN_UUID="aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"

pass=0
fail=0

ok() {
  pass=$((pass + 1))
  echo "  PASS  $1"
}

bad() {
  fail=$((fail + 1))
  echo "  FAIL  $1" >&2
}

require_gitleaks() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    echo "tests/redaction-gate: gitleaks required on PATH" >&2
    exit 2
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "tests/redaction-gate: python3 required on PATH" >&2
    exit 2
  fi
}

# Isolated git repo that installs the gate from this tree.
make_fixture_repo() {
  local repo="$1"
  rm -rf "${repo}"
  mkdir -p "${repo}/scripts" "${repo}/config"
  git -C "${repo}" init -q
  git -C "${repo}" config user.name "gate-test"
  git -C "${repo}" config user.email "gate-test@example.com"
  cp "${SCANNER}" "${repo}/scripts/redaction-scan.sh"
  chmod +x "${repo}/scripts/redaction-scan.sh"
  cp "${CONFIG}" "${repo}/config/gitleaks.toml"
  printf '# empty\n' > "${repo}/scripts/redaction-allowlist.txt"
  printf 'clean\n' > "${repo}/README.md"
  git -C "${repo}" add -A
  git -C "${repo}" commit -q -m "fixture base"
}

run_scan() {
  local repo="$1"
  shift
  (
    cd "${repo}"
    # Drop host org patterns so tests see only the committed ruleset unless set.
    env -u REDACTION_EXTRA_PATTERNS -u REDACTION_REQUIRE_EXTRA -u GITLEAKS_CONFIG \
      "$@" bash scripts/redaction-scan.sh
  )
}

echo "== redaction-gate regression =="
require_gitleaks
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

# ---------------------------------------------------------------------------
# Major: unusable organization rules must not exit 0 (reduced coverage).
# ---------------------------------------------------------------------------
echo "-- Major: unusable org rules exit 2"
REPO="${WORKDIR}/unusable-org"
make_fixture_repo "${REPO}"
printf 'bad_rule|broken|(\n' > "${WORKDIR}/bad-org.rules"
set +e
OUT="$(
  cd "${REPO}"
  REDACTION_EXTRA_PATTERNS="${WORKDIR}/bad-org.rules" \
    bash scripts/redaction-scan.sh 2>&1
)"
EC=$?
set -e
if [[ "${EC}" -eq 2 ]] && [[ "${OUT}" == *"unusable"* ]]; then
  ok "unusable org rules -> exit 2"
else
  bad "unusable org rules expected exit 2 with unusable message (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# Major-adjacent: missing REDACTION_EXTRA_PATTERNS path when set -> exit 2
# ---------------------------------------------------------------------------
echo "-- Major: missing org rules file exits 2"
set +e
OUT="$(
  cd "${REPO}"
  REDACTION_EXTRA_PATTERNS="${WORKDIR}/does-not-exist.rules" \
    bash scripts/redaction-scan.sh 2>&1
)"
EC=$?
set -e
if [[ "${EC}" -eq 2 ]]; then
  ok "missing org rules file -> exit 2"
else
  bad "missing org rules file expected exit 2 (got exit=${EC})"
fi

# ---------------------------------------------------------------------------
# P1: placeholder word on the same line must not excuse a synthetic credential.
# ---------------------------------------------------------------------------
echo "-- P1: placeholder line cannot hide synthetic credential"
REPO="${WORKDIR}/placeholder-bypass"
make_fixture_repo "${REPO}"
# Line contains both a synthetic github token shape and the word TODO.
printf 'token %s TODO\n' "${SYN_TOKEN}" > "${REPO}/leak.txt"
git -C "${REPO}" add leak.txt
git -C "${REPO}" commit -q -m "plant"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]] && [[ "${OUT}" == *"finding"* ]]; then
  ok "synthetic credential beside TODO is blocked (exit 1)"
else
  bad "expected exit 1 finding for credential+TODO line (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

echo "-- P1: placeholder word xxx cannot hide synthetic aws key"
printf 'aws %s xxx\n' "${SYN_AWS}" > "${REPO}/leak2.txt"
git -C "${REPO}" add leak2.txt
git -C "${REPO}" commit -q -m "plant2"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]]; then
  ok "synthetic aws key beside xxx is blocked (exit 1)"
else
  bad "expected exit 1 for aws+xxx line (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P2: match values (home path) never appear in scanner output.
# ---------------------------------------------------------------------------
echo "-- P2: findings redact match values"
REPO="${WORKDIR}/mask"
make_fixture_repo "${REPO}"
printf 'path %s\n' "${SYN_HOME}" > "${REPO}/home.txt"
git -C "${REPO}" add home.txt
git -C "${REPO}" commit -q -m "plant home"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]] \
  && [[ "${OUT}" == *"[home_path]"* ]] \
  && [[ "${OUT}" != *"/Users/exampleuser"* ]]; then
  ok "home_path finding without raw match text"
else
  bad "expected home_path finding with fully redacted match (exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P2: malformed gitleaks report must make the scanner exit 2 (fail-closed).
# ---------------------------------------------------------------------------
echo "-- P2: unreadable report makes scanner exit 2"
REPO="${WORKDIR}/bad-report"
make_fixture_repo "${REPO}"
FAKE_BIN="${WORKDIR}/fake-gitleaks-bin"
mkdir -p "${FAKE_BIN}"
# gitleaks that writes a malformed report and exits 0 (findings path with
# --exit-code 0). The scanner must treat unreadable JSON as undecidable exit 2.
cat > "${FAKE_BIN}/gitleaks" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "version" ]]; then
  echo "8.30.1"
  exit 0
fi
report=""
args=("$@")
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "--report-path" ]]; then
    report="${args[$((i + 1))]:-}"
  fi
done
if [[ -z "${report}" ]]; then
  echo "fake-gitleaks: missing --report-path" >&2
  exit 2
fi
printf '{not-json\n' > "${report}"
exit 0
EOF
chmod +x "${FAKE_BIN}/gitleaks"
set +e
OUT="$(
  cd "${REPO}"
  PATH="${FAKE_BIN}:/usr/bin:/bin:/usr/local/bin" \
    env -u REDACTION_EXTRA_PATTERNS -u REDACTION_REQUIRE_EXTRA -u GITLEAKS_CONFIG \
    bash scripts/redaction-scan.sh 2>&1
)"
EC=$?
set -e
if [[ "${EC}" -eq 2 ]] && [[ "${OUT}" == *"unreadable"* || "${OUT}" == *"undecidable"* || "${OUT}" == *"aggregate"* ]]; then
  ok "malformed gitleaks report -> scanner exit 2"
else
  bad "malformed report expected scanner exit 2 (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P2: python3 missing -> exit 2 with install hint
# ---------------------------------------------------------------------------
echo "-- P2: missing python3 exits 2"
REPO="${WORKDIR}/nopy"
make_fixture_repo "${REPO}"
MIN_BIN="${WORKDIR}/min-path"
mkdir -p "${MIN_BIN}" "${WORKDIR}/tmp" "${WORKDIR}/empty-home"
# Curated PATH: required tools only, no python3. Fail the test if python3 is
# still resolvable — never pass as "could not scrub".
for cmd in bash sh git gitleaks mktemp mkdir ln cp dirname basename cat rm tr wc \
  sed grep head printf env uname cut sort find awk; do
  src="$(command -v "${cmd}" 2>/dev/null || true)"
  if [[ -n "${src}" && -x "${src}" ]]; then
    ln -sf "${src}" "${MIN_BIN}/${cmd}"
  fi
done
if [[ ! -x "${MIN_BIN}/gitleaks" || ! -x "${MIN_BIN}/git" || ! -x "${MIN_BIN}/bash" ]]; then
  bad "missing python3 test could not build minimal PATH (need gitleaks, git, bash)"
elif PATH="${MIN_BIN}" command -v python3 >/dev/null 2>&1; then
  bad "missing python3 test still resolves python3 on curated PATH — not testing the branch"
else
  set +e
  OUT="$(
    cd "${REPO}"
    env -i \
      PATH="${MIN_BIN}" \
      HOME="${WORKDIR}/empty-home" \
      TMPDIR="${WORKDIR}/tmp" \
      bash scripts/redaction-scan.sh 2>&1
  )"
  EC=$?
  set -e
  if [[ "${EC}" -eq 2 ]] && [[ "${OUT}" == *"python3"* ]]; then
    ok "missing python3 -> exit 2 with hint"
  else
    bad "missing python3 expected exit 2 with hint (got exit=${EC})"
    echo "${OUT}" | sed 's/^/    /' >&2
  fi
fi

# ---------------------------------------------------------------------------
# P2: --staged reads index blobs, not worktree
# ---------------------------------------------------------------------------
echo "-- P2: --staged scans index blobs"
REPO="${WORKDIR}/staged"
make_fixture_repo "${REPO}"
printf 'path %s\n' "${SYN_HOME}" > "${REPO}/staged-secret.txt"
git -C "${REPO}" add staged-secret.txt
# Worktree cleaned of the secret after staging.
printf 'clean worktree\n' > "${REPO}/staged-secret.txt"
set +e
OUT="$(
  cd "${REPO}"
  env -u REDACTION_EXTRA_PATTERNS bash scripts/redaction-scan.sh --staged 2>&1
)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]]; then
  ok "--staged finds secret in index after worktree clean"
else
  bad "--staged should fail on index secret (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P2: single-process batch still catches a finding (smoke, not process count)
# ---------------------------------------------------------------------------
echo "-- P2: batched scan still detects findings"
REPO="${WORKDIR}/batch"
make_fixture_repo "${REPO}"
for i in 1 2 3 4 5; do
  printf 'ok %s\n' "$i" > "${REPO}/f${i}.txt"
done
printf 'path %s\n' "${SYN_HOME}" > "${REPO}/f-leak.txt"
git -C "${REPO}" add -A
git -C "${REPO}" commit -q -m "many files"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]] && [[ "${OUT}" == *"finding"* ]]; then
  ok "batched materialised scan detects finding"
else
  bad "batched scan expected exit 1 (got ${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P3: --allowlist without value exits 2
# ---------------------------------------------------------------------------
echo "-- P3: --allowlist without value exits 2"
REPO="${WORKDIR}/allowlist-arg"
make_fixture_repo "${REPO}"
set +e
OUT="$(
  cd "${REPO}"
  env -u REDACTION_EXTRA_PATTERNS bash scripts/redaction-scan.sh --allowlist 2>&1
)"
EC=$?
set -e
if [[ "${EC}" -eq 2 ]] && [[ "${OUT}" == *"--allowlist"* ]]; then
  ok "--allowlist without value -> exit 2"
else
  bad "--allowlist without value expected exit 2 (got ${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# P2: .gitleaksignore fingerprints still suppress after materialised scan.
# ---------------------------------------------------------------------------
echo "-- P2: .gitleaksignore uses repo-relative fingerprints"
REPO="${WORKDIR}/ignore-fp"
make_fixture_repo "${REPO}"
printf 'path %s\n' "${SYN_HOME}" > "${REPO}/ignored-leak.txt"
git -C "${REPO}" add ignored-leak.txt
git -C "${REPO}" commit -q -m "plant"
# Fingerprint shape measured from gitleaks dir .: path:rule:line
printf 'ignored-leak.txt:home_path:1\n' > "${REPO}/.gitleaksignore"
git -C "${REPO}" add .gitleaksignore
git -C "${REPO}" commit -q -m "ignore"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 0 ]] && [[ "${OUT}" == *"0 findings"* ]]; then
  ok ".gitleaksignore suppresses finding via repo-relative fingerprint"
else
  bad ".gitleaksignore should yield exit 0 (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# Owner: bare synthetic UUID is blocked by uuid_session.
# ---------------------------------------------------------------------------
echo "-- Owner: synthetic UUID is blocked"
REPO="${WORKDIR}/uuid-block"
make_fixture_repo "${REPO}"
printf 'session %s\n' "${SYN_UUID}" > "${REPO}/session.txt"
git -C "${REPO}" add session.txt
git -C "${REPO}" commit -q -m "plant uuid"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 1 ]] \
  && [[ "${OUT}" == *"[uuid_session]"* ]] \
  && [[ "${OUT}" != *"${SYN_UUID}"* ]] \
  && [[ "${OUT}" == *"uuid_session=bare-8-4-4-4-12-hex"* ]] \
  && [[ "${OUT}" == *"path-excused="* ]]; then
  ok "synthetic UUID blocked (exit 1, rule named, value redacted, scope line present)"
else
  bad "expected exit 1 uuid_session without raw UUID (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# Owner: angle-bracket placeholders pass (not bare UUID shape).
# ---------------------------------------------------------------------------
echo "-- Owner: <tracker-id> and <session-id> placeholders pass"
REPO="${WORKDIR}/uuid-placeholder"
make_fixture_repo "${REPO}"
printf 'tracker <tracker-id> session <session-id>\n' > "${REPO}/placeholders.txt"
git -C "${REPO}" add placeholders.txt
git -C "${REPO}" commit -q -m "placeholders"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 0 ]] && [[ "${OUT}" == *"0 findings"* ]]; then
  ok "placeholder forms <tracker-id>/<session-id> pass"
else
  bad "placeholders expected exit 0 (got exit=${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

# ---------------------------------------------------------------------------
# Clean tree still passes
# ---------------------------------------------------------------------------
echo "-- clean fixture still exits 0"
REPO="${WORKDIR}/clean"
make_fixture_repo "${REPO}"
set +e
OUT="$(run_scan "${REPO}" 2>&1)"
EC=$?
set -e
if [[ "${EC}" -eq 0 ]] && [[ "${OUT}" == *"0 findings"* ]]; then
  ok "clean fixture -> exit 0"
else
  bad "clean fixture expected exit 0 (got ${EC})"
  echo "${OUT}" | sed 's/^/    /' >&2
fi

echo
echo "redaction-gate: ${pass} passed, ${fail} failed"
if [[ "${fail}" -gt 0 ]]; then
  exit 1
fi
exit 0
