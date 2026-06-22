#!/bin/bash
# no-emoji-check.sh: PreToolUse hook (Write|Edit). Block emojis from being written.
# Forces technical docs to drop emojis and use text alternatives (not allowed, prohibited, allowed, caution).
# If you do not want this style, remove it from the PreToolUse block in settings.json.

set -euo pipefail

INPUT=$(cat)

# Self-skip: the hook's own code, plus retrospective notes that meta-quote blocked cases.
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE_PATH" in
  *.claude/hooks/*) exit 0 ;;
  *docs/wiki/postmortem/temp/*) exit 0 ;;
  *docs/wiki/postmortem/*) exit 0 ;;
esac

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Detect emojis. Excluded on purpose: arrows (U+2190-21FF), multiplication sign (U+00D7).
PYTHON3="python3"
if command -v python3 >/dev/null 2>&1; then
  case "$(command -v python3)" in
    */WindowsApps/python3*) PYTHON3="python" ;;
  esac
else
  PYTHON3="python"
fi

# Fail-closed: deny when the detector fails.
TMPERR=$(mktemp)
trap 'rm -f "$TMPERR"' EXIT

if ! EMOJIS=$(echo "$CONTENT" | "$PYTHON3" -c "
import sys, re
content = sys.stdin.read()
pattern = re.compile('[\U0001F000-\U0001FAFF☀-➿⬀-⯿]')
matches = pattern.findall(content)
if matches:
    seen = []
    for c in matches:
        if c not in seen:
            seen.append(c)
    print(','.join(seen[:5]))
" 2>"$TMPERR"); then
  ERR_MSG=$(cat "$TMPERR")
  jq -n --arg err "$ERR_MSG" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("[Hook] no-emoji-check.sh detector failed to run. Safe block (fail-closed). Cause: " + $err)
    }
  }'
  exit 0
fi

if [[ -n "$EMOJIS" ]]; then
  jq -n --arg emojis "$EMOJIS" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("[Hook] Emojis are not allowed. Use text alternatives (not allowed, prohibited, allowed, caution, etc.). Found: " + $emojis)
    }
  }'
fi

exit 0
