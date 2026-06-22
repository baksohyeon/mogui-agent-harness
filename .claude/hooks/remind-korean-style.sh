#!/bin/bash
# remind-korean-style.sh: UserPromptSubmit hook.
# At the start of every user turn, inject the Korean vocabulary anti-pattern rules into the system context.
# The assistant reads it every time before composing a response. Not a 100% block, but increases self-review frequency.
# Why: file-level blocking (.claude/hooks/no-bak-slang-check.sh) alone cannot catch CLI responses.

cat <<'EOF'
[Korean-style reminder]
한국어 응답·문서 작성 시 "박-" 영어 직역 슬랭 금지.
금지: 박는다 / 박았다 / 박혀 / 박힌 / 박둔 / 박아두.
대체: 넣다 / 추가하다 / 적어두다 / 명시하다 / 들어있다 / 기록하다 / 끼워두다.
응답 직전 self-check: 자신의 응답에 위 패턴이 있는지 확인 후 송출.
상세 매핑 표: .agent/korean-persona.md § 어휘 anti-pattern.
EOF
