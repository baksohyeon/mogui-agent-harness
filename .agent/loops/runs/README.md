# runs/ — loop run history (append-only)

One file per loop run. Never edit existing files (audit trail).

- Filename: `<loop>-YYYYMMDD-HHMM.md` (e.g. `daily-triage-20260101-0900.md`)
- Contents: run timestamp, scope (since last processed commit), item count, spend (tokens / tool calls / wall-clock), whether a pause/escalation fired
- Summary state lives in `../<loop>.STATE.md`; raw history lives here. Do not mix the two (anti-pattern: no execution history).
