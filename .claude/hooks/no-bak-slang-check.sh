#!/bin/bash
# no-bak-slang-check.sh: PreToolUse hook (Write|Edit).
# Block "박-" English-calque slang (embed/stick-in/insert family) in Korean markdown.
# Why: .agent/korean-persona.md § vocabulary anti-pattern. A strong translationese signal in Korean technical writing.
# The user strongly dislikes it. On detection, deny and rewrite with the replacement words (넣다 / 추가하다 / 적어두다 /
# 명시하다 / 들어있다 / 기록하다 / 끼워두다).

set -euo pipefail

INPUT=$(cat)

# Self-skip: exclude the hook itself / the anti-pattern definition doc / the Korean dictionary file / postmortems.
# (Reason: the definition itself contains slang words as examples. Prevents self-deadlock.
#  Postmortems are where blocked-hook cases must be written as *meta-quotes*.)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE_PATH" in
  *.claude/hooks/*) exit 0 ;;
  *.agent/korean-persona.md) exit 0 ;;
  *feedback_korean_no_bak_slang.md) exit 0 ;;
  *MEMORY.md) exit 0 ;;
  *docs/wiki/postmortem/temp/*) exit 0 ;;
  *docs/wiki/postmortem/*) exit 0 ;;
esac

# File extensions to check (Korean markdown only)
case "$FILE_PATH" in
  *.md|*.txt|*.mdx) ;;
  *) exit 0 ;;
esac

# Extract Write's .content or Edit's .new_string
CONTENT=$(echo "$INPUT" | jq -r '
  .tool_input.content //
  .tool_input.new_string //
  empty
')

[ -z "$CONTENT" ] && exit 0

# Detect "박-" slang patterns (conjugations of the verbs 박다/박히다 plus compounds like 처박-/들이박-).
# Key: "박" is slang only when it is the first syllable of a word. `(^|[^가-힣])박` forces the preceding
#   character to be "start of line or non-Hangul". This mimics a lookbehind in pure ERE.
# This excludes all words where "박" sits inside a noun, like 도박/압박/박사/대박/반박/수박/호박.
#   (e.g. 도박은 / 압박은 / 도박이다 = noun+particle, prevents false positives)
# Uses only pure grep -oE, so it works on macOS BSD grep, Linux/WSL, and Windows Git Bash (GNU grep).
#   (No dependency on perl, python, or grep -P.)
# Known limitation: 박음질 (sewing) and the noun form 박음 may cause minor false positives. Rare in this context.
BAK_RE='(^|[^가-힣])(내리|들이|뒤|되|처|쳐)?박(는다|는|다|고|지|네|나|아서|아야|아도|아라|아두|아놓|아진|아졌|아버|아|어서|어야|어도|어|은|을|음|으면|으니|으려|으며|으세|으러|았다|았어|았고|았던|았지|았네|았으|았|겠|둔|혀서|혀요|혀있|혀버|혀두|혀놓|혀도|혀야|혀|혔다|혔어|혔고|혔던|혔지|혔|히다|히고|히면|히니|히는|히어|히었|히게|히며|히|힌|힘)'
# A grep -oE match includes the 1 leading non-Hangul char, so strip it with sed and dedup.
MATCHES=$(printf '%s' "$CONTENT" | grep -oE "$BAK_RE" | sed -E 's/^[^가-힣]+//' | sort -u | head -5 | tr '\n' ',' | sed 's/,$//')

if [ -n "$MATCHES" ]; then
  jq -n --arg matches "$MATCHES" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("[Hook] \"박-\" 영어 직역 슬랭 금지 (.agent/korean-persona.md § 어휘 anti-pattern). 대체: 넣다 / 추가하다 / 적어두다 / 명시하다 / 들어있다 / 기록하다 / 끼워두다. 발견: " + $matches)
    }
  }'
fi

exit 0
