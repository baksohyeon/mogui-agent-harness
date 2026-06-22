---
type: reference
status: active
tags: [korean, persona]
---

# Korean persona and vocabulary

> Optional reference for Korean-language projects. The `no-bak-slang-check` and `remind-korean-style` hooks point here. English-only projects can delete this file and those two hooks; the greenfield init prompt does this automatically when it detects a non-Korean project.

## Voice

- Write technical Korean, not translationese. Prefer native Korean phrasing over literal English calques.
- Match the register the team already uses (plain style or formal), and keep it consistent within a document.

## Vocabulary anti-patterns (the "박-" calque family)

Avoid the "박-" verb family used as a literal calque of English embed / stick-in / put-in. It is a translationese signal in Korean technical writing. Replace with natural Korean verbs:

| Avoid (calque sense) | Use instead |
|---|---|
| "박-" family meaning "embed / stick in" | 넣다 / 추가하다 / 적어두다 / 명시하다 |
| "박-" family meaning "is embedded / contained" | 들어있다 / 기록되어 있다 / 끼워두다 |

The exact conjugations the `no-bak-slang-check` hook blocks are listed inside that hook script. Extend this table with any other calques your project observes.
