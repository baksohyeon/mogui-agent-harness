# Scope workflow

> SSOT for judging work size. The `.agents/skills/scope/` skill and `.claude/commands/scope.md` are thin adapters that point here. Keep the canonical procedure in this file.

Scope judges work size. The user does not need to know GSD: the agent reads the request and recommends whether to handle it directly, leave it as a quick, park it in a thread, raise it to a phase/workstream, or promote it to an ADR/guide/postmortem.

This workflow does not run the work itself. Before you start, it gives a short read on which operating unit fits. If the user states the size, that value wins; otherwise the agent estimates it and asks only the questions it needs.

## Core promises

- The user does not need to know GSD command names.
- Small work is not over-raised into a phase.
- Large work is not left in chat alone.
- Discussion with open questions goes into `.planning/threads/` instead of straight into an ADR.
- Long source material is captured in a thread or via GSD capture.
- Wiki promotion is explained against the promotion guide in `docs/wiki/guides/`.

## Work-size judgment

| Size | Signal | Recommended handling |
|---|---|---|
| Very small | One line, typo, link, one config snippet | direct fix or fast |
| Small | Must not be lost, but a phase is overkill | `.planning/quick/` |
| Medium | One module, small feature, needs verification | quick + todo or a small phase |
| Large | Multiple files, multiple decisions, docs/verification involved | GSD phase/workstream |
| Open discussion | Option or decision questions remain | `.planning/threads/` |
| Low confidence | Later idea, hypothesis | `.planning/seeds/` |
| Long-term knowledge | Closed decision, recurring rule, retro | ADR / guide / postmortem |
| Long source material | Evidence, bug report, meeting notes | thread or GSD capture |

## Output format

```markdown
## Scope judgment

### Conclusion
- Recommended handling:
- Reason:

### Classification
| Item | Recommended location | Reason |
|---|---|---|

### Next actions
1. Run now:
2. Record:
3. Needs user confirmation:

### Verification
- After code/doc changes:
  - `bash scripts/wiki-lint.sh` (when wiki/agentic docs change)
  - `bash scripts/verify-agent-ssot.sh` (when router/.agent/hook change)
  - `git diff --check`
```

## Example

A small doc cleanup gets a quick or direct fix. A long guide rewrite that moves several docs and a stale guard together counts as phase/workstream level. A request with an open decision question like "Should we change the search strategy?" goes into a thread, then gets promoted to an ADR once the conclusion is closed.

## Related docs

- `.agent/workflows/triple-crown.md`: the 5-phase cycle by size
- `.agent/workflows/automation-patterns.md`: 4 patterns by work type
- `docs/wiki/guides/04-gsd-llm-wiki-agent-flow.md`: flow for splitting natural-language input into planning/wiki
